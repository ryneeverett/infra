{ isDev }:
{ pkgs, lib, ...}:

let
  fetcherDb = "fetcher";
  packageDb = "package";
  dbPort = 5433;
  dbReader = "logserver";
  dbWriter = "root";
  wsgiPort = 8001;
in {
  disabledModules = [
    "services/logging/syslog-ng.nix"
  ];
  imports = [
    # TODO PR
    ./syslog-ng.nix
  ];

  services.postgresql = {
    enable = true;
    port = dbPort;
    ensureDatabases = [ fetcherDb packageDb ];
    ensureUsers = [
      {
        name = dbReader;
        ensurePermissions = {
          "ALL TABLES IN SCHEMA public" = "SELECT";
        };
      }
      {
        name = dbWriter;
        ensurePermissions = {
          "DATABASE \"${fetcherDb }\"" = "ALL PRIVILEGES";
          "DATABASE \"${packageDb}\"" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  systemd.services.syslog-ng.serviceConfig = {
    User = dbWriter;
    StandardOutput = lib.mkIf isDev (lib.mkForce "journal");
  };
  services.syslog-ng = {
    enable = true;
    package = pkgs.syslogng.overrideAttrs (old: rec {
      configureFlags = old.configureFlags ++ [ "--enable-sql" ];
      buildInputs = old.buildInputs ++ (with pkgs; [
        # Syslog-ng looks for dbd to be in the same directory as libdbi.
        # See https://github.com/syslog-ng/syslog-ng/issues/4033.
        (libdbi.overrideAttrs (old: rec {
          postFixup = ''
            ln -s ${libdbiDriversBase}/lib/dbd $out/lib/
          '';
        }))
      ]);
    });
    extraConfig = ''
      source s_journald {
        systemd-journal(namespace("nixpkgs-update"));
      };

      destination d_fetcher_db {
        sql(
          type(pgsql)
          port("${toString dbPort}")
          username("${dbWriter}")
          database("${fetcherDb}")
          table("''${SYSLOG_IDENTIFIER}")
          columns("datetime", "message")
          values("''${R_DATE}", "''${MESSAGE}")
          indexes("datetime")
        );
      };

      destination d_package_db {
        sql(
          type(pgsql)
          port("${toString dbPort}")
          username("${dbWriter}")
          database("${packageDb}")
          table("''${SYSLOG_IDENTIFIER}")
          columns("datetime", "message")
          values("''${R_DATE}", "''${MESSAGE}")
          indexes("datetime")
        );
      };

      filter f_fetcher {
        facility("local0");
      };

      filter f_package {
        facility("local1");
      };

      log {
        source(s_journald);
        filter(f_fetcher);
        destination(d_fetcher_db);
      };

      log {
        source(s_journald);
        filter(f_package);
        destination(d_package_db);
      };

    '';
    extraParams = if isDev then [ "--verbose" "--debug" "--trace" "--stderr" ] else [];
  };

  services.nginx.virtualHosts."r.ryantm.com".locations."/logdb/".proxyPass = "http://localhost:${toString wsgiPort}/";

  users.users."${dbReader}" = {
    group = dbReader;
    isSystemUser = true;
  };
  systemd.services.logserver = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.User = dbReader;
    path = [
      (pkgs.python3.withPackages(ps: with ps; [
        flask
        flask_sqlalchemy
        gunicorn
        psycopg2
      ]))
    ];
    environment = {
      FETCHER_DB = toString fetcherDb;
      PACKAGE_DB = toString packageDb;
      DB_PORT = toString dbPort;
    };
    script = if isDev then ''
      flask \
        --app ${./.}/logserver \
        --debug \
        run \
        --port ${toString wsgiPort}
      '' else ''
        gunicorn \
          logserver:app \
          --pythonpath ${./.} \
          -b :${toString wsgiPort}
        '';
  };

}
