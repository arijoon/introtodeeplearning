{
  config ? {},
  overlays ? [],
  sources ? import ./sources.nix,
  system ? builtins.currentSystem
}:
let
  pkgsConfig = { allowUnfree = true; } // config;
  allOverlays = [
    (self: super: { inherit sources; })
    (self: super: { myPython = self.callPackage (import ./python.nix) {};  })
  ] ++ overlays;
in
  (import sources.nixpkgs) {
    inherit system;
    config = pkgsConfig;
    overlays = allOverlays;
  }

