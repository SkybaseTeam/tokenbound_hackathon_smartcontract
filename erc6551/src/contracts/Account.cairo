use starknet::ContractAddress;
#[starknet::interface]
trait ICollection<TContractState> {
    fn mint_nft(ref self: TContractState, token_address: ContractAddress) -> u256;
    fn get_mint_price(self: @TContractState, pool_mint: u8) -> u256;
}

#[starknet::contract(account)]
mod Account {
    use starknet::{
        ContractAddress,
        ClassHash,
        get_contract_address,
        get_caller_address,
        call_contract_syscall
    };
    use token_bound_accounts::components::{
        AccountComponent, UpgradeableComponent
    };
    use token_bound_accounts::interfaces::IUpgradeable::IUpgradeable;
    use openzeppelin::token::erc20::interface::{ IERC20Dispatcher, IERC20DispatcherTrait };
    use super::{ ICollectionDispatcher, ICollectionDispatcherTrait };

    component!(path: AccountComponent, storage: account, event: AccountEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // Account
    #[abi(embed_v0)]
    impl AccountImpl = AccountComponent::AccountImpl<ContractState>;
    #[abi(embed_v0)]
    impl AccountCamelImpl = AccountComponent::AccountCamelImpl<ContractState>;
    impl AccountInternalImpl = AccountComponent::InternalImpl<ContractState>;

    // Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        account: AccountComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        AccountEvent: AccountComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, token_contract: ContractAddress, token_id: u256) {
        self.account.initializer(token_contract, token_id);
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            let caller = get_caller_address();
            assert(self.account._is_valid_signer(caller), AccountComponent::Errors::UNAUTHORIZED);
            let (lock_status, _) = self.account._is_locked();
            assert(!lock_status, AccountComponent::Errors::LOCKED_ACCOUNT);
            self.upgradeable._upgrade(new_class_hash);
        }
    }

    #[external(v0)]
    fn claim_token(ref self: ContractState, token_contract: ContractAddress, message_hash: felt252, signature_r: felt252, signature_s: felt252) {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        Serde::serialize(@message_hash, ref calldata);
        Serde::serialize(@signature_r, ref calldata);
        Serde::serialize(@signature_s, ref calldata);
        let _res = call_contract_syscall(
            token_contract, selector!("mint"), calldata.span()
        );
    }

    #[external(v0)]
    fn mint_nft(ref self: ContractState, nft_contract: ContractAddress, token_contract: ContractAddress) -> u256 {
        // Check owner
        let caller = get_caller_address();
        assert(self.account._is_valid_signer(caller), AccountComponent::Errors::UNAUTHORIZED);
        let (lock_status, _) = self.account._is_locked();
        assert(!lock_status, AccountComponent::Errors::LOCKED_ACCOUNT);

        // get mint price
        let mint_price = ICollectionDispatcher { contract_address: nft_contract }
            .get_mint_price(1);
        // check balance
        let balance = IERC20Dispatcher { contract_address: token_contract }
            .balance_of(get_contract_address());
        assert(balance >= mint_price, 'Errors::BALANCE_NOT_ENOUGH');
        // approved to nft contract
        IERC20Dispatcher { contract_address: token_contract }
            .approve(nft_contract, mint_price);
        let token_id = ICollectionDispatcher { contract_address: nft_contract }
            .mint_nft(token_contract);
        return token_id;
    }

    #[external(v0)]
    fn withdraw(ref self: ContractState, token_contract: ContractAddress) {
        // Check owner
        let caller = get_caller_address();
        assert(self.account._is_valid_signer(caller), AccountComponent::Errors::UNAUTHORIZED);
        let (lock_status, _) = self.account._is_locked();
        assert(!lock_status, AccountComponent::Errors::LOCKED_ACCOUNT);

        // Transfer token
        IERC20Dispatcher { contract_address: token_contract }
            .transfer(
                caller,
                IERC20Dispatcher { contract_address: token_contract }
                    .balance_of(get_contract_address())
            );
    }
}