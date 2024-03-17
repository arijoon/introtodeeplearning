{ config ? { }
, overlays ? [ ]
, sources ? import ./sources.nix
, system ? builtins.currentSystem
}:
let
  pkgsConfig = {
    allowUnfree = true;
    # Cudnn
    allowBroken = true;
    # cudaSupport = true;
    cudaVersion = "11.8";
    # Disabled as this will cause a very long
    # full compilation of openCv with cuda support
    # cudaSupport = true;
  } // config;
  allOverlays = [
    (self: super: { inherit sources; })
    (self: super: {
      cudaPackages = self.cudaPackages_11_8.overrideScope (final: prev: {
        cudnn = prev.cudnn_8_7;
      });
      cudatoolkit = self.cudaPackages.cudatoolkit;
    })
    (self: super: { myPython = self.callPackage (import ./python.nix) { }; })
  ] ++ overlays;
in
(import sources.nixpkgs) {
  inherit system;
  config = pkgsConfig;
  overlays = allOverlays;
}

