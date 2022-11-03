{ pkgs ? import <nixpkgs> {}
, sops-import-keys-hook
, deploykit
}:

with pkgs;
mkShellNoCC {
  DJANGO_DEBUG = 1;
  DJANGO_SECRET_KEY = "django-insecure-gaun66_*jbq&m7q!t1mnb98sz(pftfbpi!6k)t$i5gjgggpc_*";

  sopsPGPKeyDirs = [
    "./keys"
  ];

  buildInputs = with pkgs; [
    (terraform.withPlugins (
      p: [
        p.cloudflare
        p.null
        p.external
        p.hydra
      ]
    ))
    jq
    sops
    python3.pkgs.invoke
    rsync

    sops-import-keys-hook
    deploykit

    (import ./services/nixpkgs-update-logs/python.nix { inherit pkgs; })
  ];
}
