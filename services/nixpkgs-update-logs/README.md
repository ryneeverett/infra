How to run webserver locally:

```sh
cd djangoproject
python manage.py runserver
```

How to run virtual machine:

```sh
nixos-rebuild build-vm --flake .#dev-build02.nix-community.org

ssh -p 2222 localhost

$BROWSER http://localhost:8080/logdb
```
