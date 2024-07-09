#[starknet::contract(account)]
mod Account {
    use starknet::{ ContractAddress, get_caller_address };
    use token_bound_accounts::components::AccountComponent;

    component!(path: AccountComponent, storage: account, event: AccountEvent);

    // Account
    #[abi(embed_v0)]
    impl AccountImpl = AccountComponent::AccountImpl<ContractState>;
    #[abi(embed_v0)]
    impl AccountCamelImpl = AccountComponent::AccountCamelImpl<ContractState>;
    impl AccountInternalImpl = AccountComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        account: AccountComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        AccountEvent: AccountComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, token_contract: ContractAddress, token_id: u256) {
        self.account.initializer(token_contract, token_id);
    }
}