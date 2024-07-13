#[starknet::component]
mod RegistryComponent {
    use core::result::ResultTrait;
    use core::hash::HashStateTrait;
    use core::pedersen::PedersenTrait;
    use starknet::{
        ContractAddress, get_caller_address, syscalls::call_contract_syscall, class_hash::ClassHash,
        class_hash::Felt252TryIntoClassHash, syscalls::deploy_syscall, SyscallResultTrait
    };
    use token_bound_accounts::interfaces::IRegistry::{
        IRegistry, IRegistryCamel
    };

    const NFT_CONTRACT_ADDRESS: felt252 =
    0x04e807d6fb42aff9968db63ca4b1e4a71c2589e265482f2ee020c8a3b2e47222;

    #[storage]
    struct Storage {
        registry_deployed_accounts: LegacyMap<
            (ContractAddress, u256), u8
        >, // tracks no. of deployed accounts by registry for an NFT
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        AccountCreated: AccountCreated
    }

    /// @notice Emitted when a new tokenbound account is deployed/created
    /// @param account_address the deployed contract address of the tokenbound acccount
    /// @param token_contract the contract address of the NFT
    /// @param token_id the ID of the NFT
    #[derive(Drop, starknet::Event)]
    struct AccountCreated {
        #[key]
        account_address: ContractAddress,
        token_contract: ContractAddress,
        token_id: u256,
    }

    mod Errors {
        const CALLER_IS_NOT_OWNER: felt252 = 'Registry: caller is not onwer';
    }

    #[embeddable_as(RegistryImpl)]
    impl Registry<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>
    > of IRegistry<ComponentState<TContractState>> {

        fn create_account(
            ref self: ComponentState<TContractState>,
            implementation_hash: felt252,
            token_contract: ContractAddress,
            salt: felt252
        ) -> ContractAddress {
            return self._create_account(implementation_hash, token_contract, salt);
        }

        fn get_account(
            self: @ComponentState<TContractState>,
            implementation_hash: felt252,
            token_contract: ContractAddress,
            token_id: u256,
            salt: felt252
        ) -> ContractAddress {
            return self._get_account(implementation_hash, token_contract, token_id, salt);
        }

        fn total_deployed_accounts(
            self: @ComponentState<TContractState>, token_contract: ContractAddress, token_id: u256
        ) -> u8 {
            return self._total_deployed_accounts(token_contract, token_id);
        }
    }

    #[embeddable_as(RegistryCamelImpl)]
    impl RegistryCamel<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>
    > of IRegistryCamel<ComponentState<TContractState>> {

        fn createAccount(
            ref self: ComponentState<TContractState>,
            implementation_hash: felt252,
            token_contract: ContractAddress,
            salt: felt252
        ) -> ContractAddress {
            return self._create_account(implementation_hash, token_contract, salt);
        }

        fn getAccount(
            self: @ComponentState<TContractState>,
            implementation_hash: felt252,
            token_contract: ContractAddress,
            token_id: u256,
            salt: felt252
        ) -> ContractAddress {
            return self._get_account(implementation_hash, token_contract, token_id, salt);
        }

        fn totalDeployedAccounts(
            self: @ComponentState<TContractState>, token_contract: ContractAddress, token_id: u256
        ) -> u8 {
            return self._total_deployed_accounts(token_contract, token_id);
        }
    }

    #[generate_trait]
    impl InternalImpl<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>
    > of InternalTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>) {
            
        }

        /// @notice deploys a new tokenbound account for an NFT
        /// @param implementation_hash the class hash of the reference account
        /// @param token_contract the contract address of the NFT
        /// @param token_id the ID of the NFT
        /// @param salt random salt for deployment
        fn _create_account(
            ref self: ComponentState<TContractState>,
            implementation_hash: felt252,
            token_contract: ContractAddress,
            salt: felt252
        ) -> ContractAddress {
            let token_id = self._mint_nft(
                NFT_CONTRACT_ADDRESS.try_into().unwrap(),
                get_caller_address()
            );

            let mut constructor_calldata: Array<felt252> = array![
                token_contract.into(), token_id.low.into(), token_id.high.into()
            ];

            let class_hash: ClassHash = implementation_hash.try_into().unwrap();
            let result = deploy_syscall(class_hash, salt, constructor_calldata.span(), true);
            let (account_address, _) = result.unwrap_syscall();

            let new_deployment_index: u8 = self
                .registry_deployed_accounts
                .read((token_contract, token_id))
                + 1_u8;
            self.registry_deployed_accounts.write((token_contract, token_id), new_deployment_index);

            self.emit(AccountCreated { account_address, token_contract, token_id, });

            account_address
        }

        /// @notice calculates the account address for an existing tokenbound account
        /// @param implementation_hash the class hash of the reference account
        /// @param token_contract the contract address of the NFT
        /// @param token_id the ID of the NFT
        /// @param salt random salt for deployment
        fn _get_account(
            self: @ComponentState<TContractState>,
            implementation_hash: felt252,
            token_contract: ContractAddress,
            token_id: u256,
            salt: felt252
        ) -> ContractAddress {
            let constructor_calldata_hash = PedersenTrait::new(0)
                .update(token_contract.into())
                .update(token_id.low.into())
                .update(token_id.high.into())
                .update(3)
                .finalize();

            let prefix: felt252 = 'STARKNET_CONTRACT_ADDRESS';
            let account_address = PedersenTrait::new(0)
                .update(prefix)
                .update(0)
                .update(salt)
                .update(implementation_hash)
                .update(constructor_calldata_hash)
                .update(5)
                .finalize();

            account_address.try_into().unwrap()
        }

        /// @notice returns the total no. of deployed tokenbound accounts for an NFT by the registry
        /// @param token_contract the contract address of the NFT 
        /// @param token_id the ID of the NFT
        fn _total_deployed_accounts(
            self: @ComponentState<TContractState>, token_contract: ContractAddress, token_id: u256
        ) -> u8 {
            self.registry_deployed_accounts.read((token_contract, token_id))
        }

        /// @notice return NFT owner
        /// @param token_contract contract address of NFT
        // @param token_id token ID of NFT
        // NB: This function aims for compatibility with all contracts (snake or camel case) but do not work as expected on mainnet as low level calls do not return err at the moment. Should work for contracts which implements CamelCase but not snake_case until starknet v0.15.
        fn _get_owner(
            self: @ComponentState<TContractState>, token_contract: ContractAddress, token_id: u256
        ) -> ContractAddress {
            let mut calldata: Array<felt252> = ArrayTrait::new();
            Serde::serialize(@token_id, ref calldata);
            let mut res = call_contract_syscall(
                token_contract, selector!("ownerOf"), calldata.span()
            );
            if (res.is_err()) {
                res = call_contract_syscall(token_contract, selector!("owner_of"), calldata.span());
            }
            let mut address = res.unwrap();
            Serde::<ContractAddress>::deserialize(ref address).unwrap()
        }

        fn _mint_nft(
            self: @ComponentState<TContractState>, contract_address: ContractAddress, recipient: ContractAddress
        ) -> u256 {
            let mint_pool = 1;
            let mut calldata: Array<felt252> = ArrayTrait::new();
            Serde::serialize(@recipient, ref calldata);
            Serde::serialize(@mint_pool, ref calldata);
            let mut res = call_contract_syscall(
                contract_address, selector!("mint_nft"), calldata.span()
            );
            if (res.is_err()) {
                res = call_contract_syscall(contract_address, selector!("mintNft"), calldata.span());
            }
            let mut token_id = res.unwrap();
            Serde::<u256>::deserialize(ref token_id).unwrap()
        }
    }
}