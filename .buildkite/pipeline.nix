## To generate the buildkite json, run this on the command line:
##
## nix eval -f .buildkite/pipeline.nix --json steps

##
with import <insanepkgs> { };
with builtins;
with lib;
with buildkite-pipeline;

let

  hostname = let hn = getEnv "BUILDKITE_AGENT_META_DATA_HOSTNAME";
              in if hn != "" then hn else "bk-hostname-tag-MISSING";

  DOCKER_REGISTRY = "johnae";
  PROJECT_NAME = "buildkite-nix";
  SHORTSHA = substring 0 7 (getEnv "BUILDKITE_COMMIT");

  strict-bash = command: ''
  nix-shell .buildkite/build.nix --run strict-bash <<'NIXSH'
  ${command}
  NIXSH
  '';

in

{

  steps = pipeline ([

    (step ":pipeline: Build and Push image" {
       agents = { queue="linux"; inherit hostname; };
       env = { inherit DOCKER_REGISTRY PROJECT_NAME; };
       command = strict-bash ''
         echo +++ Nix Build
         nix-build --argstr dockerRegistry "$DOCKER_REGISTRY" \
                   --argstr dockerTag bk-"$BUILDKITE_BUILD_NUMBER" docker-buildkite.nix

         echo +++ Docker import
         docker load < result

         echo +++ Docker push
         docker push johnae/"$PROJECT_NAME":bk-"$BUILDKITE_BUILD_NUMBER"
       '';
    })

    wait

    (deploy-to-kubernetes {
      application = PROJECT_NAME;
      shortsha = SHORTSHA;
      manifests-path = "kubernetes/buildkite-agent";
      approval = false;
      image = "${DOCKER_REGISTRY}/${PROJECT_NAME}";
      imageTag = "bk-${getEnv "BUILDKITE_BUILD_NUMBER"}";
    })


    #(step ":pipeline: Deploy" {
    #  agents = { queue = "linux"; inherit hostname; };
    #  env = { inherit DOCKER_REGISTRY PROJECT_NAME; };
    #  command = strict-bash ''
    #    echo --- Apply kubernetes manifest

    #    cat<<NEWTAG | tee -a kubernetes/buildkite-agent/kustomization.yaml

    #    imageTags:
    #    - name: $DOCKER_REGISTRY/$PROJECT_NAME
    #      newTag: bk-$BUILDKITE_BUILD_NUMBER
    #    NEWTAG

    #    kustomize build kubernetes/buildkite-agent | kubectl apply -f -
    #  '';
    #})

  ]);

}