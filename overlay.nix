self: super:
let
  insane-pkgs = super.callPackage ./pkgs/insane {};
in
  with insane-pkgs; rec {

    buildkite-latest = super.callPackage ./pkgs/buildkite {};
    inherit insane-lib buildkite-pipeline buildkite;

    installcheck = super.stdenv.mkDerivation {
      name = "installcheck";
      buildInputs = [
        (insane-lib.writeStrictShellScriptBin "installcheck" ''
          RED='\033[0;31m'
          NEUTRAL='\033[0m'
          neutral() { printf "%b" "$NEUTRAL"; }
          start() { printf "%b" "$1"; }
          clr() { start "$1""$2"; neutral; }

          INSANEPKGS=''${INSANEPKGS:-}
          NIX_PATH=''${NIX_PATH:-}
          if [ -z "$INSANEPKGS" ] ||
             ! echo "$NIX_PATH" | grep "insanepkgs=" >/dev/null; then

          cat<<EOF
          ---------------------------------------------------------------------------
          $(clr "$RED" "WARNING:") Please add '. $HOME/.insane/etc/profile.d/insane.sh' to your
          .profile. Without the above, these packages won't work fully.
          ---------------------------------------------------------------------------
          EOF
          exit 1

          fi
        ''
        )
      ];
    };
  }
