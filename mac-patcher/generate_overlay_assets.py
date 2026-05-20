#!/usr/bin/env python3
"""
Generate PNG assets for the Mac Cohesion + Range overlay fallback.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import math

OUT_DIR = Path(__file__).parent / "tts-assets"
OUT_DIR.mkdir(exist_ok=True)


# Range band colors (R, G, B in 0..255) — from BB_RangeProjector defaults
RANGE_COLORS = {
    "half":  (255, 255, 255),     # 0.5 / 3" — white
    "one":   (255, 195,   0),     # R1 / 6" — yellow
    "two":   (255, 117,   0),     # R2 / 12" — orange
    "three": (255,  20,   0),     # R3 / 18" — red
    "four":  (195,   0,  66),     # R4 / 24" — magenta
    "five":  (134,   0, 112),     # R5 / 30" — violet
}

# Configurations per overlay type (bands = list of (radius_inches, color_key))
# Edge-based convention: each band's effective world radius is band_r + base_r.
RANGE_BAND_CONFIGS = {
    "fig_leader": {
        "bands": [(3, "half"), (6, "one"), (12, "two"),
                  (18, "three"), (24, "four"), (30, "five")],
        "max_radius": 30,
    },
    # SWL ranges in inches: Range 1 = 6", Range 2 = 12", Range 0.5 (poi) = 3".
    "smokeToken":    {"bands": [(6, "one")],                 "max_radius":  6},
    "token":         {"bands": [(6, "one")],                 "max_radius":  6},
    "tokenRangeTwo": {"bands": [(6, "one"), (12, "two")],    "max_radius": 12},
    "poi":           {"bands": [(3, "one")],                 "max_radius":  3},
    "bombCart":      {"bands": [(6, "one"), (12, "two")],    "max_radius": 12},
}

# Base radii (inches, half-diameter) per ROUND fig base size. Oblong bases
# (long, snail) live in OBLONG_DIMENSIONS_MM below — they don't use a single
# radius and don't generate round PNGs.
FIG_BASE_RADIUS_IN = {
    "small":  27  / 2 / 25.4,
    "medium": 50  / 2 / 25.4,
    "large":  70  / 2 / 25.4,
    "huge":  100  / 2 / 25.4,
    "laat":  120  / 2 / 25.4,
    "epic":  150  / 2 / 25.4,
}

# Token base radii (inches), only needed for multi-band tokens.
TOKEN_BASE_RADIUS_IN = {
    "tokenRangeTwo": 25.1 / 2 / 25.4,
    "bombCart":      50.0 / 2 / 25.4,
}


def _with_base_offset(config: dict, base_r: float) -> dict:
    """Shift band radii outward by base_r and grow max_radius accordingly so
    the PNG band proportions match the world positions of the vector-line
    rings (which are drawn at band_r + base_r)."""
    return {
        "bands":      [(r + base_r, c) for r, c in config["bands"]],
        "max_radius": config["max_radius"] + base_r,
    }


def generate_cohesion_halo(size: int = 512) -> Path:
    """Halo radial blanc fade transparent — reproduit le rendu Cohesion bundle.

    Le shader BB_CohesionProjector fait `rangeOne = (1 - grad)` puis multiplie
    par alpha global. On reproduit ce fade : opaque au centre, transparent au
    bord.
    """
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pixels = img.load()
    cx, cy = size / 2, size / 2
    max_r = size / 2

    # Alpha global du material Cohesion 27mm = 0.37 ; on multiplie par le fade
    base_alpha = 0.37

    for y in range(size):
        for x in range(size):
            dx, dy = x - cx, y - cy
            dist = math.sqrt(dx * dx + dy * dy)
            r_norm = dist / max_r  # [0, 1+] depuis le centre
            if r_norm > 1.0:
                continue  # transparent au-delà du rayon

            # Fade radial : (1 - r) avec courbe douce
            # Le shader fait (1 - grad) linéaire, on garde la même chose
            fade = max(0.0, 1.0 - r_norm)
            alpha = int(base_alpha * fade * 255)
            pixels[x, y] = (255, 255, 255, alpha)

    out = OUT_DIR / "cohesion_halo.png"
    img.save(out)
    return out


def generate_range_band_png(name: str, config: dict, size: int = 1024,
                            alpha: float = 0.2) -> Path:
    """Generate a circular range overlay with concentric bands.

    Drawing from outer-to-inner: each filled ellipse overlays the previous,
    producing clean rings.
    """
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = cy = size / 2
    max_r_pix = size / 2
    a = int(alpha * 255)

    for band_r, color_key in reversed(config["bands"]):
        r_pix = (band_r / config["max_radius"]) * max_r_pix
        r, g, b = RANGE_COLORS[color_key]
        draw.ellipse(
            [(cx - r_pix, cy - r_pix), (cx + r_pix, cy + r_pix)],
            fill=(r, g, b, a),
        )

    out = OUT_DIR / f"range_{name}.png"
    img.save(out)
    return out


# Oblong base dimensions (mm). Used to render stadium-shape range overlays
# whose 6 bands stay concentric to a rectangular footprint with rounded caps.
OBLONG_DIMENSIONS_MM = {
    "long":  {"width": 100, "length": 175},
    "snail": {"width": 100, "length": 200},
}


def generate_range_band_stadium_png(base_size: str, dims_mm: dict,
                                    config: dict, alpha: float = 0.2,
                                    pixels_per_inch: int = 16) -> Path:
    """Generate a stadium-shape PNG with 6 concentric range bands.

    The PNG dimensions encode the *outermost* band's bounding box (so the
    decal can be stretched in TTS using scale = {shortSpan, longSpan, 1} and
    the bands stay aligned with the matching vector stadium outlines).

    A stadium = rounded rectangle whose corner radius equals half the
    short dimension, producing a pill shape with semicircular caps on the
    long-axis ends. Each band is one rounded_rectangle of width
    2*(halfWid + band_r) and length 2*(halfLen + band_r), corner radius
    halfWid + band_r. Drawn outer-to-inner so each band overpaints the next.
    """
    halfWid_in = (dims_mm["width"]  / 2) / 25.4
    halfLen_in = (dims_mm["length"] / 2) / 25.4
    max_dist   = config["max_radius"]

    shortSpan_in = 2 * (halfWid_in + max_dist)
    longSpan_in  = 2 * (halfLen_in + max_dist)

    W = int(round(shortSpan_in * pixels_per_inch))
    H = int(round(longSpan_in  * pixels_per_inch))
    cx, cy = W / 2, H / 2

    img  = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    a    = int(alpha * 255)

    for band_r, color_key in reversed(config["bands"]):
        half_w_px = (halfWid_in + band_r) * pixels_per_inch
        half_h_px = (halfLen_in + band_r) * pixels_per_inch
        r, g, b   = RANGE_COLORS[color_key]
        draw.rounded_rectangle(
            [(cx - half_w_px, cy - half_h_px),
             (cx + half_w_px, cy + half_h_px)],
            radius=half_w_px,  # = half of the short side → semicircle caps
            fill=(r, g, b, a),
        )

    out = OUT_DIR / f"range_fig_leader_{base_size}_stadium.png"
    img.save(out)
    return out


def generate_filled_disk(name: str, color_rgb: tuple, size: int = 512,
                         alpha: float = 0.2) -> Path:
    """Generate a simple filled disk PNG (used for Maximum Move overlay)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = cy = size / 2
    r = size / 2
    a = int(alpha * 255)
    draw.ellipse([(cx - r, cy - r), (cx + r, cy + r)],
                 fill=(color_rgb[0], color_rgb[1], color_rgb[2], a))
    out = OUT_DIR / f"{name}.png"
    img.save(out)
    return out


def generate_filled_square(name: str, color_rgb: tuple, size: int = 256,
                           alpha: float = 0.3) -> Path:
    """Generate a filled square PNG (used for Deployment Boundary cells)."""
    img = Image.new("RGBA", (size, size),
                    (color_rgb[0], color_rgb[1], color_rgb[2], int(alpha * 255)))
    out = OUT_DIR / f"{name}.png"
    img.save(out)
    return out


def generate_silhouette_top_disc(size: int = 512) -> Path:
    """Hologram-style top cap for the Mac silhouette cylinder.

    Radial gradient: bright green-cyan center fades to transparent at the
    rim. Combined with the vector wireframe cylinder this gives the
    Star Wars hologram briefing look (Leia "Help me Obi-Wan" projection).
    """
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pixels = img.load()
    cx, cy = size / 2, size / 2
    max_r = size / 2

    r_center, g_center, b_center = 102, 255, 178   # bright hologram cyan-green
    a_center = 0.85

    for y in range(size):
        for x in range(size):
            dx, dy = x - cx, y - cy
            dist = math.sqrt(dx * dx + dy * dy)
            r_norm = dist / max_r
            if r_norm > 1.0:
                continue
            # Smooth radial falloff (1-r squared) for a soft hologram glow
            fade = (1.0 - r_norm) ** 1.5
            alpha = int(a_center * fade * 255)
            pixels[x, y] = (r_center, g_center, b_center, alpha)

    out = OUT_DIR / "silhouette_top.png"
    img.save(out)
    return out


def main():
    p = generate_cohesion_halo()
    print(f"Generated {p} ({p.stat().st_size} bytes)")

    # Fig leaders (round bases): one PNG per base size, bands shifted by base radius.
    fig_cfg = RANGE_BAND_CONFIGS["fig_leader"]
    for base_size, br in FIG_BASE_RADIUS_IN.items():
        out = generate_range_band_png(f"fig_leader_{base_size}",
                                      _with_base_offset(fig_cfg, br))
        print(f"Generated {out} ({out.stat().st_size} bytes)")

    # Oblong bases: stadium-shape PNGs (rectangular footprint + rounded caps).
    for base_size, dims in OBLONG_DIMENSIONS_MM.items():
        out = generate_range_band_stadium_png(base_size, dims, fig_cfg)
        print(f"Generated {out} ({out.stat().st_size} bytes)")

    # Multi-band tokens: bake in their base radius for alignment.
    for name, br in TOKEN_BASE_RADIUS_IN.items():
        cfg = RANGE_BAND_CONFIGS[name]
        out = generate_range_band_png(name, _with_base_offset(cfg, br))
        print(f"Generated {out} ({out.stat().st_size} bytes)")

    # Single-band tokens: no offset adjustment needed (band sits at outer edge).
    for name in ("smokeToken", "token", "poi"):
        out = generate_range_band_png(name, RANGE_BAND_CONFIGS[name])
        print(f"Generated {out} ({out.stat().st_size} bytes)")

    # Maximum Move: cyan filled disk (#55CCFF)
    p = generate_filled_disk("max_move_cyan", (85, 204, 255), alpha=0.2)
    print(f"Generated {p} ({p.stat().st_size} bytes)")

    # Deployment Boundary: red and blue filled squares (alpha 0.5 = match bundle)
    p = generate_filled_square("deployment_red", (255, 0, 0), alpha=0.3)
    print(f"Generated {p} ({p.stat().st_size} bytes)")
    p = generate_filled_square("deployment_blue", (0, 0, 255), alpha=0.3)
    print(f"Generated {p} ({p.stat().st_size} bytes)")

    # Silhouette top cap: hologram-style green/cyan radial gradient.
    p = generate_silhouette_top_disc()
    print(f"Generated {p} ({p.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
