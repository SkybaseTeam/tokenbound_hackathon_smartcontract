use starknet::ContractAddress;
use starknet::ClassHash;
use starknet::account::Call;

// SRC5 interface for token bound accounts
const TBA_INTERFACE_ID: felt252 = 0xd050d1042482f6e9a28d0c039d0a8428266bf4fd59fe95cee66d8e0e8b3b2e;

#[starknet::interface]
trait IAccount<TContractState> {
    fn is_valid_signature(
        self: @TContractState, hash: felt252, signature: Span<felt252>
    ) -> felt252;
    fn is_valid_signer(self: @TContractState, signer: ContractAddress) -> felt252;
    fn __validate__(ref self: TContractState, calls: Array<Call>) -> felt252;
    fn __validate_declare__(self: @TContractState, class_hash: felt252) -> felt252;
    fn __validate_deploy__(
        self: @TContractState, class_hash: felt252, contract_address_salt: felt252
    ) -> felt252;
    fn __execute__(ref self: TContractState, calls: Array<Call>) -> Array<Span<felt252>>;
    fn token(self: @TContractState) -> (ContractAddress, u256);
    fn owner(self: @TContractState) -> ContractAddress;
    fn lock(ref self: TContractState, duration: u64);
    fn is_locked(self: @TContractState) -> (bool, u64);
    fn supports_interface(self: @TContractState, interface_id: felt252) -> bool;
    fn change_owner(ref self: TContractState, token_address: ContractAddress, token_id: u256);
}

#[starknet::interface]
trait IAccountCamel<TContractState> {
    fn isValidSignature(
        self: @TContractState, hash: felt252, signature: Span<felt252>
    ) -> felt252;
    fn isValidSigner(self: @TContractState, signer: ContractAddress) -> felt252;
    fn isLocked(self: @TContractState) -> (bool, u64);
    fn supportsInterface(self: @TContractState, interface_id: felt252) -> bool;
    fn changeOwner(ref self: TContractState, token_address: ContractAddress, token_id: u256);
}