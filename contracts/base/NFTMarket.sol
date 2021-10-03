// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;
pragma abicoder v2; // solhint-disable-line

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./mixins/TreasuryNode.sol";
import "./mixins/roles/MarketAdminRole.sol";
import "./mixins/roles/MarketOperatorRole.sol";
import "./mixins/NFTMarketCore.sol";
import "./mixins/SendValueWithFallbackWithdraw.sol";
import "./mixins/NFTMarketCreators.sol";
import "./mixins/NFTMarketFees.sol";
import "./mixins/NFTMarketAuction.sol";
import "./mixins/NFTMarketReserveAuction.sol";
import "./mixins/AccountMigration.sol";

/**
 * @title A market for NFTs on Market.
 * @dev This top level file holds no data directly to ease future upgrades.
 */
contract NFTMarket is
  TreasuryNode,
  MarketAdminRole,
  MarketOperatorRole,
  AccountMigration,
  NFTMarketCore,
  ReentrancyGuardUpgradeable,
  NFTMarketCreators,
  SendValueWithFallbackWithdraw,
  NFTMarketFees,
  NFTMarketAuction,
  NFTMarketReserveAuction
{
  /**
   * @notice Called once to configure the contract after the initial deployment.
   * @dev This farms the initialize call out to inherited contracts as needed.
   */
  function initialize(address payable treasury) public initializer {
    TreasuryNode._initializeTreasuryNode(treasury);
    NFTMarketAuction._initializeNFTMarketAuction();
    NFTMarketReserveAuction._initializeNFTMarketReserveAuction();
  }

  /**
   * @notice Allows Market to update the market configuration.
   */
  function adminUpdateConfig(
    uint256 minPercentIncrementInBasisPoints,
    uint256 duration,
    uint256 primaryFeeBasisPoints,
    uint256 secondaryFeeBasisPoints,
    uint256 secondaryCreatorFeeBasisPoints
  ) public onlyMarketAdmin {
    _updateReserveAuctionConfig(minPercentIncrementInBasisPoints, duration);
    _updateMarketFees(primaryFeeBasisPoints, secondaryFeeBasisPoints, secondaryCreatorFeeBasisPoints);
  }

  /**
   * @dev Checks who the seller for an NFT is, this will check escrow or return the current owner if not in escrow.
   * This is a no-op function required to avoid compile errors.
   */
  function _getSellerFor(address nftContract, uint256 tokenId)
    internal
    view
    virtual
    override(NFTMarketCore, NFTMarketReserveAuction)
    returns (address payable)
  {
    return super._getSellerFor(nftContract, tokenId);
  }
}
