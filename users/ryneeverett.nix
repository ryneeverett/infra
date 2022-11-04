{ config, pkgs, lib, ... }:
let
  userLib = import ./lib.nix { inherit lib; };
  keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID8GxMdPCMqQ7rxvTrPzkgsCE9n1XwSDuDyQYnjwb4EL"
  ];

in
{
  users.users.ryne = {
    openssh.authorizedKeys.keys = keys;
    useDefaultShell = true;
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "trusted"
    ];
    uid = userLib.mkUid "ryne";
  };
}
