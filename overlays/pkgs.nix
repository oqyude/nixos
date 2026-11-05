{
  inputs,
  ...
}:
self: super: {
  rovr = inputs.self.packages.x86_64-linux.rovr;
  pcbu-desktop = inputs.self.packages.x86_64-linux.pcbu-desktop;

  # The SDDM themes shipped by whitesur-kde (2024-11-18) are forks of the
  # breeze greeter theme and still instantiate `VirtualKeyboardLoader`, a type
  # that plasma-workspace >= 6.6 removed from org.kde.breeze.components in
  # favour of the KWin virtual-keyboard integration. sddm-greeter-qt6 refuses
  # to load such a theme and silently falls back to the plain embedded one:
  #   Main.qml:316:9: VirtualKeyboardLoader is not a type
  #   Fallback to embedded theme
  # (seen on rydiwo). Rewrite the loader to the API the current breeze theme
  # uses; see overlays/patch-whitesur-sddm.pl.
  whitesur-kde = super.whitesur-kde.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ super.perl ];
    postPatch = (old.postPatch or "") + ''
      for f in sddm/*/Main.qml; do
        ${super.perl}/bin/perl ${./patch-whitesur-sddm.pl} "$f"
      done
    '';
  });
}
