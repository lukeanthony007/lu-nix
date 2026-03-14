pub fn workspace_banner() -> &'static str {
    "lu-nix: rust workspace online"
}

#[cfg(test)]
mod tests {
    use super::workspace_banner;

    #[test]
    fn banner_is_stable() {
        assert_eq!(workspace_banner(), "lu-nix: rust workspace online");
    }
}
