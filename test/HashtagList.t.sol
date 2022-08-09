// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import 'forge-std/Test.sol';

// Custom
import { Hashtag } from 'src/Hashtag.sol';
import { HashtagList } from 'src/HashtagList.sol';
import { MintableERC20 } from 'src/MintableERC20.sol';

contract HashtagListTest is Test {
	// Events
	event HashtagAdded(Hashtag indexed addr, string name);
	event HashtagRemoved(Hashtag indexed addr);

	// Contracts
	HashtagList hashtagList;

	function setUp() public {
		// Hashtag and hashtag list
		hashtagList = new HashtagList();
	}

	function createHashtag(string memory name) private returns (Hashtag hashtag) {
		hashtag = new Hashtag();
		hashtag.init(
			address(1),
			name,
			50e16,
			'SomeHash',
			address(2),
			MintableERC20(address(3)),
			MintableERC20(address(4))
		);
	}

	function testCannotAddUninitializedHashtag() public {
		Hashtag hashtag = new Hashtag();
		vm.expectRevert('UNINITIALIZED');
		hashtagList.add(hashtag);
	}

	function testCanAddHashtag() public {
		Hashtag hashtag = createHashtag('Hashtag');

		// Add hashtag and expect event
		vm.expectEmit(true, true, true, true);
		emit HashtagAdded(hashtag, 'Hashtag');
		hashtagList.add(hashtag);

		// Check metadata
		assertEq(address(hashtagList.hashtags(0)), address(hashtag));
		assertEq(hashtagList.count(), 1);
	}

	function testCanAddMultipleHashtags() public {
		Hashtag[] memory hashtags = new Hashtag[](6);

		hashtagList.add(hashtags[0] = createHashtag('One'));
		hashtagList.add(hashtags[1] = createHashtag('Two'));
		hashtagList.add(hashtags[2] = createHashtag('Three'));
		hashtagList.add(hashtags[3] = createHashtag('Four'));
		hashtagList.add(hashtags[4] = createHashtag('Five'));
		hashtagList.add(hashtags[5] = createHashtag('Six'));

		for (uint256 i = 0; i < 6; i++) {
			assertEq(address(hashtagList.hashtags(i)), address(hashtags[i]));
		}

		assertEq(hashtagList.count(), 6);
	}

	function testCanRemoveHashtag() public {
		Hashtag one = createHashtag('One');
		Hashtag two = createHashtag('Two');

		// Add hashtag
		hashtagList.add(one);
		hashtagList.add(two);

		// Remove hashtag and expect event
		vm.expectEmit(true, true, true, true);
		emit HashtagRemoved(one);
		hashtagList.remove(0);

		// Check metadata
		assertEq(hashtagList.count(), 1);

		// Make sure "two" is the only element left
		assertEq(address(hashtagList.hashtags(0)), address(two));

		// Expect the second element to not exist
		vm.expectRevert();
		hashtagList.hashtags(1);
	}

	function testCanRemoveAllHashtags() public {
		hashtagList.add(createHashtag('One'));
		hashtagList.add(createHashtag('Two'));
		hashtagList.add(createHashtag('Three'));
		hashtagList.add(createHashtag('Four'));
		hashtagList.add(createHashtag('Five'));
		hashtagList.add(createHashtag('Six'));

		hashtagList.remove(5);
		hashtagList.remove(1);
		hashtagList.remove(3);
		hashtagList.remove(0);
		hashtagList.remove(1);
		hashtagList.remove(0);

		assertEq(hashtagList.count(), 0);
		vm.expectRevert();
		hashtagList.hashtags(0);
	}
}
