// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Custom
import { Hashtag } from './Hashtag.sol';

contract HashtagFactory {
	event HashtagCreated(
		address indexed addr,
		string name,
		string metadata,
		uint256 fee
	);

	Hashtag[] public hashtags;

	function create(
		address token,
		string memory name,
		uint256 fee,
		string memory metadata
	) public {
		Hashtag hashtag = new Hashtag(token, name, fee, metadata, msg.sender);
		hashtags.push(hashtag);
		emit HashtagCreated(address(hashtag), name, metadata, fee);
	}
}
