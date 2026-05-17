#!/usr/bin/env python3
"""
Scan Unity .mat and .prefab YAML files in UnityProject-U6/Assets/Projectors/
and extract critical parameters for the SWL TTS mod refactor.

Output: materials-reference.md with structured tables per overlay.
"""
import os
import re
from pathlib import Path
from collections import defaultdict

ROOT = Path("/Users/martinpourrat/MARTIN/Star Wars Legion/Mod TTS SWL/UnityProject-U6/Assets/Projectors")
OUT = Path("/Users/martinpourrat/MARTIN/Star Wars Legion/Mod TTS SWL/materials-reference.md")

OVERLAYS = ["Cohesion", "Range", "Deployment", "Movement"]


def read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")


def parse_material(path: Path) -> dict:
    """Extract critical fields from a Unity .mat YAML file."""
    text = read(path)
    out = {"path": str(path.relative_to(ROOT)), "name": path.stem}

    m = re.search(r"m_ShaderKeywords:\s*(.*)", text)
    out["keywords"] = m.group(1).strip() if m else ""

    m = re.search(r"m_Shader:\s*\{fileID:\s*\d+,\s*guid:\s*([0-9a-f]+)", text)
    out["shader_guid"] = m.group(1) if m else ""

    # Floats — capture key params
    floats = {}
    for fname in ["_BaseSize", "_ProjectorRadius", "_BandSize", "_BandContrast",
                  "_MaxRange", "_Arc", "_RangeSize", "_GradScaler",
                  "_OneTuner", "_TwoTuner", "_ThreeTuner", "_FourTuner",
                  "_FiveTuner", "_InfinityTuner"]:
        m = re.search(rf"-\s*{re.escape(fname)}:\s*(-?[\d.]+)", text)
        if m:
            floats[fname] = m.group(1)
    out["floats"] = floats

    # Colors — capture all _Color* / _Range*
    colors = {}
    for m in re.finditer(r"-\s*(_\w+):\s*\{r:\s*([\d.]+),\s*g:\s*([\d.]+),\s*b:\s*([\d.]+),\s*a:\s*([\d.]+)\}", text):
        name, r, g, b, a = m.groups()
        if name in ("_BumpScale",):  # not a color
            continue
        colors[name] = (float(r), float(g), float(b), float(a))
    out["colors"] = colors

    return out


def parse_prefab(path: Path) -> dict:
    """Extract critical fields from a Unity .prefab YAML file (Projector components)."""
    text = read(path)
    out = {"path": str(path.relative_to(ROOT)), "name": path.stem}

    # Count Projector components (Unity type id 119)
    projectors = re.findall(r"---\s*!u!119\s*&\d+\s*\nProjector:(.*?)(?=\n---|\Z)", text, re.DOTALL)
    out["n_projectors"] = len(projectors)

    proj_data = []
    for body in projectors:
        d = {}
        for fname in ["m_OrthographicSize", "m_FarClipPlane", "m_NearClipPlane",
                      "m_FieldOfView", "m_AspectRatio", "m_Orthographic"]:
            m = re.search(rf"{fname}:\s*(-?[\d.]+)", body)
            if m:
                d[fname] = m.group(1)
        m = re.search(r"m_Material:\s*\{fileID:\s*\d+,\s*guid:\s*([0-9a-f]+)", body)
        if m:
            d["material_guid"] = m.group(1)
        proj_data.append(d)
    out["projectors"] = proj_data

    # Transforms (LocalPosition Y, rotation)
    transforms = []
    for body in re.findall(r"---\s*!u!4\s*&\d+\s*\nTransform:(.*?)(?=\n---|\Z)", text, re.DOTALL):
        d = {}
        m = re.search(r"m_LocalPosition:\s*\{x:\s*(-?[\d.]+),\s*y:\s*(-?[\d.]+),\s*z:\s*(-?[\d.]+)\}", body)
        if m:
            d["pos"] = (float(m.group(1)), float(m.group(2)), float(m.group(3)))
        m = re.search(r"m_LocalEulerAnglesHint:\s*\{x:\s*(-?[\d.]+),\s*y:\s*(-?[\d.]+),\s*z:\s*(-?[\d.]+)\}", body)
        if m:
            d["rot"] = (float(m.group(1)), float(m.group(2)), float(m.group(3)))
        transforms.append(d)
    out["transforms"] = transforms

    return out


def rgba_to_hex(r, g, b, a):
    """Convert 0-1 RGBA to hex + alpha note."""
    rh, gh, bh = int(r * 255), int(g * 255), int(b * 255)
    return f"#{rh:02X}{gh:02X}{bh:02X} (α={a:.2f})"


def fmt_colors(colors):
    """Format dict of colors as compact markdown."""
    if not colors:
        return "—"
    parts = []
    for name, (r, g, b, a) in colors.items():
        if a == 0 and r == 0 and g == 0 and b == 0:
            parts.append(f"`{name}` transparent")
        else:
            parts.append(f"`{name}` {rgba_to_hex(r, g, b, a)}")
    return "<br>".join(parts)


def fmt_floats(floats):
    """Format dict of floats."""
    if not floats:
        return "—"
    return ", ".join(f"`{k}`={v}" for k, v in floats.items())


def main():
    materials_by_overlay = defaultdict(list)
    prefabs_by_overlay = defaultdict(list)

    for overlay in OVERLAYS:
        for p in sorted((ROOT / overlay).rglob("*.mat")):
            if p.suffix == ".meta":
                continue
            materials_by_overlay[overlay].append(parse_material(p))
        for p in sorted((ROOT / overlay).rglob("*.prefab")):
            if p.suffix == ".meta":
                continue
            prefabs_by_overlay[overlay].append(parse_prefab(p))

    # Build the master doc
    lines = []
    lines.append("# Materials & Prefabs Reference — SWL TTS Projector Overlays")
    lines.append("")
    lines.append("Extraction directe des `.mat` et `.prefab` Unity (YAML) dans `UnityProject-U6/Assets/Projectors/`. Source de vérité pour reproduire le rendu en vector lines.")
    lines.append("")
    lines.append("Notation : couleurs en hex + alpha. Champs `Floats` clés du shader projector (paramètres procéduraux des anneaux).")
    lines.append("")

    for overlay in OVERLAYS:
        lines.append(f"## {overlay}")
        lines.append("")

        # Materials table
        lines.append("### Materials")
        lines.append("")
        lines.append("| Material | Shader keywords | Floats clés | Couleurs |")
        lines.append("|---|---|---|---|")
        for m in materials_by_overlay[overlay]:
            kw = m["keywords"] or "—"
            lines.append(f"| `{m['name']}` | `{kw}` | {fmt_floats(m['floats'])} | {fmt_colors(m['colors'])} |")
        lines.append("")

        # Prefabs table
        lines.append("### Prefabs")
        lines.append("")
        lines.append("| Prefab | Nb Projectors | OrthographicSize / FarClip | Transform pos/rot | Material guid |")
        lines.append("|---|---|---|---|---|")
        for p in prefabs_by_overlay[overlay]:
            n = p["n_projectors"]
            proj_sizes = [pr.get("m_OrthographicSize", "?") for pr in p["projectors"]]
            proj_far = [pr.get("m_FarClipPlane", "?") for pr in p["projectors"]]
            proj_summary = "<br>".join(f"size={s}, far={f}" for s, f in zip(proj_sizes, proj_far)) if proj_sizes else "—"

            tr_summary = "<br>".join(
                f"pos=({t.get('pos', ('?',)*3)[0]}, {t.get('pos', ('?',)*3)[1]}, {t.get('pos', ('?',)*3)[2]}) rot=({t.get('rot', ('?',)*3)[0]}, {t.get('rot', ('?',)*3)[1]}, {t.get('rot', ('?',)*3)[2]})"
                for t in p["transforms"]
            ) if p["transforms"] else "—"

            mat_guids = [pr.get("material_guid", "?") for pr in p["projectors"]]
            mat_summary = "<br>".join(g[:12] + "…" for g in mat_guids) if mat_guids else "—"

            lines.append(f"| `{p['name']}` | {n} | {proj_summary} | {tr_summary} | {mat_summary} |")
        lines.append("")

    # Final notes
    lines.append("## Notes globales")
    lines.append("")
    lines.append("- Cohesion : double set `Materials/cohesion_*` et `_Revamp/halfCohesion_*`. Probable : `_Revamp/` est la version actuellement utilisée (le bundle live s'appelle `halfcohesion_27mm.unity3d` cf shader-inventory).")
    lines.append("- Range : shader procédural avec jusqu'à 5 bandes (`_RangeOne` à `_RangeFive`) + `_RangeInfinity`. Le keyword `_MAXRANGE_RANGEFIVE` ou `_MAXRANGE_RANGEFOUR` détermine la dernière bande visible.")
    lines.append("- Movement : un seul Projector par prefab, paramétré par `_BaseSize` + speed. Le `_Arc` doit contrôler la portion d'arc visible.")
    lines.append("- Deployment : 6 materials uniques réutilisés par 12 prefabs (rotations différentes pour matérialiser corner/half/L/round/score).")

    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT}")
    # Stats
    total_mats = sum(len(v) for v in materials_by_overlay.values())
    total_prefabs = sum(len(v) for v in prefabs_by_overlay.values())
    print(f"Scanned {total_mats} materials and {total_prefabs} prefabs across {len(OVERLAYS)} overlays.")


if __name__ == "__main__":
    main()
