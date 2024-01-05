// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "./interfaces/IERC20.sol";

contract LoyalNFT is ERC721A, Ownable, ReentrancyGuard {
    IERC20 token;

    uint256 public constant MAX_SUPPLY = 14000;
    uint256 private constant MAX_PRIVATE_BUY = 1400;
    uint256 private constant MAX_BUY = 11000;
    uint256 private price = 1000;
    address private immutable devAddress =
        0xe42B1F6BE2DDb834615943F2b41242B172788E7E;

    uint256 public totalSold;
    uint256 public totalSoldPublic;
    uint256 totalDropTimes;
    string tokenBaseURI;

    event Buyed(address buyer, uint256 price);
    event Withdraw(address owner, uint256 amount);
    event PriceUpdated(uint256 newPrice);

    constructor(
        address _token,
        string memory _initBaseURI
    ) ERC721A("LoyalNFT", "LNFT") {
        token = IERC20(_token);
        tokenBaseURI = _initBaseURI;
    }

    function buy() external nonReentrant {
        require(
            token.transferFrom(
                msg.sender,
                address(this),
                price * 10 ** token.decimals()
            ),
            "Transfer failed"
        );
        require(totalSold < MAX_BUY, "Exceed limit buy");

        mint(msg.sender, 1);
        totalSold++;
        emit Buyed(msg.sender, price);

        if (totalSold > MAX_PRIVATE_BUY) {
            totalSoldPublic++;
            checkUpDatePrice();
        }
    }

    function dropNFTForTeam() external onlyOwner {
        uint256 numberDropCount = totalSold / 400 - totalDropTimes;

        if (numberDropCount <= 0) {
            revert();
        } else {
            mint(devAddress, numberDropCount * 40);
            totalDropTimes += numberDropCount;
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");

        bool success = token.transfer(msg.sender, balance);
        require(success, "Transfer failed");
        emit Withdraw(msg.sender, balance);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();

        // Exit early if the baseURI is empty.
        if (bytes(baseURI).length == 0) {
            return "";
        }

        return baseURI;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        // Set the new base URI.
        tokenBaseURI = newBaseURI;
    }

    /**
     * @notice Returns the base URI for the contract, which ERC721A uses
     *         to return tokenURI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return tokenBaseURI;
    }

    function mint(address account, uint256 quantity) private {
        require(
            _totalMinted() + quantity <= MAX_SUPPLY,
            "Exceed mint quantity"
        );
        _safeMint(account, quantity);
    }

    function checkUpDatePrice() private {
        if (totalSoldPublic % 40 == 0) {
            price += 20;
            emit PriceUpdated(price);
        }
    }

    function getCurrentPrice() public view returns (uint256) {
        return price;
    }
}
