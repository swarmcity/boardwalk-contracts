#!/bin/bash

source .env

forge verify-contract --watch --chain-id 5 \
  $MARKETPLACE_FACTORY src/MarketplaceFactory.sol:MarketplaceFactory $ETHERSCAN_KEY

forge verify-contract --watch --chain-id 5 \
  --constructor-args $(cast abi-encode "constructor(string,string,uint256)" "DAI" "DAI" 18) \
  $FAKE_DAI src/MintableERC20.sol:MintableERC20 $ETHERSCAN_KEY

forge verify-contract --watch --chain-id 5 \
  $MARKETPLACE_LIST src/MarketplaceList.sol:MarketplaceList $ETHERSCAN_KEY

forge verify-contract --watch --chain-id 5 \
  $MASTER_MARKETPLACE src/Marketplace.sol:Marketplace $ETHERSCAN_KEY 

forge verify-contract --watch --chain-id 5 \
  --constructor-args $(cast abi-encode "constructor(uint256)" 0) \
  $MASTER_REP src/MintableERC20.sol:MintableERC20 $ETHERSCAN_KEY
