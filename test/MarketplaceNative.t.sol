// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
import 'forge-std/Test.sol';

// Mocks
import { MockERC20 } from './mocks/MockERC20.sol';

// Custom
import { Marketplace } from 'src/Marketplace.sol';
import { MintableERC20 } from 'src/MintableERC20.sol';

contract MarketplaceNativeTest is Test {
	// Events
	event SetPayoutAddress(address payoutAddress);
	event SetMetadataHash(string metadataHash);
	event SetFee(uint256 fee);

	// Constants
	MintableERC20 ZERO_MINTABLE = MintableERC20(address(0));

	// Contracts
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

		// Reputation tokens
		seekerRep = new MintableERC20(0);
		providerRep = new MintableERC20(0);

		// Initialize tokens
		seekerRep.init('SeekerRep', 'SWRS', maintainer);
		providerRep.init('ProviderRep', 'SWRP', maintainer);

		// Marketplace
		marketplace = new Marketplace();
		marketplace.init(
			address(0),
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
		vm.deal(seeker, 100e18);
		vm.deal(provider, 100e18);
		vm.stopPrank();
	}

	function testCanCreateItem() public {
		vm.startPrank(seeker);
		uint256 id = marketplace.newItem{ value: 10e18 + 25e16 }(
			10e18,
			5e18,
			'ItemMetadata'
		);

		assertEq(id, 1);
		assertEq(seeker.balance, 100e18 - 10e18 - 25e16);
		assertEq(maintainer.balance, 25e16);
		assertEq(address(marketplace).balance, 10e18);
	}

	function testCanCreateMultipleItems() public {
		vm.startPrank(seeker);
		assertEq(
			marketplace.newItem{ value: 10e18 + 25e16 }(10e18, 5e18, 'ItemMetadata'),
			1
		);
		assertEq(
			marketplace.newItem{ value: 10e18 + 25e16 }(10e18, 5e18, 'ItemMetadata'),
			2
		);
	}

	function testCannotCreateItemWithWrongValue() public {
		vm.startPrank(seeker);

		// Too little
		vm.expectRevert('WRONG_VALUE');
		marketplace.newItem{ value: 10e18 + 25e16 - 1 }(
			10e18,
			5e18,
			'ItemMetadata'
		);

		// Too much
		vm.expectRevert('WRONG_VALUE');
		marketplace.newItem{ value: 10e18 + 25e16 + 1 }(
			10e18,
			5e18,
			'ItemMetadata'
		);
	}

	function testCanFundItem() public {
		// Create an item
		vm.startPrank(seeker);

		uint256 id = marketplace.newItem{ value: 10e18 + 25e16 }(
			10e18,
			5e18,
			'ItemMetadata'
		);
		vm.stopPrank();

		// Fund the item
		vm.startPrank(provider);

		(uint8 v, bytes32 r, bytes32 s) = vm.sign(
			seekerPrivateKey,
			getFundItemHash(id)
		);
		marketplace.fundItem{ value: 5e18 + 25e16 }(id, v, r, s);

		// Check balances
		assertEq(seeker.balance, 100e18 - 10e18 - 25e16);
		assertEq(provider.balance, 100e18 - 5e18 - 25e16);
		assertEq(maintainer.balance, 50e16);
		assertEq(address(marketplace).balance, 15e18);
	}

	function testCannotFundInexistantItem() public {
		vm.startPrank(provider);
		vm.expectRevert('ITEM_NOT_OPEN');
		marketplace.fundItem{ value: 10e18 + 25e16 }(0, 0, '', '');
	}

	function testCannotFundItemWithWrongSignature() public {
		// Create an item
		vm.startPrank(seeker);
		uint256 id = marketplace.newItem{ value: 10e18 + 25e16 }(
			10e18,
			5e18,
			'ItemMetadata'
		);
		vm.stopPrank();

		// Fund the item
		vm.startPrank(provider);

		// Made up signature
		vm.expectRevert('INVALID_SIGNER');
		marketplace.fundItem{ value: 10e18 + 25e16 }(id, 27, 0, 0);

		// Provider signature
		(uint8 v, bytes32 r, bytes32 s) = vm.sign(
			providerPrivateKey,
			getFundItemHash(id)
		);

		vm.expectRevert('INVALID_SIGNER');
		marketplace.fundItem{ value: 10e18 + 25e16 }(id, v, r, s);
	}

	function testCannotFundItemWithWrongValue() public {
		// Create an item
		vm.startPrank(seeker);

		uint256 id = marketplace.newItem{ value: 10e18 + 25e16 }(
			10e18,
			5e18,
			'ItemMetadata'
		);
		vm.stopPrank();

		// Fund the item
		vm.startPrank(provider);

		(uint8 v, bytes32 r, bytes32 s) = vm.sign(
			seekerPrivateKey,
			getFundItemHash(id)
		);

		// Too little
		vm.expectRevert('WRONG_VALUE');
		marketplace.fundItem{ value: 10e18 + 25e16 - 1 }(id, v, r, s);

		// Too much
		vm.expectRevert('WRONG_VALUE');
		marketplace.fundItem{ value: 10e18 + 25e16 + 1 }(id, v, r, s);
	}

	function testCanInvalidateSignature() public {
		// Create an item
		vm.startPrank(seeker);
		uint256 id = marketplace.newItem{ value: 10e18 + 25e16 }(
			10e18,
			5e18,
			'ItemMetadata'
		);

		// Fund the item
		(uint8 v, bytes32 r, bytes32 s) = vm.sign(
			seekerPrivateKey,
			getFundItemHash(id)
		);
		marketplace.invalidateSignature(id, provider, v, r, s);
	}

	function testCannotInvalidateSomeoneElsesSignature() public {
		// Create an item
		vm.startPrank(seeker);
		uint256 id = marketplace.newItem{ value: 10e18 + 25e16 }(
			10e18,
			5e18,
			'ItemMetadata'
		);

		// Fund the item
		(uint8 v, bytes32 r, bytes32 s) = vm.sign(
			seekerPrivateKey,
			getFundItemHash(id)
		);

		vm.stopPrank();
		vm.startPrank(provider);
		vm.expectRevert('INVALID_SIGNER');
		marketplace.invalidateSignature(id, provider, v, r, s);
	}

	function testCannotFundWithInvalidatedSignature() public {
		// Create an item
		vm.startPrank(seeker);
		uint256 id = marketplace.newItem{ value: 10e18 + 25e16 }(
			10e18,
			5e18,
			'ItemMetadata'
		);

		// Sign the meessage
		(uint8 v, bytes32 r, bytes32 s) = vm.sign(
			seekerPrivateKey,
			getFundItemHash(id)
		);

		// Invalidate signature
		marketplace.invalidateSignature(id, provider, v, r, s);
		vm.stopPrank();

		// Try to fund the item
		vm.startPrank(provider);
		vm.expectRevert('SIGNATURE_INVALIDATED');
		marketplace.fundItem{ value: 10e18 + 25e16 }(id, v, r, s);
	}

	// Private
	function getFundItemHash(uint256 item) public view returns (bytes32) {
		return
			keccak256(
				abi.encodePacked(
					'\x19\x01',
					marketplace.DOMAIN_SEPARATOR(),
					keccak256(
						abi.encode(
							keccak256(
								'PermitProvider(address seeker,address provider,uint256 item)'
							),
							seeker,
							provider,
							item
						)
					)
				)
			);
	}
}
