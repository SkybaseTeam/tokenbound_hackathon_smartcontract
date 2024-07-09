import {
    RpcProvider,
    Account,
    Contract,
    CallData
  } from "starknet";
  import "dotenv/config.js";
  const provider = new RpcProvider({
    nodeUrl: "",
  });
  
  const main = async () => {
    const account = new Account(
      provider,
      process.env.ACCOUNT_ADDRESS,
      process.env.PRIVATE_KEY
    );
    const publicKey = await account.signer.getPubKey();
    console.log("Account connected successfully with public key: ", publicKey);
  
    const { abi: contractAbi } = await provider.getClassAt(process.env.CONTRACT_ADDRESS);
    if (contractAbi == undefined) {
      console.log("Contract not found");
      return;
    }
  
    const contractView = new Contract(contractAbi, process.env.CONTRACT_ADDRESS, provider);
    contractView.connect(account); 
    const allowance = await contractView.allowance(process.env.ACCOUNT_ADDRESS, process.env.CONTRACT_ADDRESS);
    console.log(allowance);
  
    // const call = await account.execute({
    //   contractAddress: process.env.CONTRACT_ADDRESS,
    //   entrypoint: "balanceOf",
    //   calldata: CallData.compile({
    //     account: process.env.ACCOUNT_ADDRESS,
    //   })
    // })
    // console.log("Balance of account: ", call);
  };
  
  main();
  