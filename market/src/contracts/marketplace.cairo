#[starknet::contract]
mod Marketplace {
    use starknet::{
        ContractAddress, get_caller_address, get_contract_address
    };
    use market::interfaces::{
        erc721::IERC721Dispatcher, erc721::IERC721DispatcherTrait,
        erc20::IERC20Dispatcher, erc20::IERC20DispatcherTrait,
        marketplace::IMarketplace, marketplace::IMarketplaceCamel,
    };
    
    
    #[storage]
    struct Storage {
        // params: (token_address, token_id) -> owner_address
        owner: LegacyMap<(ContractAddress, u256), ContractAddress>,
        // params: (token_address, token_id) -> price
        price: LegacyMap<(ContractAddress, u256), u256>,
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
    }

    const ETH_CONTRACT_ADDRESS: felt252 =
        0x0511a1885b2a0f815e72bb368e840faea782c141c07a01af3c9f90c94fac09d1 ;

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

        fn get_price(self: @ContractState, token_address: ContractAddress, token_id: u256) -> u256 {
            return self._get_price(token_address, token_id);
        }

        fn buy_nft(ref self: ContractState, token_address: ContractAddress, token_id: u256) {
            self._buy_nft(token_address, token_id);
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
        fn getPrice(self: @ContractState, token_address: ContractAddress, token_id: u256) -> u256 {
            return self._get_price(token_address, token_id);
        }

        fn buyNft(ref self: ContractState, token_address: ContractAddress, token_id: u256) {
            self._buy_nft(token_address, token_id);
        }

        fn listingNft(ref self: ContractState, token_address: ContractAddress, token_id: u256, price: u256) {
            self._listing_nft(token_address, token_id, price);
        }

        fn cancelNft(ref self: ContractState, token_address: ContractAddress, token_id: u256) {
            self._cancel_listing(token_address, token_id);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {

        fn _get_price(self: @ContractState, token_address: ContractAddress, token_id: u256) -> u256 {
            assert(self.price.read((token_address, token_id)) > 0, Errors::NFT_NOT_ON_SALE);
            return self.price.read((token_address, token_id));
        }

        fn _buy_nft(ref self: ContractState, token_address: ContractAddress, token_id: u256) {
            assert(self.price.read((token_address, token_id)) > 0, Errors::NFT_NOT_ON_SALE);
            assert(self.owner.read((token_address, token_id)) != get_caller_address(), Errors::BUY_SELF_NFT);
            assert(
                IERC20Dispatcher { contract_address: ETH_CONTRACT_ADDRESS.try_into().unwrap() }
                .allowance(get_caller_address(), get_contract_address()) >= self.price.read((token_address, token_id)),
                Errors::ALLOWANCE_NOT_ENOUGH
            );

            IERC20Dispatcher { contract_address: ETH_CONTRACT_ADDRESS.try_into().unwrap() }
            .transferFrom(get_caller_address(), self.owner.read((token_address, token_id)), self.price.read((token_address, token_id)));
    
            IERC721Dispatcher { contract_address: token_address }
            .transfer_from(get_contract_address(), get_caller_address(), token_id);
    
            self.price.write((token_address, token_id), 0);
            self.emit(NFT_BOUGHT { from: get_caller_address(), token_address: token_address, token_id: token_id });
        }

        fn _listing_nft(ref self: ContractState, token_address: ContractAddress, token_id: u256, price: u256) {
            assert(self.price.read((token_address, token_id)) == 0, Errors::NFT_ON_SALE);
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
            self.price.write((token_address, token_id), price);

            self.emit(NFT_LISTED { from: get_caller_address(), token_address: token_address, token_id: token_id, price: price });
        }

        fn _cancel_listing(ref self: ContractState, token_address: ContractAddress, token_id: u256) {
            assert(self.price.read((token_address, token_id)) > 0, Errors::NFT_NOT_ON_SALE);
            assert(
                self.owner.read((token_address, token_id)) == get_caller_address(),
                Errors::NOT_OWNER
            );
    
            IERC721Dispatcher { contract_address: token_address }
            .transfer_from(get_contract_address(), get_caller_address(), token_id);
    
            self.price.write((token_address, token_id), 0);
            
            self.emit(NFT_CANCELLED { token_address: token_address, token_id: token_id });
        }
    }
}
