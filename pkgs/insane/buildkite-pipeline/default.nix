{ lib }:
with lib;
with builtins;

let

  isWait = step: step == "wait";
  isCommand = step: !(isWait step) && hasAttr "command" step;
  isBlock = step: !(isWait step) && hasAttr "block" step;

  step = label: {
    command,
    env ? [],
    agents ? [],
    artifact_paths ? null,
    timeout ? 600,
    only ? true,
    ...
  }: { inherit label timeout command env agents only; };

  cmd = step;

  block-text = {
    text,
    key,
    hint ? null,
    required ? true,
    default ? null,
    ...
  }: { inherit text key hint required default; };

  block-select = {
    select,
    key,
    options,
    ...
  }: { inherit select key options; };

  block = block: {
    fields ? [],
    prompt ? null,
    branches ? null,
    only ? true
  }: {
      inherit block prompt branches only;
      fields = remove null (map (field:
                   if hasAttr "text" field then
                      (block-text field)
                   else if hasAttr "select" field then
                      (block-select field)
                   else
                      null
               ) fields);
    };

  remove-adjacent-dups = l:
    let dup-filter = h: t:
      if length t == 0 then [ h ]
      else if h == head t then dup-filter (head t) (tail t)
      else [ h ] ++ dup-filter (head t) (tail t);
    in dup-filter (head l) (tail l);

  rtrim = f: l: if (f (last l)) then init l else l;

  pipeline = steps:
    let
      trim-last-wait = rtrim (x: (isWait x));
      augment-label = label: queue:
        if queue == "linux" then ":nix: :linux: ${label}"
        else if queue == "macos" then ":nix: :mac: ${label}"
        else label;
      explode-build-step = step:
          map (agents: { inherit agents;
                         inherit (step) command env timeout;
                         label = augment-label step.label agents.queue;
                       })
                       (if isAttrs step.agents then [ step.agents ]
                        else (unique step.agents));
    in
      trim-last-wait
        (remove-adjacent-dups
          (flatten
            (map (step: if (isCommand step) then
                          explode-build-step
                            (filterAttrsRecursive (n: v: v!= null) step)
                        else if (isBlock step) then
                          filterAttrsRecursive (n: v: v!= null)
                            { inherit (step) block fields prompt branches; }
                        else step)
                 (filter (step: (isWait step) || step.only) steps))));

  wait = "wait";

in

  { inherit step cmd block wait pipeline; }