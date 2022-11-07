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
    package = pkgs.syslogng.overrideAttrs (old: rec {
      configureFlags = old.configureFlags ++ [ "--enable-sql" ];
      buildInputs = old.buildInputs ++ (with pkgs; [
        libdbi
        libdbiDriversBase
      ]);
    });
    extraConfig = ''
      source s_journald {
        systemd-journal(namespace("nixpkgs-update"));
      };

      destination d_sql {
        sql(
          type(pgsql)
          host("127.0.0.1:${toString dbPort}")
          database("nixpkgs-update-logs")
          table("''${SYSLOG_IDENTIFIER}")
          columns("datetime", "message")
          values("''${R_DATE}", "''${MESSAGE}")
          indexes("datetime")
        );
      };
    '';
  };

  services.nginx.virtualHosts."r.ryantm.com".locations."/logdb/".proxyPass = "http://localhost:${toString wsgiPort}";

  # Adapted from https://github.com/DavHau/django-nixos/blob/master/default.nix
  systemd.services.gunicorn = let
    python = import ./python.nix { inherit pkgs; };
  in {
    wantedBy = [ "multi-user.target" ];
    environment = {
      # TODO: create secret key and remove hard coded key and debug flag
      # DJANGO_SECRET_KEY = config.sops.secrets."django-secret-key";
      DJANGO_SECRET_KEY = "django-insecure-gaun66_*jbq&m7q!t1mnb98sz(pftfbpi!6k)t$i5gjgggpc_*";
      DJANGO_DEBUG = "1";
      WSGI_PORT = toString wsgiPort;
    };
    script = ''
      ${python}/bin/gunicorn djangoproject.wsgi \
        --pythonpath ${./djangoproject} \
        -b :${toString wsgiPort}
    '';
  };

}
