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
		MintableERC20(address(0x1209b3001b01eDcC7bC59588D6eef6BcF1030C7e));

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

		list.add(factory.create(address(token), '5minTasks', 5e17, 'Hash'));
		list.add(factory.create(address(token), 'Delivery', 1e18, 'Hash'));
		list.add(factory.create(address(token), 'FixItForMe', 25e17, 'Hash'));
		list.add(factory.create(address(token), 'LogosTasks', 25e17, 'Hash'));
		factory.create(address(token), 'OneMoreThing', 25e17, 'Hash');

		vm.stopBroadcast();
	}
}
