// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

/// @title NFTSwap
/// @author Dec3mber
/// @notice Decentralized NFT exchange with no fees
/// @dev Implements basic NFT trading functionality, including listing, revoking, updating prices, and purchasing
contract NFTSwap {
    error NFTSwap__MoreThanZero();
    error NFTSwap__NotOwner();
    error NFTSwap__NotApproved();
    error NFTSwap__AleadyList();
    error NFTSwap__NotList();
    error NFTSwap__NotEnoughETH();
    error NFTSwap__TransferFailed();

    /// @notice Structure for an order
    /// @param seller Address of the seller
    /// @param price Price of the NFT
    struct Order {
        address seller;
        uint256 price;
    }

    /// @notice Mapping to store all orders
    /// @dev Mapping structure: NFT contract address => tokenId => Order
    mapping(address => mapping(uint256 => Order)) public orders;

    event OrderCreated(address indexed nftAddress, uint256 indexed tokenId, address seller, uint256 price);
    event OrderRevoked(address indexed nftAddress, uint256 indexed tokenId, address seller);
    event OrderUpdated(address indexed nftAddress, uint256 indexed tokenId, address seller, uint256 newPrice);
    event OrderPurchased(
        address indexed nftAddress, uint256 indexed tokenId, address buyer, address seller, uint256 price
    );

    /// @notice Lists an NFT for sale
    /// @param nftAddress The address of the NFT contract
    /// @param tokenId The token ID of the NFT
    /// @param price The sale price of the NFT
    function list(address nftAddress, uint256 tokenId, uint256 price) external {
        if (price <= 0) {
            revert NFTSwap__MoreThanZero();
        }
        if (IERC721(nftAddress).ownerOf(tokenId) != msg.sender) {
            revert NFTSwap__NotOwner();
        }
        if (
            IERC721(nftAddress).getApproved(tokenId) != address(this)
                || IERC721(nftAddress).isApprovedForAll(msg.sender, address(this))
        ) {
            revert NFTSwap__NotApproved();
        }
        if (orders[nftAddress][tokenId].seller != address(0)) {
            revert NFTSwap__AleadyList();
        }

        orders[nftAddress][tokenId] = Order({seller: msg.sender, price: price});

        emit OrderCreated(nftAddress, tokenId, msg.sender, price);
    }

    /// @notice Revokes an NFT sale order
    /// @param nftAddress The address of the NFT contract
    /// @param tokenId The token ID of the NFT
    function revoke(address nftAddress, uint256 tokenId) external {
        if (orders[nftAddress][tokenId].seller != msg.sender) {
            revert NFTSwap__NotOwner();
        }
        if (orders[nftAddress][tokenId].seller == address(0)) {
            revert NFTSwap__NotList();
        }
        delete orders[nftAddress][tokenId];

        emit OrderRevoked(nftAddress, tokenId, msg.sender);
    }

    /// @notice Updates the price of an NFT sale order
    /// @param nftAddress The address of the NFT contract
    /// @param tokenId The token ID of the NFT
    /// @param newPrice The new sale price
    function update(address nftAddress, uint256 tokenId, uint256 newPrice) external {
        if (orders[nftAddress][tokenId].seller != msg.sender) {
            revert NFTSwap__NotOwner();
        }
        if (orders[nftAddress][tokenId].seller == address(0)) {
            revert NFTSwap__NotList();
        }
        if (newPrice <= 0) {
            revert NFTSwap__MoreThanZero();
        }

        orders[nftAddress][tokenId].price = newPrice;

        emit OrderUpdated(nftAddress, tokenId, msg.sender, newPrice);
    }

    /// @notice Purchases a listed NFT
    /// @param nftAddress The address of the NFT contract
    /// @param tokenId The token ID of the NFT
    function purchase(address nftAddress, uint256 tokenId) external payable {
        if (orders[nftAddress][tokenId].seller == address(0)) {
            revert NFTSwap__NotList();
        }
        if (orders[nftAddress][tokenId].price != msg.value) {
            revert NFTSwap__NotEnoughETH();
        }
        address seller = orders[nftAddress][tokenId].seller;
        uint256 price = orders[nftAddress][tokenId].price;
        if (IERC721(nftAddress).ownerOf(tokenId) != seller) {
            revert NFTSwap__NotOwner();
        }

        delete orders[nftAddress][tokenId];

        // Use try-catch to handle potential transfer errors
        try IERC721(nftAddress).safeTransferFrom(seller, msg.sender, tokenId) {
            payable(seller).transfer(msg.value);
            emit OrderPurchased(nftAddress, tokenId, msg.sender, seller, price);
        } catch {
            // If the transfer fails, restore the order and refund the ETH
            orders[nftAddress][tokenId] = Order({seller: seller, price: price});
            payable(msg.sender).transfer(msg.value);
            revert NFTSwap__TransferFailed();
        }
    }
}
