;; NFT Marketplace - Initial Implementation
;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-listing-expired (err u102))
(define-constant err-price-mismatch (err u103))

;; Define data variables
(define-data-var marketplace-fee uint u25) ;; 2.5% fee
(define-data-var next-listing-id uint u0)

;; Define data maps
(define-map listings
    uint
    {
        token-id: uint,
        price: uint,
        seller: principal,
        expiry: uint,
        is-active: bool
    }
)

(define-map tokens
    uint
    {
        owner: principal,
        metadata-url: (string-ascii 256)
    }
)

;; NFT creation
(define-public (mint (metadata-url (string-ascii 256)))
    (let
        ((token-id (var-get next-listing-id)))
        (try! (validate-metadata metadata-url))
        (map-set tokens token-id
            {
                owner: tx-sender,
                metadata-url: metadata-url
            }
        )
        (var-set next-listing-id (+ token-id u1))
        (ok token-id)
    )
)

;; List NFT for sale
(define-public (list-token (token-id uint) (price uint) (expiry uint))
    (let
        ((owner (get owner (map-get? tokens token-id))))
        (asserts! (is-eq tx-sender owner) err-not-token-owner)
        (asserts! (> expiry block-height) err-listing-expired)
        
        (map-set listings token-id
            {
                token-id: token-id,
                price: price,
                seller: tx-sender,
                expiry: expiry,
                is-active: true
            }
        )
        (ok true)
    )
)

;; Purchase NFT
(define-public (purchase-token (listing-id uint))
    (let
        ((listing (unwrap! (map-get? listings listing-id) err-listing-expired))
         (price (get price listing))
         (seller (get seller listing)))
        
        ;; Validate listing
        (asserts! (get is-active listing) err-listing-expired)
        (asserts! (<= block-height (get expiry listing)) err-listing-expired)
        
        ;; Process payment
        (try! (stx-transfer? price tx-sender seller))
        
        ;; Transfer NFT ownership
        (map-set tokens (get token-id listing)
            {
                owner: tx-sender,
                metadata-url: (get metadata-url (unwrap! (map-get? tokens (get token-id listing)) err-listing-expired))
            }
        )
        
        ;; Update listing status
        (map-set listings listing-id
            (merge listing { is-active: false })
        )
        
        (ok true)
    )
)

;; Helper functions
(define-private (validate-metadata (metadata-url (string-ascii 256)))
    (if (is-eq (len metadata-url) u0)
        (err u104)
        (ok true)
    )
)

;; Read-only functions
(define-read-only (get-listing (listing-id uint))
    (map-get? listings listing-id)
)

(define-read-only (get-token (token-id uint))
    (map-get? tokens token-id)
)

(define-read-only (get-marketplace-fee)
    (ok (var-get marketplace-fee))
)