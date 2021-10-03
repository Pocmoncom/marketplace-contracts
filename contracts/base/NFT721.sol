// SPDX-License-Identifier: MIT OR Apache-2.0

pragma abicoder v2;
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "./mixins/TreasuryNode.sol";
import "./mixins/roles/MarketAdminRole.sol";
import "./mixins/roles/MarketOperatorRole.sol";
import "./mixins/HasSecondarySaleFees.sol";
import "./mixins/NFTCore.sol";
import "./mixins/NFT721Market.sol";
import "./mixins/NFT721Creator.sol";
import "./mixins/NFT721Metadata.sol";
import "./mixins/NFT721Mint.sol";
import "./mixins/AccountMigration.sol";

/**
 * @title Market NFTs implemented using the ERC-721 standard.
 * @dev This top level file holds no data directly to ease future upgrades.
 */
contract NFT721 is
    TreasuryNode,
    MarketAdminRole,
    MarketOperatorRole,
    AccountMigration,
    ERC165Upgradeable,
    HasSecondarySaleFees,
    ERC721Upgradeable,
    NFTCore,
    NFT721Creator,
    NFT721Market,
    NFT721Metadata,
    NFT721Mint
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

        ERC721Upgradeable.__ERC721_init(name, symbol);
        HasSecondarySaleFees._initializeHasSecondarySaleFees();
        NFT721Creator._initializeNFT721Creator();
        NFT721Mint._initializeNFT721Mint(mintRequirements);
    }

    /**
     * @notice Allows a Market admin to update NFT config variables.
     * @dev This must be called right after the initial call to `initialize`.
     */
    function adminUpdateConfig(address _nftMarket, string memory _baseURI) public onlyMarketAdmin {
        _updateNFTMarket(_nftMarket);
        _updateBaseURI(_baseURI);
    }

    /**
     * @dev This is a no-op, just an explicit override to address compile errors due to inheritance.
     */
    function _burn(uint256 tokenId)
    internal
    virtual
    override(ERC721Upgradeable, NFT721Creator, NFT721Metadata, NFT721Mint)
    {
        super._burn(tokenId);
    }
}
