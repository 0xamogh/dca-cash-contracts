import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";
import {
  AUTOMATION,
  DAI_ADDRESS,
  DAY,
  MATIC_ADDRESS,
  MATIC_WHALE,
} from "./constants";
import { Contract } from "ethers";
import { forkToMatic } from "./utils";
import erc20Abi from "./abi/erc20.abi.json";

describe("TWAPPriceGetter", function () {
  async function deployDcaCash() {
    const DCA = await ethers.getContractFactory("DcaCash");
    const dca = await DCA.deploy(AUTOMATION);
    return { dca };
  }

  describe("Deployment", function () {
    beforeEach(forkToMatic);

    it("Create task", async function () {
      let tx;

      let { dca } = await loadFixture(deployDcaCash);
      const timedAllowance = await dca.timedAllowance();
      const whale = await ethers.getImpersonatedSigner(MATIC_WHALE);

      const approveAmount = ethers.utils.parseEther("100000");
      const inputAmount = ethers.utils.parseEther("100");
      const dai = new Contract(DAI_ADDRESS, erc20Abi, whale);

      console.log(
        "🚀 ~ file: DcaCash.test.ts:36 ~ timedAllowance",
        timedAllowance
      );
      tx = await dai.approve(timedAllowance, approveAmount);
      await tx.wait();

      console.log(
        "dai allowance",
        await dai.allowance(MATIC_WHALE, timedAllowance)
      );

      console.log("Gas used :", tx.gasPrice.toString());

      dca = await dca.connect(whale);

      tx = await dca.createTask(DAI_ADDRESS, MATIC_ADDRESS, inputAmount, DAY, {
        //@ts-ignore
        value: inputAmount,
      });
      const id = await tx.wait();

      //@ts-ignore
      console.log("🚀 ~ file: DcaCash.test.ts:41 ~ id", id);
      console.log("Gas used :", tx.gasPrice!.toString());
      console.log("dedicatedMsgSender is ", await dca.dedicatedMsgSender());
    });
  });
});
