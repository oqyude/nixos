{
  inputs,
  ...
}:
self: super: {
  rovr = inputs.self.packages.x86_64-linux.rovr;
  pcbu-desktop = inputs.self.packages.x86_64-linux.pcbu-desktop;

  # fresh-editor 0.5.4 (nixpkgs f4a03c0) не собирается: cargo-setup-hook
  # безусловно экспортирует RUSTONIG_SYSTEM_LIBONIG=1, а пакет не тянет
  # oniguruma, и onig_sys падает на `pkg-config --libs oniguruma`. В nixpkgs
  # master на 2026-11-09 не исправлено. Поэтому берём пакет из
  # inputs.nixpkgs-fresh (последний rev nixos-unstable с fresh-editor 0.5.3;
  # он уже собран на sapphira). Убрать вместе с inputs.nixpkgs-fresh, когда
  # пин nixpkgs получит исправленный пакет.
  fresh-editor = inputs.nixpkgs-fresh.legacyPackages.${super.stdenv.hostPlatform.system}.fresh-editor;

  # mcat 0.6.7 — та же поломка: hook ставит AWS_LC_SYS_USE_SYSTEM=1, а пакет
  # не тянет системный AWS-LC -> aws-lc-sys падает на этапе build. В 0.6.5
  # (nixpkgs-fresh) этой зависимости нет. Убрать вместе с fresh-editor.
  mcat = inputs.nixpkgs-fresh.legacyPackages.${super.stdenv.hostPlatform.system}.mcat;

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
