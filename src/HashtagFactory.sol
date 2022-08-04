// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// OpenZeppelin
import '@openzeppelin/contracts/proxy/Clones.sol';

// Custom
import { Hashtag } from './Hashtag.sol';

contract HashtagFactory {
	event HashtagCreated(address indexed addr, string name);

	address public master;

	constructor() {
		master = address(new Hashtag());
	}

	function create(
		address token,
		string memory name,
		uint256 fee,
		string memory metadata
	) public {
		Hashtag hashtag = Hashtag(Clones.clone(master));
		hashtag.init(token, name, fee, metadata, msg.sender);
		emit HashtagCreated(address(hashtag), name);
	}
}
