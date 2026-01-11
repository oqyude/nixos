{ inputs, ... }:

self: super: {
  yazi = super.yazi.overrideDerivation (old: {
    passthru = (old.passthru or { }) // {
      configHome = configHome;
    };
  });
}
