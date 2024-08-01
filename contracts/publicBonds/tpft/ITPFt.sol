// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

interface ITPFt {
    struct TPFtData {
        string acronym;
        string code;
        uint256 maturityDate;
    }
    event CreateTPFt(uint256 indexed tpftId, uint256 indexed maturityDate);
    event TFPtFronzenBalance(address from, uint256 balance);

    error OnlyMinterContract();

    error OnlyDirectPlacementContract();
    error OnlySTNaddress(address stnAddress);
    error TPFtDoesNotExits(uint256 tpftId);
    error TPFtExits(uint256 tpftId);
    error TPFtMaturityDateExpirate();
    error TPFtFrozenBalanceIsLessThanAmount();
    error AddressCannotBeZero();
    error TPFtIdNotExists();
    error TPFtIsPaused();

    function name() external view returns (string memory);

    function getTPFtId(
        TPFtData memory tpftData
    ) external view returns (uint256);

    function createTPFt(TPFtData memory tpftData) external;

    function mint(
        address receiverAddress,
        TPFtData memory tpftData,
        uint256 tpftAmount
    ) external;

    function directPlacement(
        address from,
        address to,
        TPFtData memory tpftData,
        uint256 tpftAmount
    ) external;

    function decimals() external view returns (uint256);

    function increaseFrozenBalance(
        address from,
        TPFtData memory tpftData,
        uint256 tpftAmount
    ) external;

    function decreaseFrozenBalance(
        address from,
        TPFtData memory tpftData,
        uint256 tpftAmount
    ) external;

    function pause() external;

    function unpause() external;

    function setPaymentStatus(
        address account,
        uint256 tpftId,
        bool status
    ) external;

    function getPaymentStatus(
        address account,
        uint256 tpftId
    ) external view returns (bool);

    function setTpftIdToPaused(uint256 tpftId, bool status) external;

    function isTpftIdPaused(uint256 tpftId) external view returns (bool);
}
