{dockerRegistry, dockerTag ? "latest" }:
with import <insanepkgs> { };

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
    imageDigest = "sha256:b847b7c77a91578ebb075b91e6e8961a2e8a0dae033cb24c01126c6406826def";
    sha256 = "1m8v64w5bnz9y44fm74qryzzchf0s5p3kgxypw6rxhxgx68bfgpg";
  };

in

  dockerTools.buildImage {
    name = "${dockerRegistry}/buildkite-nix";
    tag = dockerTag;
    fromImage = nixImage;
    contents = paths ++ [ cacert iana-etc ./buildkite-container-root ];
    config = {
      Entrypoint = [
              "${tini}/bin/tini" "-g" "--"
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