{step, block, trigger, wait}:
with builtins;
let
  deploy-to-kubernetes = {
                       application,
                       shortsha,
                       manifest-cmd,
                       image,
                       imageTag,
                       agents ? { queue = "linux"; },
                       triggered_pipeline ? "gitops",
                       approval ? true,
                       only ? true,
                       env ? {}}:
    let

      command-wrapper = command: ''
      nix-shell -I nixpkgs="$INSANEPKGS" \
      -p insane-lib.strict-bash \
      -p findutils \
      -p curl \
      -p jq \
      -p kubectl \
      --run strict-bash <<'NIXSH'
      ${command}
      NIXSH
      '';

      stepenv = env // {
        APPLICATION = application;
        APP_SHORTSHA = shortsha;
        IMAGE = image;
        IMAGE_TAG = imageTag;
      };

      maybe-block = if approval then
        (block ":rocket: Deploy to kubernetes?" { inherit only; })
      else
        wait; ##functions as a noop (bit hacky though) since any adjacent dupes are filtered out of the pipeline
    in
      [
        maybe-block

        (trigger ":k8s: DEPLOY: commit ${stepenv.APPLICATION} cluster state" {
          trigger = triggered_pipeline;
          build = {
            env = stepenv;
            meta_data = {
              manifest = ''$(nix-shell -I nixpkgs=$NIXPKGS -p kubectl --run 'kubectl kustomize ${manifests-path} | base64 -w0')'';
            };
          };
          dynamic = true;
          inherit agents only;
        })

        wait

        (step ":k8s: DEPLOY ${stepenv.APPLICATION}: wait for cluster state convergence" {
          inherit agents only;
          env = stepenv;
          command = command-wrapper ''
            echo "--- Syncing cluster state"
            curl -sSL -o ./argocd https://"$ARGOCD_SERVER"/download/argocd-linux-amd64
            chmod +x argocd
            ./argocd app sync "$APPLICATION"
            ./argocd app wait --health "$APPLICATION"
          '';
        })

      ];
in
  { inherit deploy-to-kubernetes; }