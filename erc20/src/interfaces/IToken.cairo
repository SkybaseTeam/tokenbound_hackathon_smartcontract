use starknet::ContractAddress;

#[starknet::interface]
trait IToken<TContractState> {
    fn get_minted(self: @TContractState, account_contract: ContractAddress) -> u128;
    fn mint(ref self: TContractState, message_hash: felt252, signature_r: felt252, signature_s: felt252);
    fn change_mint_point(ref self: TContractState, new_achievement_point: u256);
}

#[starknet::interface]
trait ITokenCamel<TContractState> {
    fn getMinted(self: @TContractState, account_contract: ContractAddress) -> u128;
    fn changeMintPoint(ref self: TContractState, new_achievement_point: u256);
}