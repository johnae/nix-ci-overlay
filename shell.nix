with import ./default.nix { };
let

  update-buildkite-version = insane-lib.writeStrictShellScriptBin "update-buildkite-version" ''
    version=''${1:-}
    if [ -z "$version" ]; then
      echo "Please provide the wanted buildkite version"
      exit 1
    fi
    darwin_url="https://github.com/buildkite/agent/releases/download/v$version/buildkite-agent-darwin-amd64-$version.tar.gz"
    linux_url="https://github.com/buildkite/agent/releases/download/v$version/buildkite-agent-linux-amd64-$version.tar.gz"
    darwin_hash=$(nix-prefetch-url "$darwin_url")
    linux_hash=$(nix-prefetch-url "$linux_url")
    cat<<EOF>pkgs/buildkite/metadata.json
    {
      "version": "$version",
      "x86_64-linux": {
        "sha256": "$linux_hash",
        "url": "$linux_url"
      },
      "x86_64-darwin": {
        "sha256": "$darwin_hash",
        "url": "$darwin_url"
      }
    }
    EOF
  '';

  replace_or_insert_nix_path = regex: value:
    let
      existing_path = builtins.match regex (builtins.getEnv "NIX_PATH");
    in
      if existing_path != null then
        builtins.replaceStrings existing_path
          [ value ]
          (builtins.getEnv "NIX_PATH")
      else
        "${value}:${builtins.getEnv "NIX_PATH"}";

  INSANEPKGS = toString ./.;
  NIX_PATH = replace_or_insert_nix_path "(insanepkgs=[^:]+).*"
                                        "insanepkgs=${INSANEPKGS}/default.nix";



in
  pkgs.mkShell {
    buildInputs = [
       update-buildkite-version
    ];
    inherit INSANEPKGS NIX_PATH;
  }