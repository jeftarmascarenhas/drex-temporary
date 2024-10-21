// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import "../../AddressDiscovery.sol";
import {OpType, PUBLIC_BOND_NAME, TPFT_OPERATION_ID_CONTRACT} from "../TPFtUtils.sol";
import "../PublicBondDvP.sol";
import "../tpft/ITPFt.sol";
import "./TPFtOperationIdStorage.sol";

abstract contract Operation {
    AddressDiscovery public addressDiscovery;

    mapping(uint256 => uint256) public dvpIds;

    enum CallerPart {
        TPFtSender,
        TPFtReceiver
    }

    struct OperationBond {
        uint256 operationId;
        uint256 cnpj8Sender;
        uint256 cnpj8Receiver;
        address sender;
        address receiver;
        CallerPart callerPart;
        RealTokenizado tokenSeller;
        RealTokenizado tokenBuyer;
        ITPFt.TPFtData tpftData;
        uint256 tpftAmount;
        uint256 unitPerPrice;
        bool hasCNPJ8;
        bool hasToken;
    }

    event OperationExecutePublicBond(
        uint256 indexed operationId,
        bool isClientDvp,
        address indexed sender,
        address indexed receiver,
        RealTokenizado tokenSeller,
        RealTokenizado tokenBuyer,
        ITPFt.TPFtData tpftData,
        uint256 tpftAmount,
        uint256 unitPerPrice,
        uint256 financialValue,
        uint256 date
    );

    error OperationIdUsed(uint256 operationId);

    constructor(AddressDiscovery _addressDiscovery) {
        addressDiscovery = _addressDiscovery;
    }

    function calcFinancialValue(
        uint256 unitPerPrice,
        uint256 tpftAmount
    ) internal pure returns (uint256) {
        return (unitPerPrice * tpftAmount) / (10 ** 8);
    }

    function executeOperationDvP(OperationBond memory publicBond) internal {
        OpType opType = getDvpOpType(publicBond.callerPart);

        uint256 financialValue = calcFinancialValue(
            publicBond.unitPerPrice,
            publicBond.tpftAmount
        );

        if (!operationIdUsedValidate(publicBond.operationId)) {
            revert OperationIdUsed(publicBond.operationId);
        }

        PublicBondDvP publicBondDvP = getBondDvP();

        if (!publicBond.hasToken) {
            uint256 dvpId = publicBondDvP.dvpBetweenParticipant(
                publicBond.operationId,
                publicBond.receiver,
                publicBond.sender,
                publicBond.tpftData,
                publicBond.tpftAmount,
                publicBond.unitPerPrice,
                financialValue,
                opType
            );

            if (dvpIds[publicBond.operationId] == 0) {
                dvpIds[publicBond.operationId] = dvpId;
            }

            emit OperationExecutePublicBond(
                publicBond.operationId,
                false,
                publicBond.sender,
                publicBond.receiver,
                publicBond.tokenSeller,
                publicBond.tokenBuyer,
                publicBond.tpftData,
                publicBond.tpftAmount,
                publicBond.unitPerPrice,
                financialValue,
                block.timestamp
            );
        } else {
            uint256 dvpId = publicBondDvP.dvpBetweenClient(
                publicBond.operationId,
                publicBond.receiver,
                publicBond.sender,
                publicBond.tokenBuyer,
                publicBond.tokenSeller,
                publicBond.tpftData,
                publicBond.tpftAmount,
                publicBond.unitPerPrice,
                financialValue,
                opType
            );

            if (dvpIds[publicBond.operationId] == 0) {
                dvpIds[publicBond.operationId] = dvpId;
            }
            emit OperationExecutePublicBond(
                publicBond.operationId,
                true,
                publicBond.sender,
                publicBond.receiver,
                publicBond.tokenSeller,
                publicBond.tokenBuyer,
                publicBond.tpftData,
                publicBond.tpftAmount,
                publicBond.unitPerPrice,
                financialValue,
                block.timestamp
            );
        }
    }

    function operationIdUsedValidate(
        uint256 operationId
    ) internal returns (bool) {
        if (dvpIds[operationId] == 0) {
            return getOperationIdStorage().checkOperationIdIsUsed(operationId);
        }
        return true;
    }

    function getDvpOpType(
        CallerPart callerPart
    ) internal pure returns (OpType) {
        return callerPart == CallerPart.TPFtSender ? OpType.SELL : OpType.BUY;
    }

    function getOperationIdStorage()
        internal
        view
        returns (TPFtOperationIdStorage)
    {
        return
            TPFtOperationIdStorage(
                addressDiscovery.addressDiscovery(TPFT_OPERATION_ID_CONTRACT)
            );
    }

    function getBondDvP() public view returns (PublicBondDvP) {
        return
            PublicBondDvP(addressDiscovery.addressDiscovery(PUBLIC_BOND_NAME));
    }
}
