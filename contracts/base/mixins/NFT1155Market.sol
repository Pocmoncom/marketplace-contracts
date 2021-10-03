// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/INFTMarket.sol";

import "./TreasuryNode.sol";
import "./HasSecondarySaleFees.sol";
import "./NFT1155Creator.sol";

/**
 * @notice Holds a reference to the Market Market and communicates fees to 3rd party marketplaces.
 */
abstract contract NFT1155Market is TreasuryNode, HasSecondarySaleFees, NFT1155Creator {
  using AddressUpgradeable for address;

  event NFTMarketUpdated(address indexed nftMarket);

  INFTMarket private nftMarket;

  /**
   * @notice Returns the address of the Market NFTMarket contract.
   */
  function getNFTMarket() public view returns (address) {
    return address(nftMarket);
  }

  function _updateNFTMarket(address _nftMarket) internal {
    require(_nftMarket.isContract(), "NFT1155Market: Market address is not a contract");
    nftMarket = INFTMarket(_nftMarket);

    emit NFTMarketUpdated(_nftMarket);
  }

  /**
   * @notice Returns an array of recipient addresses to which fees should be sent.
   * The expected fee amount is communicated with `getFeeBps`.
   */
  function getFeeRecipients(uint256 id) public view override returns (address payable[] memory) {
    require(_exists(id), "ERC721Metadata: Query for nonexistent token");

    address payable[] memory result = new address payable[](2);
    result[0] = getTreasury();
    result[1] = getTokenCreatorPaymentAddress(id);
    return result;
  }

  /**
   * @notice Returns an array of fees in basis points.
   * The expected recipients is communicated with `getFeeRecipients`.
   */
  function getFeeBps(
    uint256 /* id */
  ) public view override returns (uint256[] memory) {
    (, uint256 secondaryFeeBasisPoints, uint256 secondaryCreatorFeeBasisPoints) = nftMarket.getFeeConfig();
    uint256[] memory result = new uint256[](2);
    result[0] = secondaryFeeBasisPoints;
    result[1] = secondaryCreatorFeeBasisPoints;
    return result;
  }

  /**
   * @notice Get fee recipients and fees in a single call.
   * The data is the same as when calling getFeeRecipients and getFeeBps separately.
   */
  function getFees(uint256 tokenId)
    public
    view
    returns (address payable[2] memory recipients, uint256[2] memory feesInBasisPoints)
  {
    require(_exists(tokenId), "ERC721Metadata: Query for nonexistent token");

    recipients[0] = getTreasury();
    recipients[1] = getTokenCreatorPaymentAddress(tokenId);
    (, uint256 secondaryFeeBasisPoints, uint256 secondaryCreatorFeeBasisPoints) = nftMarket.getFeeConfig();
    feesInBasisPoints[0] = secondaryFeeBasisPoints;
    feesInBasisPoints[1] = secondaryCreatorFeeBasisPoints;
  }

  uint256[1000] private ______gap;
}
