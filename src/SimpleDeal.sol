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

contract SimpleDeal is Auth {
    /// @dev hashtagName The human readable name of the hashtag
    /// @dev hashtagFee The fixed hashtag fee in SWT
    /// @dev token The SWT token
    /// @dev ProviderRep The rep token that is minted for the Provider
    /// @dev SeekerRep The rep token that is minted for the Seeker
    /// @dev payoutaddress The address where the hashtag fee is sent.
    /// @dev metadataHash The IPFS hash metadata for this hashtag
    string public hashtagName;
    uint256 public hashtagFee;
    ERC20 public token;
    MintableERC20 public ProviderRep;
    MintableERC20 public SeekerRep;
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
    /// @param hashtagFee The value of the hashtag fee is stored in the deal. This prevents the hashtagmaintainer to influence an existing deal when changing the hashtag fee.
    /// @param dealValue The value of the deal (SWT)
    /// @param provider The address of the provider
    /// @param deals Array of deals made by this hashtag

    struct Item {
        Status status;
        uint256 hashtagFee;
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
        uint256 hashtagFee,
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

    /// @dev ReceivedApproval - This event is fired when minime sends approval.
    event ReceivedApproval(
        address sender,
        uint256 amount,
        address fromcontract,
        bytes extraData
    );

    /// @dev hashtagChanged - This event is fired when any of the metadata is changed.
    event HashtagChanged(string _change);

    /// @notice The function that creates the hashtag
    constructor(
        address _token,
        string memory _hashtagName,
        uint256 _hashtagFee,
        string memory _metadataHash
    ) Auth(msg.sender, Authority(address(0))) {
        /// @notice The name of the hashtag is set
        hashtagName = _hashtagName;

        /// @notice The seeker reputation token is created
        SeekerRep = new MintableERC20("SeekerRep", "SWRS", 0);

        /// @notice The provider reputation token is created
        ProviderRep = new MintableERC20("ProviderRep", "SWRP", 0);

        /// @notice SWT token is added
        token = ERC20(_token);

        /// Metadata added
        metadataHash = _metadataHash;

        /// hashtag fee is set to ...
        hashtagFee = _hashtagFee;

        /// Hashtag fee payout address is set
        /// First time we set it to msg.sender
        payoutAddress = msg.sender;
    }

    function receiveApproval(
        address _msgsender,
        uint256 _amount,
        address _fromcontract,
        bytes calldata _extraData
    ) public {
        //require(address(this).call(_extraData));
        emit ReceivedApproval(_msgsender, _amount, _fromcontract, _extraData);
    }

    /// @notice The Hashtag owner can always update the payout address.
    function setPayoutAddress(address _payoutaddress) public requiresAuth {
        payoutAddress = _payoutaddress;
        emit HashtagChanged("Payout address changed");
    }

    /// @notice The Hashtag owner can always update the metadata for the hashtag.
    function setMetadataHash(string calldata _metadataHash)
        public
        requiresAuth
    {
        metadataHash = _metadataHash;
        emit HashtagChanged("MetaData hash changed");
    }

    /// @notice The Hashtag owner can always change the hashtag fee amount
    function setHashtagFee(uint256 _newHashtagFee) public requiresAuth {
        hashtagFee = _newHashtagFee;
        emit HashtagChanged("Hashtag fee amount changed");
    }

    /// @notice The item making stuff

    /// @notice The create item function
    function newItem(
        bytes32 _itemHash,
        uint256 _itemValue,
        string calldata _metadata
    ) public {
        // make sure there is enough to pay the hashtag fee later on
        require(hashtagFee / 2 <= _itemValue); // Overflow protection

        // fund this deal
        uint256 totalValue = _itemValue + hashtagFee / 2;

        require(_itemValue + hashtagFee / 2 >= _itemValue); //overflow protection

        // if deal already exists don't allow to overwrite it
        require(
            items[_itemHash].hashtagFee == 0 && items[_itemHash].itemValue == 0
        );

        // @dev The Seeker transfers SWT to the hashtagcontract
        require(
            token.transferFrom(
                tx.origin,
                address(this),
                _itemValue + hashtagFee / 2
            )
        );

        // @dev The Seeker pays half of the hashtagFee to the Maintainer
        require(token.transfer(payoutAddress, hashtagFee / 2));

        // if it's funded - fill in the details
        items[_itemHash] = Item(
            Status.Open,
            hashtagFee,
            _itemValue,
            0,
            SeekerRep.balanceOf(tx.origin),
            address(0),
            tx.origin,
            _metadata
        );

        emit NewItemForTwo(
            tx.origin,
            _itemHash,
            _metadata,
            _itemValue,
            hashtagFee,
            totalValue,
            SeekerRep.balanceOf(tx.origin)
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
        require(c.itemValue + c.hashtagFee / 2 >= c.itemValue);
        require(
            token.transferFrom(
                tx.origin,
                address(this),
                c.itemValue + c.hashtagFee / 2
            )
        );

        // @dev The Seeker pays half of the hashtagFee to the Maintainer
        require(token.transfer(payoutAddress, c.hashtagFee / 2));

        /// @dev fill in the address of the provider ( to payout the deal later on )
        items[itemHash].providerAddress = tx.origin;
        items[itemHash].providerRep = ProviderRep.balanceOf(tx.origin);

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
        ProviderRep.mint(c.providerAddress, 5);

        /// @dev mint REP for Seeker
        SeekerRep.mint(c.seekerAddress, 5);

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
    /// @notice Half of the HashtagFee is sent to PayoutAddress
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
