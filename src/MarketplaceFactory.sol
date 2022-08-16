// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

// OpenZeppelin
import '@openzeppelin/contracts/proxy/Clones.sol';

// Custom
import { Marketplace } from './Marketplace.sol';
import { MintableERC20 } from './MintableERC20.sol';

contract MarketplaceFactory {
	event MarketplaceCreated(
		address indexed addr,
		string name,
		address seekerRep,
		address providerRep
	);

	address public masterMarketplace;
	address public masterRep;

	constructor() {
		masterMarketplace = address(new Marketplace());
		masterRep = address(new MintableERC20(0));
	}

	function create(
		address token,
		string memory name,
		uint256 fee,
		string memory metadata
	) public returns (Marketplace marketplace) {
		/// @dev create the reputation tokens
		MintableERC20 seekerRep = MintableERC20(Clones.clone(masterRep));
		MintableERC20 providerRep = MintableERC20(Clones.clone(masterRep));

		/// @dev initialize the tokens
		seekerRep.init('SeekerRep', 'SWRS', msg.sender);
		providerRep.init('ProviderRep', 'SWRP', msg.sender);

		/// @dev create the marketplace
		marketplace = Marketplace(Clones.clone(masterMarketplace));
		marketplace.init(
			token,
			name,
			fee,
			metadata,
			msg.sender,
			seekerRep,
			providerRep
		);

		/// @dev emit marketplace created event
		emit MarketplaceCreated(
			address(marketplace),
			name,
			address(seekerRep),
			address(providerRep)
		);
	}
}
