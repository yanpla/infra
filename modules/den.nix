{ inputs, lib, ... }:
{
  imports = [ inputs.den.flakeModule ];

  # Each host picks up the aspect of the same name from modules/servers/.
  den.hosts.x86_64-linux = lib.genAttrs [
    "alpha"
    "beta"
    "zimaboard"
    "tunneler"
  ] (_: { });
}
