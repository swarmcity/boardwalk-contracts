// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 *  @title Simple Deal Hashtag
 *  @dev Created in Swarm City anno 2017,
 *  for the world, with love.
 *  description Symmetrical Escrow Deal Contract
 *  description This is the hashtag contract for creating Swarm City marketplaces.
 *  It's the first, most simple approach to making Swarm City work.
 *  This contract creates "SimpleDeals".
 */

import { ERC20 } from 'solmate/tokens/ERC20.sol';
import { Auth, Authority } from 'solmate/auth/Auth.sol';
import { SafeTransferLib } from 'solmate/utils/SafeTransferLib.sol';

import { MintableERC20 } from './MintableERC20.sol';

// @notice Status enum
enum Status {
	None,
	Open,
	Funded,
	Done,
	Disputed,
	Resolved,
	Cancelled
}

contract Hashtag is Auth {
	/// @dev name The human readable name of the hashtag
	/// @dev fee The fixed hashtag fee in the specified token
	/// @dev token The token for fees
	/// @dev providerRep The rep token that is minted for the Provider
	/// @dev seekerRep The rep token that is minted for the Seeker
	/// @dev payoutaddress The address where the hashtag fee is sent.
	/// @dev metadataHash The IPFS hash metadata for this hashtag
	string public name;
	uint256 public fee;
	ERC20 public token;
	MintableERC20 public providerRep;
	MintableERC20 public seekerRep;
	address public payoutAddress;
	string public metadataHash;

	/// @param dealStruct The deal object.
	/// @param status Coming from Status enum.
	/// Statuses: Open, Done, Disputed, Resolved, Cancelled
	/// @param fee The value of the hashtag fee is stored in the deal. This prevents the hashtagmaintainer to influence an existing deal when changing the hashtag fee.
	/// @param dealValue The value of the deal (SWT)
	/// @param provider The address of the provider
	/// @param deals Array of deals made by this hashtag

	struct Item {
		Status status;
		uint256 fee;
		uint256 price;
		uint256 providerRep;
		uint256 seekerRep;
		address providerAddress;
		address seekerAddress;
		string metadata;
	}

	mapping(bytes32 => Item) public items;

	/// @dev Event NewDealForTwo - This event is fired when a new deal for two is created.
	event NewItem(
		address indexed owner,
		bytes32 indexed id,
		string metadata,
		uint256 price,
		uint256 fee,
		uint256 seekerRep
	);

	/// @dev Event FundDeal - This event is fired when a deal is been funded by a party.
	event FundItem(address indexed provider, bytes32 indexed id);

	/// @dev DealStatusChange - This event is fired when a deal status is updated.
	event ItemStatusChange(bytes32 indexed id, Status newstatus);

	/// @dev hashtagChanged - This event is fired when the payout address is changed.
	event SetPayoutAddress(address payoutAddress);

	/// @dev hashtagChanged - This event is fired when the metadata hash is changed.
	event SetMetadataHash(string metadataHash);

	/// @dev hashtagChanged - This event is fired when the hashtag fee is changed.
	event SetFee(uint256 fee);

	/// @notice The function that creates the hashtag
	constructor() Auth(address(0), Authority(address(0))) {}

	/// @notice The function that initializes the hashtag
	function init(
		address _token,
		string memory _name,
		uint256 _fee,
		string memory _metadataHash,
		address _owner,
		MintableERC20 _seekerRep,
		MintableERC20 _providerRep
	) public {
		require(token == ERC20(address(0)), 'ALREADY_INITIALIZED');
		require(_token != address(0), 'INVALID_TOKEN');

		// Reputation tokens
		seekerRep = _seekerRep;
		providerRep = _providerRep;

		// Global config
		name = _name;
		token = ERC20(_token);
		metadataHash = _metadataHash;
		fee = _fee;
		payoutAddress = msg.sender;

		// Auth
		owner = _owner;
	}

	/// @notice The Hashtag owner can always update the payout address.
	function setPayoutAddress(address _payoutaddress) public requiresAuth {
		payoutAddress = _payoutaddress;
		emit SetPayoutAddress(payoutAddress);
	}

	/// @notice The Hashtag owner can always update the metadata for the hashtag.
	function setMetadataHash(string calldata _metadataHash) public requiresAuth {
		metadataHash = _metadataHash;
		emit SetMetadataHash(metadataHash);
	}

	/// @notice The Hashtag owner can always change the hashtag fee amount
	function setFee(uint256 _fee) public requiresAuth {
		fee = _fee;
		emit SetFee(fee);
	}

	/// @notice The item making stuff

	/// @notice The create item function
	function newItem(
		bytes32 _id,
		uint256 _price,
		string calldata _metadata
	) public {
		// fund this deal
		uint256 totalValue = _price + fee / 2;

		// if deal already exists don't allow to overwrite it
		require(items[_id].status == Status.None, 'ITEM_ALREADY_EXISTS');

		// @dev The Seeker transfers SWT to the hashtagcontract
		SafeTransferLib.safeTransferFrom(
			token,
			msg.sender,
			address(this),
			totalValue
		);

		// @dev The Seeker pays half of the fee to the Maintainer
		SafeTransferLib.safeTransfer(token, payoutAddress, fee / 2);

		// Seeker rep (cache to save an external call)
		uint256 rep = seekerRep.balanceOf(msg.sender);

		// if it's funded - fill in the details
		items[_id] = Item(
			Status.Open,
			fee,
			_price,
			0,
			rep,
			address(0),
			msg.sender,
			_metadata
		);

		emit NewItem(msg.sender, _id, _metadata, _price, fee, rep);
	}

	/// @notice Provider has to fund the deal
	function fundItem(bytes memory preImage) public {
		bytes32 id = keccak256(preImage);
		Item storage item = items[id];

		/// @dev only allow open deals to be funded
		require(item.status == Status.Open, 'ITEM_NOT_OPEN');

		/// @dev put the tokens from the provider on the deal
		SafeTransferLib.safeTransferFrom(
			token,
			msg.sender,
			address(this),
			item.price + item.fee / 2
		);

		// @dev The Seeker pays half of the fee to the Maintainer
		SafeTransferLib.safeTransfer(token, payoutAddress, item.fee / 2);

		/// @dev fill in the address of the provider (to payout the deal later on)
		item.providerAddress = msg.sender;
		item.providerRep = providerRep.balanceOf(msg.sender);
		item.status = Status.Funded;

		emit FundItem(item.providerAddress, id);
	}

	/// @notice The payout function can only be called by the deal owner.
	function payoutItem(bytes32 _id) public {
		Item storage item = items[_id];

		/// @dev Only Seeker can payout
		require(item.seekerAddress == msg.sender, 'UNAUTHORIZED');

		/// @dev you can only payout open deals
		require(item.status == Status.Funded, 'DEAL_NOT_FUNDED');

		/// @dev pay out the provider
		SafeTransferLib.safeTransfer(token, item.providerAddress, item.price * 2);

		/// @dev mint REP for Provider
		providerRep.mint(item.providerAddress, 5);

		/// @dev mint REP for Seeker
		seekerRep.mint(item.seekerAddress, 5);

		/// @dev mark the deal as done
		item.status = Status.Done;
		emit ItemStatusChange(_id, Status.Done);
	}

	/// @notice The Cancel Item Function
	/// @notice Half of the fee is sent to PayoutAddress
	function cancelItem(bytes32 _id) public {
		Item storage item = items[_id];
		require(item.status == Status.Open, 'DEAL_NOT_OPEN');
		require(item.seekerAddress == msg.sender, 'UNAUTHORIZED');

		SafeTransferLib.safeTransfer(token, item.seekerAddress, item.price);

		item.status = Status.Cancelled;
		emit ItemStatusChange(_id, Status.Cancelled);
	}

	/// @notice The Dispute Item Function
	/// @notice The Seeker or Provider can dispute an item, only the Maintainer can resolve it.
	function disputeItem(bytes32 _id) public {
		Item storage item = items[_id];
		require(item.status == Status.Funded, 'DEAL_NOT_FUNDED');
		require(
			item.providerAddress == msg.sender || item.seekerAddress == msg.sender,
			'UNAUTHORIZED'
		);

		/// @dev Set itemStatus to Disputed
		item.status = Status.Disputed;
		emit ItemStatusChange(_id, Status.Disputed);
	}

	/// @notice The Resolve Item Function ♡
	/// @notice The Maintainer resolves the disputed item.
	function resolveItem(bytes32 _id, uint256 _seekerFraction) public {
		Item storage item = items[_id];
		require(msg.sender == payoutAddress, 'UNAUTHORIZED');
		require(item.status == Status.Disputed, 'DEAL_NOT_DISPUTED');

		SafeTransferLib.safeTransfer(token, item.seekerAddress, _seekerFraction);
		SafeTransferLib.safeTransfer(
			token,
			item.providerAddress,
			item.price * 2 - _seekerFraction
		);

		item.status = Status.Resolved;
		emit ItemStatusChange(_id, Status.Resolved);
	}
}
