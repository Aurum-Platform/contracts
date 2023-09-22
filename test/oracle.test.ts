import { expect, use } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { AurumOracle, AurumOracle__factory } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

use(solidity);

describe("AurumOracle Contract", function () {
  let AurumOracle: AurumOracle__factory;
  let aurumOracle: AurumOracle;
  let owner: SignerWithAddress;
  let server: any;

  beforeEach(async function () {
    let mnemonic = "radar blur cabbage chef fix engine embark joy scheme fiction master release";
    server = ethers.Wallet.fromMnemonic(mnemonic);
    [owner] = await ethers.getSigners();
    AurumOracle = await ethers.getContractFactory("AurumOracle");
    aurumOracle = await AurumOracle.connect(owner).deploy();
    await aurumOracle.deployed();
  });

  it("should verify and set value", async function () {
    // Simulate fetching an integer value
    const integerValue: any = ethers.utils.parseEther('0.0001');
    const tokenContract: string = "0x7a5DeA9A956935c34A7676E5182C3Db25C8e0142"

    // Create the data packet
    const dataPacket = {
      request: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("IntegerRequest")),
      deadline: Math.floor(Date.now() / 1000) + 600, // 10 minutes in the future
      payload: ethers.utils.defaultAbiCoder.encode(["uint256"], [integerValue]),
      tokenContract: tokenContract,
    };

    // Generate the signature
    const domain = {
      name: "AurumOracle",
      version: "1",
      chainId: (await ethers.provider.getNetwork()).chainId,
      verifyingContract: aurumOracle.address,
    };

    const types = {
      VerifyPacket: [
        { name: "request", type: "bytes32" },
        { name: "deadline", type: "uint256" },
        { name: "payload", type: "bytes" },
        { name: "tokenContract", type: "address" },
      ],
    };

    // Sign the encoded data packet
    const signature = await server._signTypedData(domain, types, dataPacket);
    console.log(dataPacket, signature, server.address);
    
    await aurumOracle.connect(owner).setIsTrusted(server.address, true);

    // Call the verifyAndSetValue function
    const tx = await aurumOracle.verifyAndSetValue(
      dataPacket.request,
      // Contraact will ignore tokenContract field and will only take required fields
      dataPacket,
      tokenContract,
      signature
    );
    await tx.wait();

    const floorPrice = await aurumOracle.getNFTFloorPrice(tokenContract);
    expect(floorPrice).to.be.eq(integerValue);
  });
});
