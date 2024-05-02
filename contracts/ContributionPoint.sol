// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ContributionPoint is ERC20, Ownable, EIP712 {
    struct MintRequest {
        address requester;
        uint256 amount;
        uint256 deadline;
        uint256 nonce;
    }

    event Minted(address account, uint256 amount);
    event Burned(address account, uint256 amount);

    bytes32 private _TYPEHASH;

    mapping(address => bool) public whitelist;
    mapping(bytes => bool) public signaturesUsed;

    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) EIP712("CP", "1") {
        _TYPEHASH = keccak256(
            "params(address _requester,uint256 _amount,uint256 _deadline,uint256 _nonce)"
        );
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

    function mint(
        bytes calldata _signature,
        MintRequest calldata _req
    ) external onlyWhitelist(getAddressWithSignature(_signature, _req)) {
        require(!signaturesUsed[_signature], "Signature already used");
        signaturesUsed[_signature] = true;

        require(block.timestamp < _req.deadline, "Signature is  expired");
        _mint(_req.requester, _req.amount * 1e18);
        emit Minted(_req.requester, _req.amount * 1e18);
    }

    function burn(
        address _account,
        uint256 _amount
    ) external onlyWhitelist(msg.sender) {
        _burn(_account, _amount);
        emit Burned(_account, _amount);
    }

    function transfer(address, uint256) public virtual override returns (bool) {
        revert();
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public virtual override returns (bool) {
        revert();
    }

    function getAddressWithSignature(
        bytes calldata signature,
        MintRequest calldata req
    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _TYPEHASH,
                    req.requester,
                    req.amount,
                    req.deadline,
                    req.nonce
                )
            )
        );

        address signer = ECDSA.recover(digest, signature);

        return signer;
    }

    modifier onlyWhitelist(address signer) {
        require(whitelist[signer] == true, "Not in whitelist");
        _;
    }
}
