// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

// OpenZeppelin
import '@openzeppelin/contracts/proxy/Clones.sol';

// Custom
import { Hashtag } from './Hashtag.sol';
import { MintableERC20 } from './MintableERC20.sol';

contract HashtagFactory {
	event HashtagCreated(
		address indexed addr,
		string name,
		address seekerRep,
		address providerRep
	);

	address public masterHashtag;
	address public masterRep;

	constructor() {
		masterHashtag = address(new Hashtag());
		masterRep = address(new MintableERC20(0));
	}

	function create(
		address token,
		string memory name,
		uint256 fee,
		string memory metadata
	) public returns (Hashtag hashtag) {
		/// @dev create the reputation tokens
		MintableERC20 seekerRep = MintableERC20(Clones.clone(masterRep));
		MintableERC20 providerRep = MintableERC20(Clones.clone(masterRep));

		/// @dev initialize the tokens
		seekerRep.init('SeekerRep', 'SWRS', msg.sender);
		providerRep.init('ProviderRep', 'SWRP', msg.sender);

		/// @dev create the hashtag
		hashtag = Hashtag(Clones.clone(masterHashtag));
		hashtag.init(
			token,
			name,
			fee,
			metadata,
			msg.sender,
			seekerRep,
			providerRep
		);

		/// @dev emit hashtag created event
		emit HashtagCreated(
			address(hashtag),
			name,
			address(seekerRep),
			address(providerRep)
		);
	}
}
