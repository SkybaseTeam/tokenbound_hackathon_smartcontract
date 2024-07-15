use starknet::ContractAddress;

#[starknet::interface]
trait Token<TContractState> {
    fn get_minted(self: @TContractState, account_contract: ContractAddress) -> u256;
    fn mint(ref self: TContractState, message_hash: felt252, signature_r: felt252, signature_s: felt252);
    fn change_mint_point(ref self: TContractState, new_achievement_point: u256);
}

#[starknet::interface]
trait TokenCamel<TContractState> {
    fn getMinted(self: @TContractState, account_contract: ContractAddress) -> u256;
    fn changeMintPoint(ref self: TContractState, new_achievement_point: u256);
}