// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
import 'forge-std/Test.sol';

// Custom
import { Marketplace } from 'src/Marketplace.sol';
import { MarketplaceList } from 'src/MarketplaceList.sol';
import { MintableERC20 } from 'src/MintableERC20.sol';

contract MarketplaceListTest is Test {
	// Events
	event MarketplaceAdded(Marketplace indexed addr, string name);
	event MarketplaceRemoved(Marketplace indexed addr);

	// Contracts
	MarketplaceList marketplaceList;

	function setUp() public {
		// Marketplace and marketplace list
		marketplaceList = new MarketplaceList();
	}

	function createMarketplace(string memory name)
		private
		returns (Marketplace marketplace)
	{
		marketplace = new Marketplace();
		marketplace.init(
			address(1),
			name,
			50e16,
			'SomeHash',
			address(2),
			MintableERC20(address(3)),
			MintableERC20(address(4))
		);
	}

	function testCannotAddUninitializedMarketplace() public {
		Marketplace marketplace = new Marketplace();
		vm.expectRevert('UNINITIALIZED');
		marketplaceList.add(marketplace);
	}

	function testCanAddMarketplace() public {
		Marketplace marketplace = createMarketplace('Marketplace');

		// Add marketplace and expect event
		vm.expectEmit(true, true, true, true);
		emit MarketplaceAdded(marketplace, 'Marketplace');
		marketplaceList.add(marketplace);

		// Check metadata
		assertEq(address(marketplaceList.marketplaces(0)), address(marketplace));
		assertEq(marketplaceList.count(), 1);
	}

	function testCanAddMultipleMarketplaces() public {
		Marketplace[] memory marketplaces = new Marketplace[](6);

		marketplaceList.add(marketplaces[0] = createMarketplace('One'));
		marketplaceList.add(marketplaces[1] = createMarketplace('Two'));
		marketplaceList.add(marketplaces[2] = createMarketplace('Three'));
		marketplaceList.add(marketplaces[3] = createMarketplace('Four'));
		marketplaceList.add(marketplaces[4] = createMarketplace('Five'));
		marketplaceList.add(marketplaces[5] = createMarketplace('Six'));

		for (uint256 i = 0; i < 6; i++) {
			assertEq(
				address(marketplaceList.marketplaces(i)),
				address(marketplaces[i])
			);
		}

		assertEq(marketplaceList.count(), 6);
	}

	function testCanRemoveMarketplace() public {
		Marketplace one = createMarketplace('One');
		Marketplace two = createMarketplace('Two');

		// Add marketplace
		marketplaceList.add(one);
		marketplaceList.add(two);

		// Remove marketplace and expect event
		vm.expectEmit(true, true, true, true);
		emit MarketplaceRemoved(one);
		marketplaceList.remove(0);

		// Check metadata
		assertEq(marketplaceList.count(), 1);

		// Make sure "two" is the only element left
		assertEq(address(marketplaceList.marketplaces(0)), address(two));

		// Expect the second element to not exist
		vm.expectRevert();
		marketplaceList.marketplaces(1);
	}

	function testCanRemoveAllMarketplaces() public {
		marketplaceList.add(createMarketplace('One'));
		marketplaceList.add(createMarketplace('Two'));
		marketplaceList.add(createMarketplace('Three'));
		marketplaceList.add(createMarketplace('Four'));
		marketplaceList.add(createMarketplace('Five'));
		marketplaceList.add(createMarketplace('Six'));

		marketplaceList.remove(5);
		marketplaceList.remove(1);
		marketplaceList.remove(3);
		marketplaceList.remove(0);
		marketplaceList.remove(1);
		marketplaceList.remove(0);

		assertEq(marketplaceList.count(), 0);
		vm.expectRevert();
		marketplaceList.marketplaces(0);
	}
}
