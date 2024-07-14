#[starknet::contract]
mod HeroToken {
    use alexandria_ascii::ToAsciiTrait;
    use ecdsa::check_ecdsa_signature;
    use openzeppelin::token::erc20::ERC20Component;
    use starknet::{
        ContractAddress, get_caller_address, get_contract_address
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

    #[external(v0)]
    fn mint(
        ref self: ContractState,
        message_hash: felt252,
        signature_r: felt252,
        signature_s: felt252,
        to: ContractAddress,
        amount: u256
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
            message_hash == check_msg(contract_address, caller),
            'Error: msg hash not match'
        );


        self.erc20._mint(to, amount);
    }

    #[constructor]
    fn constructor(
        ref self: ContractState
    ) {
        let name: felt252 = 284747714119;
        let symbol: felt252 = 284747714119;
        self.erc20.initializer(name, symbol);
    }

    fn check_msg(account: ContractAddress, to: ContractAddress) -> felt252 {
        let mut message: Array<felt252> = ArrayTrait::new();
        message.append(account.into());
        message.append(to.into());
        poseidon::poseidon_hash_span(message.span())
    }
}