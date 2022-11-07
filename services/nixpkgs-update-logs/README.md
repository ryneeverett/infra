How to run virtual machine:

```sh
nixos-rebuild build-vm --flake .#dev-build02.nix-community.org

ssh -p 2222 localhost

$BROWSER http://localhost:8080/logdb
```
