// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

contract OperationIdStorage {
    mapping(uint256 => bool) public operationIdsUsed;

    function checkOperationIdIsUsed(
        uint256 operationId
    ) external returns (bool) {
        if (operationIdsUsed[operationId]) {
            return false;
        }

        operationIdsUsed[operationId] = true;

        return true;
    }
}
