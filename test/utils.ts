import { config, network } from "hardhat";

export const forkToMatic = async () => {
  const matic = config.networks.matic;
  console.log("### switch to forking matic ###");
  await network.provider.request({
    method: "hardhat_reset",
    params: [
      {
        forking: {
          jsonRpcUrl: matic.forking.url,
          blockNumber: matic.forking.blockNumber,
        },
      },
    ],
  });
};
