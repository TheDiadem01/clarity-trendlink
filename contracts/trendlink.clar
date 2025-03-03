;; TrendLink - Prediction Platform Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-topic (err u101))
(define-constant err-topic-expired (err u102))
(define-constant err-insufficient-stake (err u103))

;; Data Variables
(define-data-var next-topic-id uint u1)

;; Data Maps
(define-map topics 
  uint 
  {
    creator: principal,
    question: (string-ascii 256),
    deadline: uint,
    options: (list 10 (string-ascii 64)),
    resolved: bool,
    winning-option: uint
  }
)

(define-map predictions
  { topic-id: uint, user: principal }
  {
    option: uint,
    stake: uint,
    claimed: bool
  }
)

;; Token for staking and rewards
(define-fungible-token trendlink-token)

;; Public Functions
(define-public (create-topic (question (string-ascii 256)) (deadline uint) (options (list 10 (string-ascii 64))))
  (let ((topic-id (var-get next-topic-id)))
    (if (> deadline block-height)
      (begin
        (map-set topics topic-id {
          creator: tx-sender,
          question: question,
          deadline: deadline,
          options: options,
          resolved: false,
          winning-option: u0
        })
        (var-set next-topic-id (+ topic-id u1))
        (ok topic-id))
      err-invalid-topic)
  )
)

(define-public (make-prediction (topic-id uint) (option uint) (stake uint))
  (let ((topic (unwrap! (map-get? topics topic-id) err-invalid-topic)))
    (if (< block-height (get deadline topic))
      (begin
        (try! (ft-transfer? trendlink-token stake tx-sender (as-contract tx-sender)))
        (map-set predictions {topic-id: topic-id, user: tx-sender} {
          option: option,
          stake: stake,
          claimed: false
        })
        (ok true))
      err-topic-expired)
  )
)

(define-public (resolve-topic (topic-id uint) (winning-option uint))
  (let ((topic (unwrap! (map-get? topics topic-id) err-invalid-topic)))
    (if (and
          (is-eq tx-sender (get creator topic))
          (>= block-height (get deadline topic))
          (not (get resolved topic)))
      (begin
        (map-set topics topic-id (merge topic {
          resolved: true,
          winning-option: winning-option
        }))
        (ok true))
      err-unauthorized)
  )
)

(define-public (claim-rewards (topic-id uint))
  (let (
    (topic (unwrap! (map-get? topics topic-id) err-invalid-topic))
    (prediction (unwrap! (map-get? predictions {topic-id: topic-id, user: tx-sender}) err-invalid-topic))
  )
    (if (and
          (get resolved topic)
          (is-eq (get option prediction) (get winning-option topic))
          (not (get claimed prediction)))
      (begin
        (try! (ft-mint? trendlink-token (* (get stake prediction) u2) tx-sender))
        (map-set predictions {topic-id: topic-id, user: tx-sender} 
          (merge prediction {claimed: true}))
        (ok true))
      err-unauthorized)
  )
)

;; Read-only Functions
(define-read-only (get-topic (topic-id uint))
  (ok (map-get? topics topic-id))
)

(define-read-only (get-prediction (topic-id uint) (user principal))
  (ok (map-get? predictions {topic-id: topic-id, user: user}))
)
