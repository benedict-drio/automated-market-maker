# API Reference

## Core Functions

### Pool Management

#### create-pool

Creates a new liquidity pool for a pair of tokens.

```clarity
(define-public (create-pool (token-x <ft-trait>) (token-y <ft-trait>)))
```

**Parameters:**

- `token-x`: First token contract implementing ft-trait
- `token-y`: Second token contract implementing ft-trait

**Returns:**

- `(ok uint)`: Pool ID of the newly created pool
- `(err uint)`: Error code if creation fails

**Errors:**

- `ERR-NOT-AUTHORIZED (u100)`: Caller is not the contract owner
- `ERR-INVALID-POOL (u104)`: Invalid token pair

#### add-liquidity

Adds liquidity to an existing pool.

```clarity
(define-public (add-liquidity
    (pool-id uint)
    (token-x <ft-trait>)
    (token-y <ft-trait>)
    (amount-x uint)
    (amount-y uint)
    (min-shares uint)))
```

**Parameters:**

- `pool-id`: ID of the target pool
- `token-x`: First token contract
- `token-y`: Second token contract
- `amount-x`: Amount of first token
- `amount-y`: Amount of second token
- `min-shares`: Minimum acceptable LP tokens

**Returns:**

- `(ok uint)`: Amount of LP tokens minted
- `(err uint)`: Error code if operation fails

### Trading Functions

#### swap-exact-tokens

Performs a token swap with exact input amount.

```clarity
(define-public (swap-exact-tokens
    (pool-id uint)
    (token-in <ft-trait>)
    (token-out <ft-trait>)
    (amount-in uint)
    (min-amount-out uint)
    (x-to-y bool)))
```

**Parameters:**

- `pool-id`: Target pool ID
- `token-in`: Input token contract
- `token-out`: Output token contract
- `amount-in`: Exact input amount
- `min-amount-out`: Minimum acceptable output
- `x-to-y`: Direction of swap

**Returns:**

- `(ok uint)`: Amount of tokens received
- `(err uint)`: Error code if swap fails

### Liquidity Management

#### remove-liquidity

Removes liquidity from a pool.

```clarity
(define-public (remove-liquidity
    (pool-id uint)
    (token-x <ft-trait>)
    (token-y <ft-trait>)
    (shares uint)
    (min-amount-x uint)
    (min-amount-y uint)))
```

**Parameters:**

- `pool-id`: Target pool ID
- `token-x`: First token contract
- `token-y`: Second token contract
- `shares`: LP tokens to burn
- `min-amount-x`: Minimum token X return
- `min-amount-y`: Minimum token Y return

**Returns:**

- `(ok {amount-x: uint, amount-y: uint})`: Amounts returned
- `(err uint)`: Error code if operation fails

## Read-Only Functions

### get-pool-info

Retrieves pool information.

```clarity
(define-read-only (get-pool-info (pool-id uint)))
```

### get-provider-shares

Gets LP token balance for a provider.

```clarity
(define-read-only (get-provider-shares (pool-id uint) (provider principal)))
```

### get-exchange-rate

Calculates current exchange rate.

```clarity
(define-read-only (get-exchange-rate (pool-id uint)))
```

## Administrative Functions

### set-protocol-fee

Updates the protocol fee rate.

```clarity
(define-public (set-protocol-fee (new-fee uint)))
```

### pause-pool

Pauses operations for a specific pool.

```clarity
(define-public (pause-pool (pool-id uint)))
```

### resume-pool

Resumes operations for a paused pool.

```clarity
(define-public (resume-pool (pool-id uint)))
```
