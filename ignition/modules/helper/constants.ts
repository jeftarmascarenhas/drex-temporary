import { ethers } from "hardhat";
/**
 * CONTRACTS
 */
export const REAL_DIGITAL_CONTRACT = ethers.id("RealDigital");
export const REAL_DIGITAL_DEFAULT_CONTRACT = ethers.id(
  "RealDigitalDefaultAccount"
);
export const SWAP_ONE_STEP_FROM_NAME = ethers.id("SwapOneStepFrom");

export const TPFT_CONTRACT = ethers.id("TPFt");
export const TPFT_OPERATION_1002_CONTRACT = ethers.id("TPFtOperation1002");
export const TPFT_OPERATION_ID_CONTRACT = ethers.id("TPFtOperationIdStorage");
export const PUBLIC_BOND_DVP_CONTRACT = ethers.id("PublicBondDvP");

/**
 * ROLES
 */
// Real Digital
export const DEFAULT_ADMIN_ROLE = ethers.ZeroHash;
export const REAL_DIGITAL = ethers.id("REAL_DIGITAL");
export const PAUSER_ROLE = ethers.id("PAUSER_ROLE");
export const MINTER_ROLE = ethers.id("MINTER_ROLE");
export const ACCESS_ROLE = ethers.id("ACCESS_ROLE");
export const MOVER_ROLE = ethers.id("MOVER_ROLE");
export const BURNER_ROLE = ethers.id("BURNER_ROLE");
export const FREEZER_ROLE = ethers.id("FREEZER_ROLE");
// TPFt
export const OPERATION_ROLE = ethers.id("OPERATION_ROLE");
export const REPAYMENT_ROLE = ethers.id("REPAYMENT_ROLE");
export const AUCTION_PLACEMENT_ROLE = ethers.id("AUCTION_PLACEMENT_ROLE");

export const CBDC_ACCESS_ROLE_LIST = [
  DEFAULT_ADMIN_ROLE,
  PAUSER_ROLE,
  MINTER_ROLE,
  ACCESS_ROLE,
  MOVER_ROLE,
  BURNER_ROLE,
];
