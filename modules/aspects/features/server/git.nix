{
  den.aspects.git.nixos.programs.git = {
    enable = true;
    config = {
      user = {
        name = "yanpla";
        email = "me@yanpla.nl";
      };
      init.defaultBranch = "main";
    };
  };
}
