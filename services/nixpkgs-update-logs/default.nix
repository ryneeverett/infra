{ pkgs, config, ...}:

let
  dbPort = 5433;
  wsgiPort = 8001;
in {

  services.postgresql = {
    enable = true;
    ensureDatabases = ["nixpkgs-update-logs"];
    port = dbPort;
  };

  services.syslog-ng = {
    enable = true;
    extraConfig = ''
      source s_journald {
        systemd-journal(namespace("nixpkgs-update"));
      };

      destination d_sql {
        sql(type(pgsql)
            host("127.0.0.1:${dbPort}")
            database("nixpkgs-update-logs")
            table("''${SYSLOG_IDENTIFIER}")
            columns("datetime", "message")
            values("''${R_DATE}", "''${MESSAGE}")
            indexes("datetime"));
      };
    '';
  };

  services.nginx.virtualHosts."r.ryantm.com".locations."/logdb/".proxyPass = "http://localhost:${wsgiPort}";

  # Adapted from https://github.com/DavHau/django-nixos/blob/master/default.nix
  services.systemd.gunicorn = let
    python = import ./python.nix { inherit pkgs; };
  in {
    environment = {
      DJANGO_SECRET_KEY = config.sops.secrets."nixpkgs-update-logs-django-secret-key";
      WSGI_PORT = wsgiPort;
    };
    script = ''
      ${python}/bin/gunicorn \
        --pythonpath ${../djangoproject} \
        -b :${wsgiPort}
    '';
  };

}
