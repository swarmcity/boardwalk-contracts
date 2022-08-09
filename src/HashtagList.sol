// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Solmate
import { Auth, Authority } from 'solmate/auth/Auth.sol';

// Custom
import { Hashtag } from './Hashtag.sol';

contract HashtagList is Auth {
	event HashtagAdd(Hashtag indexed addr, string name);

	Hashtag[] public hashtags;

	constructor() Auth(msg.sender, Authority(address(0))) {}

	function add(Hashtag hashtag) public requiresAuth {
		require(address(hashtag.token()) != address(0), 'UNINITIALIZED');
		hashtags.push(hashtag);
		emit HashtagAdd(hashtag, hashtag.name());
	}

	function count() public view returns (uint256) {
		return hashtags.length;
	}
}
