# Bridging-Contracts

### Steps to Deploy and Prerequisites

1. Deploy the [Polygon Token](https://github.com/getsafle/bridging-contract/tree/main/contracts/polygon%20token) and [FxBaseChildTunnel](https://github.com/getsafle/bridging-contract/blob/main/contracts/FxBaseChildTunnel.sol) contracts on Polygon chain. Pass the [FxChild contract address](https://docs.polygon.technology/docs/develop/l1-l2-communication/fx-portal/#contract-addresses) and token contract address in the constructor of FxBaseChildTunnel contract.

2. Deploy the [ETH token](https://github.com/getsafle/bridging-contract/tree/main/contracts/eth%20token) and [FxBaseRootTunnel](https://github.com/getsafle/bridging-contract/blob/main/contracts/FxBaseRootTunnel.sol) contracts on ETH chain. Pass the [checkpoint manager address](https://docs.polygon.technology/docs/develop/l1-l2-communication/fx-portal/#example-deployments), [FxRoot contract address](https://docs.polygon.technology/docs/develop/l1-l2-communication/fx-portal/#contract-addresses) and ETH token contract address in the constructor of FxBaseRootTunnel contract.

3. Switch to Eth chain and pass the FxBaseChildTunnel contract address in the `setFxChildTunnel()` function in the FxBaseRootTunnel contract.

4. Switch to Polygon chain and pass the FxBaseRootTunnel contract address in the `setFxRootTunnel()` function in the FxBaseChildTunnel contract.

5. FxBaseRootTunnel has the rights to `burn` and `mint` tokens from the ETH token contract. Inorder to do so, the contract has to be whitelisted. This can be done using the function `setRootContract()` in the ETH token contract address.

### Transfer assets between ETH and Polygon chains

#### Transfer from Polygon to ETH

1. Approve the FxBaseChildTunnel contract to spend the tokens on behalf of the user using the `approve` function in the Polygon token contract.

2. The user can now lock the tokens with the FxBaseChildTunnel using the `withdraw` function with the amount of tokens as the parameter

3. The locked tokens can be received in the ETH chain by using the function `receiveMessage()` in the FxBaseRootTunnel contract. The input to be passed can be fetched from [this](https://apis.matic.network/api/v1/mumbai/exit-payload/{{transactionHash}}?eventSignature=0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036) API. Replace the transaction hash with the hash of the withdraw function transaction.
For Mainnet, [this](https://apis.matic.network/api/v1/matic/exit-payload/{{transactionHash}}?eventSignature=0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036) api can be used.

4. Once the `receiveMessage()` is called and executed successfully, the user's balance will be updated and can be verified using the `balanceOf()` function of the ETH contract.

#### Transfer from ETH to Polygon
1. The tokens to be transferred from ETH to Polygon has to be burned on the ETH chain using the function `deposit()` in the FxBaseRootTunnel contract.

2. Once the tokens are burned, the balance of the user will be updated in the Polygon chain and can be checked using the `balanceOf()` function in the Polygon chain token contract.