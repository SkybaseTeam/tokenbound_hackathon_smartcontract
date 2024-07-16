mod components {
    mod erc721;
    mod upgradeable;

    use erc721::ERC721Component;
    use upgradeable::UpgradeableComponent;
}
mod interfaces {
    mod IErc721;
    mod ICollection;
    mod IUpgradeable;
}
mod contracts {
    mod collection;
}