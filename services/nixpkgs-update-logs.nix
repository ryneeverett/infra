{

  services.postgresql = {
    enable = true;
    ensureDatabases = ["nixpkgs-update-logs"];
    port = 5433;
  };

  services.syslog-ng = {
    enable = true;
    extraConfig = ''
      source s_journald {
        systemd-journal(namespace("nixpkgs-update"));
      };

      destination d_sql {
        sql(type(pgsql)
            host("127.0.0.1:5433")
            database("nixpkgs-update-logs")
            table("''${SYSLOG_IDENTIFIER}")
            columns("datetime", "message")
            values("''${R_DATE}", "''${MESSAGE}")
            indexes("datetime"));
      };
    '';
  };

  # TODO Frontend website
}
