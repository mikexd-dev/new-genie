// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarketplace is ERC721 {
    using Counters for Counters.Counter;
    
    struct Listing {
        address seller;             // Address of the seller
        uint256 price;              // Price of the listing
        bool active;                // Whether the listing is active
        uint256 saleTimestamp;      // Timestamp of the sale
    }
    
    Counters.Counter private _listingId;  // Counter to keep track of listing IDs
    mapping(uint256 => Listing) private _listings;  // Mapping of listing ID to Listing
    
    uint256 private _feePercentage;  // Fee percentage charged by the marketplace
    
    event ListingCreated(uint256 indexed listingId, address indexed seller, uint256 price);
    event ListingUpdated(uint256 indexed listingId, uint256 price);
    event ListingRemoved(uint256 indexed listingId);
    event NFTSold(uint256 indexed listingId, address indexed buyer, uint256 price);

    constructor() ERC721("NFTMarketplace", "NFTM") {
        _feePercentage = 5;  // Default fee percentage of 5%
    }
    
    /**
     * @dev Creates a new listing for an NFT.
     * @param price The price of the listing.
     */
    function createListing(uint256 price) external {
        require(price > 0, "Price must be greater than zero");
        require(!_exists(_listingId.current()), "Listing already exists");
        
        _safeMint(msg.sender, _listingId.current());
        _listings[_listingId.current()] = Listing(msg.sender, price, true, 0);
        
        emit ListingCreated(_listingId.current(), msg.sender, price);
        _listingId.increment();
    }
    
    /**
     * @dev Updates a listing with a new price.
     * @param listingId The ID of the listing to update.
     * @param price The new price of the listing.
     */
    function updateListing(uint256 listingId, uint256 price) external {
        require(_exists(listingId), "Listing does not exist");
        require(msg.sender == _listings[listingId].seller, "Only seller can update the listing");

        _listings[listingId].price = price;
        
        emit ListingUpdated(listingId, price);
    }
    
    /**
     * @dev Removes a listing.
     * @param listingId The ID of the listing to remove.
     */
    function removeListing(uint256 listingId) external {
        require(_exists(listingId), "Listing does not exist");
        require(msg.sender == _listings[listingId].seller, "Only seller can remove the listing");

        delete _listings[listingId];
        
        _burn(listingId);
        emit ListingRemoved(listingId);
    }
    
    /**
     * @dev Buys the NFT with the specified listing ID.
     * @param listingId The ID of the listing to buy.
     */
    function buyNFT(uint256 listingId) external payable {
        require(_exists(listingId), "Listing does not exist");
        require(_listings[listingId].active, "Listing is not active");
        require(msg.value >= _listings[listingId].price, "Insufficient payment");
        
        address payable seller = payable(_listings[listingId].seller);
        uint256 salePrice = _listings[listingId].price;
        uint256 feeAmount = (salePrice * _feePercentage) / 100;
        uint256 paymentAmount = salePrice - feeAmount;
        
        _transfer(seller, msg.sender, listingId);
        _listings[listingId].active = false;
        _listings[listingId].saleTimestamp = block.timestamp;
        
        seller.transfer(paymentAmount);
        
        emit NFTSold(listingId, msg.sender, salePrice);
    }
    
    /**
     * @dev Sets the fee percentage charged by the marketplace.
     * @param feePercentage The fee percentage to set.
     */
    function setFeePercentage(uint256 feePercentage) external {
        require(feePercentage <= 100, "Fee percentage must be less than or equal to 100");
        
        _feePercentage = feePercentage;
    }
    
    /**
     * @dev Gets the fee percentage charged by the marketplace.
     * @return The fee percentage.
     */
    function getFeePercentage() external view returns (uint256) {
        return _feePercentage;
    }
    
    /**
     * @dev Gets the details of a listing.
     * @param listingId The ID of the listing.
     * @return The details of the listing.
     */
    function getListing(uint256 listingId) external view returns (Listing memory) {
        return _listings[listingId];
    }
}