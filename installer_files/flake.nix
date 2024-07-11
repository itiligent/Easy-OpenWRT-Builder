{
  description = "Easy OWRT Image Builder";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        my-name = "my-script";
        my-buildInputs = with pkgs; [ qemu-utils openssl binutils bash gnumake wget curl gnugrep coreutils gnused gzip python3 file ];
        my-script = (pkgs.writeScriptBin my-name (builtins.readFile ./x86-imagebuilder.sh)).overrideAttrs(old: {
          buildCommand = "${old.buildCommand}\n patchShebangs $out";
        });
      in rec {
        defaultPackage = packages.my-script;
        packages.my-script = pkgs.symlinkJoin {
          name = my-name;
          paths = [ my-script ] ++ my-buildInputs;
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = "wrapProgram $out/bin/${my-name} --prefix PATH : $out/bin";
        };
      }
    );
}
