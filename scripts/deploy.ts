import { ethers } from "hardhat";
import { AUTOMATION } from "../test/constants";

async function main() {
  const DCA = await ethers.getContractFactory("DcaCash");
  const dca = await DCA.deploy(AUTOMATION);
  return { dca };
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
