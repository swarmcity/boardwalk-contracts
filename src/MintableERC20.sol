// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import { ERC20 } from 'solmate/tokens/ERC20.sol';
import { Auth, Authority } from 'solmate/auth/Auth.sol';

contract MintableERC20 is ERC20, Auth {
	constructor(uint8 _decimals)
		ERC20('', '', _decimals)
		Auth(address(0), Authority(address(0)))
	{}

	function init(
		string memory _name,
		string memory _symbol,
		address _owner
	) public {
		require(owner == address(0), 'ALREADY_INITIALIZED');

		name = _name;
		symbol = _symbol;
		owner = _owner;
	}

	function mint(address to, uint256 amount) external requiresAuth {
		_mint(to, amount);
	}
}
