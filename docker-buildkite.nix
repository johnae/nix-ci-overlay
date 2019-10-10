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
    imageDigest = "sha256:abc1a7afa2eb42f9f6ba4a7d427a1e5352ac4231332da5ee948b0d5d71351c68";
    sha256 = "1jw5kx4j422l9sj86nd5v6s3hlgmvp4p3lmmmf107b1yqy917xki";
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