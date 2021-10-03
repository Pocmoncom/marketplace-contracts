// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "../libraries/AddressLibrary.sol";
import "../libraries/BytesLibrary.sol";

import "./OZ/ERC1155Upgradeable.sol";
import "./AccountMigration.sol";
import "./roles/MarketAdminRole.sol";

/**
 * @notice Allows each token to be associated with a creator.
 */
abstract contract NFT1155Creator is Initializable, AccountMigration, ERC1155Upgradeable {
  using SafeMathUpgradeable for uint256;
  using AddressLibrary for address;
  using BytesLibrary for bytes;

  mapping(address => bool) private creatorsPermittedToMint;

  mapping(uint256 => address payable) private tokenIdToCreator;

  /**
   * @dev Stores an optional alternate address to receive creator revenue and royalty payments.
   */
  mapping(uint256 => address payable) private tokenIdToCreatorPaymentAddress;

  event TokenCreatorUpdated(address indexed fromCreator, address indexed toCreator, uint256 indexed tokenId);
  event TokenCreatorPaymentAddressSet(
    address indexed fromPaymentAddress,
    address indexed toPaymentAddress,
    uint256 indexed tokenId
  );
  event NFTCreatorMigrated(uint256 indexed tokenId, address indexed originalAddress, address indexed newAddress);
  event NFTOwnerMigrated(uint256 indexed tokenId, address indexed originalAddress, address indexed newAddress);
  event PaymentAddressMigrated(
    uint256 indexed tokenId,
    address indexed originalAddress,
    address indexed newAddress,
    address originalPaymentAddress,
    address newPaymentAddress
  );

  /*
   * bytes4(keccak256('tokenCreator(uint256)')) == 0x40c1a064
   */
  bytes4 private constant _INTERFACE_TOKEN_CREATOR = 0x40c1a064;

  /*
   * bytes4(keccak256('getTokenCreatorPaymentAddress(uint256)')) == 0xec5f752e;
   */
  bytes4 private constant _INTERFACE_TOKEN_CREATOR_PAYMENT_ADDRESS = 0xec5f752e;

  /**
   * @dev Called once after the initial deployment to register the interface with ERC165.
   */
  function _initializeNFT1155Creator() internal initializer {
    _registerInterface(_INTERFACE_TOKEN_CREATOR);
  }

  /**
   * @notice Allows ERC165 interfaces which were not included originally to be registered.
   * @dev Currently this is the only new interface, but later other mixins can overload this function to do the same.
   */
  function registerInterfaces() public {
    _registerInterface(_INTERFACE_TOKEN_CREATOR_PAYMENT_ADDRESS);
  }

  /**
   * @notice Returns the creator's address for a given tokenId.
   */
  function tokenCreator(uint256 tokenId) public view returns (address payable) {
    return tokenIdToCreator[tokenId];
  }

  /**
   * @notice Returns the payment address for a given tokenId.
   * @dev If an alternate address was not defined, the creator is returned instead.
   */
  function getTokenCreatorPaymentAddress(uint256 tokenId)
    public
    view
    returns (address payable tokenCreatorPaymentAddress)
  {
    tokenCreatorPaymentAddress = tokenIdToCreatorPaymentAddress[tokenId];
    if (tokenCreatorPaymentAddress == address(0)) {
      tokenCreatorPaymentAddress = tokenIdToCreator[tokenId];
    }
  }

  function _updateTokenCreator(uint256 tokenId, address payable creator) internal {
    emit TokenCreatorUpdated(tokenIdToCreator[tokenId], creator, tokenId);

    tokenIdToCreator[tokenId] = creator;
  }

  /**
   * @dev Allow setting a different address to send payments to for both primary sale revenue
   * and secondary sales royalties.
   */
  function _setTokenCreatorPaymentAddress(uint256 tokenId, address payable tokenCreatorPaymentAddress) internal {
    emit TokenCreatorPaymentAddressSet(tokenIdToCreatorPaymentAddress[tokenId], tokenCreatorPaymentAddress, tokenId);
    tokenIdToCreatorPaymentAddress[tokenId] = tokenCreatorPaymentAddress;
  }

  /**
   * @notice Allows the creator to burn if they currently own the NFT.
   */
  function burn(uint256 tokenId, uint256 _amount) public {
    _burn(msg.sender, tokenId, _amount);
  }

  /**
   * @notice Allows the creator to burn if they currently own the NFT.
   */
  function burnBatch(uint256[] memory tokenIds, uint256[] memory _amounts) public {
    _burnBatch(msg.sender, tokenIds, _amounts);
  }

  /**
   * @notice Allows a split recipient and Market to work together in order to update the payment address
   * to a new account.
   * @param signature Message `I authorize Market to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   */
  function adminAccountMigrationForPaymentAddresses(
    uint256[] calldata paymentAddressTokenIds,
    address paymentAddressFactory,
    bytes memory paymentAddressCallData,
    uint256 addressLocationInCallData,
    address originalAddress,
    address payable newAddress,
    bytes calldata signature
  ) public onlyAuthorizedAccountMigration(originalAddress, newAddress, signature) {
    _adminAccountRecoveryForPaymentAddresses(
      paymentAddressTokenIds,
      paymentAddressFactory,
      paymentAddressCallData,
      addressLocationInCallData,
      originalAddress,
      newAddress
    );
  }

  /**
   * @dev Split into a second function to avoid stack too deep errors
   */
  function _adminAccountRecoveryForPaymentAddresses(
    uint256[] calldata paymentAddressTokenIds,
    address paymentAddressFactory,
    bytes memory paymentAddressCallData,
    uint256 addressLocationInCallData,
    address originalAddress,
    address payable newAddress
  ) private {
    // Call the factory and get the originalPaymentAddress
    address payable originalPaymentAddress = paymentAddressFactory.functionCallAndReturnAddress(paymentAddressCallData);

    // Confirm the original address and swap with the new address
    paymentAddressCallData.replaceAtIf(addressLocationInCallData, originalAddress, newAddress);

    // Call the factory and get the newPaymentAddress
    address payable newPaymentAddress = paymentAddressFactory.functionCallAndReturnAddress(paymentAddressCallData);

    // For each token, confirm the expected payment address and then update to the new one
    for (uint256 i = 0; i < paymentAddressTokenIds.length; i++) {
      uint256 tokenId = paymentAddressTokenIds[i];
      require(
        tokenIdToCreatorPaymentAddress[tokenId] == originalPaymentAddress,
        "NFT1155Creator: Payment address is not the expected value"
      );

      _setTokenCreatorPaymentAddress(tokenId, newPaymentAddress);
      emit PaymentAddressMigrated(tokenId, originalAddress, newAddress, originalPaymentAddress, newPaymentAddress);
    }
  }

  /**
   * @dev check if sender is whitelisted creator
   */
  function isWhitelistedCreator(address _creator) public view returns (bool) {
      return _isMinterOperator(_creator) || creatorsPermittedToMint[_creator];
  }

  /**
   * @dev permit address to mint nft
   */
  function grantMint(address _creator) public onlyWhitelistOperator {
      creatorsPermittedToMint[_creator] = true;
  }

  /**
   * @dev revoke address to mint nft
   */
  function revokeMint(address _creator) public onlyWhitelistOperator {
      creatorsPermittedToMint[_creator] = false;
  }

  /**
   * @dev Remove the creator record when burned.
   */
  function _burn(address account, uint256 tokenId, uint256 _amount) internal virtual override {
    delete tokenIdToCreator[tokenId];

    super._burn(account, tokenId, _amount);
  }

  /**
   * @dev Explicit override to address compile errors.
   */
  function _burnBatch(
    address _account,
    uint256[] memory _tokenIds,
    uint256[] memory _amounts
  ) internal virtual override(ERC1155Upgradeable) {
    for (uint i = 0; i < _tokenIds.length; i++) {
        uint256 _actualAmount = balanceOf(_account, _tokenIds[i]);
        if(_actualAmount > 0 && _actualAmount.sub(_amounts[i], "ERC1155: overflow") == 0) {
            delete tokenIdToCreator[_tokenIds[i]];
        }
    }

    super._burnBatch(_account, _tokenIds, _amounts);
  }

  /**
   * @dev fallback for checking (TODO: remove)
   **/
  function _exists(uint256) pure internal returns(bool) {
      return true;
  }


  uint256[999] private ______gap;
}
