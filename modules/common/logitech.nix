{ inputs, ... }@flakeContext:
{
  config,
  ...
}:
{
  hardware = {
    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
  };
}
