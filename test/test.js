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
  "0x04b4c8ad42e323d638eb6ab1aef32fd0b7a27243e2139aef8cebbbbc50ce38df",
  "0x014dc7d7b6d2ea2a3c0173bb0450e52fe09fa349346862434d98fbb108f07e83",
  1
)