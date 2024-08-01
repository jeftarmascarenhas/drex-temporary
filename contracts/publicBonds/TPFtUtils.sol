// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

enum OpType {
    BUY,
    SELL
}

bytes32 constant TPFT_NAME = keccak256("TPFt");
bytes32 constant REAL_DIGITAL_NAME = keccak256("RealDigital");
bytes32 constant SWAP_ONE_STEP_FROM_NAME = keccak256("SwapOneStepFrom");
bytes32 constant PUBLIC_BOND_NAME = keccak256("PublicBondDvP");
bytes32 constant REAL_DIGITAL_DEFAULT_ACCOUNT_NAME = keccak256(
    "RealDigitalDefaultAccount"
);

bytes32 constant OPERATION_ID_CONTRACT = keccak256("OperationIdStorage");
