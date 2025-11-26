if [[ -z "$DISPLAY" && "$(tty)" == "/dev/tty1" ]]; then
    startplasma-wayland
fi
