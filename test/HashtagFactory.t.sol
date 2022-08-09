// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
import 'forge-std/Test.sol';

// Solmate
import { Bytes32AddressLib } from 'solmate/utils/Bytes32AddressLib.sol';

// Custom
import { Hashtag } from 'src/Hashtag.sol';
import { HashtagFactory } from 'src/HashtagFactory.sol';

// Mocks
import { MockERC20 } from './mocks/MockERC20.sol';

contract HashtagFactoryTest is Test {
	// Events
	event HashtagCreated(
		address indexed addr,
		string name,
		address seekerRep,
		address providerRep
	);

	// Contracts
	MockERC20 token;
	HashtagFactory factory;

	function setUp() public {
		token = new MockERC20('FakeDAI', 'FDAI', 18);
		factory = new HashtagFactory();
	}

	function testCanCreateHashtag() public {
		// Expect an event to be emitted
		vm.expectEmit(false, true, true, false);
		emit HashtagCreated(address(0), 'Settler', address(0), address(0));

		// Create the hashtag and record logs
		vm.recordLogs();
		Hashtag hashtag = factory.create(
			address(token),
			'Settler',
			500000000000000000,
			'SomeHash'
		);
		Vm.Log[] memory logs = vm.getRecordedLogs();

		// Check if the address emitted in the event is right
		address emitted;
		address seekerRep;
		address providerRep;
		string memory name;

		for (uint256 i = 0; i < logs.length; i++) {
			if (logs[i].topics[0] == HashtagCreated.selector) {
				emitted = Bytes32AddressLib.fromLast20Bytes(logs[i].topics[1]);
				(name, seekerRep, providerRep) = abi.decode(
					logs[i].data,
					(string, address, address)
				);
				break;
			}
		}

		// Check metadata
		assertEq(address(hashtag.token()), address(token));
		assertEq(hashtag.name(), 'Settler');
		assertEq(hashtag.name(), name);
		assertEq(hashtag.fee(), 500000000000000000);
		assertEq(hashtag.owner(), address(this));
		assertEq(address(hashtag), emitted);
		assertEq(address(hashtag.seekerRep()), seekerRep);
		assertEq(address(hashtag.providerRep()), providerRep);
	}
}
