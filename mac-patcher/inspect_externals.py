#!/usr/bin/env python3
"""For each bundle: dump its externals (referenced external files) and list materials with external m_Shader PPtr."""
import os
import sys
import UnityPy

BUNDLE_DIR = os.path.expanduser("~/Library/Tabletop Simulator/Mods/Assetbundles/")

bundles = sorted(f for f in os.listdir(BUNDLE_DIR) if f.endswith(".unity3d"))

# We are most interested in bundles whose materials use external shaders (file_id != 0)
print("=" * 90)
print("BUNDLES WITH EXTERNAL m_Shader REFERENCES")
print("=" * 90)

for fname in bundles:
    path = os.path.join(BUNDLE_DIR, fname)
    short_id = fname.replace("httpssteamusercontentaakamaihdnetugc", "")[:20]
    env = UnityPy.load(path)

    external_mats = []
    for obj in env.objects:
        if obj.type.name != "Material":
            continue
        try:
            data = obj.read()
            sref = data.m_Shader
            fid = getattr(sref, "file_id", None)
            pid = getattr(sref, "path_id", None)
            if fid and fid != 0:
                external_mats.append((data.m_Name, fid, pid))
        except Exception:
            pass

    if not external_mats:
        continue

    print(f"\n{short_id}:")
    # Dump externals table
    for f in env.files.values():
        if hasattr(f, "externals"):
            print(f"  externals table:")
            for i, ext in enumerate(getattr(f, "externals", [])):
                # The externals entry usually has a 'path' and 'guid'
                ext_path = getattr(ext, "path", "?")
                ext_guid = getattr(ext, "guid", "?")
                # index i+1 because file_id is 1-based for externals (file_id=0 means self)
                print(f"    file_id={i+1}  path={ext_path!r}  guid={ext_guid}")
    print(f"  materials with external m_Shader:")
    for name, fid, pid in external_mats:
        print(f"    material={name!r}  m_Shader=(file_id={fid}, path_id={pid})")
