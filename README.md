# 8BitDo Ultimate 2 – udev Fuzz & Deadzone Optimierung

Automatischer Apply von Fuzz- und Deadzone-Einstellungen fuer den **8BitDo Ultimate 2 Wireless Controller** sobald er mit dem System verbunden wird.

## Voraussetzungen

- `evdev-joystick` muss installiert sein. Auf CachyOS / Arch Linux:

```bash
sudo pacman -S joyutils
```

Pruefen ob das Tool verfuegbar ist:

```bash
which evdev-joystick
```

Sollte `/usr/bin/evdev-joystick` ausgeben.

## Dateien in diesem Ordner

| Datei | Beschreibung |
|---|---|
| `99-8bitdo-ultimate2-fuzz.rules` | udev-Regel – enthaelt alle vier `evdev-joystick`-Befehle inline |
| `contoller-fuzz.sh` | Bash-Skript zum manuellen Testen (mit sudo) – nicht fuer den Betrieb noetig |
| `apply-8bitdo-fuzz.sh` | Helfer-Skript fuer aelteren udev-Ansatz – nicht fuer den Betrieb noetig |

Die beiden Bash-Skripte wurden zu Testzwecken geschrieben und sind fuer die Funktion der udev-Regel **nicht erforderlich**. Die udev-Regel enthaelt alle Befehle direkt.

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

## Manueller Test

### Variante A: Mit dem Bash-Skript (Controller muss verbunden sein)

```bash
sudo bash contoller-fuzz.sh
```

### Variante B: udev-Regel manuell triggern

Wenn der Controller bereits verbunden ist:

```bash
# Geraetepfad herausfinden
ls /dev/input/by-id/*8BitDo*event-joystick

# udev-Event manuell ausloesen (Geraeteknoten anpassen, z.B. event12)
sudo udevadm trigger --action=add /sys/class/input/event12
```

Alternativ: Controller abziehen und wieder anstecken.

### Pruefen ob die Einstellungen aktiv sind

```bash
evdev-joystick --e /dev/input/by-id/usb-8BitDo_8BitDo_Ultimate_2_Wireless_Controller_for_PC_EF8B862260-event-joystick --q
```

Das sollte die aktuellen Fuzz- und Deadzone-Werte fuer alle Achsen anzeigen. Erwartet: `fuzz=8, flat=0` fuer die Achsen 0, 1, 3, 4.

## Fehlersuche

### Regel wird nicht ausgefuehrt

1. **udev-Regel pruefen** – Syntax-Fehler finden:

```bash
udevadm verify /etc/udev/rules.d/99-8bitdo-ultimate2-fuzz.rules
```

2. **Match pruefen** – Schauen welche Eigenschaften das Geraet hat:

```bash
# Geraeteknoten herausfinden (z.B. /dev/input/event12)
cat /proc/bus/input/devices | grep -A5 "8BitDo"

# udev-Eigenschaften des Geraets anzeigen
udevadm info --query=all --path=/sys/class/input/event12
```

Dort sollte `ID_SERIAL=8BitDo_8BitDo_Ultimate_2_Wireless_Controller_for_PC_EF8B862260` und `ID_INPUT_JOYSTICK=1` auftauchen. Falls die `ID_SERIAL` abweicht, muss die udev-Regel angepasst werden.

3. **udev-Events live mitverfolgen:**

```bash
sudo udevadm monitor --property --subsystem-match=input
```

Dann Controller anstecken und pruefen ob die `ID_SERIAL` mit der Regel uebereinstimmt.

### evdev-joystick nicht gefunden

```bash
sudo pacman -S joyutils
```

## Deinstallation

```bash
sudo rm /etc/udev/rules.d/99-8bitdo-ultimate2-fuzz.rules
sudo udevadm control --reload-rules
```

## Was die Einstellungen bewirken

- **Fuzz = 8**: Ignoriert Rauschen / Mikrobewegungen unterhalb von 8 Einheiten. Verhindert Stick-Drift.
- **Deadzone (flat) = 0**: Setzt die hardwareseitige Deadzone auf 0 – der fuzz-Wert uebernimmt stattdessen die Filterung. Dadurch bleibt der Stick ueber den gesamten Bereich ansprechbar, ohne dass ungewollte Bewegungen registriert werden.
- **Achsen 0, 1**: Linker Stick (X, Y)
- **Achsen 3, 4**: Rechter Stick (X, Y)
