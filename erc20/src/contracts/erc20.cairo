#[starknet::contract]
mod HeroToken {
    use alexandria_ascii::ToAsciiTrait;
    use ecdsa::check_ecdsa_signature;
    use openzeppelin::token::erc20::ERC20Component;
    use starknet::{
        ContractAddress, get_caller_address, get_contract_address
    };

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
        achievement_point: u256,
        message_hash_storage: LegacyMap<felt252, bool>,
        #[substorage(v0)]
        erc20: ERC20Component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event
    }

    const PUBLIC_KEY_SIGN: felt252 =
        0x00c98cd142631ff9dfb2540f98f1644d9f763b7c68dda3aca98944154298618e;
    const OWNER_ADDRESS: felt252 = 
        0x05fE8F79516C123e8556eA96bF87a97E7b1eB5AbdBE4dbCD993f3FB9A6F24A66;

    #[external(v0)]
    fn mint(
        ref self: ContractState,
        message_hash: felt252,
        signature_r: felt252,
        signature_s: felt252,
        achievement_index: u128
    ) {
        let caller = get_caller_address();
        let contract_address = get_contract_address();
        // Verify signature
        assert(
            check_ecdsa_signature(message_hash, PUBLIC_KEY_SIGN, signature_r, signature_s),
            'Error: signature not match'
        );

        // Verify message hash
        assert(
            message_hash == check_msg(contract_address, caller, achievement_index),
            'Error: msg hash not match'
        );

        assert(
            !self.message_hash_storage.read(message_hash),
            'Error: msg hash used'
        );

        self.message_hash_storage.write(message_hash, true);
        self.erc20._mint(caller, self.achievement_point.read());
    }

    #[external(v0)]
    fn change_achievement_point(
        ref self: ContractState,
        new_achievement_point: u256
    ) {
        assert(
            get_caller_address() == OWNER_ADDRESS.try_into().unwrap(),
            'Error: NOT OWNER'
        );
        self.achievement_point.write(new_achievement_point);
    }

    #[constructor]
    fn constructor(
        ref self: ContractState
    ) {
        let name: felt252 = 284747714119;
        let symbol: felt252 = 284747714119;
        self.erc20.initializer(name, symbol);
        self.achievement_point.write(10);
    }

    fn check_msg(account: ContractAddress, to: ContractAddress, achievement_index: u128) -> felt252 {
        let mut message: Array<felt252> = ArrayTrait::new();
        message.append(account.into());
        message.append(to.into());
        message.append(achievement_index.into());
        poseidon::poseidon_hash_span(message.span())
    }
}