// Crie um smart contract em Solidity para realizar uma transação Delivery vs Payment (DvP) para a venda de veículos. O contrato deve permitir que um comprador pague por um veículo, e o vendedor transfira a propriedade do veículo para o comprador, de forma que ambas as ações aconteçam simultaneamente. O contrato deve incluir as seguintes funcionalidades:
// 1. Registrar os dados do veículo (VIN, marca, modelo, ano).
// 2. Registrar as informações do vendedor e do comprador.
// 3. Permitir que o comprador deposite o valor do veículo no contrato.
// 4. Transferir a propriedade do veículo para o comprador após o pagamento.
// 5. Permitir que o vendedor saque o valor após a transferência de propriedade.
// 6. Adicionar um mecanismo de confirmação para garantir que ambas as partes estão de acordo com a transação.
// 7. Incluir eventos para registrar todas as ações importantes (registro do veículo, depósito do pagamento, transferência de propriedade, saque do valor).
// Use o padrão ERC-721 para representar a propriedade do veículo como um token NFT.
// Utilize a versão 0.8.24 do Solidity.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VehicleDvP is ERC721, Ownable {
    struct Vehicle {
        string vin;
        string make;
        string model;
        uint16 year;
    }

    struct Transaction {
        address payable seller;
        address payable buyer;
        uint256 price;
        bool buyerConfirmed;
        bool sellerConfirmed;
    }

    uint256 public nextTokenId;
    mapping(uint256 => Vehicle) public vehicles;
    mapping(uint256 => Transaction) public transactions;

    event VehicleRegistered(
        uint256 tokenId,
        string vin,
        string make,
        string model,
        uint16 year
    );
    event PaymentDeposited(uint256 tokenId, address buyer, uint256 amount);
    event OwnershipTransferred(uint256 tokenId, address seller, address buyer);
    event PaymentWithdrawn(uint256 tokenId, address seller, uint256 amount);
    event TransactionConfirmed(uint256 tokenId, address party);

    constructor() ERC721("VehicleToken", "VCL") Ownable(_msgSender()) {}

    function registerVehicle(
        string memory vin,
        string memory make,
        string memory model,
        uint16 year
    ) external onlyOwner {
        uint256 tokenId = nextTokenId;
        vehicles[tokenId] = Vehicle(vin, make, model, year);
        _mint(msg.sender, tokenId);
        nextTokenId++;
        emit VehicleRegistered(tokenId, vin, make, model, year);
    }

    function initiateTransaction(
        uint256 tokenId,
        address payable buyer,
        uint256 price
    ) external {
        require(
            ownerOf(tokenId) == msg.sender,
            "Only the owner can initiate the transaction"
        );
        transactions[tokenId] = Transaction(
            payable(msg.sender),
            buyer,
            price,
            false,
            false
        );
    }

    function depositPayment(uint256 tokenId) external payable {
        Transaction storage txn = transactions[tokenId];
        require(msg.sender == txn.buyer, "Only the buyer can deposit payment");
        require(msg.value == txn.price, "Incorrect payment amount");
        emit PaymentDeposited(tokenId, msg.sender, msg.value);
    }

    function confirmTransaction(uint256 tokenId) external {
        Transaction storage txn = transactions[tokenId];
        require(
            msg.sender == txn.buyer || msg.sender == txn.seller,
            "Only buyer or seller can confirm the transaction"
        );

        if (msg.sender == txn.buyer) {
            txn.buyerConfirmed = true;
        } else if (msg.sender == txn.seller) {
            txn.sellerConfirmed = true;
        }

        emit TransactionConfirmed(tokenId, msg.sender);

        if (txn.buyerConfirmed && txn.sellerConfirmed) {
            _transfer(txn.seller, txn.buyer, tokenId);
            emit OwnershipTransferred(tokenId, txn.seller, txn.buyer);
        }
    }

    function withdrawPayment(uint256 tokenId) external {
        Transaction storage txn = transactions[tokenId];
        require(
            txn.buyerConfirmed && txn.sellerConfirmed,
            "Transaction must be confirmed by both parties"
        );
        require(
            msg.sender == txn.seller,
            "Only the seller can withdraw the payment"
        );

        uint256 amount = txn.price;
        txn.price = 0;
        txn.seller.transfer(amount);
        emit PaymentWithdrawn(tokenId, msg.sender, amount);
    }
}
