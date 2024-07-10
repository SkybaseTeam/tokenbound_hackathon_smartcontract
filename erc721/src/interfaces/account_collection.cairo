use starknet::{
    ContractAddress, ClassHash
};

#[starknet::interface]
trait IAccountCollection<TContractState> {
    fn get_sum_pool(self: @TContractState) -> Array<u256>;
    fn token_uri(self: @TContractState, token_id: u256) -> Span<felt252>;
    fn up_time(ref self: TContractState, pool: u8, time: u64);
    fn up_supply(ref self: TContractState, pool: u8, supply: u256);
    fn up_mint_max(ref self: TContractState, pool: u8, supply: u256);
    fn up_price(ref self: TContractState, pool: u8, price: u256);
    fn mint_nft(ref self: TContractState, contract_address: ContractAddress, pool_mint: u8)->u256;
    fn get_remaining_mint(self: @TContractState, pool_mint: u8) -> u256;
    fn get_mint_max(self: @TContractState, pool_mint: u8) -> u256;
    fn get_total_supply(self: @TContractState, pool_mint: u8) -> u256;
    fn get_mint_price(self: @TContractState, pool_mint: u8) -> u256;
    fn mint_public(ref self: TContractState, total: u256, pool_mint: u8, to: ContractAddress);
    fn burn(ref self: TContractState, token_id: u256);
    fn claim(ref self: TContractState);
    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);
}

#[starknet::interface]
trait IAccountCollectionCamel<TContractState> {
    fn getSumPool(self: @TContractState) -> Array<u256>;
    fn tokenUri(self: @TContractState, token_id: u256) -> Span<felt252>;
    fn upTime(ref self: TContractState, pool: u8, time: u64);
    fn upSupply(ref self: TContractState, pool: u8, supply: u256);
    fn upMintMax(ref self: TContractState, pool: u8, supply: u256);
    fn upPrice(ref self: TContractState, pool: u8, price: u256);
    fn mintNft(ref self: TContractState, contract_address: ContractAddress, pool_mint: u8)->u256;
    fn getRemainingMint(self: @TContractState, pool_mint: u8) -> u256;
    fn getMintMax(self: @TContractState, pool_mint: u8) -> u256;
    fn getTotalSupply(self: @TContractState, pool_mint: u8) -> u256;
    fn getMintPrice(self: @TContractState, pool_mint: u8) -> u256;
    fn mintPublic(ref self: TContractState, total: u256, pool_mint: u8, to: ContractAddress);
}