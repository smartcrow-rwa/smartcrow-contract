const hre = require("hardhat")

async function deploySenderFundsContract(chainId) {
    try {
        // Get the ContractFactory of your SenderFundsContract
        const SenderFundsContract = await hre.ethers.getContractFactory("SenderFundsContract");
    
        // Deploy the contract
        const contract = await SenderFundsContract.deploy(
          // "0x79c950c7446b234a6ad53b908fbf342b01c4d446", // Goerli USDT Token
          // "0x79c950c7446b234a6ad53b908fbf342b01c4d446", // Goerli USDC Token 
          // "0x79c950c7446b234a6ad53b908fbf342b01c4d446", // Goerli WBTC Token
          // "0x2899a03ffDab5C90BADc5920b4f53B0884EB13cC", // Goerli DAI Token
          // "0x79c950c7446b234a6ad53b908fbf342b01c4d446"  // Goerli WETH Token

          // // Polygon Amoy testnet

          // "0x1616d425cd540b256475cbfb604586c8598ec0fb",
          // "0xc091020dD0e357989f303FC99ac5899fa343fF6D",
          // "0xD0b33a7aCb9303D9FE2de7ba849ec9b96A4C10C1",
          // "0xb2df85a09cAB3a391Fd9ade76342583A0d4B75ce",
          // "0x52eF3d68BaB452a294342DC3e5f464d7f610f72E"

          // polygon POS mainnet
          // "0xc2132D05D31c914a87C6611C10748AEb04B58e8F",
          // "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
          // "0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6",
          // "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063",
          // "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619"

          // Aribitrum sepolia testnet - USDC only
          "0xf3c3351d6bd0098eeb33ca8f830faf2a141ea2e1",
          "0xf3c3351d6bd0098eeb33ca8f830faf2a141ea2e1",
          "0xf3c3351d6bd0098eeb33ca8f830faf2a141ea2e1",
          "0xf3c3351d6bd0098eeb33ca8f830faf2a141ea2e1",
          "0xf3c3351d6bd0098eeb33ca8f830faf2a141ea2e1"

          // "0xBD21A10F619BE90d6066c941b04e340841F1F989",
          // "0x0fa8781a83e46826621b3bc094ea2a0212e71b23",
          // "0x2F0B22371365fED3E961DAFAD61729beE7EF8a4A",
          // "0x001b3b4d0f3714ca98ba10f6042daebf0b1b7b6f",
          // "0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa",
          
          //polygon zkevm
          // "0x1E4a5963aBFD975d8c9021ce480b42188849D41d",
          // "0xA8CE8aee21bC2A48a5EF670afCc9274C7bbbC035",
          // "0xEA034fb02eB1808C2cc3adbC15f447B93CbE08e1",
          // "0xC5015b9d9161Dca7e18e32f6f25C4aD850731Fd4",
          // "0x4F9A0e7FD2Bf6067db6994CF12E4495Df938E6e9"

          // OPtimism tokens
          // "0x94b008aa00579c1307b0ef2c499ad98a8ce58e58",
          // "0x0b2c639c533813f4aa9d7837caf62653d097ff85",
          // "0x68f180fcce6836688e9084f035309e29bf0a2095",
          // "0xda10009cbd5d07dd0cecc66161fc93d7c9000da1",
          // "0x4200000000000000000000000000000000000006"
        );
    
        // Wait for the deployment transaction to be mined
        await contract.deployed();
    
        console.log(`SenderFundsContract deployed to: ${contract.address}`);
      } catch (error) {
        console.error(error);
        process.exit(1);
      }
}

module.exports = {
    deploySenderFundsContract,
}
