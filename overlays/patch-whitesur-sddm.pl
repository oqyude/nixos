#!/usr/bin/env perl
#
# Patch the WhiteSur SDDM theme for plasma-workspace >= 6.6.
#
# The WhiteSur theme (whitesur-kde 2024-11-18) is a fork of the breeze SDDM
# theme and instantiates `VirtualKeyboardLoader`. That type used to be exported
# by the `org.kde.breeze.components` QML module shipped in plasma-workspace, but
# it was removed in favour of the `org.kde.plasma.workspace.keyboardlayout`
# KWin virtual-keyboard integration.
#
# Without this patch sddm-greeter-qt6 fails to load Main.qml:
#   Main.qml:316:9: VirtualKeyboardLoader is not a type
#   Fallback to embedded theme
# and the login screen silently degrades to the plain built-in theme.
#
# Replace the loader with the same API the current breeze theme uses
# (Keyboards.KWinVirtualKeyboard), keeping the `inputPanel` object name and its
# `keyboardActive` / `showHide()` interface used elsewhere in Main.qml.
#
# Usage: perl patch-whitesur-sddm.pl sddm/*/Main.qml
use strict;
use warnings;

my $stub = <<'STUB';
        Item {
            id: inputPanel
            visible: false

            readonly property bool keyboardActive: Keyboards.KWinVirtualKeyboard.visible

            function showHide() {
                if (Keyboards.KWinVirtualKeyboard.visible) {
                    Keyboards.KWinVirtualKeyboard.active = false;
                } else {
                    Keyboards.KWinVirtualKeyboard.forceActivate();
                }
            }
        }
STUB

for my $file (@ARGV) {
    open my $in, '<', $file or die "open $file: $!";
    local $/;
    my $src = <$in>;
    close $in;

    # Nothing to do for themes that do not use the old loader.
    next if $src !~ /VirtualKeyboardLoader/;

    $src =~ s{^[ \t]*VirtualKeyboardLoader \{.*?^[ \t]*\}[ \t]*\n}{$stub}ms
        or die "$file: could not locate the VirtualKeyboardLoader block\n";

    if ($src !~ /keyboardlayout as Keyboards/) {
        $src =~ s{(import org\.kde\.plasma\.plasma5support [^\n]*\n)}
                  {$1import org.kde.plasma.workspace.keyboardlayout as Keyboards\n}
            or die "$file: could not locate the plasma5support import\n";
    }

    open my $out, '>', $file or die "write $file: $!";
    print $out $src;
    close $out;
}
