const { ethers } = require('ethers');

const abi = [
    {
      "inputs": [],
      "stateMutability": "nonpayable",
      "type": "constructor"
    },
    {
      "inputs": [],
      "name": "Trustus__InvalidPacket",
      "type": "error"
    },
    {
      "inputs": [],
      "name": "DOMAIN_SEPARATOR",
      "outputs": [
        {
          "internalType": "bytes32",
          "name": "",
          "type": "bytes32"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "tokenContract",
          "type": "address"
        }
      ],
      "name": "getNFTFloorPrice",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "signer",
          "type": "address"
        },
        {
          "internalType": "bool",
          "name": "isTrusted_",
          "type": "bool"
        }
      ],
      "name": "setIsTrusted",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "name": "tokenPacket",
      "outputs": [
        {
          "internalType": "bytes32",
          "name": "request",
          "type": "bytes32"
        },
        {
          "internalType": "uint256",
          "name": "deadline",
          "type": "uint256"
        },
        {
          "internalType": "bytes",
          "name": "payload",
          "type": "bytes"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "bytes32",
          "name": "request",
          "type": "bytes32"
        },
        {
          "components": [
            {
              "internalType": "bytes32",
              "name": "request",
              "type": "bytes32"
            },
            {
              "internalType": "uint256",
              "name": "deadline",
              "type": "uint256"
            },
            {
              "internalType": "bytes",
              "name": "payload",
              "type": "bytes"
            }
          ],
          "internalType": "struct AurumOracle.PricePacket",
          "name": "packet",
          "type": "tuple"
        },
        {
          "internalType": "address",
          "name": "tokenContract",
          "type": "address"
        },
        {
          "internalType": "bytes",
          "name": "signature",
          "type": "bytes"
        }
      ],
      "name": "verifyAndSetValue",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ];

function main() {
    const send = async () => {
        const provider = new ethers.providers.JsonRpcProvider('https://polygon-mumbai.g.alchemy.com/v2/G7GJP6uisv80k4LTBdYIn2Vi0cbJq-zt');
        const wallet = new ethers.Wallet('695443873d058db7e263d01779d068b2fdb1863556ad7d14c953de97dbe35119', provider);
        const contract = new ethers.Contract('0x8A4AA4679EB53507023F74897aE3A8570fa224ca', abi, wallet);
        const dataPacket = {
            request: '0x084c4e70d56fa9ab6c88240cf9849b6407cf6d56779ba67c47b3329fdaaca5bf',
            deadline: 1692788874,
            payload: '0x00000000000000000000000000000000000000000000000000005af3107a4000',
            tokenContract: '0x7a5DeA9A956935c34A7676E5182C3Db25C8e0142'
          };

        const signature = '0x2be2483b6554b475f731aed9dea18a4899aa54fade83e816294a3ac8eeecbb0a6317c1b076f9a9a18261f241dc94ccbed91db24f2f9b68d42b4fa16d27b337971c'

        // Call the verifyAndSetValue function
        const tx = await contract.verifyAndSetValue(
            dataPacket.request,
            // Contraact will ignore tokenContract field and will only take required fields
            dataPacket,
            dataPacket.tokenContract,
            signature
          );
          await tx.wait();
    }
    send();
}

main();