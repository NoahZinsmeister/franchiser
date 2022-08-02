# Franchiser

`Franchiser` allows holders of checkpoint voting tokens to selectively sub-delegate voting power while retaining full custody over their funds, as described in the [design document](https://uniswaplabs.notion.site/Franchiser-768dd0e188eb4323957c6e919c09491b).

## Running Locally

- Ensure that [foundry](https://book.getfoundry.sh/) is installed on your machine
- `forge build`
- `forge test --no-match-contract Integration`
- `forge test --match-contract Integration --fork-url $FORK_URL`

## Deploying

- Create and populate a .env file
- `source .env`
- `forge script script/Deploy.s.sol:Deploy --broadcast --private-key $PRIVATE_KEY --rpc-url $RPC_URL [--etherscan-api-key $ETHERSCAN_API_KEY --verify --chain-id $CHAIN_ID]`

## Deployed Addresses

| Network | FranchiserFactory                                                                                                                  | FranchiserLens                                                                                                                     |
|---------|------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------|
| Mainnet | [0xf754A7E347F81cFdc70AF9FbCCe9Df3D826360FA](https://etherscan.io/address/0xf754a7e347f81cfdc70af9fbcce9df3d826360fa#code)         | [0x3E718C61a2849FBb0181ebA83de4Ee8363014106](https://etherscan.io/address/0x3e718c61a2849fbb0181eba83de4ee8363014106#code)         |
| Görli   | [0xf754A7E347F81cFdc70AF9FbCCe9Df3D826360FA](https://goerli.etherscan.io/address/0xf754a7e347f81cfdc70af9fbcce9df3d826360fa#code)  | [0x3E718C61a2849FBb0181ebA83de4Ee8363014106](https://goerli.etherscan.io/address/0x3e718c61a2849fbb0181eba83de4ee8363014106#code)  |
| Sepolia | [0xf754A7E347F81cFdc70AF9FbCCe9Df3D826360FA](https://sepolia.etherscan.io/address/0xf754a7e347f81cfdc70af9fbcce9df3d826360fa#code) | [0x3E718C61a2849FBb0181ebA83de4Ee8363014106](https://sepolia.etherscan.io/address/0x3e718c61a2849fbb0181eba83de4ee8363014106#code) |

Note that the UNI is not yet deployed at `0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984` on Sepolia, so this deploy is non-functional for the time being.
