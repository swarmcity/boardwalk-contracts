// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

// Solmate
import { Auth, Authority } from 'solmate/auth/Auth.sol';

// Custom
import { Marketplace } from './Marketplace.sol';

contract MarketplaceList is Auth {
	event MarketplaceAdded(Marketplace indexed addr, string name);
	event MarketplaceRemoved(Marketplace indexed addr);

	Marketplace[] public marketplaces;

	constructor() Auth(msg.sender, Authority(address(0))) {}

	function add(Marketplace marketplace) public requiresAuth {
		require(address(marketplace.token()) != address(0), 'UNINITIALIZED');
		marketplaces.push(marketplace);
		emit MarketplaceAdded(marketplace, marketplace.name());
	}

	function remove(uint256 index) public requiresAuth {
		Marketplace marketplace = marketplaces[index];
		marketplaces[index] = marketplaces[marketplaces.length - 1];
		marketplaces.pop();
		emit MarketplaceRemoved(marketplace);
	}

	function count() public view returns (uint256) {
		return marketplaces.length;
	}
}
