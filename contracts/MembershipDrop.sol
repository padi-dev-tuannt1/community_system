// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {PublicDrop} from "./lib/SeaDropStructs.sol";

import {IMembershipDrop} from "./interfaces/IMembershipDrop.sol";

interface IMembershipNFT {
    function mintDrop(address minter) external;

    function getMintStats(
        address minter
    )
        external
        view
        returns (
            uint256 minterNumMinted,
            uint256 currentTotalSupply,
            uint256 maxSupply
        );
}

contract MembershipDrop is IMembershipDrop, ReentrancyGuard {
    uint256 internal constant _PUBLIC_DROP_STAGE_INDEX = 0;

    mapping(address => PublicDrop) private _publicDrops;

    function mintPublic(
        address nftContract,
        address feeRecipient,
        address minterIfNotPayer,
        uint256 quantity
    ) external payable {
        // Get the public drop data.
        PublicDrop memory publicDrop = _publicDrops[nftContract];

        // Ensure that the drop has started.
        _checkActive(publicDrop.startTime, publicDrop.endTime);

        uint256 mintPrice = publicDrop.mintPrice;

        // Get the minter address.
        address minter = minterIfNotPayer != address(0)
            ? minterIfNotPayer
            : msg.sender;

        // Check that the minter is allowed to mint the desired quantity.
        _checkMintQuantity(
            nftContract,
            minter,
            quantity,
            publicDrop.maxTotalMintableByWallet
        );

        // Mint the token(s), emit an event.
        _mint(
            nftContract,
            minter,
            quantity,
            mintPrice,
            _PUBLIC_DROP_STAGE_INDEX,
            publicDrop.feeBps,
            feeRecipient,
            publicDrop.contractERC20
        );
    }

    function updatePublicDrop(PublicDrop calldata publicDrop) external {
        // Revert if the fee basis points is greater than 10_000.
        if (publicDrop.feeBps > 10_000) {
            revert InvalidFeeBps(publicDrop.feeBps);
        }
        // Set the public drop data.
        _publicDrops[msg.sender] = publicDrop;

        // Emit an event with the update.
        emit PublicDropUpdated(msg.sender, publicDrop);
    }

    function _mint(
        address nftContract,
        address minter,
        uint256 quantity,
        uint256 mintPrice,
        uint256 dropStageIndex,
        uint256 feeBps,
        address feeRecipient,
        address contractERC20
    ) internal nonReentrant {
        // Mint the token(s).
        IMembershipNFT(nftContract).mintDrop(minter);

        // Emit an event for the mint.
        emit SeaDropMint(
            nftContract,
            minter,
            feeRecipient,
            msg.sender,
            quantity,
            mintPrice,
            feeBps,
            dropStageIndex,
            contractERC20
        );
    }

    function _checkMintQuantity(
        address nftContract,
        address minter,
        uint256 quantity,
        uint256 maxTotalMintableByWallet
    ) internal view {
        // Mint quantity of zero is not valid.
        if (quantity == 0) {
            revert MintQuantityCannotBeZero();
        }

        // Get the mint stats.
        (
            uint256 minterNumMinted,
            uint256 currentTotalSupply,
            uint256 maxSupply
        ) = IMembershipNFT(nftContract).getMintStats(minter);

        // Ensure mint quantity doesn't exceed maxTotalMintableByWallet.
        if (quantity + minterNumMinted > maxTotalMintableByWallet) {
            revert MintQuantityExceedsMaxMintedPerWallet(
                quantity + minterNumMinted,
                maxTotalMintableByWallet
            );
        }

        // Ensure mint quantity doesn't exceed maxSupply.
        if (quantity + currentTotalSupply > maxSupply) {
            revert MintQuantityExceedsMaxSupply(
                quantity + currentTotalSupply,
                maxSupply
            );
        }
    }

    function _checkActive(uint256 startTime, uint256 endTime) internal view {
        if (
            _cast(block.timestamp < startTime) |
                _cast(block.timestamp > endTime) ==
            1
        ) {
            // Revert if the drop stage is not active.
            revert NotActive(block.timestamp, startTime, endTime);
        }
    }

    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }
}
