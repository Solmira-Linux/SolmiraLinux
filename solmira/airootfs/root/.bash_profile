#!/bin/bash

# Only auto-start Plasma on tty1
if [[ -z "$DISPLAY" && "$(tty)" == "/dev/tty1" ]]; then
    startplasma-wayland
fi
