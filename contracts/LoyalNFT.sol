// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "hardhat/console.sol";

contract LoyalNFT is
    ERC721AUpgradeable,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    IERC20Metadata token;

    uint256 public constant MAX_SUPPLY = 14000;
    uint256 private constant MAX_BUY = 11000;
    uint256 private constant RANGE_CHANGE_PRICE = 200;
    uint256 private constant basePrice = 1000;
    address private devAddress;
    address public superAdmin;

    uint256 public totalSold;
    uint256 totalDropTimes;
    string tokenBaseURI;

    struct Voucher {
        uint256 startTime;
        uint256 endTime;
        uint256 discountPercent;
    }
    Voucher public voucher;

    event Buyed(address buyer, uint256 price);
    event Withdraw(address owner, uint256 amount);
    event PriceUpdated(uint256 newPrice);

    error LoyalNFT__ExceedBuyQuantity(uint256 quantity);
    error LoyalNFT__ExceedLimitBuy();

    // We will increase price each 200 NFT sold starting from 1000th NFT
    // So mapping range price 1000 -1199 => 1000$
    //                     1200 -1399 => 1010$
    //                     1400 -1599 => 1020$
    //                     ....
    mapping(uint256 => uint256) rangePriceToPrice; // (totalSold) /200 => price
    mapping(address => bool) public whitelist;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _token,
        string memory _initBaseURI,
        address _devAddress,
        uint256[] memory prices,
        string memory name,
        string memory symbol,
        address _administratorAddress
    ) public initializerERC721A initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __ERC721A_init(name, symbol);
        token = IERC20Metadata(_token);
        tokenBaseURI = _initBaseURI;
        devAddress = _devAddress;
        for (uint256 i = 0; i < prices.length; i++) {
            rangePriceToPrice[i + 5] = prices[i];
        }
        superAdmin = _administratorAddress;
    }

    /**
     * @notice Function to buy NFT with quantity, the quantity should not greater than RANGE_CHANGE_PRICE. The price of NFT base on the NFT sold.
     * @param _quantity amount of NFT to buy.
     */
    function buy(uint256 _quantity) external nonReentrant {
        uint256 buyPrice;

        if (_quantity > RANGE_CHANGE_PRICE) {
            revert LoyalNFT__ExceedBuyQuantity(_quantity);
        }

        if (totalSold + _quantity > MAX_BUY) {
            revert LoyalNFT__ExceedLimitBuy();
        }

        if (totalSold < 1000) {
            buyPrice = basePrice;
        } else {
            require(
                _quantity <=
                    RANGE_CHANGE_PRICE - (totalSold % RANGE_CHANGE_PRICE),
                "Exceed buy for current price"
            );
            buyPrice = _calculatePrice();
        }

        uint256 discountPercent = 0;
        if (
            block.timestamp >= voucher.startTime &&
            block.timestamp <= voucher.endTime
        ) {
            discountPercent = voucher.discountPercent;
        }
        buyPrice = buyPrice - (buyPrice * discountPercent) / 100;

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

    /**
     * @notice Function to drop NFT for dev team. Each 100 NFT sold will drop 10 NFT for dev members.
     */
    function dropNFTForTeam() external onlyOwner {
        uint256 numberDropCount = totalSold / 100 - totalDropTimes;

        if (numberDropCount <= 0) {
            revert();
        } else {
            mint(devAddress, numberDropCount * 10);
            totalDropTimes += numberDropCount;
        }
    }

    /**
     * @notice Function to withdraw the token for the owner
     */
    function withdraw() external onlySuperAdmin {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");

        bool success = token.transfer(msg.sender, balance);
        require(success, "Transfer failed");
        emit Withdraw(msg.sender, balance);
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
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

    /**
     * @notice Function to set new base URI only call by owner.
     */
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

    /**
     * @notice Function to mint amount of NFT for an account
     */
    function mint(address account, uint256 quantity) private {
        require(
            _totalMinted() + quantity <= MAX_SUPPLY,
            "Exceed mint quantity"
        );
        _safeMint(account, quantity);
    }

    /**
     * @notice Function to calculate the price of NFT.
     */
    function _calculatePrice() private view returns (uint256) {
        uint256 sellPrice = rangePriceToPrice[totalSold / RANGE_CHANGE_PRICE];
        require(sellPrice > 0, "Invalid price");
        return sellPrice;
    }

    function getNumberDropableNFT() public view returns (uint256) {
        return (totalSold / 100 - totalDropTimes) * 10;
    }
    /**
     * @notice Function to get current price of NFT.
     */
    function getCurrentPrice() public view returns (uint256) {
        if (totalSold < 1000) {
            return basePrice;
        } else {
            return rangePriceToPrice[totalSold / RANGE_CHANGE_PRICE];
        }
    }

    function setVoucher(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _percent
    ) external onlyOwner {
        require(_startTime < _endTime, "Invalid time");
        require(_percent > 0 && _percent < 100, "Invalid percent");

        voucher.startTime = _startTime;
        voucher.endTime = _endTime;
        voucher.discountPercent = _percent;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) internal virtual override {
        require(
            whitelist[from] == true ||
                whitelist[to] == true ||
                from == address(0),
            "Transfer NFT failed"
        );
        super._beforeTokenTransfers(from, to, tokenId, 1);
    }
    /**
     * @notice Add to whitelist
     */
    function addToWhitelist(
        address[] calldata toAddAddresses
    ) external onlyOwner {
        for (uint i = 0; i < toAddAddresses.length; i++) {
            whitelist[toAddAddresses[i]] = true;
        }
    }

    /**
     * @notice Remove from whitelist
     */
    function removeFromWhitelist(
        address[] calldata toRemoveAddresses
    ) external onlyOwner {
        for (uint i = 0; i < toRemoveAddresses.length; i++) {
            delete whitelist[toRemoveAddresses[i]];
        }
    }

    function changeOwner(address newOwner) external onlySuperAdmin {
        _transferOwnership(newOwner);
    }

    modifier onlySuperAdmin() {
        require(msg.sender == superAdmin, "Not super admin address");
        _;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
