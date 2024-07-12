use starknet::ContractAddress;
#[starknet::interface]
trait IMarketplace<TContractState> {
    fn buy_nft(ref self: TContractState, token_address: ContractAddress, token_id: u256);
    fn listing_nft(ref self: TContractState, token_address: ContractAddress, token_id: u256, price: u256);
    fn cancel_nft(ref self: TContractState, token_address: ContractAddress, token_id: u256);
}

#[starknet::interface]
trait IMarketplaceCamel<TContractState> {
    fn buyNft(ref self: TContractState, token_address: ContractAddress, token_id: u256);
    fn listingNft(ref self: TContractState, token_address: ContractAddress, token_id: u256, price: u256);
    fn cancelNft(ref self: TContractState, token_address: ContractAddress, token_id: u256);
}