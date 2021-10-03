// SPDX-License-Identifier: MIT OR Apache-2.0
pragma abicoder v2;
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/introspection/ERC165Upgradeable.sol";

import "./mixins/OZ/ERC1155Upgradeable.sol";
import "./mixins/TreasuryNode.sol";
import "./mixins/roles/MarketAdminRole.sol";
import "./mixins/roles/MarketOperatorRole.sol";
import "./mixins/HasSecondarySaleFees.sol";
import "./mixins/NFTCore.sol";
import "./mixins/NFT1155Market.sol";
import "./mixins/NFT1155Metadata.sol";
import "./mixins/NFT1155Creator.sol";
import "./mixins/NFT1155Mint.sol";
import "./mixins/AccountMigration.sol";

/**
 * @title Market NFTs implemented using the ERC-1155 standard.
 * @dev This top level file holds no data directly to ease future upgrades.
 */
contract NFT1155 is
    TreasuryNode,
    MarketAdminRole,
    MarketOperatorRole,
    AccountMigration,
    ERC165Upgradeable,
    HasSecondarySaleFees,
    ERC1155Upgradeable,
    NFTCore,
    NFT1155Creator,
    NFT1155Market,
    NFT1155Metadata,
    NFT1155Mint
{
    /**
     * @notice Called once to configure the contract after the initial deployment.
     * @dev This farms the initialize call out to inherited contracts as needed.
     */
    function initialize(
        address payable treasury,
        string memory name,
        string memory symbol,
        MintRequirementsChoice mintRequirements
    ) public initializer {
        TreasuryNode._initializeTreasuryNode(treasury);

        ERC1155Upgradeable.__ERC1155_init(name, symbol, "ipfs://");
        HasSecondarySaleFees._initializeHasSecondarySaleFees();
        NFT1155Creator._initializeNFT1155Creator();
        NFT1155Mint._initializeNFT1155Mint(mintRequirements);
    }

    /**
     * @notice Allows a Market admin to update NFT config variables.
     * @dev This must be called right after the initial call to `initialize`.
     */
    function adminUpdateConfig(address _nftMarket, string memory _URI) public onlyMarketAdmin {
        _updateNFTMarket(_nftMarket);
        _setURI(_URI);
    }

    function uri(uint256 tokenId) public view virtual override(ERC1155Upgradeable, NFT1155Mint, NFT1155Metadata) returns (string memory) {
        return NFT1155Metadata.uri(tokenId);
    }

    /**
     * @dev This is a no-op, just an explicit override to address compile errors due to inheritance.
     */
    function _burnBatch(address _account, uint256[] memory _tokenIds, uint256[] memory _amounts)
    internal
    virtual
    override(ERC1155Upgradeable, NFT1155Creator, NFT1155Mint)
    {
        super._burnBatch(_account, _tokenIds, _amounts);
    }

    /**
     * @dev This is a no-op, just an explicit override to address compile errors due to inheritance.
     */
    function _burn(address _account, uint256 tokenId, uint256 _amount)
    internal
    virtual
    override(ERC1155Upgradeable, NFT1155Creator, NFT1155Metadata, NFT1155Mint)
    {
        super._burn(_account, tokenId, _amount);
    }
}

