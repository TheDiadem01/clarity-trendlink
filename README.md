# TrendLink
A decentralized platform for crowdsourcing predictions on emerging technologies and ideas built on Stacks blockchain.

## Features
- Create prediction topics with specified deadline and outcome options
- Make predictions by staking tokens
- Reward accurate predictions with tokens
- View prediction statistics and trend data
- Claim rewards for correct predictions

## Setup and Installation
1. Clone the repository
2. Install Clarinet
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to execute test suite

## Usage Examples
```clarity
;; Create a new prediction topic
(contract-call? .trendlink create-topic "Will AI surpass human intelligence by 2030?" u1672531200 (list "Yes" "No"))

;; Make a prediction
(contract-call? .trendlink make-prediction u1 u0 u100)

;; Resolve a topic and distribute rewards
(contract-call? .trendlink resolve-topic u1 u0)

;; Claim rewards
(contract-call? .trendlink claim-rewards u1)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
