{
  config,
  deviceType,
  ...
}:
{
  imports = [
    (./. + "/${deviceType}") # specific modules
  ];
}
