use starknet::ContractAddress;

#[starknet::interface]
trait IERC721<TContractState> {
    fn owner_of(ref self: TContractState, token_id: u256) -> ContractAddress;
    fn get_approved(ref self: TContractState, token_id: u256) -> ContractAddress;
    
    fn transfer_from(
        ref self: TContractState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
    );

    fn transferFrom(
        ref self: TContractState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
    );
}