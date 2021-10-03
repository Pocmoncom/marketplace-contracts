// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;
pragma abicoder v2; // solhint-disable-line

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./mixins/Constants.sol";

contract PercentSplit is Constants, Initializable, ReentrancyGuardUpgradeable, ERC165Upgradeable {
  using AddressUpgradeable for address payable;
  using AddressUpgradeable for address;

  struct Share {
    address payable recipient;
    uint256 shareInBasisPoints;
  }

  Share[] private _shares;

  event PercentSplitCreated(address indexed contractAddress);
  event PercentSplitShare(address indexed recipient, uint256 shareInBasisPoints);

  /**
   * @notice Called once to configure the contract after the initial deployment.
   */
  function initialize(Share[] memory shares) public initializer {
    require(shares.length >= 2, "Split: Too few recipients");
    require(shares.length <= 5, "Split: Too many recipients");
    uint256 total;
    for (uint256 i = 0; i < shares.length; i++) {
      total += shares[i].shareInBasisPoints;
      _shares.push(shares[i]);
      emit PercentSplitShare(shares[i].recipient, shares[i].shareInBasisPoints);
    }
    require(total == BASIS_POINTS, "Split: Total amount must equal 100%");
  }

  function getShares() public view returns (Share[] memory) {
    return _shares;
  }

  function getShareLength() public view returns (uint256) {
    return _shares.length;
  }

  function getShareRecipientByIndex(uint256 index) public view returns (address payable) {
    return _shares[index].recipient;
  }

  function getShareInBasisPointsByIndex(uint256 index) public view returns (uint256) {
    return _shares[index].shareInBasisPoints;
  }

  receive() external payable {
    uint256 shareLengthMinus1 = _shares.length - 1;
    uint256 totalSent;
    for (uint256 i = 0; i < shareLengthMinus1; i++) {
      uint256 amountToSend = (msg.value * _shares[i].shareInBasisPoints) / BASIS_POINTS;
      totalSent += amountToSend;
      _shares[i].recipient.sendValue(amountToSend);
    }
    _shares[shareLengthMinus1].recipient.sendValue(msg.value - totalSent);
  }

  function createSplit(Share[] memory shares) public returns (PercentSplit splitInstance) {
    bytes32 salt = keccak256(abi.encode(shares));
    address clone = Clones.predictDeterministicAddress(address(this), salt);
    splitInstance = PercentSplit(payable(clone));
    if (!clone.isContract()) {
      emit PercentSplitCreated(clone);
      Clones.cloneDeterministic(address(this), salt);
      splitInstance.initialize(shares);
    }
  }

  function predictSplitAddress(Share[] memory shares) public view returns (address) {
    bytes32 salt = keccak256(abi.encode(shares));
    return Clones.predictDeterministicAddress(address(this), salt);
  }

  // TODO: Add withdrawFromEscrow or a proxy method
}
