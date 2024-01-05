// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {PublicDrop} from "../lib/SeaDropStructs.sol";

import {MembershipStructsErrorsAndEvents} from "../lib/MembershipStructsErrorsAndEvents.sol";

interface IMembershipDrop is MembershipStructsErrorsAndEvents {
    function mintPublic(
        address nftContract,
        address feeRecipient,
        address minterIfNotPayer,
        uint256 quantity
    ) external payable;

    function updatePublicDrop(PublicDrop calldata publicDrop) external;
}
