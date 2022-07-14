# Franchiser

[![test](https://github.com/NoahZinsmeister/franchiser/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/NoahZinsmeister/franchiser/actions/workflows/test.yml)

## Running Locally

- Ensure that [foundry](https://book.getfoundry.sh/) is installed on your machine
- `forge build`
- `forge test`

## Deploying

- Create and populate a .env file
- `source .env`
- `forge script script/Deploy.s.sol:Deploy --broadcast --private-key $PRIVATE_KEY  --rpc-url $RPC_URL [--etherscan-api-key $ETHERSCAN_API_KEY --verify]`
