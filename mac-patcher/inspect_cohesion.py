#!/usr/bin/env python3
"""Inspect Cohesion bundle structure: list objects, materials, shaders, and the m_Shader PPtr."""
import os
import sys
import UnityPy

BUNDLE = os.path.expanduser(
    "~/Library/Tabletop Simulator/Mods/Assetbundles/"
    "httpssteamusercontentaakamaihdnetugc2482129948496305632EBBE2560D4336E6C96317EDDA787E225CF0E5B48.unity3d"
)

env = UnityPy.load(BUNDLE)

print("=" * 80)
print("BUNDLE METADATA")
print("=" * 80)
for f in env.files.values():
    print(f"  file: {type(f).__name__}")
    if hasattr(f, "unity_version"):
        print(f"  unity_version: {f.unity_version}")
    if hasattr(f, "target_platform"):
        print(f"  target_platform: {f.target_platform}")
    if hasattr(f, "externals"):
        print(f"  externals (cross-bundle refs):")
        for ext in getattr(f, "externals", []):
            print(f"    - {ext}")

print()
print("=" * 80)
print("ALL OBJECTS")
print("=" * 80)
for obj in env.objects:
    path_id = getattr(obj, "path_id", "?")
    type_name = obj.type.name
    try:
        data = obj.read()
        name = getattr(data, "m_Name", "") or "<no name>"
    except Exception as e:
        name = f"<read error: {e!r}>"
    print(f"  PathID={path_id:<6}  type={type_name:<15}  name={name!r}")

print()
print("=" * 80)
print("MATERIAL DETAILS (looking for Cohesion_27mm)")
print("=" * 80)
for obj in env.objects:
    if obj.type.name != "Material":
        continue
    data = obj.read()
    print(f"\nMaterial PathID={obj.path_id}  name={data.m_Name!r}")
    sref = data.m_Shader
    print(f"  m_Shader PPtr:")
    print(f"    file_id = {getattr(sref, 'file_id', '?')}   "
          f"(0 = internal to this bundle, !=0 = external file)")
    print(f"    path_id = {getattr(sref, 'path_id', '?')}")
    # Try to resolve
    try:
        sobj = sref.deref()
        if sobj:
            sd = sobj.read()
            sname = (
                getattr(getattr(sd, "m_ParsedForm", None), "m_Name", None)
                or getattr(sd, "m_Name", None)
            )
            print(f"  resolved -> Shader name = {sname!r}")
        else:
            print(f"  resolved -> None (external or missing)")
    except Exception as e:
        print(f"  resolve error: {e!r}")

print()
print("=" * 80)
print("SHADER DETAILS")
print("=" * 80)
for obj in env.objects:
    if obj.type.name != "Shader":
        continue
    data = obj.read()
    sname = (
        getattr(getattr(data, "m_ParsedForm", None), "m_Name", None)
        or getattr(data, "m_Name", None)
    )
    print(f"  PathID={obj.path_id}  Shader name={sname!r}")
