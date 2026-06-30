# LinxCGMKit

A Loop CGM plugin that directly scans the Linx BLE glucose sensor and feeds readings to Loop as a continuous glucose monitor (treated like a Dexcom).

## Modules

- **LinxCGMKit** (framework) — core logic: BLE scanner (`LinxScanner`), advertisement decoder (`LinxDecoder`), two-point calibration, `LinxCGMManager` (conforms to `CGMManager`).
- **LinxCGMKitUI** (framework) — SwiftUI setup + settings: serial-number entry and a self-contained two-point calibration UI.
- **LinxCGMPlugin** (`.loopplugin` bundle) — `CGMManagerUIPlugin` entry point that Loop loads.

## How it works

1. The plugin scans for the Linx sensor's BLE advertisement (service `181F`, manufacturer ID `0x0059`), filtered by the serial number you enter.
2. The raw advertisement is decoded to a glucose value using a two-point calibration curve you set in the plugin's own UI.
3. A new `NewGlucoseSample` is handed to Loop **once every 5 minutes** (a gate; the scanner itself listens continuously). This drives a Loop cycle every 5 minutes, like a real CGM.

## Project generation

The `.xcodeproj` is generated with [XcodeGen](https://github.com/yonatanutmazgin/XcodeGen):

```sh
xcodegen generate
```

## Loop integration

Added to a Loop fork as a git submodule under `LoopWorkspace`, referenced in `LoopWorkspace.xcworkspace/contents.xcworkspacedata` and built via the `LinxCGMPlugin.loopplugin` build action in the scheme.

## ⚠️ Medical safety

This plugin feeds a reverse-engineered sensor signal into an automated insulin-dosing system. Use **open loop only** with the **pump off-body**, and cross-check against an approved CGM. Not a medical device. No warranty.
