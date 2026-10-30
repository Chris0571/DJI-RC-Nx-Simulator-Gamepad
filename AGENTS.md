# AGENTS.md — Development Guide for AI Agents

Welcome! This document provides essential architectural context, hardware protocol specifications, and development rules for AI assistants (Antigravity, Claude, Cursor, Copilot, etc.) working on the **DJI RC-Nx Simulator Gamepad** repository.

---

## 1. Project Overview

- **Goal**: Connect DJI RC-N1, RC-N2, and RC-N3 remote controllers to a Windows PC via USB and emulate a virtual Xbox 360 controller for drone flight simulators (*DCL - The Game*, *Liftoff*, *Uncrashed*, *DJI Fly Simulator*, etc.).
- **Primary Language**: Python 3.9+
- **Key Dependencies**:
  - `pyserial`: Serial communication over USB VCOM.
  - `vgamepad`: Virtual Xbox 360 gamepad controller emulation (backed by Windows ViGEmBus).
- **License**: GNU General Public License v3.0 (`GPL-3.0`).

---

## 2. System Architecture & Workflow

```
[DJI Remote Controller]
        │  (USB-C bottom port)
        ▼
[Windows Serial Port] (DJI USB VCOM For Protocol)
        │  (pyserial @ 115200 baud)
        ▼
[main.py: DUML Protocol Parser]
   ├── Sends DUML command to activate fast Simulator Mode
   ├── Periodically requests channel data (cmd 0x01)
   └── Decodes 38-byte packets (raw range ~364..1684 -> center 1024)
        │
        ▼  (Threaded update loop)
[vgamepad: ViGEm Virtual Xbox 360 Device]
        │
        ▼
[Windows Game Controllers / Flight Simulators]
```

---

## 3. DJI DUML Protocol Specifications

The controller communicates using the DJI DUML (DJI Universal Markup Language) binary protocol.

### 3.1 Packet Structure
- **Framing**: Every packet begins with magic byte `0x55`.
- **Header**: Includes packet length, protocol version, and an 8-bit CRC header checksum calculated using polynomial seed `0x77`.
- **Packet CRC16**: 16-bit CRC appended at the end of the packet using seed `0x3692` (DJI P3/P4/Mavic seed). **Do not change this seed**, otherwise communication with RC-N series controllers will fail.

### 3.2 Simulator Mode Enable Packet
Before stick data can be read at high refresh rates, the RC must be switched into simulator mode:
- Source: `0x0a`
- Target: `0x06`
- Command Type: `0x40`
- Command Set: `0x06`
- Command ID: `0x24`
- Payload: `0x01`

### 3.3 Stick & Gimbal Channel Offsets (38-byte packet)
When `len(data) == 38`, stick data is located at the following byte slices (16-bit little-endian):
- `data[13:15]`: Right Stick Horizontal (Roll)
- `data[16:18]`: Right Stick Vertical (Pitch)
- `data[19:21]`: Left Stick Vertical (Throttle)
- `data[22:24]`: Left Stick Horizontal (Yaw)
- `data[25:27]`: Gimbal dial wheel (mapped to Button `Y` for restart race and Button `B` for drone recovery)

### 3.4 Input Normalization Formula
Raw range is `[364 .. 1684]` with center `1024`:
$$\text{normalized} = \frac{(\text{raw} - 1024) \times 2 \times 4096}{165}$$
Clamped between `-32768` and `32767` to fit standard Xbox 360 stick coordinates.

---

## 4. Key Constraints & Rules for Agents

1. **Platform Sensitivity**:
   - `vgamepad` strictly requires **Windows** and the **ViGEmBus** system driver. When testing or designing features, ensure non-Windows platforms fail gracefully or provide informative logs.
2. **Serial Port Safety**:
   - The DJI controller creates a virtual COM port titled `DJI USB VCOM For Protocol`.
   - If DJI Assistant 2 is running, the COM port will be locked. Always handle `serial.SerialException` and display helpful advice to the user.
3. **Threading & Concurrency**:
   - Gamepad updates run on a separate daemon thread to ensure smooth and jitter-free controller reporting in-game. Do not introduce blocking I/O calls inside `threaded_function()`.
4. **Preserve Compatibility**:
   - Maintain CLI argument support (`-p` / `--port COMx`) and compatibility with `start.bat`.
   - Preserve project links: Telegram (`t.me/krys_cern`) and Buy Me a Coffee (`buymeacoffee.com/chris0571`).

---

## 5. Potential Feature Extensions & Roadmap

When asked to extend or refactor this codebase, prioritize:
- **GUI Application**: A modern desktop UI (e.g. CustomTkinter or PyQt) with live visual stick gauges, COM port dropdown selector, and status indicator.
- **Stick Mode Selection**: Allow toggling between Mode 2 (default), Mode 1, Mode 3, and Mode 4.
- **Deadzone & Exponential Tuning**: Configurable deadband, curve expo, and center calibration via a JSON configuration file.
- **Cross-Platform Support**: Fallback to Linux `uinput` virtual joystick emulation when running under Linux.

