// SPDX-License-Identifier: MIT OR Apache-2.0
pragma abicoder v2;
pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./OZ/ERC1155Upgradeable.sol";
import "./NFT1155Creator.sol";
import "./NFT1155Market.sol";
import "./NFT1155Metadata.sol";
import "../libraries/AddressLibrary.sol";
import "./AccountMigration.sol";

/**
 * @notice Allows creators to mint NFTs.
 */
abstract contract NFT1155Mint is Initializable, AccountMigration, ERC1155Upgradeable, NFT1155Creator, NFT1155Market, NFT1155Metadata {
    using AddressLibrary for address;

    // Mapping from token ID to account balances
    mapping (uint256 => uint256) private _tokenIdAmount;
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
        string tokenIPFSPath,
        uint256 amount
    );
    
    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return nextTokenId;
    }

    /**
    * @notice Gets the tokenId of the next NFT minted.
     */
    function getNextTokenId() public view returns (uint256) {
        return nextTokenId;
    }

    function uri(uint256 tokenId) public view virtual override(ERC1155Upgradeable, NFT1155Metadata) returns (string memory) {
        return NFT1155Metadata.uri(tokenId);
    }

    /**
     * @dev Called once after the initial deployment to set the initial tokenId.
     */
    function _initializeNFT1155Mint(MintRequirementsChoice _mintRequirement) internal initializer {
        // Use ID 1 for the first NFT tokenId
        nextTokenId = 1;
        mintRequirement = _mintRequirement;
    }

    function setMintRequirements(MintRequirementsChoice _mintRequirement) public onlyWhitelistOperator {
        require(_mintRequirement >= MintRequirementsChoice.Everybody && _mintRequirement <= MintRequirementsChoice.Nobody,
                "NFT1155Mint: Incorrect mint requirements");
        mintRequirement = _mintRequirement;
    }

    /**
     * @notice Allows a creator to mint an NFT.
     */
    function mint(
        address _account,
        string memory _tokenIPFSPath,
        uint256 _amount,
        uint256 timestamp,
        bytes memory signature
    ) public virtual returns (uint256 tokenId) {
        require(mintRequirement == MintRequirementsChoice.Limited || mintRequirement == MintRequirementsChoice.OnlyOperator,
                "NFT1155Mint: Signed minting only in limited or only operator mode");
        require(timestamp >= block.timestamp,
                "NFT1155Mint: timestamp should be in future");

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
                "NFT1155Mint: Signature must be from an operator");
        tokenId = _mint(_account, _tokenIPFSPath, _amount);
    }

    /**
    * @dev mint single token with specified amount
    **/
    function mint(
        address to,
        string memory _tokenIPFSPath,
        uint256 _amount
    ) virtual public 
    returns (uint256 tokenId) {
        if(mintRequirement == MintRequirementsChoice.Limited) {
            require(isWhitelistedCreator(msg.sender) || _isMinterOperator(msg.sender),
                    "NFT1155Mint: Only operator or whitelisted sender could mint");
        } else if(mintRequirement == MintRequirementsChoice.OnlyOperator) {
            require(_isMinterOperator(msg.sender), "NFT1155Mint: Only operator can mint");
        }
        tokenId = _mint(to, _tokenIPFSPath, _amount);
    }


    /**
    *
    * @notice Allows a buyer to mint on transfer an NFT.
     */
    function mintOnTransfer(
        string memory _tokenIPFSPath,
        uint256 _amount,
        address creator,
        bytes memory signature
    ) public virtual returns (uint256 tokenId) {
        require(mintRequirement == MintRequirementsChoice.Everybody,
                "NFT1155Mint: Signed minting only for everybody mode");

        bytes memory data = abi.encodePacked(
            "Creator ",
            super._toAsciiString(creator),
            " authorized the market to mint ",
            _tokenIPFSPath,
            " on transfer"
        );
        bytes32 hash = super._toEthSignedMessage(data);
        address signer = ECDSA.recover(hash, signature);
        require(signer == creator, "NFT1155Mint: Signer is not creator");
        tokenId = _mint(msg.sender, creator, _tokenIPFSPath, _amount);
    }

    function _mint(
        address to,
        string memory _tokenIPFSPath,
        uint256 _amount
    ) internal 
    returns (uint256 tokenId) {
        require(mintRequirement != MintRequirementsChoice.Nobody, "NFT1155Mint: Minting is not permitted");
        tokenId = _mint(to, to, _tokenIPFSPath, _amount);
    }

    function _mint(
        address to,
        address creator,
        string memory _tokenIPFSPath,
        uint256 _amount
    ) internal 
    returns (uint256 tokenId) {
        require(mintRequirement != MintRequirementsChoice.Nobody, "NFT1155Mint: Minting is not permitted");
        tokenId = nextTokenId++;

        _mint(to, tokenId, _amount, "");
        emit Minted(creator, tokenId, _tokenIPFSPath, _tokenIPFSPath, _amount);
        _updateTokenCreator(tokenId, payable(creator));
        _setTokenIPFSPath(tokenId, _tokenIPFSPath);
        _tokenIdAmount[tokenId] = _amount;
    }

    function mintBatch(
        address to,
        string[] memory tokenIPFSPaths,
        uint256[] memory _amounts
    ) virtual public returns (uint256[] memory tokenIds) {
        if(mintRequirement == MintRequirementsChoice.Limited) {
            require(isWhitelistedCreator(msg.sender) || _isMinterOperator(msg.sender),
                    "NFT1155Mint: Only operator or whitelisted sender could mint");
        } else if(mintRequirement == MintRequirementsChoice.OnlyOperator) {
            require(_isMinterOperator(msg.sender), "NFT1155Mint: Only operator can mint");
        }
        require(mintRequirement != MintRequirementsChoice.Nobody, "NFT1155Mint: Minting is not permitted");
        require(tokenIPFSPaths.length == _amounts.length, "ipfs path length should be equal to amounts");

        tokenIds = new uint256[](tokenIPFSPaths.length);

        for(uint i=0; i < tokenIPFSPaths.length; i++) {
            tokenIds[i] = nextTokenId++;
        }

        _mintBatch(to, tokenIds, _amounts, "");

        for(uint i=0; i < tokenIds.length; i++) {
            _updateTokenCreator(tokenIds[i], payable(to));
            _setTokenIPFSPath(tokenIds[i], tokenIPFSPaths[i]);
            _tokenIdAmount[tokenIds[i]] = _amounts[i];
            emit Minted(to, tokenIds[i], tokenIPFSPaths[i], tokenIPFSPaths[i], _amounts[i]);
        }
    }

    /**
     * @notice Allows a creator to mint an NFT and set approval for the Market marketplace.
     * This can be used by creators the first time they mint an NFT to save having to issue a separate
     * approval transaction before starting an auction.
     */
    function mintAndApproveMarket(string memory tokenIPFSPath, uint256 _amount) public returns (uint256 tokenId) {
      tokenId = mint(msg.sender, tokenIPFSPath, _amount);
      setApprovalForAll(getNFTMarket(), true);
    }

    /**
     * @notice Allows a creator to mint an NFT and have creator revenue/royalties sent to an alternate address.
     */
    function mintWithCreatorPaymentAddress(string memory tokenIPFSPath, uint256 _amount, address payable tokenCreatorPaymentAddress)
      public
      returns (uint256 tokenId)
    {
      require(tokenCreatorPaymentAddress != address(0), "NFT1155Mint: tokenCreatorPaymentAddress is required");
      tokenId = mint(msg.sender, tokenIPFSPath, _amount);
      _setTokenCreatorPaymentAddress(tokenId, tokenCreatorPaymentAddress);
    }

    /**
     * @notice Allows a creator to mint an NFT and have creator revenue/royalties sent to an alternate address.
     * Also sets approval for the Market marketplace.  This can be used by creators the first time they mint an NFT to
     * save having to issue a separate approval transaction before starting an auction.
     */
    function mintWithCreatorPaymentAddressAndApproveMarket(
      string memory tokenIPFSPath,
      uint256 _amount,
      address payable tokenCreatorPaymentAddress
    ) public returns (uint256 tokenId) {
      tokenId = mintWithCreatorPaymentAddress(tokenIPFSPath, _amount, tokenCreatorPaymentAddress);
      setApprovalForAll(getNFTMarket(), true);
    }

    /**
     * @notice Allows an operator to mint and transfer an NFT.
     */
    function mintAndTransfer(
        address to,
        string memory _tokenIPFSPath,
        uint256 _amount
    ) public returns (uint256 tokenId) {
        require(_isMinterOperator(msg.sender),
                "NFT1155Mint: Only operator able to mint and transfer");
        tokenId = _mint(msg.sender, _tokenIPFSPath, _amount);
        safeTransferFrom(msg.sender, to, tokenId, _amount, "");
    }

    /**
     * @notice Allows an operator to mint and transfer an NFTs.
     */
    function mintAndTransferBatch(address[] memory to, string memory _tokenIPFSPath, uint256[] memory _amounts) public returns (uint256 tokenId) {
        require(_isMinterOperator(msg.sender),
                "NFT1155Mint: Only operator able to mint and transfer");
        require(to.length == _amounts.length,
                "NFT1155Mint: to && _amounts should be the same size");
        uint256 _amount = 0;
        for(uint i; i < to.length; i++) {
            require(_amounts[i] > 0, "NFT1155Mint: unexpected _amounts");
            _amount += _amounts[i];
        }

        tokenId = _mint(msg.sender, _tokenIPFSPath, _amount);
        for(uint i; i < to.length; i++) {
            safeTransferFrom(msg.sender, to[i], tokenId, _amounts[i], "");
        }
    }

    /**
     * @dev Explicit override to address compile errors.
     */
    function _burnBatch(
        address _account,
        uint256[] memory tokenIds,
        uint256[] memory _amounts
    ) internal virtual override(ERC1155Upgradeable, NFT1155Creator) {
        super._burnBatch(_account, tokenIds, _amounts);
    }

    /**
     * @dev Explicit override to address compile errors.
     */
    function _burn(
        address _account,
        uint256 tokenId,
        uint256 _amount
    ) internal virtual override(ERC1155Upgradeable, NFT1155Creator, NFT1155Metadata) {
        super._burn(_account, tokenId, _amount);
    }

    uint256[1000] private ______gap;
}
