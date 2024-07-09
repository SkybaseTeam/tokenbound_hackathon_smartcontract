mod interfaces {
    mod IAccount;
    mod IRegistry;
    mod IUpgradeable;
}
mod components {
    mod Account;
    mod Upgradeable;

    use Account::AccountComponent;
    use Upgradeable::UpgradeableComponent;
}
mod contracts {
    mod Account;
    mod Registry;
}