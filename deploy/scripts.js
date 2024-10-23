const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Deploy contract
  const StableCoin = await ethers.getContractFactory("automatedStablecoin");
  const stablecoin = await StableCoin.deploy(
    process.env.PYTH_NETWORK_ADDRESS,
    process.env.PRICE_FEED_ID
  );

  await stablecoin.deployed();

  console.log("Contract deployed to:", stablecoin.address);
  await stablecoin.deployTransaction.wait(5);

  // Verify contract on Etherscan
  console.log("Verifying contract on Etherscan...");
  await hre.run("verify:verify", {
    address: stablecoin.address,
    constructorArguments: [
      process.env.PYTH_NETWORK_ADDRESS,
      process.env.PRICE_FEED_ID,
    ],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
