// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {MockERC20} from "./lib/mocks/MockERC20.sol";

import {Hashtag} from "src/Hashtag.sol";

contract HashtagTest is Test {
    MockERC20 token;
    Hashtag hashtag;

    function setUp() public {
        token = new MockERC20("Swarm City", "SWT", 18);
        hashtag = new Hashtag(address(token), "Marketplace", 25e16, "SomeHash");
    }

    function testMetadata() public {
        assertEq(hashtag.name(), "Marketplace");
        assertEq(hashtag.fee(), 25e16);
        assertEq(address(hashtag.token()), address(token));
        assertEq(hashtag.payoutAddress(), address(this));
        assertEq(hashtag.metadataHash(), "SomeHash");
    }
}
