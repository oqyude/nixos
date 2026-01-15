{
  description = "zeroq vars";
  outputs =
    { self }:
    {
      devices = {
        username = "oqyude";
        server.hostname = "sapphira";
        vds.hostname = "otreca";
        mini-laptop.hostname = "lamet";
      };
    };
}
