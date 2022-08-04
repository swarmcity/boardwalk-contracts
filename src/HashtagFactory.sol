// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// OpenZeppelin
import '@openzeppelin/contracts/proxy/Clones.sol';

// Custom
import { Hashtag } from './Hashtag.sol';
import { MintableERC20 } from './MintableERC20.sol';

contract HashtagFactory {
	event HashtagCreated(address indexed addr, string name);

	address public masterHashtag;
	address public masterSeekerRep;
	address public masterProviderRep;

	constructor() {
		masterHashtag = address(new Hashtag());
		masterSeekerRep = address(new MintableERC20('SeekerRep', 'SWRS', 0));
		masterProviderRep = address(new MintableERC20('ProviderRep', 'SWRP', 0));
	}

	function create(
		address token,
		string memory name,
		uint256 fee,
		string memory metadata
	) public {
		/// @dev create the reputation tokens
		MintableERC20 seekerRep = MintableERC20(Clones.clone(masterSeekerRep));
		MintableERC20 providerRep = MintableERC20(Clones.clone(masterProviderRep));

		/// @dev create the hashtag
		Hashtag hashtag = Hashtag(Clones.clone(masterHashtag));
		hashtag.init(
			token,
			name,
			fee,
			metadata,
			msg.sender,
			seekerRep,
			providerRep
		);
		emit HashtagCreated(address(hashtag), name);
	}
}
