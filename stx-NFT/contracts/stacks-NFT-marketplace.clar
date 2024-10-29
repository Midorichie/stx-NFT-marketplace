;; NFT Marketplace - Enhanced Implementation v2
;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-listing-expired (err u102))
(define-constant err-price-mismatch (err u103))
(define-constant err-invalid-metadata (err u104))
(define-constant err-listing-not-found (err u105))
(define-constant err-nft-locked (err u106))
(define-constant err-insufficient-balance (err u107))
(define-constant err-already-listed (err u108))

;; Define data variables
(define-data-var marketplace-fee uint u25) ;; 2.5% fee
(define-data-var next-listing-id uint u0)
(define-data-var next-token-id uint u0)
(define-data-var paused bool false)

;; Enhanced data maps
(define-map listings
    uint
    {
        token-id: uint,
        price: uint,
        seller: principal,
        expiry: uint,
        is-active: bool,
        royalty-percentage: uint,
        original-creator: principal
    }
)

(define-map tokens
    uint
    {
        owner: principal,
        metadata-url: (string-ascii 256),
        creator: principal,
        is-locked: bool,
        created-at: uint,
        royalty-percentage: uint
    }
)

;; New: Token offer system
(define-map token-offers
    { token-id: uint, buyer: principal }
    {
        price: uint,
        expiry: uint,
        is-active: bool
    }
)

;; New: Transaction history
(define-map transaction-history
    uint
    (list 10 {
        token-id: uint,
        from: principal,
        to: principal,
        price: uint,
        timestamp: uint,
        action: (string-ascii 20)
    })
)

;; Enhanced NFT creation
(define-public (mint (metadata-url (string-ascii 256)) (royalty-percentage uint))
    (let
        ((token-id (var-get next-token-id)))
        (asserts! (not (var-get paused)) err-owner-only)
        (asserts! (<= royalty-percentage u100) (err u110))
        (try! (validate-metadata metadata-url))
        
        (map-set tokens token-id
            {
                owner: tx-sender,
                metadata-url: metadata-url,
                creator: tx-sender,
                is-locked: false,
                created-at: block-height,
                royalty-percentage: royalty-percentage
            }
        )
        
        ;; Record creation in history
        (try! (record-transaction token-id tx-sender tx-sender u0 "MINT"))
        
        (var-set next-token-id (+ token-id u1))
        (ok token-id)
    )
)

;; Enhanced listing with royalties
(define-public (list-token (token-id uint) (price uint) (expiry uint))
    (let
        ((token (unwrap! (map-get? tokens token-id) err-listing-not-found))
         (listing-id (var-get next-listing-id)))
        
        (asserts! (not (var-get paused)) err-owner-only)
        (asserts! (is-eq tx-sender (get owner token)) err-not-token-owner)
        (asserts! (not (get is-locked token)) err-nft-locked)
        (asserts! (> expiry block-height) err-listing-expired)
        
        (map-set listings listing-id
            {
                token-id: token-id,
                price: price,
                seller: tx-sender,
                expiry: expiry,
                is-active: true,
                royalty-percentage: (get royalty-percentage token),
                original-creator: (get creator token)
            }
        )
        
        ;; Lock the token while listed
        (map-set tokens token-id (merge token { is-locked: true }))
        
        (var-set next-listing-id (+ listing-id u1))
        (ok listing-id)
    )
)

;; Enhanced purchase with royalties
(define-public (purchase-token (listing-id uint))
    (let
        ((listing (unwrap! (map-get? listings listing-id) err-listing-not-found))
         (token (unwrap! (map-get? tokens (get token-id listing)) err-listing-not-found))
         (price (get price listing))
         (seller (get seller listing))
         (royalty-amount (/ (* price (get royalty-percentage listing)) u1000))
         (marketplace-amount (/ (* price (var-get marketplace-fee)) u1000))
         (seller-amount (- price (+ royalty-amount marketplace-amount))))
        
        (asserts! (not (var-get paused)) err-owner-only)
        (asserts! (get is-active listing) err-listing-expired)
        (asserts! (<= block-height (get expiry listing)) err-listing-expired)
        
        ;; Process payments
        (try! (stx-transfer? royalty-amount tx-sender (get original-creator listing)))
        (try! (stx-transfer? marketplace-amount tx-sender contract-owner))
        (try! (stx-transfer? seller-amount tx-sender seller))
        
        ;; Transfer NFT ownership
        (map-set tokens (get token-id listing)
            (merge token {
                owner: tx-sender,
                is-locked: false
            })
        )
        
        ;; Update listing status
        (map-set listings listing-id
            (merge listing { is-active: false })
        )
        
        ;; Record transaction in history
        (try! (record-transaction (get token-id listing) seller tx-sender price "SALE"))
        
        (ok true)
    )
)

;; New: Make offer for NFT
(define-public (make-offer (token-id uint) (price uint) (expiry uint))
    (let
        ((token (unwrap! (map-get? tokens token-id) err-listing-not-found)))
        
        (asserts! (not (var-get paused)) err-owner-only)
        (asserts! (> expiry block-height) err-listing-expired)
        
        (map-set token-offers
            { token-id: token-id, buyer: tx-sender }
            {
                price: price,
                expiry: expiry,
                is-active: true
            }
        )
        (ok true)
    )
)

;; New: Accept offer
(define-public (accept-offer (token-id uint) (buyer principal))
    (let
        ((token (unwrap! (map-get? tokens token-id) err-listing-not-found))
         (offer (unwrap! (map-get? token-offers { token-id: token-id, buyer: buyer }) err-listing-not-found)))
        
        (asserts! (not (var-get paused)) err-owner-only)
        (asserts! (is-eq tx-sender (get owner token)) err-not-token-owner)
        (asserts! (get is-active offer) err-listing-expired)
        (asserts! (<= block-height (get expiry offer)) err-listing-expired)
        
        ;; Process payment
        (try! (stx-transfer? (get price offer) buyer tx-sender))
        
        ;; Transfer NFT
        (map-set tokens token-id
            (merge token {
                owner: buyer,
                is-locked: false
            })
        )
        
        ;; Update offer status
        (map-set token-offers
            { token-id: token-id, buyer: buyer }
            (merge offer { is-active: false })
        )
        
        ;; Record transaction
        (try! (record-transaction token-id tx-sender buyer (get price offer) "OFFER_ACCEPTED"))
        
        (ok true)
    )
)

;; Helper functions
(define-private (record-transaction (token-id uint) (from principal) (to principal) (price uint) (action (string-ascii 20)))
    (let
        ((history (default-to (list) (map-get? transaction-history token-id))))
        
        (map-set transaction-history token-id
            (append history {
                token-id: token-id,
                from: from,
                to: to,
                price: price,
                timestamp: block-height,
                action: action
            })
        )
        (ok true)
    )
)

;; Enhanced read-only functions
(define-read-only (get-token-history (token-id uint))
    (map-get? transaction-history token-id)
)

(define-read-only (get-token-offers (token-id uint) (buyer principal))
    (map-get? token-offers { token-id: token-id, buyer: buyer })
)

;; Administrative functions
(define-public (set-marketplace-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set marketplace-fee new-fee)
        (ok true)
    )
)

(define-public (toggle-pause)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set paused (not (var-get paused)))
        (ok true)
    )
)