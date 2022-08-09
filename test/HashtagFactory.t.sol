// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import 'forge-std/Test.sol';

// Custom
import { Hashtag } from 'src/Hashtag.sol';
import { HashtagFactory } from 'src/HashtagFactory.sol';

// Mocks
import { MockERC20 } from './mocks/MockERC20.sol';

contract HashtagFactoryTest is Test {
	// Events
	event HashtagCreated(address indexed addr, string name);

	// Contracts
	MockERC20 token;
	HashtagFactory factory;

	function setUp() public {
		token = new MockERC20('FakeDAI', 'FDAI', 18);
		factory = new HashtagFactory();
	}

	function testCanCreateHashtag() public {
		vm.expectEmit(false, true, true, true);
		emit HashtagCreated(address(0), 'Settler');

		Hashtag hashtag = factory.create(
			address(token),
			'Settler',
			500000000000000000,
			'SomeHash'
		);

		assertEq(address(hashtag.token()), address(token));
		assertEq(hashtag.name(), 'Settler');
		assertEq(hashtag.fee(), 500000000000000000);
		assertEq(hashtag.owner(), address(this));
		assertTrue(address(hashtag.seekerRep()) != address(0));
		assertTrue(address(hashtag.providerRep()) != address(0));
	}
}
