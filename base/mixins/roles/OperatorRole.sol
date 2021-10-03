// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * @notice Wraps a role from OpenZeppelin's AccessControl for easy integration.
 */
abstract contract OperatorRole is Initializable, AccessControlUpgradeable {
  bytes32 public constant SUPER_OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
  bytes32 public constant ONLY_MINTER_ROLE = keccak256("ONLY_MINTER_ROLE");
  bytes32 public constant ONLY_MIGRATER_ROLE = keccak256("ONLY_MIGRATER_ROLE");
  bytes32 public constant ONLY_CANCEL_ROLE = keccak256("ONLY_CANCEL_ROLE");
  bytes32 public constant ONLY_FEE_SETTER_ROLE = keccak256("ONLY_FEE_SETTER_ROLE");
  bytes32 public constant ONLY_WHITELIST_ROLE= keccak256("ONLY_WHITELIST_ROLE");

  function isSuperOperator(address account) public view returns (bool) {
    return hasRole(SUPER_OPERATOR_ROLE, account);
  }

  /**
   * @dev onlyOperator is enforced by `grantRole`.
   */
  function grantSuperOperator(address account) public {
    grantRole(SUPER_OPERATOR_ROLE, account);
  }

  /**
   * @dev onlyOperator is enforced by `revokeRole`.
   */
  function revokeSuperOperator(address account) public {
    revokeRole(SUPER_OPERATOR_ROLE, account);
  }

  function isMigraterOperator(address account) public view returns (bool) {
    return isSuperOperator(account) || hasRole(ONLY_MIGRATER_ROLE, account);
  }

  function isMinterOperator(address account) public view returns (bool) {
    return isSuperOperator(account) || hasRole(ONLY_MINTER_ROLE, account);
  }

  function isCancelOperator(address account) public view returns (bool) {
    return isSuperOperator(account) || hasRole(ONLY_CANCEL_ROLE, account);
  }

  function isFeeSetterOperator(address account) public view returns (bool) {
    return isSuperOperator(account) || hasRole(ONLY_FEE_SETTER_ROLE, account);
  }

  function isWhitelistOperator(address account) public view returns (bool) {
    return isSuperOperator(account) || hasRole(ONLY_WHITELIST_ROLE, account);
  }
}
