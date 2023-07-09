# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  self,
  lib,
  nixos-generators,
  microvm,
}: let
  name = "vm";
  system = "x86_64-linux";
  formatModule = nixos-generators.nixosModules.vm;
  vm = variant: let
    hostConfiguration = lib.nixosSystem {
      inherit system;
      specialArgs = {inherit lib;};
      modules =
        [
          (import ../modules/host {
            inherit self microvm netvm dockervm;
          })

          {
            ghaf = {
              hardware.x86_64.common.enable = true;
              # Enable all the default UI applications
              profiles = {
                applications.enable = true;
                #TODO clean this up when the microvm is updated to latest
                release.enable = variant == "release";
                debug.enable = variant == "debug";
              };
            };
          }

          formatModule
        ]
        ++ (import ../modules/module-list.nix);
    };
    netvm = "netvm-${name}-${variant}";
    dockervm = "dockervm-${name}-${variant}";
  in {
    inherit hostConfiguration netvm dockervm;
    name = "${name}-${variant}";
    netvmConfiguration = import ../modules/virtualization/microvm/netvm.nix {
      inherit lib microvm system;
    };
    dockervmConfiguration = import ../modules/virtualization/microvm/dockervm.nix {
      inherit lib microvm system;
    };
    package = hostConfiguration.config.system.build.${hostConfiguration.config.formatAttr};
  };
  targets = [
    (vm "debug")
    (vm "release")
  ];
in {
  nixosConfigurations =
    builtins.listToAttrs (map (t: lib.nameValuePair t.name t.hostConfiguration) targets)
    // builtins.listToAttrs (map (t: lib.nameValuePair t.netvm t.netvmConfiguration) targets)
    // builtins.listToAttrs (map (t: lib.nameValuePair t.dockervm t.dockervmConfiguration) targets);
  packages = {
    x86_64-linux =
      builtins.listToAttrs (map (t: lib.nameValuePair t.name t.package) targets);
  };
}
