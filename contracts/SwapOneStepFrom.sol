// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RealDigital.sol";
import "./RealTokenizado.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract SwapOneStepFrom is Context {
    RealDigital CBDC;

    error DigitalCurrencyNotAllowed();

    error RealDigitalSenderAndReceiveIsSame();

    error ReceiveAccountNotAllowed();

    error InsufficientAllowance();

    event SwapExecuted(
        uint256 indexed senderNumber,
        uint256 indexed receiverNumber,
        address sender,
        address receiver,
        uint256 amount
    );

    constructor(RealDigital _CBDC) {
        CBDC = _CBDC;
    }

    /**
     * Transfere o Real Tokenizado do cliente pagador para o recebedor.
     * O cliente pagador é identificado pela carteira que estiver executando esta função.
     * @param tokenSender O endereço do contrato de Real Tokenizado do participante pagador
     * @param tokenReceiver O endereço do contrato de Real Tokenizado do participante recebedor
     * @param receiver O endereço do cliente recebedor
     * @param amount O valor a ser movimentad
     */
    function executeSwap(
        RealTokenizado tokenSender,
        RealTokenizado tokenReceiver,
        address sender,
        address receiver,
        uint256 amount
    ) external {
        if (tokenSender == tokenReceiver) {
            revert RealDigitalSenderAndReceiveIsSame();
        }

        if (!tokenReceiver.authorizedAccounts(receiver)) {
            revert ReceiveAccountNotAllowed();
        }
        if (tokenSender.allowance(sender, _msgSender()) <= amount) {
            revert InsufficientAllowance();
        }

        tokenSender.setSpendAllowanceFrom(sender, _msgSender(), amount);
        tokenSender.moveAndBurn(_msgSender(), amount);

        CBDC.move(tokenSender.reserve(), tokenReceiver.reserve(), amount);

        tokenReceiver.mint(receiver, amount);

        emit SwapExecuted(
            tokenSender.cnpj8(),
            tokenReceiver.cnpj8(),
            _msgSender(),
            receiver,
            amount
        );
    }
}