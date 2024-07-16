#[starknet::contract]
mod Marketplace {
    use starknet::{
        ContractAddress,
        ClassHash,
        get_caller_address,
        get_contract_address
    };
    use market::interfaces::{
        IErc721::IERC721Dispatcher,
        IErc721::IERC721DispatcherTrait,
        IErc20::IERC20Dispatcher,
        IErc20::IERC20DispatcherTrait,
        IMarketplace::IMarketplace,
        IMarketplace::IMarketplaceCamel,
        IUpgradeable::IUpgradeable
    };
    use market::components::{
        UpgradeableComponent
    };

    const OWNER_ADDRESS: felt252 =
        0x05fE8F79516C123e8556eA96bF87a97E7b1eB5AbdBE4dbCD993f3FB9A6F24A66;

    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    
    // upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        // params: (token_address, token_id) -> owner_address
        owner: LegacyMap<(ContractAddress, u256), ContractAddress>,
        // params: (token_address, token_id) -> price
        price: LegacyMap<(ContractAddress, u256), u256>,
        // params: (token_address, token_id) -> is_on_sale
        listing: LegacyMap<(ContractAddress, u256), bool>,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage
    }

    #[derive(Drop, starknet::Event)]
    struct NFT_LISTED {
        #[key]
        from: ContractAddress,
        token_address: ContractAddress,
        token_id: u256,
        price: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct NFT_CANCELLED {
        token_address: ContractAddress,
        token_id: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct NFT_BOUGHT {
        from: ContractAddress,
        token_address: ContractAddress,
        token_id: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        NFT_LISTED: NFT_LISTED,
        NFT_CANCELLED: NFT_CANCELLED,
        NFT_BOUGHT: NFT_BOUGHT,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event
    }

    mod Errors {
        const NOT_OWNER: felt252 = 'Error: not owner';
        const ALLOWANCE_NOT_ENOUGH: felt252 = 'Error: allowance not enough';
        const ALLOWANCE_NOT_SET: felt252 = 'Error: allowance not set';
        const NFT_ON_SALE: felt252 = 'Error: nft on sale';
        const NFT_NOT_ON_SALE: felt252 = 'Error: nft not on sale';
        const BUY_SELF_NFT: felt252 = 'Error: buy self nft';
    }

    #[constructor]
    fn constructor(ref self: ContractState) {

    }

    #[abi(embed_v0)]
    impl MarketplaceImpl of IMarketplace<ContractState> {

        fn get_status(self: @ContractState, token_address: ContractAddress, token_id: u256) -> bool {
            return self._get_status(token_address, token_id);
        }

        fn get_price(self: @ContractState, token_address: ContractAddress, token_id: u256) -> u256 {
            return self._get_price(token_address, token_id);
        }

        fn buy_nft(ref self: ContractState, token_address: ContractAddress, token_id: u256, eth_address: ContractAddress) {
            self._buy_nft(token_address, token_id, eth_address);
        }

        fn listing_nft(ref self: ContractState, token_address: ContractAddress, token_id: u256, price: u256) {
            self._listing_nft(token_address, token_id, price);
        }

        fn cancel_nft(ref self: ContractState, token_address: ContractAddress, token_id: u256) {
            self._cancel_listing(token_address, token_id);
        }
    }

    #[abi(embed_v0)]
    impl MarketplaceCamelImpl of IMarketplaceCamel<ContractState> {
        fn getStatus(self: @ContractState, token_address: ContractAddress, token_id: u256) -> bool {
            return self._get_status(token_address, token_id);
        }

        fn getPrice(self: @ContractState, token_address: ContractAddress, token_id: u256) -> u256 {
            return self._get_price(token_address, token_id);
        }

        fn buyNft(ref self: ContractState, token_address: ContractAddress, token_id: u256, eth_address: ContractAddress) {
            self._buy_nft(token_address, token_id, eth_address);
        }

        fn listingNft(ref self: ContractState, token_address: ContractAddress, token_id: u256, price: u256) {
            self._listing_nft(token_address, token_id, price);
        }

        fn cancelNft(ref self: ContractState, token_address: ContractAddress, token_id: u256) {
            self._cancel_listing(token_address, token_id);
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

        fn _get_status(self: @ContractState, token_address: ContractAddress, token_id: u256) -> bool {
            return self.listing.read((token_address, token_id));
        }

        fn _get_price(self: @ContractState, token_address: ContractAddress, token_id: u256) -> u256 {
            assert(self.listing.read((token_address, token_id)) == true, Errors::NFT_NOT_ON_SALE);
            return self.price.read((token_address, token_id));
        }

        fn _buy_nft(ref self: ContractState, token_address: ContractAddress, token_id: u256, eth_address: ContractAddress) {
            assert(self.listing.read((token_address, token_id)) == true, Errors::NFT_NOT_ON_SALE);
            assert(self.owner.read((token_address, token_id)) != get_caller_address(), Errors::BUY_SELF_NFT);
            assert(
                IERC20Dispatcher { contract_address: eth_address }
                .allowance(get_caller_address(), get_contract_address()) >= self.price.read((token_address, token_id)),
                Errors::ALLOWANCE_NOT_ENOUGH
            );

            IERC20Dispatcher { contract_address: eth_address }
            .transferFrom(get_caller_address(), self.owner.read((token_address, token_id)), self.price.read((token_address, token_id)));
    
            IERC721Dispatcher { contract_address: token_address }
            .transfer_from(get_contract_address(), get_caller_address(), token_id);
    
            self.listing.write((token_address, token_id), false);
            
            self.emit(NFT_BOUGHT { from: get_caller_address(), token_address: token_address, token_id: token_id });
        }

        fn _listing_nft(ref self: ContractState, token_address: ContractAddress, token_id: u256, price: u256) {
            assert(self.listing.read((token_address, token_id)) == false, Errors::NFT_ON_SALE);
            assert(
                IERC721Dispatcher { contract_address: token_address }
                .owner_of(token_id) == get_caller_address(),
                Errors::NOT_OWNER
            );
            assert(
                IERC721Dispatcher { contract_address: token_address }
                .get_approved(token_id) == get_contract_address(),
                Errors::ALLOWANCE_NOT_SET
            );
    
            IERC721Dispatcher { contract_address: token_address }
            .transfer_from(get_caller_address(), get_contract_address(), token_id);
            
            self.owner.write((token_address, token_id), get_caller_address());
            self.listing.write((token_address, token_id), true);
            self.price.write((token_address, token_id), price);

            self.emit(NFT_LISTED { from: get_caller_address(), token_address: token_address, token_id: token_id, price: price });
        }

        fn _cancel_listing(ref self: ContractState, token_address: ContractAddress, token_id: u256) {
            assert(self.listing.read((token_address, token_id)) == true, Errors::NFT_NOT_ON_SALE);
            assert(
                self.owner.read((token_address, token_id)) == get_caller_address(),
                Errors::NOT_OWNER
            );
    
            IERC721Dispatcher { contract_address: token_address }
            .transfer_from(get_contract_address(), get_caller_address(), token_id);

            self.listing.write((token_address, token_id), false);
            
            self.emit(NFT_CANCELLED { token_address: token_address, token_id: token_id });
        }
    }
}
