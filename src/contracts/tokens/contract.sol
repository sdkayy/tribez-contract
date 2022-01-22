// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;
 
import "./nf-token-metadata.sol";
import "../ownership/ownable.sol";

contract MetaTribez is NFTokenMetadata, Ownable 
{
    address payable feeAddress;
    uint constant public mintPrice = 0.05555 ether;
    uint constant public maxMints = 5555;
    uint constant public maxMintsPerTX = 4;

    bool public buyingActive = false;
    bool public mintingActive = false;
    bool public isWhitelistActive = true;

    uint256 public currentIterator = 0;

    mapping (address => bool) whiteList;

    string private metaAddress = "https://api.metatribez.io/";
    string constant private jsonAppend = ".json";

    // Events
    event Minted(address sender, uint256 count);
    event LimitChanged(uint256 amount);

    constructor() {
        nftName = "MetaTribes";
        nftSymbol = "MT";
        feeAddress = payable(msg.sender);
    }

    function tokenURI(uint tokenID) external view returns (string memory) 
    {   
        require(tokenID <= currentIterator, "Token hasn't been minted yet.");

        bytes32 nft;
        bytes memory concat;
        nft = uintToBytes(tokenID);
        concat = abi.encodePacked(metaAddress, nft, jsonAppend);
        return string(concat);
    }

    function isWhiteListed(address addr) external view returns (bool) {
        return whiteList[addr];
    }

    // Mint
    function mint(uint8 _mintAmount) public payable {
        require(mintingActive, 'Mint is not open.');
        require(_mintAmount > 0, 'Must mint 1 or more tokens.');
        require(currentIterator + _mintAmount <= maxMints, 'Not enough NFTs left to succeed.');
        require(_mintAmount <= maxMintsPerTX, 'Cannot mint more than allowed per TX');
        require(msg.value >= mintPrice * _mintAmount, 'Amount is not correct');

        if(isWhitelistActive) {
            require(whiteList[msg.sender], 'You are not whitelisted');
        }

        for(uint i = 0; i < _mintAmount; i++) {
            currentIterator += 1;
            super._mint(msg.sender, currentIterator);
        }

        emit Minted(msg.sender, _mintAmount);
    }

    // OWNER ONLY
    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function updateURI(string calldata _URI) external onlyOwner {
        metaAddress = _URI;
    }
    
    function updateRecipient(address payable _newAddress) public onlyOwner {
        feeAddress = _newAddress;
    }

    // Toggle Minting
    function toggleMinting() public onlyOwner {
        mintingActive = !mintingActive;
    }

    // Toggle Whitelist
    function toggleWhitelist() public onlyOwner {
        isWhitelistActive = !isWhitelistActive;
    }

    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            whiteList[addresses[i]] = true;
        }
    }


    function removeFromWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            whiteList[addresses[i]] = false;
        }
    }

    // Utils
    function uintToBytes(uint v) private pure returns (bytes32 ret) {
        if (v == 0) 
        {
            ret = '0';
        }
        else 
        {
            while (v > 0) 
            {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }

        return ret;
    }
}