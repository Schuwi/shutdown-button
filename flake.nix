{
  description = "Observes GPIO input (e.g. jumper) and triggers shutdown when pin is not LOW (pull-up activated on pin)";

  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } : let
    system = "x86_64-linux";
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

    nixosModules.default = { config, ... } : let
      pkg = self.packages.${system}.default;
    in {
      imports = [
        builtins.trace self pkg
      ];

      config = {
        systemd.services.shutdownButton = {
          wantedBy = [ "multi-user.target" ];

          description = self.description;

          serviceConfig = {
            ExecStart = "${pkg}/bin/shutdown_button";
          };
        };
      };
    };
  };
}
