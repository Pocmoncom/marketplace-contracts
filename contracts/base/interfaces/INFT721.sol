// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";

pragma solidity ^0.7.0;

interface INFT721 is IERC721, IERC721Enumerable, IERC721Metadata {
  event Minted(
    address indexed creator,
    uint256 indexed tokenId,
    string indexed indexedTokenIPFSPath,
    string tokenIPFSPath
  );

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

  function burn(uint256 tokenId) external;
  function getTreasury() external view returns (address payable);
  function getNFTMarket() external view returns (address payable);
  function adminAccountMigration(
    uint256[] calldata createdTokenIds,
    uint256[] calldata ownedTokenIds,
    address originalAddress,
    address payable newAddress,
    bytes calldata signature
  ) external;
  function baseURI() external view returns (string memory);
  function tokenCreator(uint256 tokenId) external view returns (address payable);
  function adminUpdateConfig(address _nftMarket, string memory _baseURI) external;
  function getTokenCreatorPaymentAddress(uint256 tokenId) external view returns (address payable);
  function getNextTokenId() external view returns (uint256);
  function mint(string memory tokenIPFSPath) external returns (uint256 tokenId);
  function mintAndApproveMarket(string memory tokenIPFSPath) external returns (uint256 tokenId);
  function mintWithCreatorPaymentAddress(string memory tokenIPFSPath, address payable tokenCreatorPaymentAddress) external returns (uint256 tokenId);
  function mintWithCreatorPaymentAddressAndApproveMarket(string memory tokenIPFSPath, address payable tokenCreatorPaymentAddress) external returns (uint256 tokenId);
  function mintWithCreatorPaymentFactory(string memory tokenIPFSPath, address paymentAddressFactory, bytes memory paymentAddressCallData) external returns (uint256 tokenId);
  function mintWithCreatorPaymentFactoryAndApproveMarket(string memory tokenIPFSPath, address paymentAddressFactory, bytes memory paymentAddressCallData) external returns (uint256 tokenId);
}
