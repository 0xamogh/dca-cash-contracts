import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";
import {
  AUTOMATION,
  DAI_ADDRESS,
  DAY,
  MATIC_ADDRESS,
  MATIC_WHALE,
  USDC_ADDRESS,
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
      this.timeout(100000000);
      let tx;

      let { dca } = await loadFixture(deployDcaCash);
      const timedAllowance = await dca.timedAllowance();
      const whale = await ethers.getImpersonatedSigner(MATIC_WHALE);

      const approveAmount = ethers.utils.parseUnits("100000", "mwei");
      const inputAmount = ethers.utils.parseUnits("100", "mwei");
      console.log("🚀 ~ file: DcaCash.test.ts:35 ~ inputAmount", inputAmount);
      const dai = new Contract(USDC_ADDRESS, erc20Abi, whale);

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

      console.log("dai balance", await dai.balanceOf(MATIC_WHALE));

      console.log("Gas used :", tx.gasPrice.toString());

      dca = await dca.connect(whale);

      tx = await dca.createTask(USDC_ADDRESS, MATIC_ADDRESS, inputAmount, DAY, {
        //@ts-ignore
        value: "10000000000000000000",
      });
      const id = await tx.wait();

      //@ts-ignore
      console.log("🚀 ~ file: DcaCash.test.ts:41 ~ id", id.txHash);
      console.log("Gas used :", tx.gasPrice!.toString());
      let dedicatedSenderAddress = await dca.dedicatedMsgSender();
      console.log("dedicatedMsgSender is ", dedicatedSenderAddress);

      const dedicatedSender = await ethers.getImpersonatedSigner(
        dedicatedSenderAddress
      );

      tx = await whale.sendTransaction({
        to: dedicatedSenderAddress,
        value: ethers.utils.parseEther("2"),
      });
      await tx.wait();
      console.log("Balance :", (await dedicatedSender.getBalance()).toString());

      dca = await dca.connect(dedicatedSender);

      const wmatic = new Contract(MATIC_ADDRESS, erc20Abi, dedicatedSender);
      const prevBalance = await wmatic.balanceOf(whale.address);
      tx = await dca.executeSwap(
        whale.address,
        USDC_ADDRESS,
        MATIC_ADDRESS,
        inputAmount
      );
      await tx.wait();
      console.log(
        "Output :",
        ethers.utils.formatEther(
          (await wmatic.balanceOf(whale.address)).sub(prevBalance)
        )
      );

      console.log("Gas used :", tx.gasPrice!.toString());
    });
  });
});
