{ config, lib, inputs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  # Claude Code reads the first directory; Pi and other Agent Skills clients read the second.
  skillRoots = [ ".claude/skills" ".agents/skills" ];

  # Every skill directory in a bucket, keyed by skill name.
  skillsIn = bucket:
    lib.mapAttrs (name: _: "${bucket}/${name}")
      (lib.filterAttrs (_: type: type == "directory") (builtins.readDir bucket));

  skills =
    skillsIn "${inputs.mattpocock-skills}/skills/engineering"
    // skillsIn "${inputs.mattpocock-skills}/skills/productivity"
    // {
      lavish = "${inputs.lavish-axi}/skills/lavish";
      # Replaces the upstream skill of the same name: adds a Lavish review of the outcome.
      grill-with-docs =
        config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/skills/grill-with-docs";
    };
in
{
  # Linked one by one, so skills installed by other tools can share these directories.
  home.file = lib.listToAttrs (lib.concatMap
    (root: lib.mapAttrsToList
      (name: source: lib.nameValuePair "${root}/${name}" { inherit source; })
      skills)
    skillRoots);
}
