// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    }

    function createNFT(address _to, uint256 _tokenId) public {
        _mint(_to, _tokenId);
    }

    function transferNFT(address _to, uint256 _tokenId) public {
        safeTransferFrom(msg.sender, _to, _tokenId);
    }
}