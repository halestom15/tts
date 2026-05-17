# mac-patcher

Python patcher that injects Mac-compatibility fallbacks into a SWL TTS save
file. Works around the TTS Unity 6 (Berserk) shader bug where vanilla
AssetBundle Projectors (range rulers, cohesion halos, movement templates,
deployment zones, silhouettes) render as a magenta rectangle on macOS
because the custom shader bundled by Allen White (Dicewrench) fails to load
under Unity 6 Metal.

## What it does

For each affected object script in a `TS_Save_N.json`:

- **Cohesion / Range / Maximum Move / Deployment / Silhouette**: routes the
  visualization through a Mac-friendly path (vector lines + decal PNGs)
  built into the Global script. The vanilla bundle path stays available
  for per-seat opt-in (see "Mac TTS U6 Patch" floating panel).

- **SIL button**: renames `click_function = "toggleSilhouettes"` to
  `"macToggleSil"` + injects a forwarder. Empirically the engine silently
  swallows the original click_function name in Mac mode (the button plays
  its sound/animation but the function is never invoked). The rename
  bypasses the issue entirely.

- **clearSilhouette nil guard**: upstream `clearSilhouette()` derefs
  `removeAttachments()[1]` which is nil when `silhouetteState` is true but
  the physical silhouette attachment has been lost across save reloads.
  Patched to guard the nil case + reset state in onload.

- **Order Token Speed/Move button overrides**: inlines vanilla bodies of
  `changeSpeed1/2/3` and `moveForward/Backwards/Left/Right` to capture
  the clicking player's color (`macActivePlayerForMove`) for per-seat
  routing. Inlined rather than wrapped because the List Builder copies the
  block to Command Token Custom_Models which lack the vanilla
  Order_Token function bodies (wrap+call_orig would crash with "attempt
  to call a nil value").

## Usage

```bash
# Setup once
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Patch a save
python3 patch_save_for_mac.py <vanilla_save.json> <output_path.json> [--reload]
```

The patcher also mirrors the patched save into
`~/Library/Tabletop Simulator/Saves/TS_Save_N.json` (next free slot, or the
existing `SWL BETA - MAC PATCH` slot if present) so TTS picks it up in
Games -> Save & Load.

`--reload` hot-pushes the patched scripts to a running TTS instance via the
External Editor API (no need to restart TTS).

## Idempotence

All patches are idempotent: a re-run on an already-patched save strips the
previous Mac patch block from Global (via marker regex) and re-injects
fresh. Per-object wrappers are also stripped before re-injection.

## Files

- `patch_save_for_mac.py` - main patcher
- `scan_bundles.py` - UnityPy scanner for the local TTS bundle cache
- `extract_projector_specs.py` - dump Projector material properties from a
  bundle (used to discover the `_Arc` shader keyword for firing arc lines)
- `generate_overlay_assets.py` - regenerate the range/cohesion/etc. PNG
  decals from authoritative SWL geometry
- `inspect_*.py` - debug helpers
- `retro-*.md` - retrospective notes on each subsystem rewrite
- `SHADER_INVENTORY.md` - list of custom shaders in the vanilla bundles
