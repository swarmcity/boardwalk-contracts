// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
import 'forge-std/Test.sol';

// Mocks
import { MockERC20 } from './mocks/MockERC20.sol';

// Custom
import { Marketplace } from 'src/Marketplace.sol';
import { MintableERC20 } from 'src/MintableERC20.sol';

contract MarketplaceERC20Test is Test {
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

	// Private keys
	uint256 seekerPrivateKey = 0x533;
	uint256 providerPrivateKey = 0x013;

	// Accounts
	address seeker = vm.addr(seekerPrivateKey);
	address provider = vm.addr(providerPrivateKey);
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

		providerRep.transferOwnership(address(marketplace));
		seekerRep.transferOwnership(address(marketplace));

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
}
