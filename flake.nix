let
description = "Observes GPIO input (e.g. jumper) and triggers shutdown when pin is not LOW (pull-up activated on pin)";
in {
  inherit description;

  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } : let
    system = "aarch64-linux";
    python = nixpkgs.legacyPackages.${system}.python3;
    py3Packages = python.pkgs;
    pyproject = nixpkgs.lib.importTOML (./. + /pyproject.toml);
  in {
    packages.${system}.default = py3Packages.buildPythonApplication {
      pname = pyproject.project.name;
      version = pyproject.project.version;
      pyproject = true;

      src = ./.;

      build-system = [ py3Packages.setuptools ];

      dependencies = [ py3Packages.rpi-gpio ];
    };

    nixosModules.default = { pkgs, ... } : let
      pkg = builtins.trace pkgs.stdenv.hostPlatform.system self.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in builtins.trace self {
      config = {
        environment.systemPackages = [
          (builtins.trace pkg pkg)
        ];
        
        systemd.services.shutdownButton = {
          wantedBy = [ "multi-user.target" ];

          description = description;

          serviceConfig = {
            ExecStart = "${pkg}/bin/shutdown_button";
          };
        };
      };
    };
  };
}
