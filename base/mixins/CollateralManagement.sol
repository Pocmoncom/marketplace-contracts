// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../mixins/roles/AdminRole.sol";

/**
 * @notice Enables deposits and withdrawals.
 */
abstract contract CollateralManagement is AdminRole {
  using AddressUpgradeable for address payable;

  
  event RegisterToken(address);
  event UnregisterToken(address);
  event FundsWithdrawn(address indexed to, uint256 amount);
  event TokensWithdrawn(address indexed to, address token, uint256 amount);

  mapping (address => bool ) permittedTokens;
  /**
   * @notice Accept native currency payments (i.e. fees)
   */
  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  /**
   * @notice Allows an admin to withdraw funds.
   * @dev    In normal operation only ETH is required.
   *
   * @param to        Address to receive the withdrawn funds
   * @param amount    Amount to withdrawal or 0 to withdraw all available funds
   */
  function withdrawFunds(address payable to, uint256 amount) public onlyAdmin {
    if (amount == 0) {
      amount = address(this).balance;
    }
    to.sendValue(amount);

    emit FundsWithdrawn(to, amount);
  }

  /**
   * @notice Allows an admin to withdraw tokens.
   *
   * @param to        Address to receive the withdrawn funds
   * @param token     ERC-20/BEP-20 address to withdrawn
   * @param amount    Amount to withdrawal or 0 to withdraw all available funds
   */
  function withdrawTokens(address to, address token, uint256 amount) public onlyAdmin {
    if (amount == 0) {
      amount = IERC20(token).balanceOf(address(this));
    }
    IERC20(token).transferFrom(address(this), to, amount);

    emit TokensWithdrawn(to, token, amount);
  }

  function unregisterToken(address _token) public onlyAdmin() {
      permittedTokens[_token] = false;
  }

  function registerToken(address _token) public onlyAdmin() {
      permittedTokens[_token] = true;
  }

  function isTokenPermitted(address _token) public view returns (bool) {
      return permittedTokens[_token];
  }

  uint256[1000] private __gap;
}
