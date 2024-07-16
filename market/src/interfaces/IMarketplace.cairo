use starknet::ContractAddress;
#[starknet::interface]
trait IMarketplace<TContractState> {
    fn get_status(self: @TContractState, token_address: ContractAddress, token_id: u256) -> bool;
    fn get_price(self: @TContractState, token_address: ContractAddress, token_id: u256) -> u256;
    fn buy_nft(ref self: TContractState, token_address: ContractAddress, token_id: u256, eth_address: ContractAddress);
    fn listing_nft(ref self: TContractState, token_address: ContractAddress, token_id: u256, price: u256);
    fn cancel_nft(ref self: TContractState, token_address: ContractAddress, token_id: u256);
}

#[starknet::interface]
trait IMarketplaceCamel<TContractState> {
    fn getStatus(self: @TContractState, token_address: ContractAddress, token_id: u256) -> bool;
    fn getPrice(self: @TContractState, token_address: ContractAddress, token_id: u256) -> u256;
    fn buyNft(ref self: TContractState, token_address: ContractAddress, token_id: u256, eth_address: ContractAddress);
    fn listingNft(ref self: TContractState, token_address: ContractAddress, token_id: u256, price: u256);
    fn cancelNft(ref self: TContractState, token_address: ContractAddress, token_id: u256);
}