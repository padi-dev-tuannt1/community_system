// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/ILoyalNFT.sol";
import "./interfaces/IERC20.sol";

contract NFTStake is
    Initializable,
    UUPSUpgradeable,
    IERC721ReceiverUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    ILoyalNFT nft;
    IERC20 rewardToken;

    enum Status {
        UnStake,
        Stake
    }
    struct Stake {
        address owner;
        uint256 stakedAt;
        Status status;
        uint256 season;
    }

    mapping(address => mapping(uint256 => uint256)) rewardAmounts;
    mapping(uint256 => Stake) public stakeInfos;
    // ******** //
    //  EVENTS  //
    // ******** //

    event ItemsStaked(
        uint256 tokenId,
        address owner,
        uint256 timestamp,
        uint256 season
    );
    event ItemsUnstaked(uint256[] tokenIds, address owner, uint256 timestamp);
    event Claimed(address owner, uint256 reward);
    event Retrieved(address indexed owner, uint256 claimable, uint256 season);
    event RewardCreated(address recipient, uint256 reward, uint256 season);

    // ******** //
    //  ERRORS  //
    // ******** //

    error ItemAlreadyStaked();
    error NotItemOwner();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _nftAddress,
        address _rewardToken
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        nft = ILoyalNFT(_nftAddress);
        rewardToken = IERC20(_rewardToken);
    }

    function stake(uint256 tokenId, uint256 _season) external {
        require(stakeInfos[tokenId].status == Status.UnStake, "Already stake");

        if (nft.ownerOf(tokenId) != msg.sender) {
            revert NotItemOwner();
        }

        require(stakeInfos[tokenId].season < _season, "Invalid season");

        stakeInfos[tokenId] = Stake(
            msg.sender,
            block.timestamp,
            Status.Stake,
            _season
        );

        nft.safeTransferFrom(msg.sender, address(this), tokenId);

        emit ItemsStaked(tokenId, msg.sender, block.timestamp, _season);
    }

    function createReward(
        address[] calldata stakers,
        uint256[] calldata rewards,
        uint256 totalReward,
        uint256 _season
    ) external onlyOwner {
        require(stakers.length == rewards.length, "Length mismatch");

        for (uint256 i = 0; i < rewards.length; i++) {
            address who = stakers[i];
            _setReward(who, rewards[i], _season);
        }

        _processPayment(
            msg.sender,
            address(this),
            totalReward * 10 ** rewardToken.decimals()
        );
    }

    function claim(
        uint256[] calldata tokenIds,
        uint256 _season
    ) external nonReentrant {
        _unstake(tokenIds, _season);
        uint256 claimable = rewardAmounts[msg.sender][_season];
        require(claimable > 0, "Nothing to claim");

        _processPayment(address(this), msg.sender, claimable);
        rewardAmounts[msg.sender][_season] = 0;
        emit Retrieved(msg.sender, claimable, _season);
    }

    function _unstake(uint256[] calldata tokenIds, uint256 _season) private {
        uint256 unstakedCount = tokenIds.length;

        for (uint256 i; i < unstakedCount; ) {
            uint256 tokenId = tokenIds[i];
            require(stakeInfos[tokenId].season == _season, "Invalid season");
            require(
                stakeInfos[tokenId].status == Status.Stake,
                "Already unstake"
            );
            require(stakeInfos[tokenId].owner == msg.sender, "Not owner");

            nft.safeTransferFrom(address(this), msg.sender, tokenId);
            stakeInfos[tokenId].status = Status.UnStake;
            stakeInfos[tokenId].owner = address(0);

            unchecked {
                ++i;
            }
        }

        emit ItemsUnstaked(tokenIds, msg.sender, block.timestamp);
    }

    function _setReward(
        address staker,
        uint256 reward,
        uint256 _season
    ) private {
        require(rewardAmounts[staker][_season] == 0, "Already add reward");
        require(staker != address(0), "Staker cannot be zero address");
        require(staker != address(this), "Cannot reward for self");
        require(reward != 0, "Reward cannot be zero");

        rewardAmounts[staker][_season] = reward * 10 ** rewardToken.decimals();
        emit RewardCreated(staker, reward, _season);
    }

    function _processPayment(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) return;
        if (from == address(this)) {
            IERC20(rewardToken).transfer(to, amount);
        } else {
            IERC20(rewardToken).transferFrom(from, to, amount);
        }
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /*
     * @dev Allow contract to receive ERC721 token.
     */
    function onERC721Received(
        address /**operator*/,
        address /**from*/,
        uint256 /**amount*/,
        bytes calldata //data
    ) external pure override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}
