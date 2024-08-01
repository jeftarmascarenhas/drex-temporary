// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * Smart Contract responsável pela camada de controle de acesso para as operações envolvendo Título Público Federal tokenizado (TPFt).
 * Suas principais funcionalidades são:
 *  - Determinar quais carteiras podem criar e emitir TPFt,
 *  - Controlar quais carteiras tem acesso as operações envolvendo TPFt.
 * @title TPFtAccessControl
 * @author Jeftar Mascarenhas
 * @notice Este contrato utiliza informações públicas e está atualizado usando Openzeppelin V5
 */
contract TPFtAccessControl is AccessControl {
    /**
     * @dev Role que permite criar e emitir TPFt.
     */
    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /**
     * @dev Role que permite realizar a operação de colocação direta.
     */
    bytes32 constant DIRECT_PLACEMENT_ROLE = keccak256("DIRECT_PLACEMENT_ROLE");
    /**
     * @dev Role que permite realizar a liquidação de oferta pública.
     */
    bytes32 constant AUCTION_PLACEMENT_ROLE =
        keccak256("AUCTION_PLACEMENT_ROLE");
    /**
     * @dev Role que permite bloquear saldo de uma carteira.
     */
    bytes32 constant FREEZER_ROLE = keccak256("FREEZER_ROLE");
    /**
     * @dev Role que permite realizar a operação de resgate.
     */
    bytes32 constant REPAYMENT_ROLE = keccak256("REPAYMENT_ROLE");
    /**
     * @dev Role que permite realizar a operação transferência.
     */
    bytes32 constant OPERATION_ROLE = keccak256("OPERATION_ROLE");
    /**
     * @notice Constrói uma instância do contrato e permite a carteira conceder ou revogar as roles para os participantes.
     */
    mapping(address => bool) public enableAddresses;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(DIRECT_PLACEMENT_ROLE, _msgSender());
        _grantRole(AUCTION_PLACEMENT_ROLE, _msgSender());
        _grantRole(FREEZER_ROLE, _msgSender());
        _grantRole(REPAYMENT_ROLE, _msgSender());
        _grantRole(OPERATION_ROLE, _msgSender());
    }

    /**
     * Habilita a carteira a criar e emitir TPFt.
     * @param member Carteira a ser habilitada
     */
    function allowTPFtMint(address member) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, member);
    }

    /**
     * Habilita a carteira a realizar a operação de colocação direta envolvendo TPFt.
     * @param member Carteira a ser habilitada
     */
    function allowDirectPlacement(
        address member
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DIRECT_PLACEMENT_ROLE, member);
    }

    /**
     * Habilita a carteira a realizar a liquidação de oferta pública envolvendo TPFt.
     * @param member Carteira a ser habilitada
     */
    function allowAuctionPlacement(
        address member
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DIRECT_PLACEMENT_ROLE, member);
    }

    /**
     * Habilita a carteira a ter saldo de ativos bloqueados.
     * @param member Carteira a ser habilitada
     */
    function allowFreezingPlacement(
        address member
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(FREEZER_ROLE, member);
    }

    /**
     * Habilita a carteira a operar no piloto Real Digital Selic.
     * @param member Carteira a ser habilitada
     */
    function enableAddress(address member) public onlyRole(DEFAULT_ADMIN_ROLE) {
        enableAddresses[member] = true;
    }

    /**
     * Desabilita a carteira a operar no piloto Real Digital Selic.
     * @param member Carteira a ser desabilita
     */
    function disableAddress(
        address member
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        enableAddresses[member] = false;
    }

    /**
     * Verifica se a carteira está habilitada a operar no piloto Real Digital Selic.
     * @param member Carteira a ser verificada
     * @return Retorna um valor booleano que indica se a carteira está habilitada a operar no piloto Real Digital Selic.
     */
    function isEnabledAddress(
        address member
    ) public view onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        return enableAddresses[member];
    }
}
