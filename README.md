# 8BitDo Ultimate 2 – udev Fuzz & Deadzone Optimierung

Automatischer Apply von Fuzz- und Deadzone-Einstellungen für den **8BitDo Ultimate 2 Wireless Controller** sobald er mit dem System verbunden wird.

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
| `99-8bitdo-ultimate2-fuzz.rules` | udev-Regel für den 8BitDo Controller – enthält alle vier `evdev-joystick`-Befehle inline |
| `60-steam-input.rules` | Gefixte Steam-udev-Regel – behebt den `power/wakeup`-Fehler beim Booten |
| `contoller-fuzz.sh` | Bash-Skript zum manuellen Testen (mit sudo) – nicht für den Betrieb nötig |
| `apply-8bitdo-fuzz.sh` | Helfer-Skript für älteren udev-Ansatz – nicht für den Betrieb nötig |

Die beiden Bash-Skripte wurden zu Testzwecken geschrieben und sind für die Funktion der udev-Regel **nicht erforderlich**. Die udev-Regel enthält alle Befehle direkt.

## Installation

### 1. udev-Regel installieren

```bash
sudo cp 99-8bitdo-ultimate2-fuzz.rules /etc/udev/rules.d/
```

### 2. udev-Regeln neu laden

```bash
sudo udevadm control --reload-rules
```

Das war's. Ab jetzt werden die Einstellungen automatisch angewendet sobald der Controller verbunden wird.

### 3. Steam Controller `power/wakeup`-Fix installieren (falls OG Steam Controller vorhanden)

Wenn du einen OG Steam Controller mit Empfänger hast, verursacht die originale Steam-udev-Regel seit neueren Kerneln einen Fehler beim Booten:

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

### Variante A: Mit dem Bash-Skript (Controller muss verbunden sein)

```bash
sudo bash contoller-fuzz.sh
```

### Variante B: udev-Regel manuell triggern

Wenn der Controller bereits verbunden ist:

```bash
# Gerätepfad herausfinden
ls /dev/input/by-id/*8BitDo*event-joystick

# udev-Event manuell auslösen (Geräteknoten anpassen, z.B. event12)
sudo udevadm trigger --action=add /sys/class/input/event12
```

Alternativ: Controller abziehen und wieder anstecken.

### Prüfen ob die Einstellungen aktiv sind

```bash
evdev-joystick --s /dev/input/by-id/usb-8BitDo_8BitDo_Ultimate_2_Wireless_Controller_for_PC_EF8B862260-event-joystick
```

Das sollte die aktuellen Fuzz- und Deadzone-Werte für alle Achsen anzeigen. Erwartet: `fuzz=8, flat=0` für die Achsen 0, 1, 3, 4.

## Fehlersuche

### Regel wird nicht ausgeführt

1. **udev-Regel prüfen** – Syntax-Fehler finden:

```bash
udevadm verify /etc/udev/rules.d/99-8bitdo-ultimate2-fuzz.rules
```

2. **Match prüfen** – Schauen welche Eigenschaften das Gerät hat:

```bash
# Geräteknoten herausfinden (z.B. /dev/input/event12)
cat /proc/bus/input/devices | grep -A5 "8BitDo"

# udev-Eigenschaften des Geräts anzeigen
udevadm info --query=all --path=/sys/class/input/event12
```

Dort sollte `ID_SERIAL=8BitDo_8BitDo_Ultimate_2_Wireless_Controller_for_PC_EF8B862260` und `ID_INPUT_JOYSTICK=1` auftauchen. Falls die `ID_SERIAL` abweicht, muss die udev-Regel angepasst werden.

3. **udev-Events live mitverfolgen:**

```bash
sudo udevadm monitor --property --subsystem-match=input
```

Dann Controller anstecken und prüfen ob die `ID_SERIAL` mit der Regel übereinstimmt.

### evdev-joystick nicht gefunden

```bash
sudo pacman -S joyutils
```

## Deinstallation

```bash
sudo rm /etc/udev/rules.d/99-8bitdo-ultimate2-fuzz.rules
sudo rm -f /etc/udev/rules.d/60-steam-input.rules
sudo udevadm control --reload-rules
```

## Was die Einstellungen bewirken

- **Fuzz = 8**: Ignoriert Rauschen / Mikrobewegungen unterhalb von 8 Einheiten. Verhindert Stick-Drift.
- **Deadzone (flat) = 0**: Setzt die hardwareseitige Deadzone auf 0 – der fuzz-Wert übernimmt stattdessen die Filterung. Dadurch bleibt der Stick über den gesamten Bereich ansprechbar, ohne dass ungewollte Bewegungen registriert werden.
- **Achsen 0, 1**: Linker Stick (X, Y)
- **Achsen 3, 4**: Rechter Stick (X, Y)

## Lizenz

Dieses Projekt steht unter der [MIT-Lizenz](LICENSE).

## Mitwirkende

- **Marc K.** – Autor und Maintainer
- **OpenCode** – Co-Autor (udev-Regel-Optimierung, Steam-Input-Fix, Dokumentation)
