# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.dci;
in {
  options.services.dci = {
    enable = mkEnableOption "DCI service";

    username = mkOption {
      type = types.str;
      description = "Username for login to ghcr.io";
    };
    pat = mkOption {
      type = types.str;
      description = "Personal Autentification token for login to ghcr.io";
    };
    compose-path = mkOption {
      type = types.str;
      description = "Path to docker-compose's .yml file";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      docker-compose
    ];

    systemd.services.my-dci = {
    script = ''
        DCPATH=$(echo ${cfg.compose-path} )
        echo "Login ghcr.io"
        export PAT=${cfg.pat}
        echo $PAT | ${pkgs.docker}/bin/docker login ghcr.io -u ${cfg.username} --password-stdin
        echo "Start docker-compose"
        ${pkgs.docker-compose}/bin/docker-compose -f $DCPATH up
      '';

      wantedBy = ["multi-user.target"];
      # If you use podman
      # after = ["podman.service" "podman.socket"];
      # If you use docker
      after = ["docker.service" "docker.socket"];
    };
  };
}
