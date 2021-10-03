// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable

pragma solidity ^0.7.0;

import "./IOperatorRole.sol";


interface ITreasury {
  function SUPER_OPERATOR_ROLE() external;
  function ONLY_MINTER_ROLE() external;
  function ONLY_MIGRATER_ROLE() external;
  function ONLY_CANCEL_ROLE() external;
  function ONLY_FEE_SETTER_ROLE() external;
  function ONLY_WHITELIST_ROLE() external;

  function withdrawFunds(address payable to, uint256 amount) external;
  function grantAdmin(address account) external;
  function revokeAdmin(address account) external;
  function isAdmin(address account) external view returns (bool);

  function grantSuperOperator(address account) external;
  function revokeSuperOperator(address account) external;
  function isSuperOperator(address account) external view returns (bool);
  function isMigraterOperator(address account) external view returns (bool);
  function isMinterOperator(address account) external view returns (bool);
  function isCancelOperator(address account) external view returns (bool);
  function isFeeSetterOperator(address account) external view returns (bool);
  function isWhitelistOperator(address account) external view returns (bool);

  function initialize(address admin) external;
}

