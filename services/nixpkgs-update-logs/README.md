How to build the virtual machine:

```sh
nixos-rebuild build-vm --flake .#dev-build02.nix-community.org
```

How to view the app once the virtual machine is running:

```sh
$BROWSER http://localhost:8080/logdb
```

How to ssh into the virtual machine (after adding yourself to `users/`:

```sh
ssh -p 2222 localhost

# Access database:
sudo su - postgres
psql --port 5433 nixpkgs-update-logs
```
