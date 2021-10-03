// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./NFTCore.sol";
import "./NFT1155Creator.sol";

/**
 * @notice A mixin to extend the OpenZeppelin metadata implementation.
 */
abstract contract NFT1155Metadata is NFT1155Creator {
    using StringsUpgradeable for uint256;

    /**
     * @dev Stores hashes minted by a creator to prevent duplicates.
     */
    mapping(address => mapping(string => bool)) private creatorToIPFSHashToMinted;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    event URI(string URI);
    /**
     * @notice Checks if the creator has already minted a given NFT.
     */
    function getHasCreatorMintedIPFSHash(address creator, string memory tokenIPFSPath) public view returns (bool) {
        return creatorToIPFSHashToMinted[creator][tokenIPFSPath];
    }

    function baseURI() public view returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(bytes(_tokenURIs[tokenId]).length > 0,
                "ERC1155Metadata: URI query for nonexistent token"); 
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        return string(abi.encodePacked(base, _tokenURI));
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev The IPFS path should be the CID + file.extension, e.g.
     * `QmfPsfGwLhiJrU8t9HpG4wuyjgPo9bk8go4aQqSu9Qg4h7/metadata.json`
     */
    function _setTokenIPFSPath(uint256 tokenId, string memory _tokenIPFSPath) internal {
        // 46 is the minimum length for an IPFS content hash, it may be longer if paths are used
        require(bytes(_tokenIPFSPath).length >= 46, "NFT1155Metadata: Invalid IPFS path");
        require(!creatorToIPFSHashToMinted[msg.sender][_tokenIPFSPath], "NFT1155Metadata: NFT was already minted");

        creatorToIPFSHashToMinted[msg.sender][_tokenIPFSPath] = true;
        _setTokenURI(tokenId, _tokenIPFSPath);
    }

    /**
     * @dev When a token is burned, remove record of it allowing that creator to re-mint the same NFT again in the future.
     */
    function _burn(address account, uint256 tokenId, uint256 amount) internal virtual override {
        super._burn(account, tokenId, amount);
        if (balanceOf(account, tokenId) == 0) {
            delete creatorToIPFSHashToMinted[account][uri(tokenId)];
        }
    }

    uint256[999] private ______gap;
}
