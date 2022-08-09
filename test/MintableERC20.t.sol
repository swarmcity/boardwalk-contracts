// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import 'forge-std/Test.sol';

// Custom
import { MintableERC20 } from 'src/MintableERC20.sol';

contract MintableERC20Test is Test {
	MintableERC20 token;

	function setUp() public {
		token = new MintableERC20('Name', 'Symbol', 18);
	}

	function testMetadata() public {
		assertEq(token.name(), 'Name');
		assertEq(token.symbol(), 'Symbol');
		assertEq(token.decimals(), 18);
	}

	function testMint(uint256 amount) public {
		token.mint(address(0xBEEF), amount);

		assertEq(token.totalSupply(), amount);
		assertEq(token.balanceOf(address(0xBEEF)), amount);
	}

	function testMintNotAuthorized(address from) public {
		vm.assume(from != address(this));
		vm.expectRevert('UNAUTHORIZED');
		vm.prank(from);
		token.mint(address(0xBEEF), 0);
	}
}
