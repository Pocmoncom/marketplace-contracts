// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "../../interfaces/ITreasury.sol";
import "../TreasuryNode.sol";

/**
 * @notice Allows a contract to leverage the operator role defined by the market treasury.
 */
abstract contract MarketOperatorRole is TreasuryNode {
  // This file uses 0 data slots (other than what's included via TreasuryNode)

  function _isMigraterOperator(address account) internal view returns (bool) {
    return ITreasury(getTreasury()).isMigraterOperator(account);
  }

  function _isCancelOperator(address account) internal view returns (bool) {
    return ITreasury(getTreasury()).isCancelOperator(account);
  }

  function _isFeeSetterOperator(address account) internal view returns (bool) {
    return ITreasury(getTreasury()).isFeeSetterOperator(account);
  }
  
  function _isMinterOperator(address account) internal view returns (bool) {
    return ITreasury(getTreasury()).isMinterOperator(account);
  }
  
  function _isSuperOperator(address account) internal view returns (bool) {
    return ITreasury(getTreasury()).isSuperOperator(account);
  }

  function _isWhitelistOperator(address account) internal view returns (bool) {
    return ITreasury(getTreasury()).isWhitelistOperator(account);
  }
  
  modifier onlyMigraterOperator() {
    require(_isMigraterOperator(msg.sender), "OperatorRole: caller does not have the Migrater role");

    _;
  }

  modifier onlyCancelOperator() {
    require(_isCancelOperator(msg.sender), "OperatorRole: caller does not have the Cancel role");

    _;
  }

  modifier onlyFeeSetterOperator() {
    require(_isFeeSetterOperator(msg.sender), "OperatorRole: caller does not have the FeeSetter role");

    _;
  }

  modifier onlyWhitelistOperator() {
    require(_isWhitelistOperator(msg.sender), "OperatorRole: caller does not have the whitelist manage role");

    _;
  }

  modifier onlyMinterOperator() {
    require(_isMinterOperator(msg.sender), "OperatorRole: caller does not have the Minter role");

    _;
  }

}
