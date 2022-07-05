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

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";

import {MintableERC20} from "./MintableERC20.sol";

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

    // @notice Status enum
    enum Status {
        Open,
        Done,
        Disputed,
        Resolved,
        Cancelled
    }

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
        uint256 itemValue;
        uint256 providerRep;
        uint256 seekerRep;
        address providerAddress;
        address seekerAddress;
        string metadata;
    }

    mapping(bytes32 => Item) items;

    /// @dev Event NewDealForTwo - This event is fired when a new deal for two is created.
    event NewItemForTwo(
        address owner,
        bytes32 itemHash,
        string metadata,
        uint256 itemValue,
        uint256 fee,
        uint256 totalValue,
        uint256 seekerRep
    );

    /// @dev Event FundDeal - This event is fired when a deal is been funded by a party.
    event FundItem(address seeker, address provider, bytes32 itemHash);

    /// @dev DealStatusChange - This event is fired when a deal status is updated.
    event ItemStatusChange(
        address owner,
        bytes32 itemHash,
        Status newstatus,
        string metadata
    );

    /// @dev hashtagChanged - This event is fired when the payout address is changed.
    event SetPayoutAddress(address payoutAddress);

    /// @dev hashtagChanged - This event is fired when the metadata hash is changed.
    event SetMetadataHash(string metadataHash);

    /// @dev hashtagChanged - This event is fired when the hashtag fee is changed.
    event Setfee(uint256 fee);

    /// @notice The function that creates the hashtag
    constructor(
        address _token,
        string memory _name,
        uint256 _fee,
        string memory _metadataHash
    ) Auth(msg.sender, Authority(address(0))) {
        // Create reputation tokens
        seekerRep = new MintableERC20("SeekerRep", "SWRS", 0);
        providerRep = new MintableERC20("ProviderRep", "SWRP", 0);

        // Global config
        name = _name;
        token = ERC20(_token);
        metadataHash = _metadataHash;
        fee = _fee;
        payoutAddress = msg.sender;
    }

    /// @notice The Hashtag owner can always update the payout address.
    function setPayoutAddress(address _payoutaddress) public requiresAuth {
        payoutAddress = _payoutaddress;
        emit SetPayoutAddress(payoutAddress);
    }

    /// @notice The Hashtag owner can always update the metadata for the hashtag.
    function setMetadataHash(string calldata _metadataHash)
        public
        requiresAuth
    {
        metadataHash = _metadataHash;
        emit SetMetadataHash(metadataHash);
    }

    /// @notice The Hashtag owner can always change the hashtag fee amount
    function setFee(uint256 _fee) public requiresAuth {
        fee = _fee;
        emit Setfee(fee);
    }

    /// @notice The item making stuff

    /// @notice The create item function
    function newItem(
        bytes32 _itemHash,
        uint256 _itemValue,
        string calldata _metadata
    ) public {
        // make sure there is enough to pay the hashtag fee later on
        require(fee / 2 <= _itemValue); // Overflow protection

        // fund this deal
        uint256 totalValue = _itemValue + fee / 2;

        require(_itemValue + fee / 2 >= _itemValue); //overflow protection

        // if deal already exists don't allow to overwrite it
        require(items[_itemHash].fee == 0 && items[_itemHash].itemValue == 0);

        // @dev The Seeker transfers SWT to the hashtagcontract
        require(
            token.transferFrom(tx.origin, address(this), _itemValue + fee / 2)
        );

        // @dev The Seeker pays half of the fee to the Maintainer
        require(token.transfer(payoutAddress, fee / 2));

        // if it's funded - fill in the details
        items[_itemHash] = Item(
            Status.Open,
            fee,
            _itemValue,
            0,
            seekerRep.balanceOf(tx.origin),
            address(0),
            tx.origin,
            _metadata
        );

        emit NewItemForTwo(
            tx.origin,
            _itemHash,
            _metadata,
            _itemValue,
            fee,
            totalValue,
            seekerRep.balanceOf(tx.origin)
        );
    }

    /// @notice Provider has to fund the deal
    function fundItem(string calldata _itemId) public {
        bytes32 itemHash = keccak256(abi.encodePacked(_itemId));

        Item storage c = items[itemHash];

        /// @dev only allow open deals to be funded
        require(c.status == Status.Open);

        /// @dev if the provider is filled in - the deal was already funded
        require(c.providerAddress == address(0));

        /// @dev put the tokens from the provider on the deal
        require(c.itemValue + c.fee / 2 >= c.itemValue);
        require(
            token.transferFrom(
                tx.origin,
                address(this),
                c.itemValue + c.fee / 2
            )
        );

        // @dev The Seeker pays half of the fee to the Maintainer
        require(token.transfer(payoutAddress, c.fee / 2));

        /// @dev fill in the address of the provider ( to payout the deal later on )
        items[itemHash].providerAddress = tx.origin;
        items[itemHash].providerRep = providerRep.balanceOf(tx.origin);

        emit FundItem(
            items[itemHash].seekerAddress,
            items[itemHash].providerAddress,
            itemHash
        );
    }

    /// @notice The payout function can only be called by the deal owner.
    function payoutItem(bytes32 _itemHash) public {
        Item storage c = items[_itemHash];

        /// @dev Only Seeker can payout
        require(c.seekerAddress == msg.sender);

        /// @dev you can only payout open deals
        require(c.status == Status.Open);

        /// @dev pay out the provider
        require(token.transfer(c.providerAddress, c.itemValue * 2));

        /// @dev mint REP for Provider
        providerRep.mint(c.providerAddress, 5);

        /// @dev mint REP for Seeker
        seekerRep.mint(c.seekerAddress, 5);

        /// @dev mark the deal as done
        items[_itemHash].status = Status.Done;
        emit ItemStatusChange(
            c.seekerAddress,
            _itemHash,
            Status.Done,
            c.metadata
        );
    }

    /// @notice The Cancel Item Function
    /// @notice Half of the fee is sent to PayoutAddress
    function cancelItem(bytes32 _itemHash) public {
        Item storage c = items[_itemHash];
        if (
            c.itemValue > 0 &&
            c.providerAddress == address(0) &&
            c.status == Status.Open
        ) {
            // @dev The Seeker gets the remaining value
            require(token.transfer(c.seekerAddress, c.itemValue));

            items[_itemHash].status = Status.Cancelled;

            emit ItemStatusChange(
                msg.sender,
                _itemHash,
                Status.Cancelled,
                c.metadata
            );
        }
    }

    /// @notice The Dispute Item Function
    /// @notice The Seeker or Provider can dispute an item, only the Maintainer can resolve it.
    function disputeItem(bytes32 _itemHash) public {
        Item storage c = items[_itemHash];
        require(c.status == Status.Open, "item not open");

        if (msg.sender == c.seekerAddress) {
            /// @dev Seeker starts the dispute
            /// @dev Only items with Provider set can be disputed
            require(c.providerAddress != address(0), "provider not 0 not open");
        } else {
            /// @dev Provider starts dispute
            require(c.providerAddress == msg.sender, "sender is provider");
        }
        /// @dev Set itemStatus to Disputed
        items[_itemHash].status = Status.Disputed;
        emit ItemStatusChange(
            msg.sender,
            _itemHash,
            Status.Disputed,
            c.metadata
        );
    }

    /// @notice The Resolve Item Function ♡
    /// @notice The Maintainer resolves the disputed item.
    function resolveItem(bytes32 _itemHash, uint256 _seekerFraction) public {
        Item storage c = items[_itemHash];
        require(msg.sender == payoutAddress);
        require(c.status == Status.Disputed);
        require(token.transfer(c.seekerAddress, _seekerFraction));
        require(c.itemValue * 2 - _seekerFraction <= c.itemValue * 2);
        require(
            token.transfer(c.providerAddress, c.itemValue * 2 - _seekerFraction)
        );
        items[_itemHash].status = Status.Resolved;
        emit ItemStatusChange(
            c.seekerAddress,
            _itemHash,
            Status.Resolved,
            c.metadata
        );
    }

    /// @notice Read the details of a deal
    function readDeal(bytes32 _itemHash)
        public
        view
        returns (Item memory item)
    {
        return items[_itemHash];
    }
}
