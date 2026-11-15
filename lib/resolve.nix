{ lib, layatLib }:
let
  inherit (lib) types mkOption;

  skillRefType = types.either types.str (
    types.submodule {
      options = {
        name = mkOption { type = types.str; };
        path = mkOption { type = types.str; };
      };
    }
  );

  sourceType = types.submodule {
    options = {
      src = mkOption {
        type = types.nullOr types.raw;
        default = null;
      };
      live = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      dir = mkOption {
        type = types.str;
        default = ".";
      };
      skills = mkOption {
        type = types.either (types.enum [ "all" ]) (types.listOf skillRefType);
      };
    };
  };

  setType = types.submodule {
    options = {
      scope = mkOption {
        type = types.enum [
          "project"
          "global"
        ];
      };
      paths = mkOption { type = types.listOf types.str; };
      sources = mkOption {
        type = types.listOf sourceType;
        default = [ ];
      };
    };
  };

  roots = {
    project = layatLib.projectRoot;
    global = layatLib.homeRoot;
  };

  components = p: lib.filter (c: c != "" && c != ".") (lib.splitString "/" p);
  normalize = p: lib.concatStringsSep "/" (components p);
  join = a: b: normalize "${a}/${b}";

  requireInside =
    ctx: p:
    if lib.hasPrefix "/" p || lib.elem ".." (lib.splitString "/" p) then
      throw "${ctx}: '${p}' must be a relative path without '..'"
    else
      normalize p;

  skillDirs =
    base:
    let
      go =
        rel:
        let
          entries = builtins.readDir (if rel == "" then base else "${base}/${rel}");
          subdirs = lib.attrNames (lib.filterAttrs (_: type: type == "directory") entries);
        in
        if entries ? "SKILL.md" then [ rel ] else lib.concatMap (name: go (join rel name)) subdirs;
    in
    go "";

  pinned =
    ctx: dir: ref:
    let
      subpath = join dir (requireInside ctx ref.path);
    in
    if subpath != "" && lib.last (components subpath) != ref.name then
      throw "${ctx}: '${ref.name}' would rename the skill at '${subpath}'; name must equal its directory name"
    else
      {
        inherit (ref) name;
        inherit subpath;
      };

  searched =
    ctx: source: dir:
    let
      base = if dir == "" then "${source.src}" else "${source.src}/${dir}";
      found =
        if builtins.pathExists base then
          skillDirs base
        else
          throw "${ctx}: dir '${dir}' does not exist in the source";
      nameOf = rel: lib.last ([ "" ] ++ components (join dir rel));
      index = removeAttrs (lib.groupBy nameOf found) [ "" ];
      byName =
        name:
        let
          matches = index.${name} or [ ];
        in
        if lib.hasInfix "/" name then
          throw "${ctx}: '${name}' is a path; write { name; path; } to pin a location"
        else if matches == [ ] then
          throw "${ctx}: no skill named '${name}' (found: ${lib.concatStringsSep " " (lib.attrNames index)})"
        else if lib.length matches > 1 then
          throw "${ctx}: '${name}' is found at ${lib.concatStringsSep " and " (map (join dir) matches)}; narrow it with dir or pin it with { name; path; }"
        else
          {
            inherit name;
            subpath = join dir (lib.head matches);
          };
      byRecord =
        ref:
        let
          skill = pinned ctx dir ref;
        in
        if builtins.pathExists "${source.src}/${skill.subpath}/SKILL.md" then
          skill
        else
          throw "${ctx}: no SKILL.md at '${skill.subpath}'";
    in
    if source.skills == "all" then
      if index == { } then
        throw "${ctx}: no skill found under '${dir}'; a skill at the source root needs { name; path = \".\"; }"
      else
        map byName (lib.attrNames index)
    else
      map (ref: if builtins.isString ref then byName ref else byRecord ref) source.skills;

  unsearched =
    ctx: why: source: dir:
    if source.skills == "all" then
      throw "${ctx}: \"all\" needs a source that can be read during evaluation, and ${why}; list the skills"
    else
      map (
        ref:
        if !builtins.isString ref then
          pinned ctx dir ref
        else if source.live == null then
          throw "${ctx}: '${ref}' cannot be searched for, because ${why}; write { name; path; }"
        else
          pinned ctx dir {
            name = ref;
            path = ref;
          }
      ) source.skills;

  resolveSource =
    setName: index: source:
    let
      ctx = "agenput-skills: set '${setName}', source ${toString index}";
      dir = requireInside ctx source.dir;
      isLive = source.live != null;
      skills =
        if isLive == (source.src != null) then
          throw "${ctx}: set exactly one of src and live"
        else if isLive then
          unsearched ctx "a live directory is outside the Nix store" source dir
        else if lib.isDerivation source.src then
          unsearched ctx "a derivation is not built during evaluation" source dir
        else
          searched ctx source dir;
      src =
        if !isLive then
          source.src
        else if lib.hasPrefix "/" source.live then
          layatLib.mkOutOfStoreSymlink source.live
        else
          layatLib.mkRootRelativeSymlink source.live;
    in
    map (
      skill:
      skill
      // {
        inherit src index;
        liveAt = if isLive && !lib.hasPrefix "/" source.live then join source.live skill.subpath else null;
      }
    ) skills;

  resolveSet =
    setName: set:
    let
      skills = lib.concatLists (lib.imap1 (resolveSource setName) set.sources);
      clashes = lib.filterAttrs (_: group: lib.length group > 1) (lib.groupBy (skill: skill.name) skills);
      entry = path: skill: {
        name = "${path}/${skill.name}";
        value = {
          inherit (skill) src;
          subpath = if skill.subpath == "" then "." else skill.subpath;
        };
      };
      # layat rejects a link whose source is its own target, so a live skill is not placed where it already sits.
      inPlace = path: skill: skill.liveAt == join path skill.name;
    in
    if clashes != { } then
      throw "agenput-skills: set '${setName}': ${
        lib.concatStringsSep "; " (
          lib.mapAttrsToList (
            name: group:
            "'${name}' comes from sources ${
              lib.concatMapStringsSep " and " (skill: toString skill.index) group
            }"
          ) clashes
        )
      }"
    else
      {
        root = roots.${set.scope};
        entries = lib.listToAttrs (
          lib.concatMap (path: map (entry path) (lib.filter (skill: !inPlace path skill) skills)) (
            lib.unique set.paths
          )
        );
      };
in
{
  inherit setType resolveSet;
}
