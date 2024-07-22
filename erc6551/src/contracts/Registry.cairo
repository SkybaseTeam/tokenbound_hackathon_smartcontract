#[starknet::contract]
mod Registry {
    use starknet::{ ContractAddress, ClassHash, get_caller_address };
    use token_bound_accounts::components::{
        RegistryComponent, UpgradeableComponent
    };
    use token_bound_accounts::interfaces::{
        IUpgradeable::IUpgradeable
    };

    component!(path: RegistryComponent, storage: registry, event: RegistryEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl RegistryImpl = RegistryComponent::RegistryImpl<ContractState>;
    #[abi(embed_v0)]
    impl RegistryCamelImpl = RegistryComponent::RegistryCamelImpl<ContractState>;
    impl RegistryInternalImpl = RegistryComponent::InternalImpl<ContractState>;

    // Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        registry: RegistryComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        RegistryEvent: RegistryComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event
    }

    const OWNER_ADDRESS: felt252 =
        0x05fE8F79516C123e8556eA96bF87a97E7b1eB5AbdBE4dbCD993f3FB9A6F24A66;


    mod Errors {
        const CALLER_IS_NOT_OWNER: felt252 = 'Registry: caller is not onwer';
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.registry.initializer();
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            let caller = get_caller_address();
            assert(caller == OWNER_ADDRESS.try_into().unwrap(), Errors::CALLER_IS_NOT_OWNER);
            self.upgradeable._upgrade(new_class_hash);
        }
    }
}