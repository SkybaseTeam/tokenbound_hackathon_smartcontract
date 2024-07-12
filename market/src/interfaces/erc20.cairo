use starknet::ContractAddress;

#[starknet::interface]
trait IERC20<TContractState> {
    fn allowance(
        ref self: TContractState,
        owner: ContractAddress,
        spender: ContractAddress,
    ) -> u256;
    fn transferFrom(
        ref self: TContractState,
        sender: ContractAddress,
        recipient: ContractAddress,
        amount: u256,
    );
}