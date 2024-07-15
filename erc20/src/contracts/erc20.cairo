#[starknet::contract]
mod Token {
    use alexandria_ascii::ToAsciiTrait;
    use ecdsa::check_ecdsa_signature;
    use openzeppelin::token::erc20::ERC20Component;
    use starknet::{
        ContractAddress, get_caller_address, get_contract_address
    };
    use erc20::interfaces::erc20::{
        Token, TokenCamel
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
        mint_point: u256,
        message_hash_storage: LegacyMap<felt252, bool>,
        minted_time: LegacyMap<ContractAddress, u256>,
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

    #[constructor]
    fn constructor(
        ref self: ContractState
    ) {
        let name: felt252 = 284747714119;
        let symbol: felt252 = 284747714119;
        self.erc20.initializer(name, symbol);
        self.mint_point.write(10);
    }

    #[abi(embed_v0)]
    impl TokenImpl of Token<ContractState> {
        fn get_minted(self: @ContractState, account_contract: ContractAddress) -> u256 {
            return self._get_minted(account_contract);
        }
        fn mint(ref self: ContractState, message_hash: felt252, signature_r: felt252, signature_s: felt252) {
            self._mint(message_hash, signature_r, signature_s);
        }
        fn change_mint_point(ref self: ContractState, new_achievement_point: u256) {
            self._change_mint_point(new_achievement_point);
        }
    }

    #[abi(embed_v0)]
    impl TokenCamelImpl of TokenCamel<ContractState> {
        fn getMinted(self: @ContractState, account_contract: ContractAddress) -> u256 {
            return self._get_minted(account_contract);
        }
        fn changeMintPoint(ref self: ContractState, new_achievement_point: u256) {
            self._change_mint_point(new_achievement_point);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {

        fn _get_minted(
            self: @ContractState,
            account_contract: ContractAddress
        ) -> u256 {
            return self.minted_time.read(account_contract);
        }

        fn _mint(
            ref self: ContractState,
            message_hash: felt252,
            signature_r: felt252,
            signature_s: felt252
        ) {
            let caller = get_caller_address();
            let contract_address = get_contract_address();
            // Verify signature
            assert(
                check_ecdsa_signature(message_hash, PUBLIC_KEY_SIGN, signature_r, signature_s),
                'Error: signature not match'
            );
    
            assert(
                !self.message_hash_storage.read(message_hash),
                'Error: msg hash used'
            );

            let mint_time = self.minted_time.read(caller);

            // Verify message hash
            assert(
                message_hash == check_msg(contract_address, caller, mint_time + 1),
                'Error: msg hash not match'
            );
    
            self.message_hash_storage.write(message_hash, true);
            self.minted_time.write(caller, mint_time + 1);
            self.erc20._mint(caller, self.mint_point.read());
        }

        fn _change_mint_point(
            ref self: ContractState,
            new_mint_point: u256
        ) {
            assert(
                get_caller_address() == OWNER_ADDRESS.try_into().unwrap(),
                'Error: NOT OWNER'
            );
            self.mint_point.write(new_mint_point);
        }
    }

    fn check_msg(account: ContractAddress, to: ContractAddress, index: u256) -> felt252 {
        let mut message: Array<felt252> = ArrayTrait::new();
        message.append(account.into());
        message.append(to.into());
        message.append(index.low.into());
        message.append(index.high.into());
        poseidon::poseidon_hash_span(message.span())
    }
}