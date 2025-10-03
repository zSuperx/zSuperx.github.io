{
  description = "Quartz static site";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    quartz-src = {
      url = "github:jackyzha0/quartz/v4";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    quartz-src,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = {
          default = pkgs.buildNpmPackage {
            name = "quartz";
            npmDepsHash = "sha256-rZcEzU0nZb85T+xj+OHJn1x197orw8On51vmz+BIxUM=";
            src = quartz-src;
            dontNpmBuild = true;

            installPhase = ''
              runHook preInstall
              npmInstallHook
              cd $out/lib/node_modules/@jackyzha0/quartz
              rm -rf ./content
              mkdir content
              cp -r ${./content}/* ./content
              $out/bin/quartz build
              mv ./public $out/public
              runHook postInstall
            '';
          };
        };
      }
    );
}
