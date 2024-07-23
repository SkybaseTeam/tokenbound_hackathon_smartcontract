use starknet::ContractAddress;

#[starknet::interface]
trait IAccountAction<TContractState> {
    fn equip_item(ref self: TContractState, token_id: u256) -> (u256, ContractAddress);
}

#[starknet::contract]
mod Collection {
    use alexandria_ascii::ToAsciiTrait;
    use gacha::components::{
        ERC721Component, UpgradeableComponent
    };
    use gacha::interfaces::{
        ICollection::ICollection, ICollection::ICollectionDispatcher, ICollection::ICollectionDispatcherTrait,
        ICollection::ICollectionCamel,
        IUpgradeable::IUpgradeable
    };
    use core::{
        Zeroable, poseidon
    };
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
    use starknet::{
        get_caller_address,
        get_contract_address,
        get_block_timestamp,
        replace_class_syscall,
        call_contract_syscall,
        get_block_number
    };
    use starknet::{ContractAddress, ClassHash, SyscallResult, SyscallResultTrait};
    use super::{
        IAccountActionDispatcher, IAccountActionDispatcherTrait
    };

    const OWNER_ADDRESS: felt252 =
        0x05fE8F79516C123e8556eA96bF87a97E7b1eB5AbdBE4dbCD993f3FB9A6F24A66;

    const S_RANK_MAX_PITY: u8 = 80;
    const A_RANK_MAX_PITY: u8 = 10;
    const S_RANK_RATE_INCREASED_AT: u8 = 75;
    const A_RANK_RATE_INCREASED_AT: u8 = 9;
    const S_RANK_BASE_RATE: u8 = 1;
    const A_RANK_BASE_RATE: u8 = 5;

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // ERC721
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721CamelOnly = ERC721Component::ERC721CamelOnlyImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    // SRC5
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    // upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        token_id: u256,
        id_stack: LegacyMap<u256, u256>,
        stack_index: u256,
        total_supply: u256,
        token_uri_1: felt252,
        token_uri_2: felt252,
        token_uri_3: felt252,
        token_uri_4: felt252,
        token_uri_5: felt252,
        supply_pool: LegacyMap<u8, u256>,
        sum_pool: LegacyMap<u8, u256>,
        time_pool: LegacyMap<u8, u64>,
        price_pool: LegacyMap<u8, u256>,
        mint_max: LegacyMap<u8, u256>,
        user_minted: LegacyMap<(ContractAddress, u8), u256>,
        token_metadata: LegacyMap<u256, (u8, u8, u8)>,
        s_pity_counter: LegacyMap<ContractAddress, u8>,
        a_pity_counter: LegacyMap<ContractAddress, u8>,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage
    }

    #[derive(Drop, starknet::Event)]
    struct NFTMinted {
        token_id: u256,
        token_type: u8,
        token_rank: u8,
        token_power: u8,
        token_owner: ContractAddress,
        pool: u8
    }

    #[derive(Drop, starknet::Event)]
    struct NFTBurned {
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct NFTEquipped {
        account: ContractAddress,
        token_id: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        NFTMinted: NFTMinted,
        NFTBurned: NFTBurned,
        NFTEquipped: NFTEquipped,
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event
    }

    mod Errors {
        const NOT_OWNER: felt252 = 'Error: not owner';
        const SIGNATURE_NOT_MATCH: felt252 = 'Error: signature not match';
        const MESSAGE_HASH_NOT_MATCH: felt252 = 'Error: msg hash not match';
        const TIME_NOT_START_YET: felt252 = 'Error: time not start yet';
        const SUPPLY_POOL_LIMIT: felt252 = 'Error: supply pool limit';
        const TOTAL_SUPPLY_LIMIT: felt252 = 'Error: total supply limit';
        const MINTED_MAX_AMOUNT_POOL: felt252 = 'Error: minted max amt pool';
        const INVALID_TOKEN_ID: felt252 = 'Error: invalid token id';
        const INVALID_CLASS_HASH: felt252 = 'Error: invalid class hash';
        const ALLOWANCE_NOT_ENOUGH: felt252 = 'Error: allowance not enough';
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        let name: felt252 = 'Tokenbound Account Item';
        let symbol: felt252 = 'TBAI';

        self.erc721.initializer(name, symbol);

        // Token URI
        self.token_uri_1.write('https://');
        self.token_uri_2.write('be-blingbling.');
        self.token_uri_3.write('onrender.com/');
        self.token_uri_4.write('metadata/');
        self.token_uri_5.write('nft/');

        // Total supply
        self.total_supply.write(1000000000000000000000000);

        // Supply
        self.supply_pool.write(1, 1000000000000000000000000); // Public  
        self.supply_pool.write(2, 0); // Private
        self.supply_pool.write(3, 0); // Whitelist
        self.supply_pool.write(4, 0); // Holder

        // Price 
        self.price_pool.write(1, 100);
        self.price_pool.write(2, 0);
        self.price_pool.write(3, 0);
        self.price_pool.write(4, 0);

        // Time
        self.time_pool.write(1, 1715698800);
        self.time_pool.write(2, 0);
        self.time_pool.write(3, 0);
        self.time_pool.write(4, 0);

        // Max mint
        self.mint_max.write(1, 500);
        self.mint_max.write(2, 0);
        self.mint_max.write(3, 0);
        self.mint_max.write(4, 0);

        self.sum_pool.write(1, 0);
        self.sum_pool.write(2, 0);
        self.sum_pool.write(3, 0);
        self.sum_pool.write(4, 0);
        
    }

    #[abi(embed_v0)]
    impl ICollectionImpl of ICollection<ContractState> {
        fn get_sum_pool(self: @ContractState) -> Array<u256> {
            return self._get_sum_pool();
        }
        fn token_uri(self: @ContractState, token_id: u256) -> Span<felt252> {
            return self._token_uri(token_id);
        }
        fn up_time(ref self: ContractState, pool: u8, time: u64) {
            self._up_time(pool, time);
        }
        fn up_supply(ref self: ContractState, pool: u8, supply: u256) {
            self._up_supply(pool, supply);
        }
        fn up_mint_max(ref self: ContractState, pool: u8, supply: u256) {
            self._up_mint_max(pool, supply);
        }
        fn up_price(ref self: ContractState, pool: u8, price: u256) {
            self._up_price(pool, price);
        }
        fn get_remaining_mint(self: @ContractState, pool_mint: u8) -> u256 {
            return self._get_remaining_mint(pool_mint);
        }
        fn get_mint_max(self: @ContractState, pool_mint: u8) -> u256 {
            return self._get_mint_max(pool_mint);
        }
        fn get_total_supply(self: @ContractState, pool_mint: u8) -> u256 {
            return self._get_total_supply(pool_mint);
        }
        fn get_mint_price(self: @ContractState, pool_mint: u8) -> u256 {
            return self._get_mint_price(pool_mint);
        }
        fn get_token_metadata(self: @ContractState, token_id: u256) -> (u8, u8, u8) {
            return self._get_token_metadata(token_id);
        }
        fn mint_nft(ref self: ContractState, eth_address: ContractAddress) -> u256 {
            return self._mint_nft(eth_address);
        }
        fn burn(ref self: ContractState, token_id: u256) {
            self._burn(token_id);
        }
        fn claim(ref self: ContractState, eth_address: ContractAddress) {
            self._claim(eth_address);
        }
        fn equip(ref self: ContractState, token_id: u256) {
            self._equip(token_id);
        }
    }

    #[abi(embed_v0)]
    impl ICollectionCamelImpl of ICollectionCamel<ContractState> {
        fn getSumPool(self: @ContractState) -> Array<u256> {
            return self._get_sum_pool();
        }
        fn tokenUri(self: @ContractState, token_id: u256) -> Span<felt252> {
            return self._token_uri(token_id);
        }
        fn upTime(ref self: ContractState, pool: u8, time: u64) {
            self._up_time(pool, time);
        }
        fn upSupply(ref self: ContractState, pool: u8, supply: u256) {
            self._up_supply(pool, supply);
        }
        fn upMintMax(ref self: ContractState, pool: u8, supply: u256) {
            self._up_mint_max(pool, supply);
        }
        fn upPrice(ref self: ContractState, pool: u8, price: u256) {
            self._up_price(pool, price);
        }
        fn getRemainingMint(self: @ContractState, pool_mint: u8) -> u256 {
            return self._get_remaining_mint(pool_mint);
        }
        fn getMintMax(self: @ContractState, pool_mint: u8) -> u256 {
            return self._get_mint_max(pool_mint);
        }
        fn getTotalSupply(self: @ContractState, pool_mint: u8) -> u256 {
            return self._get_total_supply(pool_mint);
        }
        fn getMintPrice(self: @ContractState, pool_mint: u8) -> u256 {
            return self._get_mint_price(pool_mint);
        }
        fn getTokenMetadata(self: @ContractState, token_id: u256) -> (u8, u8, u8) {
            return self._get_token_metadata(token_id);
        }
        fn mintNft(ref self: ContractState, eth_address: ContractAddress) -> u256 {
            return self._mint_nft(eth_address);
        }
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            let caller = get_caller_address();
            assert(caller == OWNER_ADDRESS.try_into().unwrap(), 'Error: UNAUTHORIZED');
            self.upgradeable._upgrade(new_class_hash);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _up_time(ref self: ContractState, pool: u8, time: u64) {
            // Check owner
            let caller = get_caller_address();
            let owner_address: ContractAddress = OWNER_ADDRESS.try_into().unwrap();
            assert(caller == owner_address, Errors::NOT_OWNER);
    
            // Save to storage
            self.time_pool.write(pool, time);
        }

        fn _up_supply(ref self: ContractState, pool: u8, supply: u256) {
            // Check owner
            let caller = get_caller_address();
            let owner_address: ContractAddress = OWNER_ADDRESS.try_into().unwrap();
            assert(caller == owner_address, Errors::NOT_OWNER);
    
            // Save to storage
            self.supply_pool.write(pool, supply);
        }

        fn _up_mint_max(ref self: ContractState, pool: u8, supply: u256) {
            // Check owner
            let caller = get_caller_address();
            let owner_address: ContractAddress = OWNER_ADDRESS.try_into().unwrap();
            assert(caller == owner_address, Errors::NOT_OWNER);
    
            // Save to storage
            self.mint_max.write(pool, supply);
        }

        fn _up_price(ref self: ContractState, pool: u8, price: u256) {
            // Check owner
            let caller = get_caller_address();
            let owner_address: ContractAddress = OWNER_ADDRESS.try_into().unwrap();
            assert(caller == owner_address, Errors::NOT_OWNER);
    
            // Save to storage
            self.price_pool.write(pool, price);
        }

        fn _get_sum_pool(self: @ContractState) -> Array<u256> {
            let mut arr: Array<u256> = ArrayTrait::new();
            arr.append(self.token_id.read());
            arr.append(self.sum_pool.read(1));
            arr.append(self.sum_pool.read(2));
            arr.append(self.sum_pool.read(3));
            arr.append(self.sum_pool.read(4));
            arr
        }

        fn _token_uri(self: @ContractState, token_id: u256) -> Span<felt252> {
            assert(self.erc721.owner_of(token_id).is_non_zero(), Errors::INVALID_TOKEN_ID);
            let token_id_str: felt252 = token_id.low.to_ascii();
            let mut token_uri: Array<felt252> = array![
                self.token_uri_1.read(),
                self.token_uri_2.read(),
                self.token_uri_3.read(),
                self.token_uri_4.read(),
                self.token_uri_5.read(),
                token_id_str
            ];
            token_uri.span()
        }

        fn _get_remaining_mint(self: @ContractState, pool_mint: u8) -> u256 {
            return self.supply_pool.read(pool_mint) - self.sum_pool.read(pool_mint);
        }

        fn _get_mint_max(self: @ContractState, pool_mint: u8) -> u256 {
            return self.mint_max.read(pool_mint);
        }

        fn _get_total_supply(self: @ContractState, pool_mint: u8) -> u256 {
            return self.supply_pool.read(pool_mint);
        }

        fn _get_mint_price(self: @ContractState, pool_mint: u8) -> u256 {
            return self.price_pool.read(pool_mint);
        }

        fn _get_token_metadata(self: @ContractState, token_id: u256) -> (u8, u8, u8) {
            return self.token_metadata.read(token_id);
        }

        fn _mint_nft(ref self: ContractState, eth_address: ContractAddress) -> u256 {
            let pool_mint: u8 = 1;
            let caller = get_caller_address();
    
            // Verify time
            assert(get_block_timestamp() >= self.time_pool.read(pool_mint), Errors::TIME_NOT_START_YET);
    
            // Verify supply pool
            assert(
                self.supply_pool.read(pool_mint) > self.sum_pool.read(pool_mint),
                Errors::SUPPLY_POOL_LIMIT
            );

            // assign token id
            let mut token_id = self.token_id.read();
            if(self.stack_index.read() > 0) {
                token_id = self.id_stack.read(self.stack_index.read());
                self.stack_index.write(self.stack_index.read() - 1);
            } else {
                token_id = token_id + 1;
            }
    
            // Verify token id
            assert(token_id < self.total_supply.read(), Errors::TOTAL_SUPPLY_LIMIT);
    
            // Verify the number of nft user has minted
            let acc_user_mint: (ContractAddress, u8) = (caller, pool_mint);
            assert(
                self.user_minted.read(acc_user_mint) < self.mint_max.read(pool_mint),
                Errors::MINTED_MAX_AMOUNT_POOL
            );

            // Transfer token
            let this_contract_address = get_contract_address();
            let allowance = IERC20CamelDispatcher { contract_address: eth_address }
                .allowance(caller, this_contract_address);
            assert(allowance >= self.price_pool.read(pool_mint), Errors::ALLOWANCE_NOT_ENOUGH);
            IERC20CamelDispatcher { contract_address: eth_address }
                .transferFrom(caller, this_contract_address, self.price_pool.read(pool_mint));
    
            // Save to storage
            self.token_id.write(token_id);
            self.sum_pool.write(pool_mint, self.sum_pool.read(pool_mint) + 1);
            self.user_minted.write(acc_user_mint, self.user_minted.read(acc_user_mint) + 1);
    
            // Mint NFT & set the token's URI
            self.erc721._mint(caller, token_id);

            // Calculate token metadata
            let s_pity_counter = self.s_pity_counter.read(caller) + 1;
            let a_pity_counter = self.a_pity_counter.read(caller) + 1;
            self.s_pity_counter.write(caller, s_pity_counter);
            self.a_pity_counter.write(caller, a_pity_counter);

            let s_rate_by_pity = rates(s_pity_counter, S_RANK_MAX_PITY, S_RANK_BASE_RATE, S_RANK_RATE_INCREASED_AT);
            let a_rate_by_pity = rates(a_pity_counter, A_RANK_MAX_PITY, A_RANK_BASE_RATE, A_RANK_RATE_INCREASED_AT);

             // create random variable
             let token_type_core: Array<felt252> = array![
                '_token_type_',
                get_block_timestamp().into(),
                get_block_number().into(),
                self.user_minted.read(acc_user_mint).try_into().unwrap()
            ];
             let token_rank_core: Array<felt252> = array![
                '_token_rank_',
                get_block_timestamp().into(),
                get_block_number().into(),
                self.user_minted.read(acc_user_mint).try_into().unwrap()
            ];
             let token_power_core: Array<felt252> = array![
                '_token_power_',
                get_block_timestamp().into(),
                get_block_number().into(),
                self.user_minted.read(acc_user_mint).try_into().unwrap()
            ];
             let token_type_hash: u256 = poseidon::poseidon_hash_span(token_type_core.span()).into();
             let token_rank_hash: u256 = poseidon::poseidon_hash_span(token_rank_core.span()).into();
             let token_power_hash: u256 = poseidon::poseidon_hash_span(token_power_core.span()).into();
 
             let token_type_precentage = (token_type_hash % 600).try_into().unwrap();
             let mut token_type = 0;
             if(token_type_precentage >= 500) {
                token_type = 5;
             } else if (token_type_precentage >= 400_u256) {
                token_type = 4;
             } else if (token_type_precentage >= 300_u256) {
                token_type = 3;
             } else if (token_type_precentage >= 200_u256) {
                token_type = 2;
             } else if (token_type_precentage >= 100_u256) {
                token_type = 1;
             }

             let token_rank_precentage = (token_rank_hash % 100).try_into().unwrap();
             let mut token_rank: u8 = 0;
             if (token_rank_precentage < s_rate_by_pity) {
                 token_rank = 2_u8;
                 self.s_pity_counter.write(caller, 0);
             } else if (token_rank_precentage < a_rate_by_pity) {
                 token_rank = 1_u8;
                 self.a_pity_counter.write(caller, 0);
             }
 
             let mut token_power: u8 = 0;
             if(token_rank == 2) {
                 token_power = 50_u8 + (token_power_hash % (60 - 50)).try_into().unwrap();
             } else if (token_rank == 1) {
                 token_power = 30_u8 + (token_power_hash % (40 - 30)).try_into().unwrap();
             } else {
                 token_power = 10_u8 + (token_power_hash % (20 - 10)).try_into().unwrap();
             }

            self.token_metadata.write(token_id, (token_type, token_rank, token_power));

            // Emit event
            self.emit(NFTMinted {
                token_id,
                token_type,
                token_rank,
                token_power,
                token_owner: caller,
                pool: pool_mint
            });

            return token_id;
        }

        fn _burn(ref self: ContractState, token_id: u256) {
            // Check owner
            let caller = get_caller_address();
            assert(caller == self.erc721._owner_of(token_id), Errors::NOT_OWNER);
    
            // Burn NFT
            self.erc721._burn(token_id);
            self.stack_index.write(self.stack_index.read() + 1);
            self.id_stack.write(self.stack_index.read(), token_id);
    
            // Emit event
            self.emit(NFTBurned { from: caller, to: Zeroable::zero(), token_id });
        }

        fn _claim(ref self: ContractState, eth_address: ContractAddress) {
            // Check owner
            let caller = get_caller_address();
            let owner_address: ContractAddress = OWNER_ADDRESS.try_into().unwrap();
            assert(caller == owner_address, Errors::NOT_OWNER);
    
            // Transfer token
            IERC20CamelDispatcher { contract_address: eth_address }
                .transfer(
                    owner_address,
                    IERC20CamelDispatcher { contract_address: eth_address }
                        .balanceOf(get_contract_address())
                );
        }

        fn _equip(ref self: ContractState, token_id: u256) {
            assert(self.erc721.ERC721_owners.read(token_id) == get_caller_address(), Errors::NOT_OWNER);
            self.emit(NFTEquipped { account: get_caller_address(), token_id });
        }
    }

    fn rates(current_pity: u8, max_pity: u8, base_rate: u8, rate_increased_at: u8) -> u8 {
        if (current_pity >= max_pity) {
            return 100;
        }
        if (current_pity < rate_increased_at) {
            return base_rate;
        }
        
        let rate_increased_by = (100 - base_rate) / (max_pity + 1 - rate_increased_at);
        let rate_before_current_pity = (current_pity + 1 - rate_increased_at) * rate_increased_by;
        let increased_rate = base_rate + rate_before_current_pity;
        return increased_rate;
    }
}