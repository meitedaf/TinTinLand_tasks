// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

// GPT 完善 natspect------------------------------------------------------------------
contract NFTSwap {
    error NFTSwap__MoreThanZero();
    error NFTSwap__NotOwner();
    error NFTSwap__NotApproved();
    error NFTSwap__AleadyList();
    error NFTSwap__NotList();
    error NFTSwap__NotEnoughETH();
    error NFTSwap__TransferFailed();

    struct Order {
        address seller;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Order)) public orders;

    event OrderCreated(address indexed nftAddress, uint256 indexed tokenId, address seller, uint256 price);
    event OrderRevoked(address indexed nftAddress, uint256 indexed tokenId, address seller);
    event OrderUpdated(address indexed nftAddress, uint256 indexed tokenId, address seller, uint256 newPrice);
    event OrderPurchased(
        address indexed nftAddress, uint256 indexed tokenId, address buyer, address seller, uint256 price
    );

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

    function purchase(address nftAddress, uint256 tokenId) external payable {
        if (orders[nftAddress][tokenId].seller == address(0)) {
            revert NFTSwap__NotList();
        }
        if (orders[nftAddress][tokenId].price != msg.value) {
            revert NFTSwap__NotEnoughETH();
        }
        address seller = orders[nftAddress][tokenId].seller;
        uint256 price = orders[nftAddress][tokenId].price;

        // 检查卖家是否仍然是NFT的所有者
        if (IERC721(nftAddress).ownerOf(tokenId) != seller) {
            revert NFTSwap__NotOwner();
        }

        delete orders[nftAddress][tokenId];

        // 使用try-catch来处理可能的转移错误
        try IERC721(nftAddress).safeTransferFrom(seller, msg.sender, tokenId) {
            payable(seller).transfer(msg.value);
            emit OrderPurchased(nftAddress, tokenId, msg.sender, seller, price);
        } catch {
            // 如果转移失败，恢复订单并返还ETH
            orders[nftAddress][tokenId] = Order({seller: seller, price: price});
            payable(msg.sender).transfer(msg.value);
            revert NFTSwap__TransferFailed();
        }
    }
}
