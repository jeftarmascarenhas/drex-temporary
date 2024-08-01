// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "./Operation.sol";
import "../tpft/ITPFt.sol";
import "../TPFtAccessControl.sol";
import "../../RealDigitalDefaultAccount.sol";
import {PUBLIC_BOND_NAME, REAL_DIGITAL_DEFAULT_ACCOUNT_NAME} from "../TPFtUtils.sol";

/**
 * Contrato por permitir a liquidação de oferta pública envolvendo Título Público Federal tokenizado (TPFt).
 * @title Operation1002
 * @author Jeftar Mascarenhas
 * @notice @notice Este contrato utiliza informações públicas e está atualizado usando Openzeppelin V5
 */
contract Operation1002 is TPFtAccessControl, Operation, Pausable {
    constructor(
        AddressDiscovery _addressDiscovery
    ) Operation(_addressDiscovery) {}

    /**
     * Interface responsável por permitir a liquidação de oferta pública envolvendo Título Público Federal tokenizado (TPFt).
     * @param operationId Número de operação + data vigente no formato yyyyMMdd.
     * @param cnpj8Sender CNPJ8 do cedente da operação. Nesta operação sempre será o CNPJ8 da STN.
     * @param cnpj8Receiver CNPJ8 do cessionário da operação.
     * @param callerPart Parte que está transmitindo o comando da operação. Se for o cedente deve ser informado CallerPart.TPFtSender,
     * se for o cessionário deve ser informado CallerPart.TPFtReceiver
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações:
     * - acronym: A sigla do TPFt.
     * - code: O código único do TPFt.
     * - maturityDate: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser negociada. Incluir as 2 casas decimais.
     * @param unitPerPrice Preço unitário do TPFt. Incluir as 8 casas decimais.
     */
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
        // uint256 dvpId,
        // address seller,
        // address buyer,
        // ITPFt.TPFtData memory tpftData,
        // uint256 tpftAmount,
        // uint256 unitPerPrice,
        // uint256 coinAmount,
        // OpType opType
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

    /**
     * Função para cancelar uma operação de liquidação de oferta pública envolvendo TPFt.
     * @param operationId Número de operação + data vigente no formato yyyyMMdd.
     * @param reason Motivo do cancelamento
     */
    function cancel(uint256 operationId, string memory reason) external {}

    /**
     * Função externa utilizada pela carteira que é detentor da ROLE DEFAULT_ADMIN_ROLE para colocar o contrato em pausa.
     * O contrato em pausa bloqueará a execução de funções, garantindo que o contrato possa ser temporariamente interrompido.
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * Função externa utilizada pela carteira que é detentor da ROLE DEFAULT_ADMIN_ROLE para retirar o contrato de pausa. O contrato retirado de pausa permite a execução normal de todas as funções novamente após ter sido previamente pausado.
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
