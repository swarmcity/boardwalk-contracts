// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';

import {MockERC20} from './lib/mocks/MockERC20.sol';

import {Hashtag} from 'src/Hashtag.sol';
import {MintableERC20} from 'src/MintableERC20.sol';

contract HashtagTest is Test {
	// Constants
	MintableERC20 ZERO_MINTABLE = MintableERC20(address(0));

	// Contracts
	MockERC20 token;
	Hashtag hashtag;

	MintableERC20 providerRep;
	MintableERC20 seekerRep;

	// Accounts
	address seeker = address(0x1);
	address provider = address(0x2);
	address maintainer = address(0x3);

	function setUp() public {
		vm.startPrank(maintainer);
		token = new MockERC20('Swarm City', 'SWT', 18);
		hashtag = new Hashtag(address(token), 'Marketplace', 25e16, 'SomeHash');

		providerRep = hashtag.providerRep();
		seekerRep = hashtag.seekerRep();
	}

	function testMetadata() public {
		assertEq(hashtag.name(), 'Marketplace');
		assertEq(hashtag.fee(), 25e16);
		assertEq(address(hashtag.token()), address(token));
		assertEq(hashtag.payoutAddress(), maintainer);
		assertEq(hashtag.metadataHash(), 'SomeHash');
		assertTrue(providerRep != ZERO_MINTABLE);
		assertTrue(seekerRep != ZERO_MINTABLE);
	}
}
