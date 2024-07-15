mod interfaces {
    mod IAccount;
    mod IRegistry;
    mod IUpgradeable;
}
mod components {
    mod Account;
    mod Registry;
    mod Upgradeable;

    use Account::AccountComponent;
    use Registry::RegistryComponent;
    use Upgradeable::UpgradeableComponent;
}
mod contracts {
    mod Account;
    mod Registry;
}