// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Solmate
import { Auth, Authority } from 'solmate/auth/Auth.sol';

// Custom
import { Hashtag } from './Hashtag.sol';

contract HashtagList is Auth {
	event HashtagAdded(Hashtag indexed addr, string name);
	event HashtagRemoved(Hashtag indexed addr);

	Hashtag[] public hashtags;

	constructor() Auth(msg.sender, Authority(address(0))) {}

	function add(Hashtag hashtag) public requiresAuth {
		require(address(hashtag.token()) != address(0), 'UNINITIALIZED');
		hashtags.push(hashtag);
		emit HashtagAdded(hashtag, hashtag.name());
	}

	function remove(uint256 index) public requiresAuth {
		Hashtag hashtag = hashtags[index];
		hashtags[index] = hashtags[hashtags.length - 1];
		hashtags.pop();
		emit HashtagRemoved(hashtag);
	}

	function count() public view returns (uint256) {
		return hashtags.length;
	}
}
