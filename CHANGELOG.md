# Changelog

All notable changes to the Trio + Equil + Linx community build. Fork development **Jun 2026 – Jul 2026**.

Author: **Hristos** ([@Hristos0527](https://github.com/Hristos0527))

Upstream baseline: [nightscout/Trio](https://github.com/nightscout/Trio) **v0.8.2** → **v0.8.4** (Build #55).

Plugin repos: [EquilKit-Trio](https://github.com/Hristos0527/EquilKit-Trio) · [LinxCGMKit-Trio](https://github.com/Hristos0527/LinxCGMKit-Trio)

---

## [1.0.0] - 2026-07-03 — Public release

Pre-wired Trio fork with EquilKit + LinxCGMKit + Omnipod 5 (upstream) integrated.

- **Trio app version**: 0.8.4 (Build #55 upstream merge)
- **EquilKit**: full handoff port + Build #53 background keepalive
- **LinxCGMKit**: 3 min loop gate + Build #52 background BLE scan fix
- **Omnipod 5**: `feat/o5` minimal support (Build #54)
- One-command build/install via `scripts/build.sh` and `scripts/install.sh`

See plugin changelogs for kit-specific detail.

---

## Development history (pre-release)

### Baseline

| Field | Value |
|-------|-------|
| Clone date | 2026-06-15 22:43 (+0200) |
| Baseline commit | `86e4f4c` — upstream **v0.8.2** |
| Backup branch | `backup/pre-full-port-20260623` @ `86e4f4c` |
| Upstream merge point | `7b8db13` — **v0.8.3** (2026-06-20) |
| Bundle ID | `org.nightscout.DF6M6737H2.trio` |
| GitHub fork | https://github.com/Hristos0527/trio-equil-linx |

### Build summary (#0 – #55)

| Build | Date | Equil | Linx CGM | Other | Installed |
|-------|------|:-----:|:--------:|-------|:---------:|
| **#0** | 2026-06-15 | — | — | Clean upstream clone v0.8.2 | — |
| **#1** | ~2026-06-22 | Partial handoff | — | LinxCGMKit dir created | — |
| **#2** | 2026-06-23 | Handoff preserved | — | Upstream pull v0.8.3 | — |
| **#3** | 2026-06-23 | Full port | Initial kit | Workspace wiring | — |
| **#4** | 2026-06-23 | — | — | First iphoneos build (device unavailable) | — |
| **#5** | 2026-06-23 | — | — | First iPhone install | ✓ |
| **#6–14** | 2026-06-24 | UI, battery %, crashes, dashboard | 3 min loop attempt | Intensive device testing | ✓ |
| **#15–19** | 2026-06-24–25 | Battery alerts, suspend/resume | — | Loop.app mistaken install (#37 later) | mixed |
| **#20** | ~2026-06-25 | Priming, run-gate, mute, HUD battery | — | | ? |
| **#21–25** | 2026-06-25–26 | Priming stability, battery opt | Loop gate 5p+4.5p | Parallel build stalls | BUILD only |
| **#26** | ~2026-06-27 | Priming held-open fix | — | Unified rebuild | ✓ |
| **#27** | ~2026-06-27 | — | NS dedup | | ✓ |
| **#28** | 2026-06-28 | BLE retry, UUID persist | — | Oldest surviving backup | ✓ |
| **#29** | 2026-06-29 | — | — | CH/FPU batch import, FPU default 0.6 | ? |
| **#30–31** | 2026-06-30 | Incremental fixes | — | | likely ✓ |
| **#32** | 2026-06-30 01:22 | prepareForLoopCycle | 5p loop + dedup | Garmin Hypo CIQ UUID | ✓ |
| **#33–35** | 2026-06-30 | Finetuning | — | | ? |
| **#36** | 2026-06-30 02:13 | — | — | Last stable loop **without** hypo timer | likely ✓ |
| **#37** | 2026-06-30 02:14 | — | — | ⚠️ **Loop.app** not Trio — do not restore | ✓ (wrong app) |
| **#38–39** | 2026-06-30 02:20–22 | — | — | Restore after Loop.app mistake | ✓ |
| **#40–43** | 2026-06-30 02:23 | — | — | Hypo repeat timer → crash loop | ✓ |
| **#44** | 2026-06-30 02:27 | — | — | Stable, hypo timer OFF | ✓ |
| **#45** | 2026-06-30 02:32 | — | — | Stable, hypo timer ON, no BG task | ✓ |
| **#46–47** | 2026-06-30 02:42–44 | — | — | BGProcessingTask → crash returns | ✓ |
| **#49** | 2026-06-30 02:56 | — | — | Pre-Garmin restore, loop OK | ✓ |
| **#50** | 2026-06-30 | — | — | Hypo UI settings (uncommitted) | uncertain |
| **#51** | 2026-06-30 21:34 | Build #26 restore | **3 min loop** restored | Hypo timer OFF | ✓ |
| **#52** | 2026-07-03 | — | Background BLE scan fix | Tag: `trio-build-52-…` | ✓ |
| **#53** | 2026-07-03 | Background keepalive | — | Tag: `trio-build-53-…` | ✓ |
| **#54** | 2026-07-03 | — | — | Omnipod 5 `feat/o5` minimal | BUILD only |
| **#55** | 2026-07-03 | — (unchanged) | — (unchanged) | Upstream **v0.8.4** merge | BUILD only |

### Notable non-plugin changes

| Area | Builds | Summary |
|------|--------|---------|
| **CH/FPU** | #29, #32+ | `CarbsStorage` batch import fix; FPU default `individualAdjustmentFactor` 0.5 → 0.6 |
| **Garmin/Hypo** | #32, #36–49, #50 | Hypo CIQ app UUID, repeat timer experiments, BGProcessingTask crashes, UI settings |
| **Glucose/NS** | #27, #32 | Deduplication, memory trim |
| **APS/Loop** | #32, #51 | Pump sync wait before loop; 3 vs 5 min loop interval experiments |
| **Omnipod 5** | #54, #55 | Submodule bump to `feat/o5`; upstream v0.8.4 merge |

### Git versioning (from Build #51)

| Field | Value |
|-------|-------|
| First tag | `trio-build-51-20260630-restore26-3min-loop` |
| Tag pattern | `trio-build-NN-YYYYMMDD-short-description` |
| EquilKit / LinxCGMKit | Vendored in fork (not separate submodules) |

### Known rollback points

| Goal | Backup / tag | Build |
|------|--------------|-------|
| Loop OK, no hypo timer | `0213` or `0256-pre-garmin-restore` | #36, #49 |
| Build #26 + 3 min loop | `2134-build51-build26-restore` / tag build-51 | **#51** |
| Hypo test, stable | `0232-hypo-timer-enabled` | #45 |
| Pre-port clean upstream | `backup/pre-full-port-20260623` | #0 |
| **Never use** | `0214` (Loop.app!) | #37 |

### Reconstruction gaps

- **Jun 24–26**: no `/tmp/trio-app-backups/` files; per-build diffs not reconstructable
- **Jun 27**: `0143`, `1453` backups deleted — stash hashes only
- **Jun 29**: no Trio backup or build log
- **Builds #30–35, #38–48**: identifiable by backup name, exact file diffs unavailable

---

*56 documented build events (#0–#55). Source: working-tree backups, git stash checkpoints, agent transcripts.*
