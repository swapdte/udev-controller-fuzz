#!/usr/bin/env bash
# 8BitDo Ultimate 2 - Fuzz und Deadzone Optimierung
# Wird automatisch durch die udev-Regel aufgerufen wenn der Controller verbunden wird.
# Kein sudo noetig - udev fuehrt RUN-Programme als root aus.

sleep 1

DEV="/dev/input/by-id/usb-8BitDo_8BitDo_Ultimate_2_Wireless_Controller_for_PC_EF8B862260-event-joystick"

if [ ! -e "$DEV" ]; then
    exit 1
fi

/usr/bin/evdev-joystick --e "$DEV" --f 8 --d 0 --a 0
/usr/bin/evdev-joystick --e "$DEV" --f 8 --d 0 --a 1
/usr/bin/evdev-joystick --e "$DEV" --f 8 --d 0 --a 3
/usr/bin/evdev-joystick --e "$DEV" --f 8 --d 0 --a 4
