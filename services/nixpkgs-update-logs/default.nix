{ isDev }:
{ pkgs, ...}:

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

  services.nginx.virtualHosts."r.ryantm.com".locations."/logdb/".proxyPass = "http://localhost:${toString wsgiPort}/";

  systemd.services.logserver = {
    wantedBy = [ "multi-user.target" ];
    path = [
      (pkgs.python3.withPackages(ps: with ps; [
        flask
        flask_sqlalchemy
        gunicorn
        psycopg2
      ]))
    ];
    environment = {
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
