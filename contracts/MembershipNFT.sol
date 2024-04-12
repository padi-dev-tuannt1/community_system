// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IMembershipDrop} from "./interfaces/IMembershipDrop.sol";
import {PublicDrop} from "./lib/SeaDropStructs.sol";

interface ICPToken {
    function balanceOf(address user) external returns (uint256);

    function burn(address account, uint256 amount) external;
}

contract MembershipNFT is ERC721, Ownable, ReentrancyGuard {
    /* Error declarations */
    error OnlyAllowedDrop();
    error OnlyOwner();
    error NotEnoughCP();

    /* Events */
    event LevelUpdated(
        address account,
        uint256 tokenId,
        uint256 level,
        uint256 CPBurn
    );
    event MaxSupplyUpdated(uint256 supply);

    struct MultiConfigureStruct {
        uint256 maxSupply;
        address membershipDropImpl;
        PublicDrop publicDrop;
    }

    ICPToken public CPtoken;
    address public drop;
    uint256 private _tokenIdCounter;
    uint256 _maxSupply;

    mapping(uint256 => uint256) public levelToPoint;
    mapping(uint256 => uint256) tokenIdToLevel;

    string[12] public levelURI = [
        "https://ipfs.filebase.io/ipfs/Qme1z6mZQ74ZRJVoMRmth51e7x6tcSVewNitHzvvUxGuvW",
        "https://ipfs.filebase.io/ipfs/QmZeaXP4TEB6LKRpPqBRAMD5wTeZS1TpGVsmurJFwZ74Jn",
        "https://ipfs.filebase.io/ipfs/QmX6PMYkZJQGNUePXUyMnVJ2oD5FKsFbWMQzFsy5rmjFQ1",
        "https://ipfs.filebase.io/ipfs/QmdRcS1jiWf6FCr6323nNyVuUWCffUShou9bJnWuFV69hk",
        "https://ipfs.filebase.io/ipfs/QmdSHt2wn8DZYYkmXRNqcE22eXqybRXhdESqK1JTguCF98",
        "https://ipfs.filebase.io/ipfs/QmUj9rLURHTyie1BoPBTFBbLaGBDy2EBhgz5LfJNTk3LsU",
        "https://ipfs.filebase.io/ipfs/QmWpuRH41LNUDsL3YcMqgeKGw3aZWSCVjWzDc7RP683Ymi",
        "https://ipfs.filebase.io/ipfs/QmXbfKfC5wRCtxtoLJHu7a1aTx6UmzYQboQAGTB3hsnUhm",
        "https://ipfs.filebase.io/ipfs/QmWZKf1yN3sojuPTHJedBwAxCdGyZFzXCcnApqvwwzjF7U",
        "https://ipfs.filebase.io/ipfs/QmTfs37s7rKyYoZkKQ2aoTDeXgfGAbVW6YWCY6D5A7FBd1",
        "https://ipfs.filebase.io/ipfs/QmWqy5goJggYv9CYu8nP6972RGdT3ciNw1YtKycB2szocA",
        "https://ipfs.filebase.io/ipfs/QmdiyUk4inJEM5dDU55oorr2kHaVf9Z64GvRaSmDZeeMup"
    ];

    /*
     * @dev Constructor to initialize the contract with CP token, name, symbol, and drop address.
     * @param _token Address of the CP token contract.
     * @param name Name of the ERC721 token.
     * @param symbol Symbol of the ERC721 token.
     * @param _drop Address of the drop contract.
     */
    constructor(
        address _token,
        string memory name,
        string memory symbol,
        address _drop
    ) ERC721(name, symbol) {
        CPtoken = ICPToken(_token);
        drop = _drop;
        levelToPoint[1] = 50;
        levelToPoint[2] = 250;
        levelToPoint[3] = 1000;
        levelToPoint[4] = 5000;
        levelToPoint[5] = 25000;
        levelToPoint[6] = 100000;
        levelToPoint[7] = 500000;
        levelToPoint[8] = 2500000;
        levelToPoint[9] = 5000000;
        levelToPoint[10] = 20000000;
        levelToPoint[11] = 50000000;
    }

    /*
     * @dev Function to mint a MembershipNFT.
     * @param minter Address of the account minting the NFT.
     */
    function mintDrop(
        address minter
    ) external virtual nonReentrant _onlyAllowedDrop(msg.sender) {
        require(balanceOf(minter) == 0, "MembershipNFT: Already a membership");

        _tokenIdCounter += 1;
        require(
            _tokenIdCounter <= _maxSupply,
            "MembershipNFT: Exceed max supply"
        );
        _safeMint(minter, _tokenIdCounter);
        tokenIdToLevel[_tokenIdCounter] = 0;
    }

    /*
     * @dev Function to set the maximum supply of MembershipNFT.
     * @param newMaxSupply New maximum supply value.
     */
    function setMaxSupply(uint256 newMaxSupply) external _onlyOwnerOrSelf {
        _maxSupply = newMaxSupply;
        emit MaxSupplyUpdated(newMaxSupply);
    }

    /*
     * @dev Function to update public drop data on MembershipDrop.
     * @param membershipImpl Address of the membership drop implementation contract.
     * @param publicDrop Data for the public drop.
     */
    function updatePublicDrop(
        address membershipImpl,
        PublicDrop calldata publicDrop
    ) external virtual _onlyOwnerOrSelf _onlyAllowedDrop(membershipImpl) {
        // Update the public drop data on MembershipDrop.
        IMembershipDrop(membershipImpl).updatePublicDrop(publicDrop);
    }

    /*
     * @dev Function to configure maxsupply and drop of the contract.
     */
    function multiConfigure(
        MultiConfigureStruct calldata config
    ) external onlyOwner {
        if (config.maxSupply > 0) {
            this.setMaxSupply(config.maxSupply);
        }
        if (
            _cast(config.publicDrop.startTime != 0) |
                _cast(config.publicDrop.endTime != 0) ==
            1
        ) {
            this.updatePublicDrop(config.membershipDropImpl, config.publicDrop);
        }
    }

    /*
     * @dev Function to update the level of a MembershipNFT.
     * @param _tokenId ID of the token to update.
     * @param _level New level for the token.
     */
    function updateLevel(
        uint256 _tokenId,
        uint256 _level
    ) external nonReentrant {
        require(_level > 0 && _level < 12, "MembershipNFT: Invalid level");
        require(
            msg.sender == ownerOf(_tokenId),
            "MembershipNFT: You are not owner of NFT"
        );

        uint256 currentLevel = tokenIdToLevel[_tokenId];
        require(currentLevel < _level, "Can not update to lower level");
        uint256 totalNeed = 0;

        for (uint256 i = currentLevel; i < _level; i++) {
            totalNeed += levelToPoint[i + 1];
        }

        uint256 CPBalance = CPtoken.balanceOf(msg.sender);
        totalNeed = totalNeed * 1e18;

        if (CPBalance < totalNeed) revert NotEnoughCP();

        CPtoken.burn(msg.sender, totalNeed);

        tokenIdToLevel[_tokenId] = _level;
        emit LevelUpdated(msg.sender, _tokenId, _level, totalNeed);
    }

    function setLevelURI(string[12] memory newLevelURI) external onlyOwner {
        levelURI = newLevelURI;
    }

    function setCPToken(address newCPToken) external onlyOwner {
        require(
            newCPToken != address(0),
            "MembershipNFT: CP token cannot be zero address"
        );
        CPtoken = ICPToken(newCPToken);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) internal virtual override {
        require(
            from == address(0),
            "MembershipNFT: Can not transfer membership NFT"
        );
        super._beforeTokenTransfer(from, to, tokenId, 1);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        _requireMinted(tokenId);
        string memory _tokenURI = levelURI[tokenIdToLevel[tokenId]];
        return _tokenURI;
    }

    function getLevelURIs() public view returns (string[12] memory) {
        return levelURI;
    }

    function getMintStats(
        address minter
    )
        external
        view
        returns (
            uint256 minterNumMinted,
            uint256 currentTotalSupply,
            uint256 maxSupply
        )
    {
        minterNumMinted = balanceOf(minter);
        currentTotalSupply = _tokenIdCounter;
        maxSupply = _maxSupply;
    }

    modifier _onlyAllowedDrop(address _drop) {
        if (drop != _drop) {
            revert OnlyAllowedDrop();
        }
        _;
    }

    modifier _onlyOwnerOrSelf() {
        if (
            _cast(msg.sender == owner()) | _cast(msg.sender == address(this)) ==
            0
        ) {
            revert OnlyOwner();
        }
        _;
    }

    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }
}
