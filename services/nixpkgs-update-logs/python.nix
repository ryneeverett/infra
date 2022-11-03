{ pkgs, ... }:

pkgs.python3.withPackages(ps: with ps; [
  django
  gunicorn
  psycopg2
])
