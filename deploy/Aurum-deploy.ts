import { ethers } from 'hardhat';
import dotenv from 'dotenv';

dotenv.config(); // Load environment variables from .env file

async function main() {
    const AurumContract = await ethers.getContractFactory('AurumV2core');
    const aurumcontract = await AurumContract.deploy(
        500,
        400,
        5000
    );

    await aurumcontract.deployed();
    console.log(
        `The Aurum contract address is ${aurumcontract.address}`
      );
    return;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// The Aurum contract address is 0x532dFde42Cf3F2286B0B8223E22CdaBE45249F46