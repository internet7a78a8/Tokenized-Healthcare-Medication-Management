;; Patient Verification Contract
;; This contract securely manages patient identities

(define-data-var admin principal tx-sender)

;; Map to store verified patients
(define-map patients principal
  {
    patient-id: (string-utf8 20),
    is-active: bool,
    registration-date: uint
  }
)

;; Map to store patient consent for data access
(define-map patient-consent
  { patient: principal, accessor: principal }
  { has-consent: bool, granted-at: uint }
)

;; Public function to register a new patient
(define-public (register-patient (patient-id (string-utf8 20)))
  (begin
    (asserts! (is-none (map-get? patients tx-sender)) (err u100))
    (ok (map-set patients
      tx-sender
      {
        patient-id: patient-id,
        is-active: true,
        registration-date: block-height
      }
    ))
  )
)

;; Public function to deactivate a patient (self or admin)
(define-public (deactivate-patient (patient principal))
  (begin
    (asserts! (or (is-eq tx-sender patient) (is-admin)) (err u403))
    (asserts! (is-some (map-get? patients patient)) (err u404))
    (match (map-get? patients patient)
      patient-data (ok (map-set patients
        patient
        (merge patient-data { is-active: false })
      ))
      (err u404)
    )
  )
)

;; Public function to reactivate a patient (self or admin)
(define-public (reactivate-patient (patient principal))
  (begin
    (asserts! (or (is-eq tx-sender patient) (is-admin)) (err u403))
    (asserts! (is-some (map-get? patients patient)) (err u404))
    (match (map-get? patients patient)
      patient-data (ok (map-set patients
        patient
        (merge patient-data { is-active: true })
      ))
      (err u404)
    )
  )
)

;; Public function to grant consent to a healthcare provider
(define-public (grant-consent (provider principal))
  (begin
    (asserts! (is-some (map-get? patients tx-sender)) (err u404))
    (ok (map-set patient-consent
      { patient: tx-sender, accessor: provider }
      { has-consent: true, granted-at: block-height }
    ))
  )
)

;; Public function to revoke consent from a healthcare provider
(define-public (revoke-consent (provider principal))
  (begin
    (asserts! (is-some (map-get? patients tx-sender)) (err u404))
    (ok (map-set patient-consent
      { patient: tx-sender, accessor: provider }
      { has-consent: false, granted-at: block-height }
    ))
  )
)

;; Read-only function to check if a patient is verified and active
(define-read-only (is-verified-patient (patient principal))
  (match (map-get? patients patient)
    patient-data (get is-active patient-data)
    false
  )
)

;; Read-only function to check if a provider has consent to access patient data
(define-read-only (has-consent (patient principal) (provider principal))
  (match (map-get? patient-consent { patient: patient, accessor: provider })
    consent-data (get has-consent consent-data)
    false
  )
)

;; Read-only function to get patient details (self, admin, or consented provider)
(define-read-only (get-patient-details (patient principal))
  (begin
    (asserts! (or
      (is-eq tx-sender patient)
      (is-admin)
      (has-consent patient tx-sender)
    ) none)
    (map-get? patients patient)
  )
)

;; Private function to check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Public function to transfer admin rights (admin only)
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (ok (var-set admin new-admin))
  )
)
