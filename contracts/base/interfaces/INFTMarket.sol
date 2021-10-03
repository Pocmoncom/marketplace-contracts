// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable
pragma abicoder v2;
pragma solidity ^0.7.0;

interface INFTMarket {
  event ReserveAuctionConfigUpdated(
    uint256 minPercentIncrementInBasisPoints,
    uint256 maxBidIncrementRequirement,
    uint256 duration,
    uint256 extensionDuration,
    uint256 goLiveDate
  );

  event ReserveAuctionCreated(
    address indexed seller,
    address indexed nftContract,
    uint256 indexed tokenId,
    uint256 duration,
    uint256 extensionDuration,
    uint256 reservePrice,
    uint256 auctionId
  );
  event ReserveAuctionUpdated(uint256 indexed auctionId, uint256 reservePrice);
  event ReserveAuctionCanceled(uint256 indexed auctionId);
  event ReserveAuctionBidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 endTime);
  event ReserveAuctionFinalized(
    uint256 indexed auctionId,
    address indexed seller,
    address indexed bidder,
    uint256 marketFee,

    uint256 creatorFee,
    uint256 ownerRev
  );
  event ReserveAuctionCanceledByAdmin(uint256 indexed auctionId, string reason);
  event ReserveAuctionSellerMigrated(
    uint256 indexed auctionId,
    address indexed originalSellerAddress,
    address indexed newSellerAddress
  );
  struct ReserveAuction {
    address nftContract;
    uint256 tokenId;
    address payable seller;
    uint256 duration;
    uint256 extensionDuration;
    uint256 endTime;
    address payable bidder;
    uint256 amount;
  }

  function adminUpdateConfig(
    uint256 minPercentIncrementInBasisPoints,
    uint256 duration,
    uint256 primaryFeeBasisPoints,
    uint256 secondaryFeeBasisPoints,
    uint256 secondaryCreatorFeeBasisPoints
  ) external;

  function getReserveAuction(uint256 auctionId) external view returns (ReserveAuction memory);

  function getReserveAuctionIdFor(address nftContract, uint256 tokenId) external view returns (uint256);

  function getReserveAuctionConfig() external view returns (uint256 minPercentIncrementInBasisPoints, uint256 duration);

  function createReserveAuction(
    address nftContract,
    uint256 tokenId,
    uint256 reservePrice
  ) external;

  function updateReserveAuction(uint256 auctionId, uint256 reservePrice) external;

  function cancelReserveAuction(uint256 auctionId) external;

  function placeBid(uint256 auctionId) external payable;

  function finalizeReserveAuction(uint256 auctionId) external;

  function getMinBidAmount(uint256 auctionId) external view returns (uint256);

  function adminCancelReserveAuction(uint256 auctionId, string memory reason) external;

  function adminAccountMigration(
    uint256[] calldata listedAuctionIds,
    address originalAddress,
    address payable newAddress,
    bytes calldata signature
  ) external;

  function getFeeConfig()
    external
    view
    returns (
      uint256 primaryFeeBasisPoints,
      uint256 secondaryFeeBasisPoints,
      uint256 secondaryCreatorFeeBasisPoints
    );
}
