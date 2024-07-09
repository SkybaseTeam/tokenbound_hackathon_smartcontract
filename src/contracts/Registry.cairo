#[starknet::contract]
mod Registry {
    use core::hash::HashStateTrait;
    use core::pedersen::PedersenTrait;
    use starknet::{
        ContractAddress, get_caller_address
    };
    use starknet::{
        SyscallResultTrait
    };
    use starknet::syscalls::{
        deploy_syscall, call_contract_syscall
    };
    use starknet::class_hash::{
        ClassHash
    };
    use tba::interfaces::{
        IRegistry::IRegistry
    };
    use core::poseidon::{
        poseidon_hash_span
    };

    #[storage]
    struct Storage {
        /// tracks no. of deployed accounts by registry for an NFT
        registry_deployed_accounts: LegacyMap<(ContractAddress, u256), u8>,
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

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        AccountCreated: AccountCreated,
    }

    mod Errors {
        const CALLER_IS_NOT_OWNER: felt252 = 'Registry: caller is not onwer';
    }

    #[abi(embed_v0)]
    impl IRegistryImpl of IRegistry<ContractState> {

        /// @notice deploys a new tokenbound account for an NFT
        /// @param implementation_hash the class hash of the reference account
        /// @param token_contract the contract address of the NFT
        /// @param token_id the ID of the NFT
        /// @param salt random salt for deployment
        fn create_account(
            ref self: ContractState,
            implementation_hash: felt252,
            token_contract: ContractAddress,
            token_id: u256
        ) -> ContractAddress {
            let owner = self.__get_owner(token_contract, token_id);
            assert(owner == get_caller_address(), Errors::CALLER_IS_NOT_OWNER);

            let mut constructor_calldata: Array<felt252> = array![
                token_contract.into(), token_id.low.into(), token_id.high.into()
            ];

            let salt = poseidon_hash_span(constructor_calldata.span());

            let class_hash: ClassHash = implementation_hash.try_into().unwrap();
            let result = deploy_syscall(class_hash, salt, constructor_calldata.span(), true);
            let (account_address, _) = result.unwrap_syscall();

            let new_deployment_index: u8 = self
                .registry_deployed_accounts
                .read((token_contract, token_id))
                + 1_u8;
            self.registry_deployed_accounts.write((token_contract, token_id), new_deployment_index);

            self.emit(AccountCreated { account_address, token_contract, token_id });

            return account_address;
        }

        fn get_account(
            self: @ContractState,
            implementation_hash: felt252,
            token_contract: ContractAddress,
            token_id: u256
        ) -> ContractAddress {
            let constructor_calldata_hash = PedersenTrait::new(0)
                .update(token_contract.into())
                .update(token_id.low.into())
                .update(token_id.high.into())
                .update(3)
                .finalize();

            let salt = poseidon_hash_span(array![
                token_contract.into(), token_id.low.into(), token_id.high.into()
            ].span());
            let prefix: felt252 = 'STARKNET_CONTRACT_ADDRESS';
            let account_address = PedersenTrait::new(0)
                .update(prefix)
                .update(0)
                .update(salt)
                .update(implementation_hash)
                .update(constructor_calldata_hash)
                .update(5)
                .finalize();

            return account_address.try_into().unwrap();
        }

        /// @notice returns the total no. of deployed tokenbound accounts for an NFT by the registry
        /// @param token_contract the contract address of the NFT 
        /// @param token_id the ID of the NFT
        fn total_deployed_accounts(
            self: @ContractState,
            token_contract: ContractAddress,
            token_id: u256
        ) -> u8 {
            return self.registry_deployed_accounts.read((token_contract, token_id));
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {

        /// @notice internal function for getting NFT owner
        /// @param token_contract contract address of NFT
        // @param token_id token ID of NFT
        fn __get_owner (
            self: @ContractState,
            token_contract: ContractAddress,
            token_id: u256
        ) -> ContractAddress {
            let mut calldata: Array<felt252> = ArrayTrait::<felt252>::new();
            Serde::serialize(@token_id, ref calldata);
            let mut res = call_contract_syscall(
                token_contract, selector!("ownerOf"), calldata.span()
            );
            if(res.is_err()) {
                res = call_contract_syscall(
                    token_contract, selector!("owner_of"), calldata.span()
                );
            }
            let mut address = res.unwrap();
            return Serde::<ContractAddress>::deserialize(ref address).unwrap();
        }
    }
}