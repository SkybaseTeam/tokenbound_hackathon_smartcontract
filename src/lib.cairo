mod interfaces {
    mod IAccount;
    mod IRegistry;
}
mod components {
    mod Account;
    mod Registry;

    use Account::AccountComponent;
    use Registry::RegistryComponent;
}
mod contracts {
    mod Account;
    mod Registry;
}