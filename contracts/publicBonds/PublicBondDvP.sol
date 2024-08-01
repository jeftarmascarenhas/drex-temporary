// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./tpft/ITPFt.sol";
import "./tpft/TPFt.sol";
import {OpType, SWAP_ONE_STEP_FROM_NAME, TPFT_NAME, REAL_DIGITAL_NAME} from "./TPFtUtils.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../AddressDiscovery.sol";
import "../SwapOneStepFrom.sol";

contract PublicBondDvP is ReentrancyGuard {
    using SafeERC20 for RealDigital;
    using SafeERC20 for RealTokenizado;

    uint256 public dvpIds;
    mapping(uint256 => DvpParticipantOp) dvpParticipantOps;
    mapping(uint256 => DvpClientOp) dvpClientOps;
    AddressDiscovery public addressDiscovery;

    error TPFtNotMatchOp();
    error TPFtRepeatedOp();
    error TPFtCanceledOp();

    struct DvpParticipantOp {
        uint256 dvpId;
        address seller;
        address buyer;
        ITPFt.TPFtData tpftData;
        uint256 tpftAmount;
        uint256 unitPerPrice;
        uint256 coinAmount;
        bool buyerConfirmed;
        bool sellerConfirmed;
        bool canceled;
        bool exectued;
    }

    struct DvpClientOp {
        uint256 dvpId;
        address seller;
        address buyer;
        RealTokenizado tokenSeller;
        RealTokenizado tokenBuyer;
        ITPFt.TPFtData tpftData;
        uint256 tpftAmount;
        uint256 unitPerPrice;
        uint256 tokenAmount;
        bool buyerConfirmed;
        bool sellerConfirmed;
        bool canceled;
        bool exectued;
    }

    constructor(AddressDiscovery _addressDiscovery) {
        addressDiscovery = _addressDiscovery;
    }

    function dvpBetweenParticipant(
        uint256 dvpId,
        address seller,
        address buyer,
        ITPFt.TPFtData memory tpftData,
        uint256 tpftAmount,
        uint256 unitPerPrice,
        uint256 coinAmount,
        OpType opType
    ) external nonReentrant returns (uint256 _dvpId) {
        DvpParticipantOp storage dvpOp = dvpParticipantOps[dvpId];

        validateOp(
            dvpOp.sellerConfirmed,
            dvpOp.buyerConfirmed,
            dvpOp.canceled,
            opType
        );

        if (dvpId != 0 && dvpId == dvpOp.dvpId) {
            if (
                checkParticipantOp(
                    dvpId,
                    seller,
                    buyer,
                    tpftData,
                    tpftAmount,
                    unitPerPrice,
                    coinAmount
                )
            ) revert TPFtNotMatchOp();
        }

        if (dvpOp.dvpId == 0) {
            dvpIds++;
            dvpOp.dvpId = dvpIds;
        }

        dvpOp.tpftData = tpftData;
        dvpOp.buyer = buyer;
        dvpOp.seller = seller;
        dvpOp.unitPerPrice = unitPerPrice;
        dvpOp.coinAmount = coinAmount;
        dvpOp.tpftAmount = tpftAmount;

        if (opType == OpType.BUY) {
            dvpOp.buyerConfirmed = true;
        } else {
            dvpOp.sellerConfirmed = true;
        }

        RealDigital realDigital = getRealDigital();
        TPFt tpft = getTPFt();

        if (dvpOp.buyerConfirmed && dvpOp.sellerConfirmed) {
            realDigital.safeTransferFrom(
                dvpOp.buyer,
                dvpOp.seller,
                dvpOp.coinAmount
            );
            tpft.safeTransferFrom(
                dvpOp.seller,
                dvpOp.buyer,
                tpft.getTPFtId(dvpOp.tpftData),
                dvpOp.tpftAmount,
                ""
            );
            dvpOp.exectued = true;
        }
        _dvpId = dvpIds;
    }

    function validateOp(
        bool buyerConfirmed,
        bool sellerConfirmed,
        bool canceled,
        OpType opType
    ) internal pure {
        if (OpType.SELL == opType && sellerConfirmed) revert TPFtRepeatedOp();
        if (OpType.BUY == opType && buyerConfirmed) revert TPFtRepeatedOp();
        if (canceled) revert TPFtCanceledOp();
    }

    function checkParticipantOp(
        uint256 dvpId,
        address seller,
        address buyer,
        ITPFt.TPFtData memory tpftData,
        uint256 tpftAmount,
        uint256 unitPerPrice,
        uint256 coinAmount
    ) internal view returns (bool) {
        DvpParticipantOp memory dvpOp = dvpParticipantOps[dvpId];
        return
            keccak256(
                abi.encodePacked(
                    dvpOp.dvpId,
                    abi.encode(dvpOp.tpftData),
                    dvpOp.buyer,
                    dvpOp.seller,
                    dvpOp.tpftAmount,
                    dvpOp.unitPerPrice,
                    dvpOp.coinAmount
                )
            ) ==
            keccak256(
                abi.encodePacked(
                    dvpId,
                    abi.encode(tpftData),
                    buyer,
                    seller,
                    tpftAmount,
                    unitPerPrice,
                    coinAmount
                )
            );
    }

    function dvpBetweenClient(
        uint256 dvpId,
        address buyer,
        address seller,
        RealTokenizado tokenBuyer,
        RealTokenizado tokenSeller,
        ITPFt.TPFtData memory tpftData,
        uint256 tpftAmount,
        uint256 unitPerPrice,
        uint256 tokenAmount,
        OpType opType
    ) external nonReentrant returns (uint256 _dvpId) {
        DvpClientOp storage dvpOp = dvpClientOps[dvpId];

        SwapOneStepFrom swapOneStepFrom = SwapOneStepFrom(
            addressDiscovery.addressDiscovery(SWAP_ONE_STEP_FROM_NAME)
        );

        validateOp(
            dvpOp.sellerConfirmed,
            dvpOp.buyerConfirmed,
            dvpOp.canceled,
            opType
        );

        if (dvpOp.dvpId == 0) {
            dvpIds++;
            dvpOp.dvpId = dvpIds;
        }

        dvpOp.buyer = buyer;
        dvpOp.seller = seller;
        dvpOp.tokenBuyer = tokenBuyer;
        dvpOp.tokenSeller = tokenSeller;
        dvpOp.tpftData = tpftData;
        dvpOp.tpftAmount = tpftAmount;
        dvpOp.unitPerPrice = unitPerPrice;
        dvpOp.tokenAmount = tokenAmount;

        if (opType == OpType.BUY) {
            dvpOp.buyerConfirmed = true;
        } else {
            dvpOp.sellerConfirmed = true;
        }

        if (dvpOp.buyerConfirmed && dvpOp.sellerConfirmed) {
            if (dvpOp.tokenBuyer == dvpOp.tokenSeller) {
                dvpOp.tokenBuyer.safeTransferFrom(
                    dvpOp.buyer,
                    dvpOp.seller,
                    dvpOp.tokenAmount
                );
            } else {
                swapOneStepFrom.executeSwap(
                    dvpOp.tokenBuyer,
                    dvpOp.tokenSeller,
                    dvpOp.buyer,
                    dvpOp.seller,
                    dvpOp.tokenAmount
                );
            }

            TPFt tpft = getTPFt();

            tpft.safeTransferFrom(
                dvpOp.seller,
                dvpOp.buyer,
                tpft.getTPFtId(dvpOp.tpftData),
                dvpOp.tpftAmount,
                ""
            );

            dvpOp.exectued = true;
        }

        _dvpId = dvpIds;
    }

    function getTPFt() internal view returns (TPFt) {
        return TPFt(addressDiscovery.addressDiscovery(TPFT_NAME));
    }

    function getRealDigital() internal view returns (RealDigital) {
        return
            RealDigital(addressDiscovery.addressDiscovery(REAL_DIGITAL_NAME));
    }
}
