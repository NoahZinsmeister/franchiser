# Franchiser

`Franchiser` allows holders of checkpoint voting tokens to selectively sub-delegate voting power while retaining full custody over their funds, as described in the [design document](https://uniswaplabs.notion.site/Franchiser-768dd0e188eb4323957c6e919c09491b).

## Running Locally

- Ensure that [foundry](https://book.getfoundry.sh/) is installed on your machine
- `forge build`
- `forge test`

## Deploying

- Create and populate a .env file
- `source .env`
- `forge script script/Deploy.s.sol:Deploy --broadcast --private-key $PRIVATE_KEY  --rpc-url $RPC_URL [--etherscan-api-key $ETHERSCAN_API_KEY --verify]`
