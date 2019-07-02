{ system ? null , config ? {}, ... }:
let
  metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
  nixpkgs = builtins.fetchTarball {
    name = "${metadata.repo}-${metadata.rev}";
    url = "https://github.com/nixos/nixpkgs/archive/${metadata.rev}.tar.gz";
    sha256 = metadata.sha256;
  };
in
  import nixpkgs (
    { overlays = [(import ./overlay.nix)]; }
    // (if system != null then { inherit system; } else {})
    // { inherit config; }
  )