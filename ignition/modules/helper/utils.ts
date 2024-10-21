import { AccountRuntimeValue } from "@nomicfoundation/ignition-core";
import { ethers } from "hardhat";

export function getAccounts(
  numbersAccounts: number,
  getAccount: (accountIndex: number) => AccountRuntimeValue
): AccountRuntimeValue[] {
  return Array.from({ length: numbersAccounts }, (_, index) =>
    getAccount(index)
  );
}

export function realParseUnits(amount = 100) {
  return ethers.parseUnits(amount.toString(), 2);
}
