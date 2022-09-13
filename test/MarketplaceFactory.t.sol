// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
import 'forge-std/Test.sol';

// Solmate
import { Bytes32AddressLib } from 'solmate/utils/Bytes32AddressLib.sol';

// Custom
import { Marketplace } from 'src/Marketplace.sol';
import { MarketplaceFactory } from 'src/MarketplaceFactory.sol';

// Mocks
import { MockERC20 } from './mocks/MockERC20.sol';

contract MarketplaceFactoryTest is Test {
	// Events
	event MarketplaceCreated(
		address indexed addr,
		string name,
		address seekerRep,
		address providerRep
	);

	// Contracts
	MockERC20 token;
	MarketplaceFactory factory;

	function setUp() public {
		token = new MockERC20('FakeDAI', 'FDAI', 18);
		factory = new MarketplaceFactory();
	}

	function testCanCreateMarketplace() public {
		// Expect an event to be emitted
		vm.expectEmit(false, true, true, false);
		emit MarketplaceCreated(address(0), 'Settler', address(0), address(0));

		// Create the marketplace and record logs
		vm.recordLogs();
		Marketplace marketplace = factory.create(
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
			if (logs[i].topics[0] == MarketplaceCreated.selector) {
				emitted = Bytes32AddressLib.fromLast20Bytes(logs[i].topics[1]);
				(name, seekerRep, providerRep) = abi.decode(
					logs[i].data,
					(string, address, address)
				);
				break;
			}
		}

		// Check metadata
		assertEq(address(marketplace.token()), address(token));
		assertEq(marketplace.name(), 'Settler');
		assertEq(marketplace.name(), name);
		assertEq(marketplace.fee(), 500000000000000000);
		assertEq(marketplace.owner(), address(this));
		assertEq(address(marketplace), emitted);
		assertEq(address(marketplace.seekerRep()), seekerRep);
		assertEq(address(marketplace.providerRep()), providerRep);

		// Check reputation token owners
		assertEq(marketplace.seekerRep().owner(), address(marketplace));
		assertEq(marketplace.providerRep().owner(), address(marketplace));
	}
}
