#!/usr/bin/env python3
"""
PATCH ATTEMPT #1 — Rename embedded Shader m_Name from
'BucketheadBits/Projector/Cohesion' to 'Standard'.

Theory: at AssetBundle.LoadAsset, Unity may resolve the shader by name via
Shader.Find() before falling back to the embedded bytecode. If so, TTS picks
up its own built-in Standard shader and renders the Cohesion projector with
it, ignoring the broken embedded shader.

Writes to <bundle>.patched.unity3d alongside the original. Does NOT touch
the live bundle in ~/Library/Tabletop Simulator/Mods/Assetbundles/ yet.
"""
import os
import sys
import shutil
import UnityPy

BUNDLE_DIR = os.path.expanduser("~/Library/Tabletop Simulator/Mods/Assetbundles/")
BUNDLE_NAME = "httpssteamusercontentaakamaihdnetugc2482129948496305632EBBE2560D4336E6C96317EDDA787E225CF0E5B48.unity3d"
SRC = os.path.join(BUNDLE_DIR, BUNDLE_NAME)
DST = os.path.join("/tmp", "cohesion.patched.unity3d")

print(f"Loading: {SRC}")
env = UnityPy.load(SRC)

modified = False
for obj in env.objects:
    if obj.type.name != "Shader":
        continue
    data = obj.read()
    current = getattr(getattr(data, "m_ParsedForm", None), "m_Name", None) or getattr(data, "m_Name", None)
    print(f"  Found Shader PathID={obj.path_id}  current m_Name={current!r}")
    if current != "BucketheadBits/Projector/Cohesion":
        print("  -> Not our target, skipping.")
        continue

    # Modify via typetree (safest cross-version path with UnityPy)
    tree = obj.read_typetree()
    # m_ParsedForm.m_Name is the canonical name for parsed shaders.
    # m_Name may also exist for the asset itself; we try both.
    if "m_ParsedForm" in tree and "m_Name" in tree["m_ParsedForm"]:
        old = tree["m_ParsedForm"]["m_Name"]
        tree["m_ParsedForm"]["m_Name"] = "Standard"
        print(f"  -> renamed m_ParsedForm.m_Name {old!r} -> 'Standard'")
        modified = True
    if "m_Name" in tree and tree.get("m_Name"):
        old = tree["m_Name"]
        tree["m_Name"] = "Standard"
        print(f"  -> renamed m_Name {old!r} -> 'Standard'")
        modified = True

    obj.save_typetree(tree)

if not modified:
    print("ERROR: no shader matched. Aborting.")
    sys.exit(1)

# Write out the patched bundle
print(f"\nSaving patched bundle to: {DST}")
with open(DST, "wb") as f:
    f.write(env.file.save(packer="lz4"))

print(f"  size: {os.path.getsize(DST)} bytes  (original was {os.path.getsize(SRC)})")

# Verify roundtrip
print("\nVerifying patched bundle is re-loadable...")
env2 = UnityPy.load(DST)
for obj in env2.objects:
    if obj.type.name == "Shader":
        d = obj.read()
        n = getattr(getattr(d, "m_ParsedForm", None), "m_Name", None) or getattr(d, "m_Name", None)
        print(f"  After patch: Shader PathID={obj.path_id}  m_Name={n!r}")
    elif obj.type.name == "Material":
        d = obj.read()
        sref = d.m_Shader
        print(f"  Material {d.m_Name!r}  m_Shader=(file_id={sref.file_id}, path_id={sref.path_id})")

print("\nDone. Patched file ready at:", DST)
print("Run this command to replace the live bundle (only when TTS is closed):")
print(f"  cp {DST!r} {SRC!r}")
