// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract HERGT is Ownable, ERC721A {
  
  string public _baseTokenURI;
  bool public _isSaleActive = false;
  uint256 public _maxSupply = 50;
  constructor(
    string memory name,
    string memory symbol,
    string memory baseTokenURI
  )ERC721A(name, symbol) {
    _baseTokenURI = baseTokenURI;
  }

  function setSaleActive(bool isSaleActive) external onlyOwner {
    _isSaleActive = isSaleActive;
  }

  function mint(address to, uint256 quantity) onlyOwner external {
    require(totalSupply() + quantity <= _maxSupply, "ERC721: max supply reached");
    _safeMint(to, quantity);
  }
  /**
   * @dev Mint a batch of tokens
   * @param tos List of addresses to mint to
   * @param quantity List of quantities to mint
   */
  function batchMint(address[] calldata tos, uint256[] calldata quantity) onlyOwner external {
    require(tos.length == quantity.length, "ERC721: tos and quantity length mismatch");
    require(totalSupply() + _sum(quantity) <= _maxSupply, "ERC721: max supply reached");
    for(uint256 i = 0; i < tos.length; i++) {
      _safeMint(tos[i], quantity[i]);
    }
  }
  // override transfer
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
    ) public payable virtual override {
    require(_isSaleActive, "ERC721: sale is not active");
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual override {
      require(_isSaleActive, "ERC721: sale is not active");
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable virtual override {
      require(_isSaleActive, "ERC721: sale is not active");
      super.safeTransferFrom(from, to, tokenId, _data);
  }

  function setDefaultURI(string memory defaultURI) external onlyOwner {
    _baseTokenURI = defaultURI;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(
            _exists(tokenId),
            "WeaponNft: URI query for nonexistent token"
        );
        return string(
            abi.encodePacked(
                _baseTokenURI,
                Strings.toString(tokenId),
                ".json"
            ));
  }

   function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
  }

  function _sum(uint256[] calldata quantity) internal pure returns (uint256) {
    uint256 sum = 0;
    for(uint256 i = 0; i < quantity.length; i++) {
      sum += quantity[i];
    }
    return sum;
  }
  /**
   * @dev Prevents accidental sending of ether
   */
  receive() external payable {
    revert();
  }

  /**
   * @dev Prevents accidental sending of ether
   */
  fallback() external payable {
    revert();
  }
}