{
  inputs,
  ...
}:
self: super: {
  rovr = inputs.self.packages.x86_64-linux.rovr;
}
