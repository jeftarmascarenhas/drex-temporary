// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./ITPFt.sol";
import "../TPFtAccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../../AddressDiscovery.sol";
import "../../RealDigitalDefaultAccount.sol";

/**
 * @title TPFt
 * @author BCB
 * @notice Contrato responsável pela criação e emissão de Título Público Federal tokenizado (TPFt).
 * @notice Este contrato utiliza informações públicas e está atualizado usando Openzeppelin V5
 * ATENÇÃO: Na Selic existe uma operação 1001 que é responsável por criação/emissão de título público federal.
 * Creio que o BACEN tenha um contrato para operação 1001, mas como não existe ABI deste contrato a criação/emissão
 * serão feitas no contrato de TPFt.
 * Numa atualização futura poderá para criar/emitir o fluxo será TPFtOperation1001 > TPFt
 */
contract TPFt is ITPFt, ERC1155Supply, TPFtAccessControl, Pausable {
    string constant _name = "TPFt";
    uint256 public tpftIds;
    /**
     * @dev CNPJ8 da STN são os primeiros 8 digitos do CNPJ de uma empresa
     */
    uint256 constant STN_CNPJ8 = 394460;
    AddressDiscovery public addressDiscovery;

    mapping(uint256 => TPFtData) public tpfts;
    mapping(bytes32 => uint256) public tpftMapToId;
    mapping(uint256 => bool) tpftPaused;
    mapping(uint256 => mapping(address => bool)) tpftPaymentStatus;
    mapping(address => mapping(uint256 => uint)) frozenBalances;

    constructor(
        AddressDiscovery _addressDiscovery
    ) ERC1155("") TPFtAccessControl() {
        _addressDiscovery = addressDiscovery;
    }

    modifier frozenBalanceAnalyzing(
        address from,
        uint256[] memory ids,
        uint256[] memory values
    ) {
        uint256 idsLen = ids.length;
        for (uint i = 0; i < idsLen; i++) {
            if (
                frozenBalances[from][ids[i]] > 0 &&
                frozenBalances[from][ids[i]] <=
                (balanceOf(from, ids[i]) - values[i])
            ) {
                revert TPFtFrozenBalanceIsLessThanAmount();
            }
        }
        _;
    }

    /**
     * Função pública que retorna o nome do contrato.
     * @return Retorna uma string contendo o nome do contrato.
     */
    function name() external pure returns (string memory) {
        return _name;
    }

    function getTPFtId(TPFtData memory tpftData) public view returns (uint256) {
        return tpftMapToId[keccak256(abi.encode(tpftData))];
    }

    /**
     * Função pública para criar TPFt, neste ponto o TPFt não será emitido, apenas criado.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     */
    function createTPFt(
        TPFtData memory tpftData
    ) external whenNotPaused onlyRole(MINTER_ROLE) {
        TPFtData storage newTPFt = tpfts[tpftIds];

        tpftIds++;

        if (isTPFt(tpftData)) {
            revert TPFtExits(getTPFtId(tpftData));
        }

        if (tpftData.maturityDate > block.timestamp) {
            revert TPFtMaturityDateExpirate();
        }

        newTPFt.acronym = tpftData.acronym;
        newTPFt.code = tpftData.code;
        newTPFt.maturityDate = tpftData.maturityDate;

        tpftMapToId[keccak256(abi.encode(newTPFt))] = tpftIds;
        emit CreateTPFt(tpftIds, tpftData.maturityDate);
    }

    function isTPFt(TPFtData memory tpftData) public view returns (bool) {
        return getTPFtId(tpftData) != 0;
    }

    function mint(
        address receiverAddress,
        TPFtData memory tpftData,
        uint256 tpftAmount
    ) external whenNotPaused onlyRole(MINTER_ROLE) {
        if (!isTPFt(tpftData)) {
            revert TPFtDoesNotExits(getTPFtId(tpftData));
        }

        if (
            receiverAddress !=
            getRealDigitalDefaultAccountContract().defaultAccount(STN_CNPJ8)
        ) {
            revert OnlySTNaddress(receiverAddress);
        }

        _mint(receiverAddress, getTPFtId(tpftData), tpftAmount, "");
    }

    /**
     * Função para realizar uma operação de colocação direta de TPFt.
     * @param from Endereço da carteira de origem da operação de colocação direta.
     * @param to Endereço da carteira de destino da operação de colocação direta.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações:
        - acronym: A sigla do TPFt.
        - code: O código único do TPFt.
        - maturityDate: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser enviada na operação de colocação direta.
     */
    function directPlacement(
        address from,
        address to,
        TPFtData memory tpftData,
        uint256 tpftAmount
    ) external whenNotPaused onlyRole(DIRECT_PLACEMENT_ROLE) {
        _safeTransferFrom(from, to, getTPFtId(tpftData), tpftAmount, "");
    }

    /**
     * Função externa para obter o número de casas decimais do TPFt.
     * @return Número de casas decimais que para o TPFt será de 2.
     */
    function decimals() external pure returns (uint256) {
        return 2;
    }

    function increaseFrozenBalance(
        address from,
        TPFtData memory tpftData,
        uint256 tpftAmount
    ) external whenNotPaused onlyRole(DIRECT_PLACEMENT_ROLE) {
        if (from == address(0)) {
            revert AddressCannotBeZero();
        }
        if (getTPFtId(tpftData) == 0) {
            revert TPFtIdNotExists();
        }
        frozenBalances[from][getTPFtId(tpftData)] += tpftAmount;
        emit TFPtFronzenBalance(
            from,
            frozenBalances[from][getTPFtId(tpftData)]
        );
    }

    function decreaseFrozenBalance(
        address from,
        TPFtData memory tpftData,
        uint256 tpftAmount
    ) external whenNotPaused onlyRole(DIRECT_PLACEMENT_ROLE) {
        if (from == address(0)) {
            revert AddressCannotBeZero();
        }
        if (getTPFtId(tpftData) == 0) {
            revert TPFtIdNotExists();
        }
        if (frozenBalances[from][getTPFtId(tpftData)] <= tpftAmount) {
            // revert TPFtFrozenBalanceMustGreaterThanZero();
        }
        frozenBalances[from][getTPFtId(tpftData)] -= tpftAmount;
        emit TFPtFronzenBalance(
            from,
            frozenBalances[from][getTPFtId(tpftData)]
        );
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * Função externa que permite definir o status de pagamento para um determinado endereço da carteira e ID de TPFt.
     * Apenas contas com a Role REPAYMENT_ROLE têm permissão para utilizar esta função.
     * @param account Endereço da carteira para o qual o status de pagamento será definido.
     * @param tpftId ID do TPFt para o qual o status de pagamento será definido.
     * @param status Status de pagamento a ser definido (verdadeiro para pago, falso para não pago).
     */
    function setPaymentStatus(
        address account,
        uint256 tpftId,
        bool status
    ) external whenNotPaused onlyRole(REPAYMENT_ROLE) {
        tpftPaymentStatus[tpftId][account] = status;
    }

    /**
     * Função externa que retorna o status de pagamento para um determinado endereço da carteira e ID de TPFt.
     * @param account Endereço da carteira para a qual o status de pagamento está sendo consultado.
     * @param tpftId ID do TPFt para o qual o status de pagamento está sendo consultado.
     * @return Retorna true se o pagamento foi efetuado, false se não foi.
     */
    function getPaymentStatus(
        address account,
        uint256 tpftId
    ) external view returns (bool) {
        return tpftPaymentStatus[tpftId][account];
    }

    /**
     * Função externa que permite definir o status de pausa para um determinado ID de TPFt.
     * Apenas contas com a Role REPAYMENT_ROLE têm permissão para utilizar esta função.
     * @param tpftId ID do TPFt para o qual o status de pausa será ajustado.
     * @param status Status de pausa a ser definido (verdadeiro para pausado, falso para não pausado).
     */
    function setTpftIdToPaused(
        uint256 tpftId,
        bool status
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        tpftPaused[tpftId] = status;
    }

    /**
     * Função externa que retorna o status de pausa para um determinado ID de TPFt.
     * @param tpftId ID do TPFt para o qual o status de pausa está sendo consultado.
     * @return Retorna true se o TPFt está pausado para operações, false se não está.
     */
    function isTpftIdPaused(uint256 tpftId) external view returns (bool) {
        return tpftPaused[tpftId];
    }

    function getRealDigitalDefaultAccountContract()
        internal
        view
        returns (RealDigitalDefaultAccount)
    {
        return
            RealDigitalDefaultAccount(
                addressDiscovery.addressDiscovery(
                    keccak256("RealDigitalDefaultAccount")
                )
            );
    }

    /**
     * Função que valida se os TPFtIds estão pausados.
     * @param ids Array com TPFtIds que serão verificados.
     */
    function TpftIdPauseValidation(uint256[] memory ids) internal view {
        uint256 len = ids.length;
        for (uint i = 0; i < len; i++) {
            if (tpftPaused[ids[i]]) {
                revert TPFtIsPaused();
            }
        }
    }

    /**
     * Função interna que é chamada antes da transferência de TPFt ocorrer.
     * Sua funcionalidade é realizar verificações adicionais antes da transferência.
     * @param from Endereço de origem.
     * @param to Endereço de destino .
     * @param ids Array com os TPFtIds transferidos.
     * @param values Array com as quantidades dos TPFts a serem transferidos.
     */
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    )
        internal
        virtual
        override
        whenNotPaused
        frozenBalanceAnalyzing(from, ids, values)
        onlyRole(OPERATION_ROLE)
    {
        TpftIdPauseValidation(ids);
        super._update(from, to, ids, values);
    }

    /**
     * Verificar se um contrato implementa uma interface específica
     * @dev O identificador da interface é um hash das assinaturas das funções que compõem a interface
     * @param interfaceId identificador da interface
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
