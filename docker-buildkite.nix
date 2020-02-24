{ dockerRegistry, dockerTag ? "latest" }:
with import <insanepkgs> {};
let
  paths = [
    buildkite-latest
    bashInteractive
    openssh
    coreutils
    gitMinimal
    gnutar
    gzip
    #        docker
    xz
    tini
    cacert
  ];

  nixImage = dockerTools.pullImage {
    imageName = "nixpkgs/nix";
    imageDigest = "sha256:89ed93bf4269c9fd088daa296f0c363eab931b3c4d3c0dc3dca12091115555f3";
    sha256 = "13flfwmqhlllcd54abbmwbfqlgad49a2iz63mdw77axxhbnnfjbl";
  };
in
dockerTools.buildImage {
  name = "${dockerRegistry}/buildkite-nix";
  tag = dockerTag;
  fromImage = nixImage;
  contents = paths ++ [ cacert iana-etc ./buildkite-container-root ];
  config = {
    Entrypoint = [
      "${tini}/bin/tini"
      "-g"
      "--"
      "${buildkite-latest}/bin/buildkite-agent"
    ];
    Cmd = [ "start" ];
    Env = [
      "ENV=/etc/profile.d/nix.sh"
      "NIX_PATH=nixpkgs=channel:nixpkgs-unstable"
      "PAGER=cat"
      "PATH=/nix/var/nix/profiles/default/bin:/usr/bin:/bin"
      "GIT_SSL_CAINFO=/etc/ssl/certs/ca-bundle.crt"
      "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
      "BUILDKITE_PLUGINS_PATH=/var/lib/buildkite/plugins"
      "BUILDKITE_BUILD_PATH=/var/lib/buildkite/builds"
    ];
    Volumes = {
      "/nix" = {};
    };
  };
}
