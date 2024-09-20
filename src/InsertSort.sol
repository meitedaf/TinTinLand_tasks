// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract InsertionSort {
    function insert(uint256[] memory array) public pure returns (uint256[] memory) {
        uint256 length = array.length;
        uint256 temp;
        for (uint256 i = 1; i < length; i++) {
            for (uint256 j = i; j > 0; j--) {
                if (array[j] < array[j - 1]) {
                    temp = array[j];
                    array[j] = array[j - 1];
                    array[j - 1] = temp;
                } else {
                    break;
                }
            }
        }
        return array;
    }
}
