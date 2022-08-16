// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
import 'forge-std/Test.sol';

// Mocks
import { MockERC20 } from './mocks/MockERC20.sol';

// Custom
import { Marketplace } from 'src/Marketplace.sol';
import { MintableERC20 } from 'src/MintableERC20.sol';

contract MarketplaceTest is Test {
	// Events
	event SetPayoutAddress(address payoutAddress);
	event SetMetadataHash(string metadataHash);
	event SetFee(uint256 fee);

	// Constants
	MintableERC20 ZERO_MINTABLE = MintableERC20(address(0));

	// Contracts
	MockERC20 token;
	Marketplace marketplace;

	MintableERC20 providerRep;
	MintableERC20 seekerRep;

	// Accounts
	address seeker = address(1);
	address provider = address(2);
	address maintainer = address(3);

	function setUp() public {
		// Create contracts
		vm.startPrank(maintainer);

		// Currency
		token = new MockERC20('Swarm City', 'SWT', 18);

		// Reputation tokens
		seekerRep = new MintableERC20(0);
		providerRep = new MintableERC20(0);

		// Initialize tokens
		seekerRep.init('SeekerRep', 'SWRS', maintainer);
		providerRep.init('ProviderRep', 'SWRP', maintainer);

		// Marketplace
		marketplace = new Marketplace();
		marketplace.init(
			address(token),
			'Marketplace',
			50e16,
			'SomeHash',
			maintainer,
			seekerRep,
			providerRep
		);

		providerRep.setOwner(address(marketplace));
		seekerRep.setOwner(address(marketplace));

		// Mint tokens
		token.mint(seeker, 100e18);
		token.mint(provider, 100e18);
		vm.stopPrank();
	}

	function testMetadata() public {
		assertEq(marketplace.name(), 'Marketplace');
		assertEq(marketplace.fee(), 50e16);
		assertEq(address(marketplace.token()), address(token));
		assertEq(marketplace.payoutAddress(), maintainer);
		assertEq(marketplace.metadataHash(), 'SomeHash');
		assertTrue(providerRep != ZERO_MINTABLE);
		assertTrue(seekerRep != ZERO_MINTABLE);
	}

	function testCanChangePayoutAddress() public {
		address user = address(99);

		vm.expectEmit(true, true, false, false);
		emit SetPayoutAddress(user);
		vm.prank(maintainer);
		marketplace.setPayoutAddress(user);

		assertEq(marketplace.payoutAddress(), user);
	}

	function testCanChangeMetadataHash() public {
		string memory newHash = 'NewMetadataHash';

		vm.expectEmit(true, true, false, false);
		emit SetMetadataHash(newHash);
		vm.prank(maintainer);
		marketplace.setMetadataHash(newHash);

		assertEq(marketplace.metadataHash(), newHash);
	}

	function testCanChangeFee() public {
		uint256 fee = 123456;

		vm.expectEmit(true, true, false, false);
		emit SetFee(fee);
		vm.prank(maintainer);
		marketplace.setFee(fee);

		assertEq(marketplace.fee(), fee);
	}

	function testCanCreateItem() public {
		vm.startPrank(seeker);
		token.approve(address(marketplace), 10e18 + 25e16);
		marketplace.newItem('ItemHash', 10e18, 'ItemMetadata');

		assertEq(token.balanceOf(seeker), 100e18 - 10e18 - 25e16);
		assertEq(token.balanceOf(maintainer), 25e16);
		assertEq(token.balanceOf(address(marketplace)), 10e18);
	}

	function testCannotCreateSameItem() public {
		vm.startPrank(seeker);
		token.approve(address(marketplace), 10e18 + 2 * 25e16);
		marketplace.newItem('ItemHash', 10e18, 'ItemMetadata');

		vm.expectRevert('ITEM_ALREADY_EXISTS');
		marketplace.newItem('ItemHash', 15e18, 'OtherMetadata');
	}

	function testCanFundItem() public {
		// Create an item
		vm.startPrank(seeker);
		token.approve(address(marketplace), 10e18 + 25e16);

		bytes memory key = 'ItemHash';
		bytes32 id = keccak256(key);

		marketplace.newItem(id, 10e18, 'ItemMetadata');
		vm.stopPrank();

		// Fund the item
		vm.startPrank(provider);
		token.approve(address(marketplace), 10e18 + 25e16);

		marketplace.fundItem(key);
	}

	function testCannotFundInexistantItem() public {
		vm.startPrank(provider);
		token.approve(address(marketplace), 10e18 + 25e16);

		vm.expectRevert('ITEM_NOT_OPEN');
		marketplace.fundItem(bytes('ItemHash'));
	}
}
