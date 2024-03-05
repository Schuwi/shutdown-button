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
    system = "aarch64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    python = pkgs.python3;
    py3Packages = python.pkgs;
    pyproject = nixpkgs.lib.importTOML (./. + /pyproject.toml);
  in {
    packages.${system}.default = py3Packages.buildPythonApplication {
      pname = pyproject.project.name;
      version = pyproject.project.version;
      pyproject = true;

      src = ./.;

      build-system = [ py3Packages.setuptools ];

      dependencies = [ py3Packages.libgpiod ];
    };

    nixosModules.default = { pkgs, ... } : let
      pkg = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in {
      config = {
        environment.systemPackages = [
          pkg
        ];
        
        systemd.services.shutdownButton = {
          description = "Observes GPIO input (e.g. jumper) and triggers shutdown when pin is not LOW (pull-up activated on pin)";

          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            ExecStart = "${pkg}/bin/shutdown_button";
          };
        };
      };
    };
  };
}
