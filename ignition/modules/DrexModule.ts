import { buildModule } from "@nomicfoundation/ignition-core";
import { getAccounts } from "./helper/utils";
import {
  ACCESS_ROLE,
  PUBLIC_BOND_DVP_CONTRACT,
  REAL_DIGITAL_CONTRACT,
  REAL_DIGITAL_DEFAULT_CONTRACT,
  SWAP_ONE_STEP_FROM_NAME,
  TPFT_CONTRACT,
  TPFT_OPERATION_1002_CONTRACT,
  TPFT_OPERATION_ID_CONTRACT,
} from "./helper";

const DrexModule = buildModule("DrexModule", (module) => {
  const [admin, authority, stn, bankA] = getAccounts(7, module.getAccount);

  const addressDiscovery = module.contract("AddressDiscovery", [
    authority,
    admin,
  ]);

  const name = "Real Digital";
  const symbol = "BRL";

  const realDigital = module.contract("RealDigital", [
    name,
    symbol,
    authority,
    admin,
  ]);

  const realDigitalDefaultAccount = module.contract(
    "RealDigitalDefaultAccount",
    [realDigital, authority, admin]
  );

  const swapOneStepFrom = module.contract("SwapOneStepFrom", [
    admin,
    authority,
    realDigital,
  ]);

  const publicBondDvP = module.contract("PublicBondDvP", [addressDiscovery]);

  const tpft = module.contract("TPFt", [addressDiscovery]);

  const tpftOperationIdStorage = module.contract("TPFtOperationIdStorage");

  const tpftOperation1002 = module.contract("TPFtOperation1002", [
    addressDiscovery,
  ]);

  // const STN_CNPJ8 = 394460;
  // grant role to Real Digital Default Account
  module.call(
    realDigital,
    "grantRole",
    [ACCESS_ROLE, realDigitalDefaultAccount],
    {
      from: admin,
    }
  );

  module.call(
    addressDiscovery,
    "updateAddress",
    [REAL_DIGITAL_CONTRACT, realDigital],
    {
      id: "updateAddress1",
      from: authority,
    }
  );

  // Update Address Discovery
  module.call(
    addressDiscovery,
    "updateAddress",
    [REAL_DIGITAL_DEFAULT_CONTRACT, realDigitalDefaultAccount],
    {
      from: authority,
      id: "updateAddress2",
    }
  );

  module.call(
    addressDiscovery,
    "updateAddress",
    [SWAP_ONE_STEP_FROM_NAME, swapOneStepFrom],
    {
      id: "swapOneStepFrom",
    }
  );

  module.call(addressDiscovery, "updateAddress", [TPFT_CONTRACT, tpft], {
    id: "TPFt1",
  });

  module.call(
    addressDiscovery,
    "updateAddress",
    [PUBLIC_BOND_DVP_CONTRACT, publicBondDvP],
    {
      id: "publicBondDvP1",
    }
  );

  module.call(
    addressDiscovery,
    "updateAddress",
    [TPFT_OPERATION_1002_CONTRACT, tpftOperation1002],
    {
      id: "TPFtOperation1002ID1",
    }
  );

  module.call(
    addressDiscovery,
    "updateAddress",
    [TPFT_OPERATION_ID_CONTRACT, tpftOperationIdStorage],
    {
      id: "tpftOperationIdStorageID1",
    }
  );

  return {
    addressDiscovery,
    realDigital,
    realDigitalDefaultAccount,
    swapOneStepFrom,
    tpftOperation1002,
    tpftOperationIdStorage,
  };
});

export default DrexModule;
