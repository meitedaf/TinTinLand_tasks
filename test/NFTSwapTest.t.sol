// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/NFTSwap.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNFT is ERC721 {
    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}

contract NFTSwapTest is Test {
    NFTSwap public nftSwap;
    MockNFT public nftA;
    MockNFT public nftB;
    address public alice;
    address public bob;

    function setUp() public {
        nftSwap = new NFTSwap();
        nftA = new MockNFT();
        nftB = new MockNFT();
        alice = address(1);
        bob = address(2);
    }

    function testList() public {
        uint256 tokenIdA = 1;
        uint256 price = 1 ether;

        nftA.mint(alice, tokenIdA);
        vm.startPrank(alice);
        nftA.approve(address(nftSwap), tokenIdA);
        nftSwap.list(address(nftA), tokenIdA, price);
        vm.stopPrank();

        (address seller, uint256 listedPrice) = nftSwap.orders(address(nftA), tokenIdA);

        assertEq(seller, alice);
        assertEq(listedPrice, price);
    }

    function testPurchase() public {
        uint256 tokenIdA = 1;
        uint256 price = 1 ether;

        address seller = address(0x1234); 
        address buyer = address(0x5678); 

        nftA.mint(seller, tokenIdA);

        vm.startPrank(seller);
        nftA.approve(address(nftSwap), tokenIdA);
        nftSwap.list(address(nftA), tokenIdA, price);
        vm.stopPrank();

        (address listedSeller, uint256 listedPrice) = nftSwap.orders(address(nftA), tokenIdA);
        assertEq(listedSeller, seller);
        assertEq(listedPrice, price);

        assertEq(nftA.ownerOf(tokenIdA), seller);

        vm.deal(buyer, price);
        vm.prank(buyer);
        nftSwap.purchase{value: price}(address(nftA), tokenIdA);

        assertEq(nftA.ownerOf(tokenIdA), buyer);
        assertEq(seller.balance, price);

        (address finalSeller, uint256 finalPrice) = nftSwap.orders(address(nftA), tokenIdA);
        assertEq(finalSeller, address(0));
        assertEq(finalPrice, 0);
    }

    function testRevoke() public {
        uint256 tokenIdA = 1;
        uint256 price = 1 ether;

        nftA.mint(alice, tokenIdA);

        vm.startPrank(alice);
        nftA.approve(address(nftSwap), tokenIdA);
        nftSwap.list(address(nftA), tokenIdA, price);
        nftSwap.revoke(address(nftA), tokenIdA);
        vm.stopPrank();

        (address seller, uint256 listedPrice) = nftSwap.orders(address(nftA), tokenIdA);
        assertEq(seller, address(0));
        assertEq(listedPrice, 0);
    }

    function testUpdate() public {
        uint256 tokenIdA = 1;
        uint256 initialPrice = 1 ether;
        uint256 newPrice = 2 ether;

        nftA.mint(alice, tokenIdA);

        vm.startPrank(alice);
        nftA.approve(address(nftSwap), tokenIdA);
        nftSwap.list(address(nftA), tokenIdA, initialPrice);
        nftSwap.update(address(nftA), tokenIdA, newPrice);
        vm.stopPrank();

        (address seller, uint256 listedPrice) = nftSwap.orders(address(nftA), tokenIdA);
        assertEq(seller, alice);
        assertEq(listedPrice, newPrice);
    }
}
