// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC20 } from 'solmate/tokens/ERC20.sol';
import { Auth, Authority } from 'solmate/auth/Auth.sol';

contract MintableERC20 is ERC20, Auth {
	constructor(
		string memory _name,
		string memory _symbol,
		uint8 _decimals
	) ERC20(_name, _symbol, _decimals) Auth(msg.sender, Authority(address(0))) {}

	function mint(address to, uint256 amount) external requiresAuth {
		_mint(to, amount);
	}
}
