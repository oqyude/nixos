{
  deviceType = "minimal";
  modules = [
    (
      {
        inputs,
        ...
      }:
      {
        imports = [
          inputs.self.nixosModules.default
        ];

        system.stateVersion = "26.05";
      }
    )
  ];
}
