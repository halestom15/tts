#!/usr/bin/env python3
"""Scan TTS AssetBundles for material -> shader references."""
import UnityPy
import os
import sys
from collections import defaultdict, Counter

BUNDLE_DIR = os.path.expanduser("~/Library/Tabletop Simulator/Mods/Assetbundles/")
STOCK_PREFIXES = (
    "Standard",
    "Hidden/",
    "Mobile/",
    "Particles/",
    "UI/",
    "Sprites/",
    "Skybox/",
    "Legacy Shaders/",
    "Universal Render Pipeline/",
    "URP/",
    "Unlit/",
    "GUI/",
    "Lightmap",
    "VertexLit",
    "Reflective/",
    "Self-Illumin/",
    "Transparent/",
    "FX/",
    "Nature/",
    "TextMeshPro/",
    "TextMesh Pro/",
)

def is_stock(name: str) -> bool:
    return any(name.startswith(p) for p in STOCK_PREFIXES)

shader_to_bundles = defaultdict(set)
shader_material_count = Counter()
bundle_to_shaders = defaultdict(set)
embedded_shaders_per_bundle = defaultdict(set)
errors = []
bundle_summary = []

bundles = sorted(f for f in os.listdir(BUNDLE_DIR) if f.endswith(".unity3d"))
print(f"Scanning {len(bundles)} bundles in {BUNDLE_DIR}\n", file=sys.stderr)

for fname in bundles:
    path = os.path.join(BUNDLE_DIR, fname)
    short_id = fname.replace("httpssteamusercontentaakamaihdnetugc", "")[:20]
    fsize = os.path.getsize(path)
    n_mat = 0
    n_shader = 0
    n_tex = 0
    try:
        env = UnityPy.load(path)
        for obj in env.objects:
            t = obj.type.name
            if t == "Material":
                n_mat += 1
                try:
                    data = obj.read()
                    shader_name = None
                    try:
                        sref = data.m_Shader
                        # Try multiple ways to resolve PPtr
                        try:
                            shader_obj = sref.deref()
                        except Exception:
                            shader_obj = None
                        if shader_obj is None:
                            try:
                                shader_obj_read = sref.read()
                                if shader_obj_read is not None:
                                    shader_name = (
                                        getattr(getattr(shader_obj_read, "m_ParsedForm", None), "m_Name", None)
                                        or getattr(shader_obj_read, "m_Name", None)
                                    )
                            except Exception:
                                pass
                        else:
                            sd = shader_obj.read()
                            shader_name = (
                                getattr(getattr(sd, "m_ParsedForm", None), "m_Name", None)
                                or getattr(sd, "m_Name", None)
                            )
                    except Exception as e:
                        errors.append(f"{short_id} mat shader resolve: {e!r}")
                    if not shader_name:
                        # PPtr fields
                        try:
                            file_id = getattr(data.m_Shader, "file_id", "?")
                            path_id = getattr(data.m_Shader, "path_id", "?")
                            shader_name = f"<unresolved fileId={file_id} pathId={path_id}>"
                        except Exception:
                            shader_name = "<unresolved>"
                    # Material name
                    mat_name = getattr(data, "m_Name", "") or "<noname>"
                    shader_to_bundles[shader_name].add(short_id)
                    shader_material_count[shader_name] += 1
                    bundle_to_shaders[short_id].add((shader_name, mat_name))
                except Exception as e:
                    errors.append(f"{short_id} mat read err: {e!r}")
            elif t == "Shader":
                n_shader += 1
                try:
                    data = obj.read()
                    sname = (
                        getattr(getattr(data, "m_ParsedForm", None), "m_Name", None)
                        or getattr(data, "m_Name", None)
                    )
                    if sname:
                        embedded_shaders_per_bundle[short_id].add(sname)
                except Exception as e:
                    errors.append(f"{short_id} shader read: {e!r}")
            elif t in ("Texture2D", "Texture"):
                n_tex += 1
    except Exception as e:
        errors.append(f"{short_id}: load failed: {e!r}")

    bundle_summary.append((short_id, fsize, n_mat, n_shader, n_tex))

# === REPORT ===
print("=" * 90)
print("BUNDLE SUMMARY (id_prefix, size_bytes, n_materials, n_shaders_embedded, n_textures)")
print("=" * 90)
for short_id, fsize, n_mat, n_shader, n_tex in bundle_summary:
    print(f"  {short_id}  {fsize:>10}  mats={n_mat:>3}  shaders={n_shader:>2}  tex={n_tex:>3}")

print()
print("=" * 90)
print("SHADER FREQUENCY ACROSS ALL MATERIALS (sorted by usage)")
print("=" * 90)
for sname, count in shader_material_count.most_common():
    flag = "  [CUSTOM?]" if not is_stock(sname) and not sname.startswith("<unresolved") else ""
    n_bundles = len(shader_to_bundles[sname])
    print(f"  {count:>4} mats / {n_bundles:>2} bundles  {sname}{flag}")

print()
print("=" * 90)
print("EMBEDDED SHADERS (shaders bundled INSIDE a .unity3d, sorted)")
print("=" * 90)
all_embedded = set()
for shaders in embedded_shaders_per_bundle.values():
    all_embedded.update(shaders)
print(f"\nDistinct embedded shaders: {len(all_embedded)}")
for s in sorted(all_embedded):
    bundles_with = [b for b, ss in embedded_shaders_per_bundle.items() if s in ss]
    print(f"  - {s}   ({len(bundles_with)} bundle(s): {','.join(bundles_with[:3])}{'...' if len(bundles_with) > 3 else ''})")

print()
print("=" * 90)
print("BUNDLES REFERENCING NON-STOCK SHADERS (with material names)")
print("=" * 90)
for short_id, items in sorted(bundle_to_shaders.items()):
    custom = [(s, m) for (s, m) in items if not is_stock(s) and not s.startswith("<unresolved")]
    if custom:
        print(f"\n{short_id}:")
        for s, m in sorted(set(custom)):
            print(f"  shader={s!r}   material={m!r}")

if errors:
    print()
    print("=" * 90)
    print(f"ERRORS ({len(errors)} total, first 30)")
    print("=" * 90)
    for e in errors[:30]:
        print(f"  {e}")
