with import <insanepkgs> { };
with pkgs;
stdenv.mkDerivation {
  name = "build";
  buildInputs = with insane-lib; [
       strict-bash
       docker
       kustomize
       kubectl
       jq
  ];
}