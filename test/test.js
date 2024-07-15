import { 
  ec,
  num
} from "starknet";
import { poseidonHashMany } from "@scure/starknet";

const SignMint = async (contract, account, achievement_index) => {
    const privateSign = "0x024d59610984eadcb879a4d16c6bca4bbf85a5a54731363fb7cb4b2c2d9c2057";
    const message = [
        num.toBigInt(contract),
        num.toBigInt(account),
        num.toBigInt(achievement_index),
    ];
    const msgHash = num.toHex(poseidonHashMany(message));
    const signature = ec.starkCurve.sign(msgHash, privateSign);
    console.log(msgHash);
    console.log(String(signature.r));
    console.log(String(signature.s));

    return [msgHash, signature.r, signature.s];
}
SignMint(
  "0x060efe1b9e278850bc72074652795fdc32f6904de3d99762562b0aabf94e2c32",
  "0x05fE8F79516C123e8556eA96bF87a97E7b1eB5AbdBE4dbCD993f3FB9A6F24A66",
  1
)