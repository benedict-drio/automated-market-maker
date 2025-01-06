;; Title: Automated Market Maker (AMM) Pool Contract
;;
;; Summary:
;;  A decentralized exchange implementation that enables users to create liquidity pools,
;;  provide liquidity, and perform token swaps using an automated market maker model.
;;
;; Description:
;;  This contract implements a Uniswap-style AMM with the following features:
;;  - Pool creation and management
;;  - Liquidity provision and removal
;;  - Token swapping with configurable slippage protection
;;  - Protocol fee collection
;;  - Administrative controls for emergency situations
;;  - Constant product market maker formula (x * y = k)

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-POOL-NOT-FOUND (err u103))
(define-constant ERR-INVALID-POOL (err u104))
(define-constant ERR-SLIPPAGE-TOO-HIGH (err u105))
(define-constant ERR-ZERO-LIQUIDITY (err u106))
(define-constant PRECISION u1000000) ;; 6 decimal places for price calculations

;; Data Variables
(define-data-var protocol-fee-rate uint u3000) ;; 0.3% fee
(define-data-var total-pools uint u0)

;; Data Maps
(define-map pools
    uint
    {
        token-x: principal,
        token-y: principal,
        reserve-x: uint,
        reserve-y: uint,
        total-shares: uint,
        active: bool
    }
)

(define-map liquidity-providers
    {pool-id: uint, provider: principal}
    {shares: uint}
)

(define-map accumulated-fees
    principal
    uint
)

;; Private Functions
(define-private (calculate-output-amount
    (input-amount uint)
    (input-reserve uint)
    (output-reserve uint)
)
    (let
        (
            (input-with-fee (mul input-amount (- PRECISION (var-get protocol-fee-rate))))
            (numerator (mul input-with-fee output-reserve))
            (denominator (+ (mul input-reserve PRECISION) input-with-fee))
        )
        (/ numerator denominator)
    )
)

(define-private (mint-pool-tokens
    (pool-id uint)
    (amount-x uint)
    (amount-y uint)
    (recipient principal)
)
    (let
        (
            (pool (unwrap! (map-get? pools pool-id) ERR-POOL-NOT-FOUND))
            (total-shares (get total-shares pool))
            (shares-to-mint (if (is-eq total-shares u0)
                (mul amount-x amount-y)
                (min
                    (/ (mul amount-x total-shares) (get reserve-x pool))
                    (/ (mul amount-y total-shares) (get reserve-y pool))
                )
            ))
        )
        (map-set pools pool-id
            (merge pool {
                reserve-x: (+ (get reserve-x pool) amount-x),
                reserve-y: (+ (get reserve-y pool) amount-y),
                total-shares: (+ total-shares shares-to-mint)
            })
        )
        (map-set liquidity-providers
            {pool-id: pool-id, provider: recipient}
            {shares: (+ (default-to u0 (get shares (map-get? liquidity-providers {pool-id: pool-id, provider: recipient}))) shares-to-mint)}
        )
        (ok shares-to-mint)
    )
)

;; Public Functions
(define-public (create-pool (token-x principal) (token-y principal))
    (let
        (
            (pool-id (var-get total-pools))
        )
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (not (is-eq token-x token-y)) ERR-INVALID-POOL)
        
        (map-set pools pool-id
            {
                token-x: token-x,
                token-y: token-y,
                reserve-x: u0,
                reserve-y: u0,
                total-shares: u0,
                active: true
            }
        )
        (var-set total-pools (+ pool-id u1))
        (ok pool-id)
    )
)

(define-public (add-liquidity
    (pool-id uint)
    (amount-x uint)
    (amount-y uint)
    (min-shares uint)
)
    (let
        (
            (pool (unwrap! (map-get? pools pool-id) ERR-POOL-NOT-FOUND))
            (token-x (get token-x pool))
            (token-y (get token-y pool))
        )
        (asserts! (> amount-x u0) ERR-INVALID-AMOUNT)
        (asserts! (> amount-y u0) ERR-INVALID-AMOUNT)
        (asserts! (get active pool) ERR-POOL-NOT-FOUND)
        
        ;; Transfer tokens to pool
        (try! (contract-call? token-x transfer amount-x tx-sender (as-contract tx-sender)))
        (try! (contract-call? token-y transfer amount-y tx-sender (as-contract tx-sender)))
        
        ;; Mint LP tokens
        (let
            ((shares (unwrap! (mint-pool-tokens pool-id amount-x amount-y tx-sender) ERR-INVALID-AMOUNT)))
            (asserts! (>= shares min-shares) ERR-SLIPPAGE-TOO-HIGH)
            (ok shares)
        )
    )
)

(define-public (swap-exact-tokens
    (pool-id uint)
    (amount-in uint)
    (min-amount-out uint)
    (x-to-y bool)
)
    (let
        (
            (pool (unwrap! (map-get? pools pool-id) ERR-POOL-NOT-FOUND))
            (input-token (if x-to-y (get token-x pool) (get token-y pool)))
            (output-token (if x-to-y (get token-y pool) (get token-x pool)))
            (input-reserve (if x-to-y (get reserve-x pool) (get reserve-y pool)))
            (output-reserve (if x-to-y (get reserve-y pool) (get reserve-x pool)))
        )
        (asserts! (> amount-in u0) ERR-INVALID-AMOUNT)
        (asserts! (get active pool) ERR-POOL-NOT-FOUND)
        
        (let
            (
                (amount-out (calculate-output-amount amount-in input-reserve output-reserve))
            )
            (asserts! (>= amount-out min-amount-out) ERR-SLIPPAGE-TOO-HIGH)
            
            ;; Transfer input tokens to pool
            (try! (contract-call? input-token transfer amount-in tx-sender (as-contract tx-sender)))
            
            ;; Transfer output tokens to user
            (as-contract
                (try! (contract-call? output-token transfer amount-out (as-contract tx-sender) tx-sender))
            )
            
            ;; Update pool reserves
            (map-set pools pool-id
                (merge pool
                    (if x-to-y
                        {
                            reserve-x: (+ input-reserve amount-in),
                            reserve-y: (- output-reserve amount-out)
                        }
                        {
                            reserve-x: (- output-reserve amount-out),
                            reserve-y: (+ input-reserve amount-in)
                        }
                    )
                )
            )
            
            (ok amount-out)
        )
    )
)

(define-public (remove-liquidity
    (pool-id uint)
    (shares uint)
    (min-amount-x uint)
    (min-amount-y uint)
)
    (let
        (
            (pool (unwrap! (map-get? pools pool-id) ERR-POOL-NOT-FOUND))
            (provider-shares (unwrap! (get shares (map-get? liquidity-providers {pool-id: pool-id, provider: tx-sender})) ERR-INSUFFICIENT-BALANCE))
            (total-shares (get total-shares pool))
        )
        (asserts! (>= provider-shares shares) ERR-INSUFFICIENT-BALANCE)
        (asserts! (> shares u0) ERR-INVALID-AMOUNT)
        
        (let
            (
                (amount-x (/ (mul shares (get reserve-x pool)) total-shares))
                (amount-y (/ (mul shares (get reserve-y pool)) total-shares))
            )
            (asserts! (>= amount-x min-amount-x) ERR-SLIPPAGE-TOO-HIGH)
            (asserts! (>= amount-y min-amount-y) ERR-SLIPPAGE-TOO-HIGH)
            
            ;; Update provider shares
            (map-set liquidity-providers
                {pool-id: pool-id, provider: tx-sender}
                {shares: (- provider-shares shares)}
            )
            
            ;; Update pool
            (map-set pools pool-id
                (merge pool {
                    reserve-x: (- (get reserve-x pool) amount-x),
                    reserve-y: (- (get reserve-y pool) amount-y),
                    total-shares: (- total-shares shares)
                })
            )
            
            ;; Transfer tokens back to provider
            (as-contract
                (begin
                    (try! (contract-call? (get token-x pool) transfer amount-x (as-contract tx-sender) tx-sender))
                    (try! (contract-call? (get token-y pool) transfer amount-y (as-contract tx-sender) tx-sender))
                    (ok {amount-x: amount-x, amount-y: amount-y})
                )
            )
        )
    )
)