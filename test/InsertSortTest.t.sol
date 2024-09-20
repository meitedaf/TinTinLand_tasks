// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {InsertionSort} from "src/InsertSort.sol";
import {Test, console} from "forge-std/Test.sol";

contract InsertionSortTest is Test {
    InsertionSort insertionSort;

    function setUp() external {
        insertionSort = new InsertionSort();
    }

    function testInsertSort(uint256[] memory randomArraySeed) public view {
        uint256 length = randomArraySeed.length;
        uint256[] memory sortedArray;

        for (uint256 i = 0; i < length; i++) {
            randomArraySeed[i] = randomArraySeed[i] % 100;
        }
        sortedArray = insertionSort.insert(randomArraySeed);

        for (uint256 i = 0; i < length; i++) {
            console.log(sortedArray[i]);
        }
    }
}
