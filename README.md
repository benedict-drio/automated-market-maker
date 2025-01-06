# Automated Market Maker (AMM) Pool Contract

A robust decentralized exchange implementation built on Clarity, enabling users to create liquidity pools, provide liquidity, and perform token swaps using an automated market maker model.

## Features

- Pool Creation and Management
- Liquidity Provision and Removal
- Token Swapping with Slippage Protection
- Protocol Fee Collection
- Administrative Controls
- Constant Product Market Maker (x \* y = k)

## Overview

This AMM implementation follows the Uniswap V2 model, providing a decentralized way to trade tokens without traditional order books. It uses the constant product market maker formula (x \* y = k) to determine exchange rates and manage liquidity.

## Quick Start

### Prerequisites

- A Stacks wallet
- STX tokens for transaction fees
- Compatible fungible tokens that implement the `ft-trait`

### Core Functions

1. **Create Pool**

```clarity
(create-pool (token-x <ft-trait>) (token-y <ft-trait>))
```

2. **Add Liquidity**

```clarity
(add-liquidity
    (pool-id uint)
    (token-x <ft-trait>)
    (token-y <ft-trait>)
    (amount-x uint)
    (amount-y uint)
    (min-shares uint))
```

3. **Swap Tokens**

```clarity
(swap-exact-tokens
    (pool-id uint)
    (token-in <ft-trait>)
    (token-out <ft-trait>)
    (amount-in uint)
    (min-amount-out uint)
    (x-to-y bool))
```

4. **Remove Liquidity**

```clarity
(remove-liquidity
    (pool-id uint)
    (token-x <ft-trait>)
    (token-y <ft-trait>)
    (shares uint)
    (min-amount-x uint)
    (min-amount-y uint))
```

## Architecture

The contract is built with several key components:

- **Pools**: Manages liquidity pools for token pairs
- **Liquidity Providers**: Tracks LP token balances
- **Protocol Fees**: Configurable fee structure
- **Safety Measures**: Slippage protection and emergency controls

## Security Features

- Slippage protection on all trades
- Emergency pause functionality
- Access control for administrative functions
- Comprehensive error handling
- Mathematical precision handling

## Documentation

For detailed documentation, please refer to the [docs](./docs) directory:

- [Technical Specification](./docs/TECHNICAL.md)
- [API Reference](./docs/API.md)
- [Security Model](./docs/SECURITY.md)

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Code of Conduct

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before participating in our community.
