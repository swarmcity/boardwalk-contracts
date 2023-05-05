#!/bin/bash

source .env

forge script \
  script/Deploy.s.sol:DeployScript \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --legacy \
  --etherscan-api-key $ETHERSCAN_KEY \
  --verifier etherscan \
  --verifier-url "https://zkevm.polygonscan.com/" \
  -vvvv
