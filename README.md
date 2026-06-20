# 8BitDo Ultimate 2 & 3 – udev Fuzz & Deadzone Optimierung

Automatisches Setzen von Fuzz- und Deadzone-Einstellungen für den **8BitDo Ultimate 2** und **8BitDo Ultimate 3 Wireless Controller**, sobald sie mit dem System verbunden werden.

## Inhalt

- [Unterstützte Controller](#unterstützte-controller)
- [Was die Einstellungen bewirken](#was-die-einstellungen-bewirken)
- [Wichtig: Ultimate 3 im Switch-Modus](#wichtig-ultimate-3-im-switch-modus)
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
| 8BitDo Ultimate 3 Wireless | `057e:2009` | Switch-Modus (S-Taste) | `ATTRS{uniq}` (MAC-Adresse) |

## Was die Einstellungen bewirken

- **Fuzz = 8**: Ignoriert Rauschen und Mikrobewegungen unterhalb von 8 Einheiten. Verhindert Stick-Drift.
- **Deadzone (flat) = 0**: Setzt die hardwareseitige Deadzone auf 0 – der Fuzz-Wert übernimmt stattdessen die Filterung. Dadurch bleibt der Stick über den gesamten Bereich ansprechbar, ohne dass ungewollte Bewegungen registriert werden.
- **Achsen 0, 1**: Linker Stick (X, Y)
- **Achsen 3, 4**: Rechter Stick (X, Y)
- **Achsen 2, 5** (Trigger): Werden nicht gesetzt – im Switch-Modus nicht als Analogachsen vorhanden.

## Wichtig: Ultimate 3 im Switch-Modus

Der 8BitDo Ultimate 3 meldet sich im Switch-Modus als **"Nintendo Pro Controller"** (vendor `057e`, product `2009`). Das ist normales Verhalten für 8BitDo-Controller im Switch-Modus. Die udev-Regel identifiziert den Controller anhand seiner MAC-Adresse (`ATTRS{uniq}`), da die USB-Serial (`000000000001`) identisch mit echten Nintendo Pro Controllern ist und nicht zur Unterscheidung taugt.

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
| `99-8bitdo-ultimate3-fuzz.rules` | udev-Regel für den 8BitDo Ultimate 3 (Switch-Modus) – identifiziert den Controller per MAC-Adresse |
| `60-steam-input.rules` | Gefixte Steam-udev-Regel – behebt den `power/wakeup`-Fehler beim Booten |
| `contoller-fuzz.sh` | Bash-Skript zum manuellen Testen (mit sudo) – nicht für den Betrieb nötig |
| `apply-8bitdo-fuzz.sh` | Helfer-Skript für älteren udev-Ansatz – nicht für den Betrieb nötig |

Die beiden Bash-Skripte wurden zu Testzwecken geschrieben und sind für die Funktion der udev-Regel **nicht erforderlich**. Die udev-Regeln enthalten alle Befehle direkt.

## Quick Start

Für alle drei Regeln auf einmal:

```bash
sudo cp 99-8bitdo-ultimate2-fuzz.rules 99-8bitdo-ultimate3-fuzz.rules 60-steam-input.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
```

Controller abziehen und wieder anstecken – fertig.

## Installation

### 8BitDo Ultimate 2

```bash
sudo cp 99-8bitdo-ultimate2-fuzz.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
```

### 8BitDo Ultimate 3

```bash
sudo cp 99-8bitdo-ultimate3-fuzz.rules /etc/udev/rules.d/
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

**Ultimate 3:**
```bash
# Gerätepfad herausfinden (meldet sich als Nintendo Pro Controller)
ls /dev/input/by-id/*Pro_Controller*event-joystick

# udev-Event manuell auslösen (Geräteknoten anpassen, z.B. event27 – die Nummer variiert)
sudo udevadm trigger --action=add /sys/class/input/event27
```

Alternativ: Controller abziehen und wieder anstecken.

### Prüfen ob die Einstellungen aktiv sind

**Ultimate 2:**
```bash
evdev-joystick --s /dev/input/by-id/usb-8BitDo_8BitDo_Ultimate_2_Wireless_Controller_for_PC_EF8B862260-event-joystick
```

**Ultimate 3:**
```bash
evdev-joystick --s /dev/input/by-id/usb-Nintendo.Co.Ltd._Pro_Controller_000000000001-event-joystick
```

Das sollte die aktuellen Fuzz- und Deadzone-Werte für alle Achsen anzeigen. Erwartet: `fuzz=8, flat=0` für die Achsen 0, 1, 3, 4.

## Fehlersuche

### Regel wird nicht ausgeführt

1. **udev-Regel prüfen** – Syntax-Fehler finden:

```bash
udevadm verify /etc/udev/rules.d/99-8bitdo-ultimate2-fuzz.rules
udevadm verify /etc/udev/rules.d/99-8bitdo-ultimate3-fuzz.rules
```

2. **Match prüfen** – Schauen welche Eigenschaften das Gerät hat:

**Ultimate 2:**
```bash
cat /proc/bus/input/devices | grep -A5 "8BitDo"
udevadm info --query=all --path=/sys/class/input/event12
```

Dort sollte `ID_SERIAL=8BitDo_8BitDo_Ultimate_2_Wireless_Controller_for_PC_EF8B862260` und `ID_INPUT_JOYSTICK=1` auftauchen.

**Ultimate 3:**
```bash
cat /proc/bus/input/devices | grep -A5 "Pro Controller"
udevadm info -a /dev/input/by-id/usb-Nintendo.Co.Ltd._Pro_Controller_000000000001-event-joystick
```

Dort sollte `ATTRS{uniq}=="C5:4E:B8:D8:17:E4"` (die MAC-Adresse deines Controllers) und `ID_INPUT_JOYSTICK=1` auftauchen. Falls die MAC abweicht, muss die udev-Regel angepasst werden.

3. **udev-Events live mitverfolgen:**

```bash
sudo udevadm monitor --property --subsystem-match=input
```

Dann Controller anstecken und prüfen ob die Eigenschaften mit der Regel übereinstimmen.

### MAC-Adresse des Ultimate 3 herausfinden

Falls du einen anderen Ultimate 3 hast (andere MAC) oder die Regel anpassen musst:

```bash
# Controller muss verbunden sein
udevadm info -a /dev/input/by-id/usb-Nintendo.Co.Ltd._Pro_Controller_000000000001-event-joystick | grep -i uniq
```

Ausgabe (Beispiel):
```
ATTRS{uniq}=="C5:4E:B8:D8:17:E4"
```

Diesen Wert in `99-8bitdo-ultimate3-fuzz.rules` bei `ATTRS{uniq}=="..."` eintragen.

### evdev-joystick nicht gefunden

```bash
sudo pacman -S joyutils
```

## Einschränkungen

- **SDL2 / Steam**: SDL2 (verwendet von Steam und vielen Spielen) kann den Controller via `/dev/hidraw*` anstelle von `/dev/input/event*` ansprechen. In diesem Fall werden die evdev-joystick-Einstellungen umgangen. Die Einstellungen wirken sich nur auf Software aus, die den evdev-Layer verwendet (z.B. `jstest`, `evtest`, native Linux-Spiele).
- **Switch-Modus**: Der Ultimate 3 muss im Switch-Modus verbunden sein, damit die Regel greift. Im XInput- oder DInput-Modus meldet er sich mit anderer vendor/product ID und die Regel trifft nicht zu.
- **by-id-Pfad nicht einzigartig**: Der Pfad `usb-Nintendo.Co.Ltd._Pro_Controller_000000000001-event-joystick` ist identisch mit dem eines echten Nintendo Pro Controllers. Die Regel matched zwar über die MAC-Adresse (`ATTRS{uniq}`), aber der `RUN`-Befehl verwendet den by-id-Pfad. Falls du beide Controller gleichzeitig anschließt, könnte der Pfad auf das falsche Gerät zeigen.

## Deinstallation

```bash
sudo rm /etc/udev/rules.d/99-8bitdo-ultimate2-fuzz.rules
sudo rm /etc/udev/rules.d/99-8bitdo-ultimate3-fuzz.rules
sudo rm -f /etc/udev/rules.d/60-steam-input.rules
sudo udevadm control --reload-rules
```

## Lizenz

Dieses Projekt steht unter der [MIT-Lizenz](LICENSE).

## Mitwirkende

- **Marc K.** – Autor und Maintainer
- **OpenCode** – Co-Autor (udev-Regel-Optimierung, Steam-Input-Fix, Dokumentation)
