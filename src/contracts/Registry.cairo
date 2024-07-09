#[starknet::contract]
mod Registry {
    use starknet::{ ContractAddress, get_caller_address };
    use token_bound_accounts::components::RegistryComponent;

    component!(path: RegistryComponent, storage: registry, event: RegistryEvent);
    
    #[abi(embed_v0)]
    impl RegistryImpl = RegistryComponent::RegistryImpl<ContractState>;
    #[abi(embed_v0)]
    impl RegistryCamelImpl = RegistryComponent::RegistryCamelImpl<ContractState>;
    impl RegistryInternalImpl = RegistryComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        registry: RegistryComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        RegistryEvent: RegistryComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, token_contract: ContractAddress, token_id: u256) {
        self.registry.initializer();
    }
}