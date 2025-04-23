;; Prescriber Verification Contract
;; This contract validates authorized healthcare providers

(define-data-var admin principal tx-sender)

;; Map to store verified prescribers
(define-map prescribers principal
  {
    license-number: (string-utf8 20),
    specialty: (string-utf8 50),
    is-active: bool,
    verification-date: uint
  }
)

;; Public function to register a new prescriber (admin only)
(define-public (register-prescriber
    (prescriber-id principal)
    (license-number (string-utf8 20))
    (specialty (string-utf8 50)))
  (begin
    (asserts! (is-admin) (err u403))
    (asserts! (is-none (map-get? prescribers prescriber-id)) (err u100))
    (ok (map-set prescribers
      prescriber-id
      {
        license-number: license-number,
        specialty: specialty,
        is-active: true,
        verification-date: block-height
      }
    ))
  )
)

;; Public function to deactivate a prescriber (admin only)
(define-public (deactivate-prescriber (prescriber-id principal))
  (begin
    (asserts! (is-admin) (err u403))
    (asserts! (is-some (map-get? prescribers prescriber-id)) (err u404))
    (match (map-get? prescribers prescriber-id)
      prescriber-data (ok (map-set prescribers
        prescriber-id
        (merge prescriber-data { is-active: false })
      ))
      (err u404)
    )
  )
)

;; Public function to reactivate a prescriber (admin only)
(define-public (reactivate-prescriber (prescriber-id principal))
  (begin
    (asserts! (is-admin) (err u403))
    (asserts! (is-some (map-get? prescribers prescriber-id)) (err u404))
    (match (map-get? prescribers prescriber-id)
      prescriber-data (ok (map-set prescribers
        prescriber-id
        (merge prescriber-data { is-active: true })
      ))
      (err u404)
    )
  )
)

;; Read-only function to check if a prescriber is verified and active
(define-read-only (is-verified-prescriber (prescriber-id principal))
  (match (map-get? prescribers prescriber-id)
    prescriber-data (get is-active prescriber-data)
    false
  )
)

;; Read-only function to get prescriber details
(define-read-only (get-prescriber-details (prescriber-id principal))
  (map-get? prescribers prescriber-id)
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
