;; EcoChain: Environmental Action Tracking and Sustainability Reward System
;; Version: 1.0.0

;; Constants
(define-constant ECO_INCENTIVE_CAPACITY u2800000)
(define-constant BASE_ECO_REWARD u20)
(define-constant GREEN_BONUS u7)
(define-constant MAX_ECO_LEVEL u10)
(define-constant ERR_INVALID_ACTION_USAGE u1)
(define-constant ERR_NO_ECO_POINTS u2)
(define-constant ERR_INCENTIVE_EXCEEDED u3)
(define-constant BLOCKS_PER_ECO_CYCLE u1440)
(define-constant SUSTAINABILITY_OPTIMIZATION_MULTIPLIER u3)
(define-constant MIN_OPTIMIZATION_PERIOD u720)
(define-constant EARLY_OPTIMIZATION_PENALTY u12)

;; Data Variables
(define-data-var total-eco-points-awarded uint u0)
(define-data-var total-eco-actions uint u0)
(define-data-var sustainability-coordinator principal tx-sender)

;; Data Maps
(define-map eco-warrior-actions principal uint)
(define-map eco-warrior-points principal uint)
(define-map action-start-time principal uint)
(define-map eco-level principal uint)
(define-map eco-warrior-last-action principal uint)
(define-map eco-warrior-optimized-initiatives principal uint)
(define-map eco-warrior-optimization-start-block principal uint)

;; Public Functions
(define-public (start-eco-action (action-impact uint))
  (let
    (
      (eco-warrior tx-sender)
    )
    (asserts! (> action-impact u0) (err ERR_INVALID_ACTION_USAGE))
    (map-set action-start-time eco-warrior burn-block-height)
    (ok true)
  ))

(define-public (complete-eco-action (action-impact uint))
  (let
    (
      (eco-warrior tx-sender)
      (start-block (default-to u0 (map-get? action-start-time eco-warrior)))
      (blocks-acting (- burn-block-height start-block))
      (last-action-block (default-to u0 (map-get? eco-warrior-last-action eco-warrior)))
      (eco-tier (default-to u0 (map-get? eco-level eco-warrior)))
      (capped-tier (if (<= eco-tier MAX_ECO_LEVEL) eco-tier MAX_ECO_LEVEL))
      (eco-reward (+ BASE_ECO_REWARD (* capped-tier GREEN_BONUS)))
    )
    (asserts! (and (> start-block u0) (>= blocks-acting action-impact)) (err ERR_INVALID_ACTION_USAGE))
    
    (map-set eco-warrior-actions eco-warrior (+ (default-to u0 (map-get? eco-warrior-actions eco-warrior)) u1))
    (map-set eco-warrior-points eco-warrior (+ (default-to u0 (map-get? eco-warrior-points eco-warrior)) eco-reward))
    
    (if (< (- burn-block-height last-action-block) BLOCKS_PER_ECO_CYCLE)
      (map-set eco-level eco-warrior (+ eco-tier u1))
      (map-set eco-level eco-warrior u1)
    )
    
    (map-set eco-warrior-last-action eco-warrior burn-block-height)
    (var-set total-eco-actions (+ (var-get total-eco-actions) u1))
    (var-set total-eco-points-awarded (+ (var-get total-eco-points-awarded) eco-reward))
    
    (asserts! (<= (var-get total-eco-points-awarded) ECO_INCENTIVE_CAPACITY) (err ERR_INCENTIVE_EXCEEDED))
    (ok eco-reward)
  ))

(define-public (claim-eco-rewards)
  (let
    (
      (eco-warrior tx-sender)
      (point-balance (default-to u0 (map-get? eco-warrior-points eco-warrior)))
    )
    (asserts! (> point-balance u0) (err ERR_NO_ECO_POINTS))
    (map-set eco-warrior-points eco-warrior u0)
    (ok point-balance)
  ))

;; Sustainability Optimization Features
(define-public (optimize-sustainability-initiatives (amount uint))
  (let
    (
      (eco-warrior tx-sender)
    )
    (asserts! (> amount u0) (err ERR_INVALID_ACTION_USAGE))
    (asserts! (>= (var-get total-eco-points-awarded) amount) (err ERR_INCENTIVE_EXCEEDED))
    
    (map-set eco-warrior-optimized-initiatives eco-warrior amount)
    (map-set eco-warrior-optimization-start-block eco-warrior burn-block-height)
    (var-set total-eco-points-awarded (- (var-get total-eco-points-awarded) amount))
    (ok amount)
  ))

(define-public (complete-sustainability-optimization)
  (let
    (
      (eco-warrior tx-sender)
      (optimized-amount (default-to u0 (map-get? eco-warrior-optimized-initiatives eco-warrior)))
      (optimization-start-block (default-to u0 (map-get? eco-warrior-optimization-start-block eco-warrior)))
      (blocks-optimized (- burn-block-height optimization-start-block))
      (penalty (if (< blocks-optimized MIN_OPTIMIZATION_PERIOD) (/ (* optimized-amount EARLY_OPTIMIZATION_PENALTY) u100) u0))
      (final-amount (- optimized-amount penalty))
    )
    (asserts! (> optimized-amount u0) (err ERR_NO_ECO_POINTS))
    
    (map-set eco-warrior-optimized-initiatives eco-warrior u0)
    (map-set eco-warrior-optimization-start-block eco-warrior u0)
    (var-set total-eco-points-awarded (+ (var-get total-eco-points-awarded) final-amount))
    (ok final-amount)
  ))

;; Read-Only Functions
(define-read-only (get-eco-action-count (user principal))
  (default-to u0 (map-get? eco-warrior-actions user)))

(define-read-only (get-eco-point-balance (user principal))
  (default-to u0 (map-get? eco-warrior-points user)))

(define-read-only (get-eco-level (user principal))
  (default-to u0 (map-get? eco-level user)))

(define-read-only (get-eco-program-stats)
  {
    total-eco-actions: (var-get total-eco-actions),
    total-eco-points-awarded: (var-get total-eco-points-awarded)
  })

;; Private Functions
(define-private (is-sustainability-coordinator)
  (is-eq tx-sender (var-get sustainability-coordinator)))