# Build guide — Trio + Equil + Linx (beginner-friendly)

This repository is a **pre-wired community fork** of [Nightscout Trio](https://github.com/nightscout/Trio) with:

- **[EquilKit](https://github.com/Hristos0527/EquilKit-Trio)** — Equil patch pump (BLE)
- **[LinxCGMKit](https://github.com/Hristos0527/LinxCGMKit-Trio)** — Linx CGM (passive BLE scan)
- **Omnipod 5** support from upstream Trio (Build #55 baseline)

You do **not** need to manually integrate the kits — they are already wired into the Xcode workspace.

## Disclaimer

This software is provided **as-is** for **experienced developers** who build and install Trio themselves.

- **Not a medical device.** Not reviewed or approved by any regulatory authority.
- **Use at your own risk.** You are solely responsible for building, installing, configuring, and operating this software with your pump and CGM.
- **No warranty.** The authors assume **no liability** for incorrect dosing, device failure, or any harm arising from use or misuse.
- Personal testing (~2 weeks, n=1) does **not** replace your own safety testing.

---

## What you need

| Requirement | Notes |
|-------------|-------|
| **Mac** | Apple Silicon or Intel with macOS 14+ recommended |
| **Xcode 16+** | Free from the Mac App Store (~12 GB download) |
| **Apple ID** | Free account works for personal device install (7-day cert) |
| **Apple Developer Program** ($99/year) | Optional — longer signing, easier rebuilds |
| **iPhone** | iOS 17+ (check Trio docs for latest minimum) |
| **Git** | Included with Xcode command-line tools |

Hardware this build supports (community plugins):

- Equil patch pump (BLE)
- Linx CGM sensor (BLE)
- Omnipod 5 (upstream Trio feature — requires Insulet beta enrollment for pod pairing)

---

## One-command build (recommended)

### 1. Clone the repository

Open **Terminal** and run:

```bash
git clone --recurse-submodules https://github.com/Hristos0527/Trio-Equil-Linx-Build.git
cd Trio-Equil-Linx-Build
```

If you already cloned without submodules:

```bash
git submodule update --init --recursive
```

### 2. Build and install on your iPhone

```bash
chmod +x scripts/build.sh scripts/install.sh
./scripts/build.sh
```

The script will:

1. Check that Xcode is installed
2. Download submodule dependencies
3. Ask for your **Apple Developer Team ID** (10 characters — find it at [developer.apple.com/account](https://developer.apple.com/account))
4. Build Trio for your connected iPhone
5. Tell you how to install

Then install:

```bash
./scripts/install.sh
```

### 3. Trust the app on iPhone

After first install:

**Settings → General → VPN & Device Management → Developer App → Trust**

---

## Build for simulator only (no iPhone / no Team ID)

Useful to verify the project compiles without signing:

```bash
./scripts/build.sh --simulator
```

You cannot run Trio on a simulator with real pump/CGM hardware — this is a compile check only.

---

## Build options

```bash
# Specify Team ID without prompt
./scripts/build.sh --team ABCDE12345

# Specific iPhone (find UDID in Xcode → Window → Devices and Simulators)
./scripts/build.sh --team ABCDE12345 --device-id 00008150-000C05D43EC1401C

# Release build
./scripts/build.sh --release --team ABCDE12345
```

---

## Build with Xcode (alternative)

If you prefer the graphical interface:

```bash
echo 'DEVELOPER_TEAM = YOUR_TEAM_ID' > ConfigOverride.xcconfig
xed .
```

In Xcode:

1. Select the **Trio** scheme
2. Select your **iPhone** as the run destination
3. **Product → Build** (⌘B), then **Product → Run** (⌘R)

---

## After installing

1. **Pump:** Settings → Pump → add **Equil Patch** (or Omnipod 5 if enrolled)
2. **CGM:** Settings → CGM → add **Linx**
3. Complete onboarding flows for each device
4. Configure Nightscout / OpenAPS settings as you would with standard Trio

See the kit repos for hardware-specific notes:

- [EquilKit-Trio README](https://github.com/Hristos0527/EquilKit-Trio)
- [LinxCGMKit-Trio README](https://github.com/Hristos0527/LinxCGMKit-Trio)

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `xcodebuild: command not found` | Install Xcode; run `xcode-select --install` |
| Signing / provisioning errors | Check Team ID; open Xcode → Settings → Accounts → sign in |
| No iPhone detected | USB cable, unlock phone, tap **Trust This Computer** |
| Build fails on submodule | Run `git submodule update --init --recursive` |
| Pump alarms "no connection" in background | EquilKit includes keepalive — ensure latest build |
| Linx gaps overnight | Known iOS BLE throttling; LinxCGMKit includes scan watchdog |

Build log is saved to `build.log` in the repo root.

---

## Version tags

Stable snapshots use tags like:

```
trio-build-55-20260703-upstream-op5
```

To build a specific snapshot:

```bash
git fetch --tags
git checkout tags/trio-build-55-20260703-upstream-op5
git submodule update --init --recursive
./scripts/build.sh
```

---

## Community

- **EquilKit:** https://github.com/Hristos0527/EquilKit-Trio
- **LinxCGMKit:** https://github.com/Hristos0527/LinxCGMKit-Trio
- **Trio Discord:** https://discord.triodocs.org
- **Trio docs:** https://triodocs.org

Developer: **Hristos** ([@Hristos0527](https://github.com/Hristos0527))
