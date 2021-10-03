// SPDX-License-Identifier: MIT OR Apache-2.0
pragma abicoder v2;
pragma solidity ^0.7.0;

import "./base/NFT721.sol";
import "./base/NFT1155.sol";


contract PocmonNFT is NFT721 {
    function getVersion() public pure returns (uint256) {
        return 1;
    }
}

contract PocmonNFTs is NFT1155 {
    function getVersion() public pure returns (uint256) {
        return 1;
    }
}

