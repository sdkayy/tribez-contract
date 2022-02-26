// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;
 
import "./ERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";

error MintedOut();
error NotEnoughEther();
contract MetaMythics is ERC721, Ownable 
{
    using Strings for uint256;

    uint constant public mintPrice = 0.04 ether;
    uint constant public maxMints = 5555;
    uint constant public reserveCount = 55;
    uint constant public maxMintsPerTX = 4;
    uint256 public mintSupply = 0;
    bool public buyingActive = false;
    bool public mintingActive = false;
    bool public isWhitelistActive = true;
    address public mythicReserve;

    mapping (address => bool) whiteList;

    string baseURI;
    string constant private jsonAppend = ".json";

    constructor(string memory _baseURI, address _mythicReserve) ERC721("Meta Mythics", "MYTHS") {
        baseURI = _baseURI;
        mythicReserve = _mythicReserve;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, id.toString()));
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function isWhiteListed(address addr) external view returns (bool) {
        return whiteList[addr];
    }

    // Mint
    function mint(uint256 mintAmount) public payable {
        if (mintSupply + mintAmount > maxMints) revert MintedOut();
        // if (msg.value < mintPrice * mintAmount) revert NotEnoughEther();

        unchecked {
            _bulkMint(msg.sender, mintSupply, mintAmount);
            mintSupply += mintAmount;
        }
    }

    // Mints all reserved mints
    function mintReserves() external onlyOwner {
        unchecked {
            _bulkMint(msg.sender, mintSupply, reserveCount);
            mintSupply += reserveCount;
        }
    }

    // Bulk mint functin for ERC721, thanks to deltadevelopers llamaverse contract
    function _bulkMint(
        address to,
        uint256 id,
        uint256 count
    ) internal {
        unchecked {
            balanceOf[to] += count;
        }

        for (uint256 i = id; i < id + count; i++) {
            ownerOf[i] = to;
            emit Transfer(address(0), to, i);
        }
    }

    // OWNER ONLY
    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
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

    /* @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC721, Ownable)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == 0x7f5828d0; // ERC165 Interface ID for ERC173
    }
}