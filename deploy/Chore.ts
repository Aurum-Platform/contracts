import { ethers } from 'hardhat';

async function main() {
    const clientAddress = '0x84E6A80BB81f236f3Ba8E8A92604aAD9cCE545C9';
    const aurumAddress = '0x532dFde42Cf3F2286B0B8223E22CdaBE45249F46';
    const ClientContract = await ethers.getContractAt('AurumClient', clientAddress);
    const AurumContract = await ethers.getContractAt('AurumV2core', aurumAddress);

    const tx = await AurumContract.setAurumClient(clientAddress);
    await tx.wait();
    const tx1 = await ClientContract.setAurumAddress(aurumAddress);
    await tx1.wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });