mod interfaces {
    mod IAccount;
    mod IRegistry;
    mod IUpgradeable;
}
mod components {
    mod account;
    mod registry;
    mod upgradeable;

    use account::AccountComponent;
    use registry::RegistryComponent;
    use upgradeable::UpgradeableComponent;
}
mod contracts {
    mod account;
    mod registry;
}