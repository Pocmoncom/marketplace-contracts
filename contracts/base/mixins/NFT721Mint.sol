// SPDX-License-Identifier: MIT OR Apache-2.0
pragma abicoder v2;
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./NFT721Creator.sol";
import "./NFT721Market.sol";
import "./NFT721Metadata.sol";
import "../libraries/AddressLibrary.sol";
import "./AccountMigration.sol";

/**
 * @notice Allows creators to mint NFTs.
 */
abstract contract NFT721Mint is Initializable, AccountMigration, ERC721Upgradeable, NFT721Creator, NFT721Market, NFT721Metadata {
  using AddressLibrary for address;

  uint256 private nextTokenId;

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
    nextTokenId = 1;
    mintRequirement = _mintRequirement;
  }


  function setMintRequirements(MintRequirementsChoice _mintRequirement) public onlyWhitelistOperator {
    require(_mintRequirement >= MintRequirementsChoice.Everybody && _mintRequirement <= MintRequirementsChoice.Nobody,
            "NFT721Mint: Incorrect mint requirements");
    mintRequirement = _mintRequirement;
  }
  /**
   *
   * @notice Allows an operator to mint and transfer an NFT.
   */
  function mintAndTransfer(address to, string memory _tokenIPFSPath) public returns (uint256 tokenId) {
    require(_isMinterOperator(msg.sender),
            "NFT721Mint: Only operator able to mint and transfer");
    tokenId = _mint(msg.sender, _tokenIPFSPath);
    _safeTransfer(msg.sender, to, tokenId, "");
  }
  
  /**
   *
   * @notice Allows an operator to mints and transfer NFTs.
   */
  function mintBatchAndTransfer(address[] memory to, string[] memory _tokenIPFSPaths) public returns (uint256[] memory tokenIds) {
    require(to.length == _tokenIPFSPaths.length,
            "NFT721Mint: to && tokenIPFSPaths should be the same size");

    tokenIds = new uint256[](to.length);
    for(uint i; i < to.length; i++) {
        tokenIds[i]=mintAndTransfer(to[i], _tokenIPFSPaths[i]);
    }
    return tokenIds;
  }

  /**
   * @notice Allows a buyer to mint on transfer an NFT.
   */
  function mintOnTransfer(string memory _tokenIPFSPath, address creator, bytes memory signature) public returns (uint256 tokenId) {
    require(mintRequirement == MintRequirementsChoice.Everybody,
            "NFT721Mint: Signed minting only for everybody mode");

    bytes memory data = abi.encodePacked(
        "Creator ",
        super._toAsciiString(creator),
        " authorized the market to mint ",
        _tokenIPFSPath,
        " on transfer"
    );
    bytes32 hash = super._toEthSignedMessage(data);
    address signer = ECDSA.recover(hash, signature);
    require(signer == creator, "NFT721Mint: Signer is not creator");
    tokenId = _mint(creator, _tokenIPFSPath);
    _safeTransfer(creator, msg.sender, tokenId, "");
  }

  /**
   * @notice Allows a creator to mint an NFT.
   */
  function mint(string memory _tokenIPFSPath, uint256 timestamp, bytes memory signature) public returns (uint256 tokenId) {
    require(mintRequirement == MintRequirementsChoice.Limited || mintRequirement == MintRequirementsChoice.OnlyOperator,
            "NFT721Mint: Signed minting only in limited or only operator mode");
    require(timestamp >= block.timestamp,
            "NFT721Mint: timestamp should be in future");

    bytes memory data = abi.encodePacked(
        "I authorized ",
        super._toAsciiString(msg.sender),
        " to mint ", 
        _tokenIPFSPath,
        " on ",
        super._toAsciiString(address(this)),
        " but not after ",
        Strings.toString(timestamp)
    );
    bytes32 hash = super._toEthSignedMessage(data);
    address signer = ECDSA.recover(hash, signature);
    require(_isMinterOperator(signer),
            "NFT721Mint: Signature must be from an operator"
           );
    tokenId = _mint(_tokenIPFSPath);
  }

  /**
   * @notice Minting with permission check
   */
  function mint(string memory tokenIPFSPath) public returns (uint256 tokenId) {
    if(mintRequirement == MintRequirementsChoice.Limited) {
        require(isWhitelistedCreator(msg.sender) || _isMinterOperator(msg.sender),
                "NFT721Mint: Only operator or whitelisted sender could mint");
    } else if(mintRequirement == MintRequirementsChoice.OnlyOperator) {
        require(_isMinterOperator(msg.sender), "NFT721Mint: Only operator can mint");
    }
    tokenId = _mint(tokenIPFSPath);
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

  /**
   * @notice Allows a creator to mint an NFT and set approval for the Market marketplace.
   * This can be used by creators the first time they mint an NFT to save having to issue a separate
   * approval transaction before starting an auction.
   */
  function mintAndApproveMarket(string memory tokenIPFSPath, uint256 timestamp, bytes memory signature) public returns (uint256 tokenId) {
    tokenId = mint(tokenIPFSPath, timestamp, signature);
    setApprovalForAll(getNFTMarket(), true);
  }
  
  /**
   * @notice Allows a creator to mint an NFT and set approval for the Market marketplace.
   * This can be used by creators the first time they mint an NFT to save having to issue a separate
   * approval transaction before starting an auction.
   */
  function mintAndApproveMarket(string memory tokenIPFSPath) public returns (uint256 tokenId) {
    tokenId = mint(tokenIPFSPath);
    setApprovalForAll(getNFTMarket(), true);
  }

  /**
   * @notice Allows a creator to mint an NFT and have creator revenue/royalties sent to an alternate address.
   */
  function mintWithCreatorPaymentAddress(string memory tokenIPFSPath, address payable tokenCreatorPaymentAddress)
    public
    returns (uint256 tokenId)
  {
    require(tokenCreatorPaymentAddress != address(0), "NFT721Mint: tokenCreatorPaymentAddress is required");
    tokenId = mint(tokenIPFSPath);
    _setTokenCreatorPaymentAddress(tokenId, tokenCreatorPaymentAddress);
  }

  /**
   * @notice Allows a creator to mint an NFT and have creator revenue/royalties sent to an alternate address.
   * Also sets approval for the Market marketplace.  This can be used by creators the first time they mint an NFT to
   * save having to issue a separate approval transaction before starting an auction.
   */
  function mintWithCreatorPaymentAddressAndApproveMarket(
    string memory tokenIPFSPath,
    address payable tokenCreatorPaymentAddress
  ) public returns (uint256 tokenId) {
    tokenId = mintWithCreatorPaymentAddress(tokenIPFSPath, tokenCreatorPaymentAddress);
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
