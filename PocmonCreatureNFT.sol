// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "./base/mixins/TreasuryNode.sol";
import "./base/mixins/roles/MarketAdminRole.sol";
import "./base/mixins/roles/MarketOperatorRole.sol";
import "./base/mixins/HasSecondarySaleFees.sol";
import "./base/mixins/NFTCore.sol";
import "./base/mixins/NFT721Market.sol";
import "./base/mixins/NFT721Creator.sol";
import "./base/mixins/NFT721Metadata.sol";
import "./base/mixins/AccountMigration.sol";

abstract contract NFT721CreatureMint is Initializable, AccountMigration, ERC721Upgradeable, NFT721Creator, NFT721Market, NFT721Metadata {
  using AddressLibrary for address;

  uint256 private nextTokenId;
  mapping (uint256=>uint256) public classIds;

  enum MintRequirementsChoice {
    Everybody,
    Limited,
    OnlyOperator,
    Nobody
  }

  MintRequirementsChoice public mintRequirement;

  event Minted(
    address indexed creator,
    uint256 indexed tokenId,
    string indexed indexedTokenIPFSPath,
    string tokenIPFSPath
  );


  function getClassId(uint256 tokenId) public view returns (uint256) {
      return classIds[tokenId];
  }

  /**
   * @notice Gets the tokenId of the next NFT minted.
   */
  function getNextTokenId() public view returns (uint256) {
    return nextTokenId;
  }

  /**
   * @dev Called once after the initial deployment to set the initial tokenId.
   */
  function _initializeNFT721Mint(MintRequirementsChoice _mintRequirement) internal initializer {
    // Use ID 1 for the first NFT tokenId
    mintRequirement = _mintRequirement;
    nextTokenId = 1;
  }


  function setMintRequirements(MintRequirementsChoice _mintRequirement) public onlyWhitelistOperator {
    require(_mintRequirement >= MintRequirementsChoice.Everybody && _mintRequirement <= MintRequirementsChoice.Nobody,
            "NFT721Mint: Incorrect mint requirements");
    mintRequirement = _mintRequirement;
  }


  /**
   * @notice Minting with permission check
   */
  function mint(string memory tokenIPFSPath, uint256 classId) public returns (uint256 tokenId) {
    if(mintRequirement == MintRequirementsChoice.Limited) {
        require(isWhitelistedCreator(msg.sender) || _isMinterOperator(msg.sender),
                "NFT721Mint: Only operator or whitelisted sender could mint");
    } else if(mintRequirement == MintRequirementsChoice.OnlyOperator) {
        require(_isMinterOperator(msg.sender), "NFT721Mint: Only operator can mint");
    }
    require(mintRequirement != MintRequirementsChoice.Nobody, "NFT721Mint: Minting is not permitted");
    tokenId = _mint(tokenIPFSPath);
    classIds[tokenId] = classId;
  }

  function _mint(address to, string memory tokenIPFSPath) internal returns (uint256 tokenId) {
    require(mintRequirement != MintRequirementsChoice.Nobody, "NFT721Mint: Minting is not permitted");
    tokenId = nextTokenId++;
    _mint(to, tokenId);
    _updateTokenCreator(tokenId, payable(to));
    _setTokenIPFSPath(tokenId, tokenIPFSPath);
    emit Minted(to, tokenId, tokenIPFSPath, tokenIPFSPath);
  }


  function _mint(string memory tokenIPFSPath) internal returns (uint256 tokenId) {
    tokenId = _mint(msg.sender, tokenIPFSPath);
  }
  
  function mintAndApproveMarket(string memory tokenIPFSPath, uint256 classId) public returns (uint256 tokenId) {
    tokenId = mint(tokenIPFSPath, classId);
    setApprovalForAll(getNFTMarket(), true);
  }

  /**
   * @dev Explicit override to address compile errors.
   */
  function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, NFT721Creator, NFT721Metadata) {
    super._burn(tokenId);
  }

  uint256[1000] private ______gap;
}

contract PocmonCreatureNFT is
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
    NFT721CreatureMint
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
        NFT721CreatureMint._initializeNFT721Mint(mintRequirements);
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
    override(ERC721Upgradeable, NFT721Creator, NFT721Metadata, NFT721CreatureMint)
    {
        super._burn(tokenId);
    }

}
