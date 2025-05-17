{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  users = {
    users = {
      beets = {
        #isNormalUser = true;
        description = "beets service";
        #initialPassword = "1234";
        extraGroups = [
          "beets"
        ];
      };
    };
  };
}
