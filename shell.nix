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
in
  pkgs.mkShell {
    buildInputs = [
                update-buildkite-version
    ];
    shellHook = ''
      export INSANEPKGS="$(pwd)"
      NIX_PATH="$(echo "$NIX_PATH" | sed -E 's|insanepkgs=[^:]+:||g')"
      export NIX_PATH=insanepkgs=$INSANEPKGS/default.nix:$NIX_PATH
    '';
  }