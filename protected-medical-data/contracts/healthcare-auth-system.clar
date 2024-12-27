;; Personalized Medicine Contract
;; Handles patient medical records, prescriptions, and healthcare provider authorizations

;; Error codes
(define-constant ERR-UNAUTHORIZED-ACCESS (err u1))
(define-constant ERR-DUPLICATE-PATIENT-RECORD (err u2))
(define-constant ERR-PATIENT-RECORD-NOT-FOUND (err u3))
(define-constant ERR-INVALID-PRESCRIPTION-DATA (err u4))
(define-constant ERR-DUPLICATE-HEALTHCARE-PROVIDER (err u5))
(define-constant ERR-HEALTHCARE-PROVIDER-NOT-FOUND (err u6))
(define-constant ERR-PRESCRIPTION-LIST-OVERFLOW (err u7))
(define-constant ERR-INVALID-INPUT (err u8))
(define-constant ERR-PROVIDER-ALREADY-AUTHORIZED (err u9))
(define-constant ERR-MAX-AUTHORIZED-PROVIDERS-REACHED (err u10))

;; Data structures
(define-map patient-health-records 
    { patient-blockchain-address: principal }
    {
        complete-health-history: (string-ascii 256),
        dna-sequencing-data: (string-ascii 256),
        active-medication-list: (list 10 uint),
        authorized-medical-providers: (list 5 principal)
    }
)

(define-map medical-provider-directory
    { provider-blockchain-address: principal }
    {
        medical-specialty-field: (string-ascii 64),
        state-license-number: (string-ascii 32),
        provider-license-status: bool
    }
)

(define-map medication-prescriptions
    { prescription-unique-id: uint }
    {
        patient-blockchain-address: principal,
        authorized-prescriber: principal,
        medication-name: (string-ascii 64),
        medication-instructions: (string-ascii 32),
        prescription-valid-from: uint,
        prescription-valid-until: uint,
        prescription-is-active: bool
    }
)

;; Global variables
(define-data-var total-prescriptions-counter uint u0)
(define-data-var prescription-tracking-list (list 100 uint) (list))

;; Helper functions for input validation
(define-private (validate-long-string (string-input (string-ascii 256)))
    (and 
        (is-eq (len string-input) (len (concat string-input "")))
        (>= (len string-input) u1)
        (<= (len string-input) u256)
    )
)

(define-private (validate-medium-string (string-input (string-ascii 64)))
    (and 
        (is-eq (len string-input) (len (concat string-input "")))
        (>= (len string-input) u1)
        (<= (len string-input) u64)
    )
)

(define-private (validate-short-string (string-input (string-ascii 32)))
    (and 
        (is-eq (len string-input) (len (concat string-input "")))
        (>= (len string-input) u1)
        (<= (len string-input) u32)
    )
)

;; Authorization verification
(define-private (check-provider-authorization (patient-blockchain-address principal) (provider-blockchain-address principal))
    (let ((patient-health-data (get-patient-health-record patient-blockchain-address)))
        (match patient-health-data
            health-record (is-some (index-of (get authorized-medical-providers health-record) provider-blockchain-address))
            false
        )
    )
)

;; Patient management functions
(define-public (register-patient (complete-health-history (string-ascii 256)) (dna-sequencing-data (string-ascii 256)))
    (let ((patient-blockchain-address tx-sender))
        (asserts! (validate-long-string complete-health-history) ERR-INVALID-INPUT)
        (asserts! (validate-long-string dna-sequencing-data) ERR-INVALID-INPUT)
        (asserts! (is-none (get-patient-health-record patient-blockchain-address)) ERR-DUPLICATE-PATIENT-RECORD)
        (ok (map-set patient-health-records
            { patient-blockchain-address: patient-blockchain-address }
            {
                complete-health-history: complete-health-history,
                dna-sequencing-data: dna-sequencing-data,
                active-medication-list: (list),
                authorized-medical-providers: (list)
            }
        ))
    )
)

(define-read-only (get-patient-health-record (patient-blockchain-address principal))
    (map-get? patient-health-records { patient-blockchain-address: patient-blockchain-address })
)

(define-public (authorize-medical-provider (provider-blockchain-address principal))
    (let (
        (patient-blockchain-address tx-sender)
        (patient-health-data (get-patient-health-record patient-blockchain-address))
        )
        (asserts! (is-some patient-health-data) ERR-PATIENT-RECORD-NOT-FOUND)
        (let ((existing-health-record (unwrap-panic patient-health-data)))
            (asserts! (< (len (get authorized-medical-providers existing-health-record)) u5) ERR-MAX-AUTHORIZED-PROVIDERS-REACHED)
            (asserts! (is-none (index-of (get authorized-medical-providers existing-health-record) provider-blockchain-address)) ERR-PROVIDER-ALREADY-AUTHORIZED)
            (ok (map-set patient-health-records
                { patient-blockchain-address: patient-blockchain-address }
                (merge existing-health-record
                    { authorized-medical-providers: 
                        (unwrap! (as-max-len? 
                            (append (get authorized-medical-providers existing-health-record) provider-blockchain-address)
                            u5
                        ) ERR-MAX-AUTHORIZED-PROVIDERS-REACHED)
                    }
                )
            ))
        )
    )
)

;; Healthcare provider functions
(define-public (register-medical-provider (medical-specialty-field (string-ascii 64)) (state-license-number (string-ascii 32)))
    (let ((provider-blockchain-address tx-sender))
        (asserts! (validate-medium-string medical-specialty-field) ERR-INVALID-INPUT)
        (asserts! (validate-short-string state-license-number) ERR-INVALID-INPUT)
        (asserts! (is-none (get-provider-profile provider-blockchain-address)) ERR-DUPLICATE-HEALTHCARE-PROVIDER)
        (ok (map-set medical-provider-directory
            { provider-blockchain-address: provider-blockchain-address }
            {
                medical-specialty-field: medical-specialty-field,
                state-license-number: state-license-number,
                provider-license-status: true
            }
        ))
    )
)

(define-read-only (get-provider-profile (provider-blockchain-address principal))
    (map-get? medical-provider-directory { provider-blockchain-address: provider-blockchain-address })
)

;; Prescription management functions
(define-private (generate-prescription-unique-id)
    (let ((current-prescription-count (var-get total-prescriptions-counter)))
        (var-set total-prescriptions-counter (+ current-prescription-count u1))
        current-prescription-count
    )
)

(define-public (create-prescription 
    (patient-blockchain-address principal)
    (medication-name (string-ascii 64))
    (medication-instructions (string-ascii 32))
    (prescription-valid-from uint)
    (prescription-valid-until uint)
)
    (let (
        (authorized-prescriber tx-sender)
        (prescription-unique-id (generate-prescription-unique-id))
    )
        (asserts! (check-provider-authorization patient-blockchain-address authorized-prescriber) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (< prescription-valid-from prescription-valid-until) ERR-INVALID-PRESCRIPTION-DATA)
        (asserts! (validate-medium-string medication-name) ERR-INVALID-INPUT)
        (asserts! (validate-short-string medication-instructions) ERR-INVALID-INPUT)

        ;; Add prescription record
        (map-set medication-prescriptions
            { prescription-unique-id: prescription-unique-id }
            {
                patient-blockchain-address: patient-blockchain-address,
                authorized-prescriber: authorized-prescriber,
                medication-name: medication-name,
                medication-instructions: medication-instructions,
                prescription-valid-from: prescription-valid-from,
                prescription-valid-until: prescription-valid-until,
                prescription-is-active: true
            }
        )

        ;; Add prescription ID to tracking list
        (match (as-max-len? (append (var-get prescription-tracking-list) prescription-unique-id) u100)
            success (ok (var-set prescription-tracking-list success))
            ERR-PRESCRIPTION-LIST-OVERFLOW
        )
    )
)

(define-read-only (get-prescription-details (prescription-unique-id uint))
    (map-get? medication-prescriptions { prescription-unique-id: prescription-unique-id })
)

(define-public (deactivate-prescription (prescription-unique-id uint))
    (let (
        (requester-address tx-sender)
        (prescription-data (get-prescription-details prescription-unique-id))
    )
        (asserts! (is-some prescription-data) ERR-INVALID-PRESCRIPTION-DATA)
        (let ((existing-prescription-data (unwrap-panic prescription-data)))
            (asserts! (or
                (is-eq requester-address (get authorized-prescriber existing-prescription-data))
                (is-eq requester-address (get patient-blockchain-address existing-prescription-data))
            ) ERR-UNAUTHORIZED-ACCESS)
            (ok (map-set medication-prescriptions
                { prescription-unique-id: prescription-unique-id }
                (merge existing-prescription-data { prescription-is-active: false })
            ))
        )
    )
)

(define-read-only (get-active-patient-prescriptions (patient-blockchain-address principal))
    (ok (fold filter-active-prescriptions-fold (var-get prescription-tracking-list) (list)))
)

(define-private (filter-active-prescriptions-fold 
    (prescription-unique-id uint) 
    (filtered-prescription-list (list 100 uint))
)
    (let ((patient-blockchain-address tx-sender))
        (if (is-prescription-active patient-blockchain-address prescription-unique-id)
            (unwrap! (as-max-len? (append filtered-prescription-list prescription-unique-id) u100) filtered-prescription-list)
            filtered-prescription-list
        )
    )
)

(define-private (is-prescription-active (patient-blockchain-address principal) (prescription-unique-id uint))
    (check-active-prescription-for-patient prescription-unique-id patient-blockchain-address)
)

(define-private (check-active-prescription-for-patient (prescription-unique-id uint) (patient-blockchain-address principal))
    (match (get-prescription-details prescription-unique-id)
        prescription-data 
            (and 
                (is-eq (get patient-blockchain-address prescription-data) patient-blockchain-address)
                (get prescription-is-active prescription-data)
            )
        false
    )
)

(define-read-only (verify-medical-provider-credentials (provider-blockchain-address principal))
    (match (get-provider-profile provider-blockchain-address)
        provider-data (get provider-license-status provider-data)
        false
    )
)