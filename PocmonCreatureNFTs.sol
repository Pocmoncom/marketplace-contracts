// SPDX-License-Identifier: MIT OR Apache-2.0
pragma abicoder v2;
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/introspection/ERC165Upgradeable.sol";

import "./base/mixins/OZ/ERC1155Upgradeable.sol";
import "./base/mixins/TreasuryNode.sol";
import "./base/mixins/roles/MarketAdminRole.sol";
import "./base/mixins/roles/MarketOperatorRole.sol";
import "./base/mixins/HasSecondarySaleFees.sol";
import "./base/mixins/NFTCore.sol";
import "./base/mixins/NFT1155Market.sol";
import "./base/mixins/NFT1155Mint.sol";
import "./base/mixins/NFT1155Creator.sol";
import "./base/mixins/NFT1155Metadata.sol";
import "./base/mixins/AccountMigration.sol";

contract PocmonCreatureNFTs is
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
    using AddressLibrary for address;

    mapping (uint256=>uint256) public classIds;


    function getClassId(uint256 tokenId) public view returns (uint256) {
        return classIds[tokenId];
    }
    /**
     * @notice Called once to configure the contract after the initial deployment.
     * @dev This farms the initialize call out to inherited contracts as needed.
     */
    function initialize(
        address payable treasury,
        string memory name,
        string memory symbol,
        MintRequirementsChoice _mintRequirement
    ) public initializer {
        TreasuryNode._initializeTreasuryNode(treasury);

        ERC1155Upgradeable.__ERC1155_init(name, symbol, "ipfs://");
        HasSecondarySaleFees._initializeHasSecondarySaleFees();
        NFT1155Creator._initializeNFT1155Creator();
        NFT1155Mint._initializeNFT1155Mint(_mintRequirement);
    }

    /**
     * @notice Allows a Market admin to update NFT config variables.
     * @dev This must be called right after the initial call to `initialize`.
     */
    function adminUpdateConfig(address _nftMarket, string memory _baseURI) public onlyMarketAdmin {
        _updateNFTMarket(_nftMarket);
        _setURI(_baseURI);
    }

    function uri(uint256 tokenId) public view virtual override(ERC1155Upgradeable, NFT1155Mint, NFT1155Metadata) returns (string memory) {
        return NFT1155Metadata.uri(tokenId);
    }


    /**
     * @notice Minting with permission check
     */
    function mint(
        address to,
        string memory _tokenIPFSPath,
        uint256 classId,
        uint256 _amount
    ) public returns (uint256 tokenId) {
        if(mintRequirement == MintRequirementsChoice.Limited) {
            require(isWhitelistedCreator(msg.sender) || _isMinterOperator(msg.sender),
                    "NFT1155Mint: Only operator or whitelisted sender could mint");
        } else if(mintRequirement == MintRequirementsChoice.OnlyOperator) {
            require(_isMinterOperator(msg.sender), "NFT1155Mint: Only operator can mint");
        }
        tokenId = _mint(to, _tokenIPFSPath, _amount);
        classIds[tokenId] = classId;
    }
    
    /**
     * @notice Batch Minting with permission check
     */
    function mintBatch(
        address to,
        string[] memory _tokenIPFSPaths,
        uint256[] memory _classIds,
        uint256[] memory _amounts
    ) public returns (uint256[] memory tokenIds) {
        if(mintRequirement == MintRequirementsChoice.Limited) {
            require(isWhitelistedCreator(msg.sender) || _isMinterOperator(msg.sender),
                    "NFT1155Mint: Only operator or whitelisted sender could mint");
        } else if(mintRequirement == MintRequirementsChoice.OnlyOperator) {
            require(_isMinterOperator(msg.sender), "NFT1155Mint: Only operator can mint");
        }
        require(_classIds.length == _amounts.length,
                "classIds size should be equal to amounts size");
        tokenIds = super.mintBatch(to, _tokenIPFSPaths, _amounts);
        for(uint i=0; i < tokenIds.length; i++) {
            classIds[tokenIds[i]] = _classIds[i];
        }
    }

    /*
     * @notice Deny direct minting without classId
     */
    function mint(
        address to,
        string memory _tokenIPFSPath,
        uint256 _amount
    ) public override returns (uint256) {
        revert("Direct minting forbidden");
    }
    
    function mintBatch(
        address to,
        string[] memory _tokenIPFSPaths,
        uint256[] memory _amounts
    ) public override returns (uint256[] memory tokenIds) {
        revert("Direct minting forbidden");
    }

    function mint(
        address to,
        string memory _tokenIPFSPath,
        uint256 _amount,
        uint256 timestamp,
        bytes memory signature
    ) public override returns (uint256 tokenId) {
        revert("Direct minting forbidden");
    }

    function mintOnTransfer(
        string memory _tokenIPFSPath,
        uint256 _amount,
        address creator,
        bytes memory signature
    ) public override returns (uint256 tokenId) {
        revert("Direct minting forbidden");
    }

    function _burnBatch(address _account, uint256[] memory _tokenIds, uint256[] memory _amounts)
        internal
        override(ERC1155Upgradeable, NFT1155Creator, NFT1155Mint)
    {
        super._burnBatch(_account, _tokenIds, _amounts);
    }
    
    /**
     * @dev This is a no-op, just an explicit override to address compile errors due to inheritance.
     */
    function _burn(address _account, uint256 tokenId, uint256 _amount)
        internal
        override(ERC1155Upgradeable, NFT1155Creator, NFT1155Metadata, NFT1155Mint)
    {
        super._burn(_account, tokenId, _amount);
    }


}
