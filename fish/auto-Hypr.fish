# Auto start Hyprland on tty1
if test -z "$DISPLAY" ;and test "$XDG_VTNR" -eq 1
    mkdir -p $HOME/.cache
    exec Hyprland > $HOME/.cache/hyprland.log ^&1
end
