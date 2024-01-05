// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {PublicDrop} from "./SeaDropStructs.sol";

interface MembershipStructsErrorsAndEvents {
    event SeaDropMint(
        address indexed nftContract,
        address indexed minter,
        address indexed feeRecipient,
        address payer,
        uint256 quantityMinted,
        uint256 unitMintPrice,
        uint256 feeBps,
        uint256 dropStageIndex,
        address contractERC20
    );
    event PublicDropUpdated(address indexed nftContract, PublicDrop publicDrop);

    error IncorrectPayment(uint256 got, uint256 want);
    error NotActive(
        uint256 currentTimestamp,
        uint256 startTimestamp,
        uint256 endTimestamp
    );
    error MintQuantityCannotBeZero();
    error MintQuantityExceedsMaxMintedPerWallet(uint256 total, uint256 allowed);
    error MintQuantityExceedsMaxSupply(uint256 total, uint256 maxSupply);
    error InvalidFeeBps(uint256 feeBps);
}
