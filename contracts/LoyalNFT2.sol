// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "./interfaces/IERC20.sol";

contract LoyalNFT2 is ERC721A, Ownable, ReentrancyGuard {
    IERC20 token;

    uint256 public constant MAX_SUPPLY = 14000;
    uint256 private constant MAX_BUY = 11000;
    uint256 private basePrice = 1000;
    address private immutable devAddress =
        0xe42B1F6BE2DDb834615943F2b41242B172788E7E;

    uint256 public totalSold;
    uint256 totalDropTimes;
    string tokenBaseURI;

    event Buyed(address buyer, uint256 price);
    event Withdraw(address owner, uint256 amount);
    event PriceUpdated(uint256 newPrice);

    error LoyalNFT__ExceedBuyQuantity(uint256 quantity);
    error LoyalNFT__ExceedLimitBuy();

    mapping(uint256 => uint256) rangePriceToPrice; // (totalSold) /200 => price

    constructor(
        address _token,
        string memory _initBaseURI,
        uint256[] memory prices
    ) ERC721A("LoyalNFT", "LNFT") {
        token = IERC20(_token);
        tokenBaseURI = _initBaseURI;
        for (uint256 i = 0; i < prices.length; i++) {
            rangePriceToPrice[i + 5] = prices[i];
        }
    }

    function buy(uint256 _quantity) external nonReentrant {
        uint256 buyPrice;
        if (_quantity > 200) {
            revert LoyalNFT__ExceedBuyQuantity(_quantity);
        }
        if (totalSold < 1000) {
            buyPrice = basePrice;
        } else {
            require(
                _quantity <= 200 - (totalSold % 200),
                "Exceed buy for current price"
            );
            buyPrice = _caculatePrice(_quantity);
        }

        if (totalSold + _quantity > MAX_BUY) {
            revert LoyalNFT__ExceedLimitBuy();
        }
        require(
            token.transferFrom(
                msg.sender,
                address(this),
                _quantity * buyPrice * 10 ** token.decimals()
            ),
            "Transfer failed"
        );

        mint(msg.sender, _quantity);
        totalSold += _quantity;
        emit Buyed(msg.sender, buyPrice);
    }

    function dropNFTForTeam() external onlyOwner {
        uint256 numberDropCount = totalSold / 100 - totalDropTimes;

        if (numberDropCount <= 0) {
            revert();
        } else {
            mint(devAddress, numberDropCount * 10);
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

    function _caculatePrice(uint256 _quantity) private view returns (uint256) {
        uint256 sellPrice = rangePriceToPrice[
            (totalSold + _quantity - 1) / 200
        ];
        require(sellPrice > 0, "Invalid price");
        return sellPrice;
    }

    function getCurrentPrice() public view returns (uint256) {
        if (totalSold < 1000) {
            return basePrice;
        } else {
            return rangePriceToPrice[totalSold / 200];
        }
    }
}
