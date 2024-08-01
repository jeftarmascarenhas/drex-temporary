// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "./Operation.sol";
import "../tpft/ITPFt.sol";
import "../TPFtAccessControl.sol";
import "../../RealDigitalDefaultAccount.sol";
import {PUBLIC_BOND_NAME, REAL_DIGITAL_DEFAULT_ACCOUNT_NAME} from "../TPFtUtils.sol";

contract Operation1002 is TPFtAccessControl, Operation, Pausable {
    constructor(
        AddressDiscovery _addressDiscovery
    ) Operation(_addressDiscovery) {}

    function auctionPlacement(
        uint256 operationId,
        uint256 cnpj8Sender,
        uint256 cnpj8Receiver,
        CallerPart callerPart,
        ITPFt.TPFtData memory tpftData,
        uint256 tpftAmount,
        uint256 unitPerPrice
    ) external {
        RealDigitalDefaultAccount realDigitalDefaultAccount = RealDigitalDefaultAccount(
                addressDiscovery.addressDiscovery(
                    REAL_DIGITAL_DEFAULT_ACCOUNT_NAME
                )
            );

        address receiver = realDigitalDefaultAccount.defaultAccount(
            cnpj8Receiver
        );
        address sender = realDigitalDefaultAccount.defaultAccount(cnpj8Sender);

        OperationBond memory publicBond;

        publicBond.operationId = operationId;
        publicBond.cnpj8Sender = cnpj8Sender;
        publicBond.cnpj8Receiver = cnpj8Receiver;
        publicBond.receiver = receiver;
        publicBond.sender = sender;
        publicBond.callerPart = callerPart;
        publicBond.tpftData = tpftData;
        publicBond.tpftAmount = tpftAmount;
        publicBond.unitPerPrice = unitPerPrice;
        publicBond.hasCNPJ8 = true;

        executeOperationDvP(publicBond);
    }

    function cancel(uint256 operationId, string memory reason) external {}

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
