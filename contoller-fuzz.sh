#!/usr/bin/env bash

echo "Fuzz und Deadzone Optimierung fuer 8bitdo Ultimate 2 Controller."
## 8bitdo Ultimate 2
sudo evdev-joystick --e /dev/input/by-id/usb-8BitDo_8BitDo_Ultimate_2_Wireless_Controller_for_PC_EF8B862260-event-joystick --f 8 --d 0 --a 0
sudo evdev-joystick --e /dev/input/by-id/usb-8BitDo_8BitDo_Ultimate_2_Wireless_Controller_for_PC_EF8B862260-event-joystick --f 8 --d 0 --a 1
sudo evdev-joystick --e /dev/input/by-id/usb-8BitDo_8BitDo_Ultimate_2_Wireless_Controller_for_PC_EF8B862260-event-joystick --f 8 --d 0 --a 3
sudo evdev-joystick --e /dev/input/by-id/usb-8BitDo_8BitDo_Ultimate_2_Wireless_Controller_for_PC_EF8B862260-event-joystick --f 8 --d 0 --a 4
##
exit 0
