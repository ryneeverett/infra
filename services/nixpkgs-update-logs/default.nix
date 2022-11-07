{ isDev }:
{ pkgs, lib, ...}:

let
  dbName = "nixpkgs-update-logs";
  dbPort = 5433;
  dbReader = "logserver";
  dbWriter = "root";
  wsgiPort = 8001;
in {

  services.postgresql = {
    enable = true;
    port = dbPort;
    ensureDatabases = [ dbName ];
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
          "DATABASE \"${dbName}\"" = "ALL PRIVILEGES";
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
          username ("${dbWriter}")
          database("${toString dbName}")
          table("''${SYSLOG_IDENTIFIER}")
          columns("datetime", "message")
          values("''${R_DATE}", "''${MESSAGE}")
          indexes("datetime")
        );
      };
    '';
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
      DB_NAME = toString dbName;
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
