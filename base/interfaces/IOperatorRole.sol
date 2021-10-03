// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

/**
 * @notice Interface for OperatorRole which wraps a role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IOperatorRole {
  function hasRole(bytes32 role, address account) external view returns (bool);
  function grantRole(bytes32 role, address account) external view returns (bool);
  function revokeRole(bytes32 role, address account) external view returns (bool);
}
