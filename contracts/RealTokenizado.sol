// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RealDigital.sol";

contract RealTokenizado is RealDigital {
    string public participant; // String que representa o nome do participante.
    uint256 public cnpj8; // Uitn256 que representa o número da instituição.
    address public reserve; // Carteira de reserva da instituição participante.

    constructor(
        string memory _name,
        string memory _symbol,
        address _authority,
        address _admin,
        string memory _participant,
        uint256 _cnpj8,
        address _reserve
    ) RealDigital(_name, _symbol, _authority, _admin) {
        participant = _participant;
        cnpj8 = _cnpj8;
        reserve = _reserve;
    }

    function updateReserve(
        address newReserve
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        reserve = newReserve;
    }

    function setSpendAllowanceFrom(
        address owner,
        address spender,
        uint256 value
    ) external onlyRole(BURNER_ROLE) {
        _spendAllowance(owner, spender, value);
    }
}
