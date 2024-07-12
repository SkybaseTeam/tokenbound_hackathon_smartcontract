#[starknet::contract]
mod HeroToken {
    use openzeppelin::token::erc20::ERC20Component;
    use starknet::{
        ContractAddress, get_caller_address
    };
    use erc20::utils::utils::Utils;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20CamelOnlyImpl = ERC20Component::ERC20CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20MetadataImpl = ERC20Component::ERC20MetadataImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        co_owner_address: ContractAddress,
        #[substorage(v0)]
        erc20: ERC20Component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event
    }

    const OWNER_ADDRESS: felt252 =
        0x01c31ccFCD807F341E2Ae54856c42b1977f6d92f62C68336e7499Cc01E18524b;

    #[external(v0)]
    fn mint(ref self: ContractState, to: ContractAddress, amount: u256) {
        assert(
            get_caller_address() == OWNER_ADDRESS.try_into().unwrap() || get_caller_address() == self.co_owner_address.read(),
            'Error: not owner'
        );
        self.erc20._mint(to, amount);
    }

    #[external(v0)]
    fn change_co_owner(ref self: ContractState, co_owner_address: ContractAddress) {
        assert(
            get_caller_address() == OWNER_ADDRESS.try_into().unwrap(),
            'Error: not owner'
        );
        self.co_owner_address.write(co_owner_address);
    }

    #[constructor]
    fn constructor(
        ref self: ContractState
    ) {
        let name: felt252 = 284747714119;
        let symbol: felt252 = 284747714119;
        self.erc20.initializer(name, symbol);
    }
}