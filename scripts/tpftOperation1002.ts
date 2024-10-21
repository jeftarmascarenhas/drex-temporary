import { ethers } from "hardhat";
import { OPERATION_ROLE } from "../ignition/modules/helper";
// change DrexLocalID1 to correct deployment folder
import deployedAddresses from "../ignition/deployments/DrexLocalID1/deployed_addresses.json";
import { publicBonds } from "../typechain-types/contracts";

const STN_CNPJ8 = 394460;
const BANK_A_CNPJ8 = 12392;

const tpftData = {
  acronym: "LTN",
  code: "12312",
  // Ex: const date = new Date("2023-09-26"); Math.floor(date.getTime() / 1000); retorno 1695686400
  // maturityDate: Math.ceil(new Date(new Date().setMonth(11)).getTime() / 1000),
  maturityDate: 1734789963,
};

const tpftAmount = 10000n;

const realAmount = 100n * 10000n;

async function getAccounts() {
  const [admin, authority, stn, bankA] = await ethers.getSigners();

  return {
    admin,
    authority,
    stn,
    bankA,
  };
}

async function deployFixture() {
  const { admin, authority, stn, bankA } = await getAccounts();

  const addressDiscovery = await ethers.getContractAt(
    "AddressDiscovery",
    deployedAddresses["DrexModule#AddressDiscovery"]
  );
  const tpft = await ethers.getContractAt(
    "TPFt",
    deployedAddresses["DrexModule#TPFt"]
  );
  const real = await ethers.getContractAt(
    "RealDigital",
    deployedAddresses["DrexModule#RealDigital"]
  );
  const realDigitalDefaultAccount = await ethers.getContractAt(
    "RealDigitalDefaultAccount",
    deployedAddresses["DrexModule#RealDigitalDefaultAccount"]
  );
  const publicBondDvP = await ethers.getContractAt(
    "PublicBondDvP",
    deployedAddresses["DrexModule#PublicBondDvP"]
  );

  const tpftOperation1002 = await ethers.getContractAt(
    "TPFtOperation1002",
    deployedAddresses["DrexModule#TPFtOperation1002"]
  );

  return {
    admin,
    authority,
    stn,
    bankA,
    addressDiscovery,
    tpft,
    real,
    realDigitalDefaultAccount,
    publicBondDvP,
    tpftOperation1002,
  };
}

async function addRealDigitalDefaultAccount() {
  console.log("Running Real Digital Default Account scripts");

  const { realDigitalDefaultAccount, real, authority, stn, bankA } =
    await deployFixture();

  await (
    await realDigitalDefaultAccount
      .connect(authority)
      .addDefaultAccount(STN_CNPJ8, stn.address)
  ).wait();

  console.log(
    "SNT real digital verifyAccount: ",
    await real.verifyAccount(stn.address)
  );

  console.log(
    "GET STN => ",
    await realDigitalDefaultAccount.defaultAccount(STN_CNPJ8)
  );

  await (
    await realDigitalDefaultAccount
      .connect(authority)
      .addDefaultAccount(BANK_A_CNPJ8, bankA.address)
  ).wait();

  console.log(
    "Bank A real digital verifyAccount: ",
    await real.verifyAccount(bankA.address)
  );

  console.log(
    "IT IS stn cnpj to address",
    (await realDigitalDefaultAccount.defaultAccount(STN_CNPJ8)) == stn.address
  );
}

async function addRealDigital() {
  console.log("Running Real Digital scripts");
  const { real, authority, bankA, publicBondDvP } = await deployFixture();

  await (await real.connect(authority).mint(bankA.address, realAmount)).wait();
  await (
    await real.connect(bankA).approve(publicBondDvP.target, realAmount)
  ).wait();

  console.log(
    "Grant Real Allowance to publicBondDvP => ",
    await real.allowance(bankA.address, publicBondDvP.target)
  );
}

async function addTPFt() {
  console.log("Running TPFt scripts");
  const { tpft, bankA, admin, stn, publicBondDvP } = await deployFixture();

  await (await tpft.enableAddress(stn.address)).wait();
  await (await tpft.enableAddress(bankA.address)).wait();

  await (
    await tpft.connect(stn).setApprovalForAll(publicBondDvP.target, true)
  ).wait();

  await (await tpft.createTPFt(tpftData)).wait();
  await (
    await tpft.connect(admin).mint(stn.address, tpftData, tpftAmount)
  ).wait();
  console.log(" OPERATION_ROLE => ", OPERATION_ROLE);
  await (await tpft.grantRole(OPERATION_ROLE, publicBondDvP.target)).wait();
  // const tpftIds = await tpft.tpftIds();
  // const tpftId = await tpft.getTPFtId(tpftData);
}

async function addTPFtOperation1002() {
  const { tpftOperation1002, stn, bankA, publicBondDvP, real, tpft } =
    await deployFixture();

  const params = {
    operationId: 121112024,
    cnpj8Sender: STN_CNPJ8,
    cnpj8Receiver: BANK_A_CNPJ8,
    tpftData,
    tpftAmount,
    unitPrice: 2 * 10 ** 8,
  };

  /**
   * Quando o cedente está transmitindo o comando da operação.
   */
  const callerPartBySender = 0n;
  /**
   * Quando o cessionário está transmitindo o comando da operação.
   */
  const callerPartByReceiver = 1n;

  await tpftOperation1002
    .connect(stn)
    .auctionPlacement(
      params.operationId,
      params.cnpj8Sender,
      params.cnpj8Receiver,
      callerPartBySender,
      params.tpftData,
      params.tpftAmount,
      params.unitPrice
    );

  const dvpParticipantOps = await publicBondDvP.dvpParticipantOps(
    params.operationId
  );

  await tpftOperation1002
    .connect(bankA)
    .auctionPlacement(
      params.operationId,
      params.cnpj8Sender,
      params.cnpj8Receiver,
      callerPartByReceiver,
      params.tpftData,
      params.tpftAmount,
      params.unitPrice
    );

  console.log("STN real => ", await real.balanceOf(stn.address));
  console.log("STN TPFt => ", await tpft.balanceOf(stn.address, 1n));

  console.log("Bank real => ", await real.balanceOf(bankA.address));
  console.log("Bank TPFt => ", await tpft.balanceOf(bankA.address, 1n));
}

async function main() {
  const { stn, bankA } = await getAccounts();
  await addRealDigitalDefaultAccount();

  await addRealDigital();

  await addTPFt();

  await addTPFtOperation1002();
}

main().catch(console.error);
