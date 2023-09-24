import { ethers } from 'hardhat';
import dotenv from 'dotenv';

dotenv.config(); // Load environment variables from .env file

async function main() {
    const ClientContract = await ethers.getContractFactory('AurumClient');
    const clientcontract = await ClientContract.deploy(
        '0x01FeDA43882AB7d1f3fcB79ae8e4EF90BE2ab1a0',
        "5de8f4ceac3e4615bdb2ba4604418d61"
    );

    await clientcontract.deployed();
    console.log(
        `The Client contract address is ${clientcontract.address}`
      );
    return;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// The Client contract address is 0x84E6A80BB81f236f3Ba8E8A92604aAD9cCE545C9