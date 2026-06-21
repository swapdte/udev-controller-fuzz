# 8BitDo Ultimate 2 & 3 – udev Fuzz & Deadzone Optimierung

Automatisches Setzen von Fuzz- und Deadzone-Einstellungen für den **8BitDo Ultimate 2** und **8BitDo Pro 3 Wireless Controller**, sobald sie mit dem System verbunden werden.

## Inhalt

- [Unterstützte Controller](#unterstützte-controller)
- [Was die Einstellungen bewirken](#was-die-einstellungen-bewirken)
- [Wichtig: Pro 3 meldet sich in zwei Modi](#wichtig-pro-3-meldet-sich-in-zwei-modi)
- [Voraussetzungen](#voraussetzungen)
- [Dateien in diesem Ordner](#dateien-in-diesem-ordner)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Manueller Test](#manueller-test)
- [Fehlersuche](#fehlersuche)
- [Einschränkungen](#einschränkungen)
- [Deinstallation](#deinstallation)
- [Lizenz](#lizenz)
- [Mitwirkende](#mitwirkende)

## Unterstützte Controller

| Controller | Vendor:Product | Modus | Identifikation via |
|---|---|---|---|
| 8BitDo Ultimate 2 Wireless | `2dc8:6013` | USB | `ID_SERIAL` (Serial `EF8B862260`) |
| 8BitDo Pro 3 Wireless | `057e:2009` | Switch-Modus (1. Verbindung nach Reboot) | `ATTRS{uniq}` (MAC-Adresse) |
| 8BitDo Pro 3 Wireless | `2dc8:310b` | XInput-Modus (nach Neuverbinden) | `ID_VENDOR_ID` + `ID_MODEL_ID` |

## Was die Einstellungen bewirken

- **Fuzz = 8**: Ignoriert Rauschen und Mikrobewegungen unterhalb von 8 Einheiten. Verhindert Stick-Drift.
- **Deadzone (flat) = 0**: Setzt die hardwareseitige Deadzone auf 0 – der Fuzz-Wert übernimmt stattdessen die Filterung. Dadurch bleibt der Stick über den gesamten Bereich ansprechbar, ohne dass ungewollte Bewegungen registriert werden.
- **Achsen 0, 1**: Linker Stick (X, Y)
- **Achsen 3, 4**: Rechter Stick (X, Y)
- **Achsen 2, 5** (Trigger): Werden nicht gesetzt. Im Switch-Modus nicht vorhanden, im XInput-Modus als Analogachsen (0–255) vorhanden, benötigen aber keine Fuzz/Deadzone-Optimierung.

## Wichtig: Pro 3 meldet sich in zwei Modi

Der 8BitDo Pro 3 kann sich auf zwei verschiedene Arten am System melden:

### Modus 1: Switch-Modus (erste Verbindung nach Reboot)

Beim ersten Verbinden nach einem Neustart meldet sich der Controller als **"Nintendo Pro Controller"** (vendor `057e`, product `2009`). Das ist normales Verhalten für 8BitDo-Controller im Switch-Modus.

- **Treiber:** `hid_nintendo`
- **Identifikation:** MAC-Adresse (`ATTRS{uniq}`), da die USB-Serial (`000000000001`) identisch mit echten Nintendo Pro Controllern ist
- **by-id-Pfad:** `usb-Nintendo.Co.Ltd._Pro_Controller_000000000001-event-joystick`
- **Achsen:** 0, 1, 3, 4, 16, 17 (keine Trigger-Achsen 2, 5)

### Modus 2: XInput-Modus (nach Trennen und Neuverbinden)

Nach dem Trennen und Neuverbinden des Controllers wechselt dieser in den XInput-Modus und meldet sich als **"8BitDo Pro 3 Receiver"** (vendor `2dc8`, product `310b`).

- **Treiber:** `xpad`
- **Identifikation:** Vendor/Product ID (`2dc8:310b`), da `ATTRS{uniq}` in diesem Modus leer ist
- **by-id-Pfad:** `usb-8BitDo_8BitDo_Pro_3_Receiver-event-joystick`
- **Achsen:** 0, 1, 2, 3, 4, 5, 16, 17 (inkl. Trigger-Achsen 2, 5)

Die udev-Regel enthält **zwei separate Match-Blöcke**, um beide Modi abzudecken.

## Voraussetzungen

- `evdev-joystick` muss installiert sein. Auf CachyOS / Arch Linux:

```bash
sudo pacman -S joyutils
```

Prüfen ob das Tool verfügbar ist:

```bash
which evdev-joystick
```

Sollte `/usr/bin/evdev-joystick` ausgeben.

## Dateien in diesem Ordner

| Datei | Beschreibung |
|---|---|
| `99-8bitdo-ultimate2-fuzz.rules` | udev-Regel für den 8BitDo Ultimate 2 – enthält alle vier `evdev-joystick`-Befehle inline |
| `99-8bitdo-pro3-fuzz.rules` | udev-Regel für den 8BitDo Pro 3 – unterstützt beide Modi (Switch + XInput) |
| `60-steam-input.rules` | Gefixte Steam-udev-Regel – behebt den `power/wakeup`-Fehler beim Booten |
| `contoller-fuzz.sh` | Bash-Skript zum manuellen Testen (mit sudo) – nicht für den Betrieb nötig |
| `apply-8bitdo-fuzz.sh` | Helfer-Skript für älteren udev-Ansatz – nicht für den Betrieb nötig |

Die beiden Bash-Skripte wurden zu Testzwecken geschrieben und sind für die Funktion der udev-Regel **nicht erforderlich**. Die udev-Regeln enthalten alle Befehle direkt.

## Quick Start

Für alle drei Regeln auf einmal:

```bash
sudo cp 99-8bitdo-ultimate2-fuzz.rules 99-8bitdo-pro3-fuzz.rules 60-steam-input.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
```

Controller abziehen und wieder anstecken – fertig.

## Installation

### 8BitDo Ultimate 2

```bash
sudo cp 99-8bitdo-ultimate2-fuzz.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
```

### 8BitDo Pro 3

```bash
sudo cp 99-8bitdo-pro3-fuzz.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
```

Ab jetzt werden die Einstellungen automatisch angewendet sobald der jeweilige Controller verbunden wird.

### Steam Controller `power/wakeup`-Fix (falls OG Steam Controller vorhanden)

Wenn du einen OG Steam Controller mit Empfänger hast, verursacht die originale Steam-udev-Regel seit neueren Kerneln (6.10+) einen Fehler beim Booten:

```
60-steam-input.rules:14 ATTR{power/wakeup}="enabled": Could not chase sysfs attribute
```

**Ursache:** Die Regel matched auf `SUBSYSTEM=="usb"`, was sowohl USB-Devices als auch USB-Interfaces trifft. Auf Interface-Ebene existiert `power/wakeup` jedoch nicht mehr.

**Fix:** Die gepatchte Regel enthält `ENV{DEVTYPE}=="usb_device"` und trifft somit nur noch auf das richtige Sysfs-Level.

```bash
sudo cp 60-steam-input.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
```

Diese Datei überschreibt die Steam-Regel aus `/usr/lib/udev/rules.d/` komplett. Sie ist identisch zur Originalregel – nur Zeile 14 enthält den Fix.

## Manueller Test

### udev-Regel manuell triggern

Wenn der Controller bereits verbunden ist:

**Ultimate 2:**
```bash
# Gerätepfad herausfinden
ls /dev/input/by-id/*8BitDo*event-joystick

# udev-Event manuell auslösen (Geräteknoten anpassen, z.B. event12 – die Nummer variiert)
sudo udevadm trigger --action=add /sys/class/input/event12
```

**Pro 3:**
```bash
# Gerätepfad herausfinden – hängt vom Modus ab:
# Switch-Modus (1. Verbindung nach Reboot):
ls /dev/input/by-id/*Pro_Controller*event-joystick
# XInput-Modus (nach Neuverbinden):
ls /dev/input/by-id/*Pro_3_Receiver*event-joystick

# udev-Event manuell auslösen (Geräteknoten anpassen, z.B. event27 – die Nummer variiert)
sudo udevadm trigger --action=add /sys/class/input/event27
```

Alternativ: Controller abziehen und wieder anstecken.

### Prüfen ob die Einstellungen aktiv sind

**Ultimate 2:**
```bash
evdev-joystick --s /dev/input/by-id/usb-8BitDo_8BitDo_Ultimate_2_Wireless_Controller_for_PC_EF8B862260-event-joystick
```

**Pro 3:**
```bash
# Switch-Modus:
evdev-joystick --s /dev/input/by-id/usb-Nintendo.Co.Ltd._Pro_Controller_000000000001-event-joystick
# XInput-Modus:
evdev-joystick --s /dev/input/by-id/usb-8BitDo_8BitDo_Pro_3_Receiver-event-joystick
```

Das sollte die aktuellen Fuzz- und Deadzone-Werte für alle Achsen anzeigen. Erwartet: `fuzz=8, flat=0` für die Achsen 0, 1, 3, 4.

## Fehlersuche

### Regel wird nicht ausgeführt

1. **udev-Regel prüfen** – Syntax-Fehler finden:

```bash
udevadm verify /etc/udev/rules.d/99-8bitdo-ultimate2-fuzz.rules
udevadm verify /etc/udev/rules.d/99-8bitdo-pro3-fuzz.rules
```

2. **Match prüfen** – Schauen welche Eigenschaften das Gerät hat:

**Ultimate 2:**
```bash
cat /proc/bus/input/devices | grep -A5 "8BitDo"
udevadm info --query=all --path=/sys/class/input/event12
```

Dort sollte `ID_SERIAL=8BitDo_8BitDo_Ultimate_2_Wireless_Controller_for_PC_EF8B862260` und `ID_INPUT_JOYSTICK=1` auftauchen.

**Pro 3:**
```bash
# Switch-Modus:
cat /proc/bus/input/devices | grep -A5 "Pro Controller"
udevadm info -a /dev/input/by-id/usb-Nintendo.Co.Ltd._Pro_Controller_000000000001-event-joystick

# XInput-Modus:
cat /proc/bus/input/devices | grep -A5 "8BitDo"
udevadm info -a /dev/input/by-id/usb-8BitDo_8BitDo_Pro_3_Receiver-event-joystick
```

Im **Switch-Modus** sollte `ATTRS{uniq}=="C5:4E:B8:D8:17:E4"` (MAC-Adresse) und `ID_INPUT_JOYSTICK=1` auftauchen. Falls die MAC abweicht, muss die udev-Regel angepasst werden.

Im **XInput-Modus** sollte `ID_VENDOR_ID=2dc8`, `ID_MODEL_ID=310b` und `ID_INPUT_JOYSTICK=1` auftauchen. `ATTRS{uniq}` ist in diesem Modus leer – das ist normal.

3. **udev-Events live mitverfolgen:**

```bash
sudo udevadm monitor --property --subsystem-match=input
```

Dann Controller anstecken und prüfen ob die Eigenschaften mit der Regel übereinstimmen.

### MAC-Adresse des Pro 3 herausfinden

Falls du einen anderen Pro 3 hast (andere MAC) oder die Regel anpassen musst:

```bash
# Controller muss im Switch-Modus verbunden sein (1. Verbindung nach Reboot)
udevadm info -a /dev/input/by-id/usb-Nintendo.Co.Ltd._Pro_Controller_000000000001-event-joystick | grep -i uniq
```

Ausgabe (Beispiel):
```
ATTRS{uniq}=="C5:4E:B8:D8:17:E4"
```

Diesen Wert in `99-8bitdo-pro3-fuzz.rules` im Modus-1-Block bei `ATTRS{uniq}=="..."` eintragen.

> **Hinweis:** Im XInput-Modus (nach Neuverbinden) ist `ATTRS{uniq}` leer. Die MAC kann nur im Switch-Modus ausgelesen werden. Der XInput-Modus-Block der Regel verwendet stattdessen `ID_VENDOR_ID` und `ID_MODEL_ID` und muss in der Regel nicht angepasst werden.

### evdev-joystick nicht gefunden

```bash
sudo pacman -S joyutils
```

## Einschränkungen

- **SDL2 / Steam**: SDL2 (verwendet von Steam und vielen Spielen) kann den Controller via `/dev/hidraw*` anstelle von `/dev/input/event*` ansprechen. In diesem Fall werden die evdev-joystick-Einstellungen umgangen. Die Einstellungen wirken sich nur auf Software aus, die den evdev-Layer verwendet (z.B. `jstest`, `evtest`, native Linux-Spiele).
- **Zwei Modi des Pro 3**: Der Controller wechselt beim Neuverbinden vom Switch-Modus (Nintendo IDs) in den XInput-Modus (8BitDo IDs). Die udev-Regel deckt beide Modi ab, aber die Einstellungen müssen bei jedem Modus-Wechsel neu angewendet werden (passiert automatisch durch die udev-Regel).
- **by-id-Pfad nicht einzigartig**: Im Switch-Modus ist der Pfad `usb-Nintendo.Co.Ltd._Pro_Controller_000000000001-event-joystick` identisch mit dem eines echten Nintendo Pro Controllers. Die Regel matched zwar über die MAC-Adresse (`ATTRS{uniq}`), aber der `RUN`-Befehl verwendet den by-id-Pfad. Falls du beide Controller gleichzeitig anschließt, könnte der Pfad auf das falsche Gerät zeigen. Im XInput-Modus ist der Pfad `usb-8BitDo_8BitDo_Pro_3_Receiver-event-joystick` nicht serial-spezifisch – bei zwei Pro 3 Receivern gäbe es einen Konflikt.

## Deinstallation

```bash
sudo rm /etc/udev/rules.d/99-8bitdo-ultimate2-fuzz.rules
sudo rm /etc/udev/rules.d/99-8bitdo-pro3-fuzz.rules
sudo rm -f /etc/udev/rules.d/60-steam-input.rules
sudo udevadm control --reload-rules
```

## Lizenz

Dieses Projekt steht unter der [MIT-Lizenz](LICENSE).

## Mitwirkende

- **Marc K.** – Autor und Maintainer
- **OpenCode** – Co-Autor (udev-Regel-Optimierung, Steam-Input-Fix, Dokumentation)
