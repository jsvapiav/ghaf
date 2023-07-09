# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  microvm,
  system,
}:
lib.nixosSystem {
  inherit system;
  modules =
    [
      {
        ghaf = {
          users.accounts.enable = true;
          development = {
            ssh.daemon.enable = true;
            debug.tools.enable = true;
          };
        };
      }

# Move that to modules
#     ../../modules/dci/dci.nix

    microvm.nixosModules.microvm

    ({pkgs, ...}: {
      networking.hostName = "appvm-docker";
      # TODO: Maybe inherit state version
      system.stateVersion = lib.trivial.release;

      microvm.hypervisor = "qemu";

      networking = {
        enableIPv6 = false;
        interfaces.ethint0.useDHCP = false;
        firewall.allowedTCPPorts = [22 80 8080 8888 4280 4222 5432];
        firewall.allowedUDPPorts = [22 80 8080 8888 4280 4222 5432];
        firewall.enable = false;
        useNetworkd = true;
      };

#      systemd.network.enable = true;

      microvm.interfaces = [
        {
          type = "tap";
          id = "vm-appvm-docker";
          mac = "02:00:00:02:03:04";
        }
      ];

      # Set internal network's interface name to ethint0
      systemd.network.links."10-ethint0" = {
        matchConfig.PermanentMACAddress = "02:00:00:02:03:04";
        linkConfig.Name = "ethint0";
      };

      systemd.network = {
        enable = true;
        networks."10-ethint0" = {
          matchConfig.MACAddress = "02:00:00:02:03:04";
          addresses = [
            {
              # IP-address for debugging subnet
              addressConfig.Address = "192.168.101.11/24";
            }
          ];
          routes =  [
            { routeConfig.Gateway = "192.168.101.1"; }
          ];
          linkConfig.RequiredForOnline = "routable";
          linkConfig.ActivationPolicy = "always-up";
        };
      };

        services.dci = {
          enable = true;
          username = "";
          pat = "";
          compose-path = "/var/lib/fogdata/docker-compose.yml";
        };

	microvm.volumes = [
	{
		image = "/var/tmp/docker.img";
		mountPoint = "/var/lib/docker";
		size = 10240;
		autoCreate = true;
		fsType = "ext4";
	}

	];

	microvm.shares = [
        {
	  # On the host
	  source = "/var/foghyper";
	  # In the MicroVM
	  mountPoint = "/var/lib/foghyper/fog_system/conf";
	  tag = "foghyperfs";
	  proto = "virtiofs";
	  socket = "foghyperfs.sock";
	}

	{
	  # On the host
	  source = "/var/fogdata";
	  # In the MicroVM
	  mountPoint = "/var/lib/fogdata";
	  tag = "fogdatafs";
	  proto = "virtiofs";
	  socket = "fogdata.sock";
	}
      ];

      microvm.qemu.bios.enable = false;
      microvm.writableStoreOverlay = "true";
      microvm.mem = 4096;
      microvm.vcpu = 2;
    })
  ]
  # TODO: fix indents!!!111111
  ++ (import ../../module-list.nix);
}
