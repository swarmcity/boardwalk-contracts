// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
import 'forge-std/Script.sol';

import { Marketplace } from 'src/Marketplace.sol';
import { MarketplaceFactory } from 'src/MarketplaceFactory.sol';
import { MarketplaceList } from 'src/MarketplaceList.sol';
import { MintableERC20 } from 'src/MintableERC20.sol';

contract DeployScript is Script {
	address owner;
	MintableERC20 token =
		MintableERC20(0xC5015b9d9161Dca7e18e32f6f25C4aD850731Fd4);

	function setUp() public {
		owner = msg.sender;
	}

	function run() public {
		vm.startBroadcast();

		if (address(token) == address(0)) {
			token = new MintableERC20(18);
			token.init('Fake DAI', 'FDAI', owner);
		}

		MarketplaceList list = new MarketplaceList();
		MarketplaceFactory factory = new MarketplaceFactory();

		list.add(factory.create(address(token), 'LogosTasks', 25e17, 'Hash'));

		vm.stopBroadcast();
	}
}
