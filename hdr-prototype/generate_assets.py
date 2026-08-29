#!/usr/bin/env python3
"""HDR asset authoring for the /hdr-lab dev harness.

Writes PQ-encoded (BT.2100) 16-bit PNGs with a cICP chunk into
priv/static/images/hdr-lab/. A cICP-tagged PNG is real HDR in Chromium
(117+) and needs no external encoder — stdlib only, so it runs on a clean
machine. Production assets should later be re-authored as gain-map AVIF
(wider support + tone-mapped fallback baked in); this script is the
dev-lab source of truth until then.

THE ORBS reproduce the Figma comp (node 3390-3684, "Group 126") layer for
layer. Measured construction, per orb, bottom → top:

  1. hover-under-fx      base ellipse (white / black), normal blend,
                         drop shadow #B19FF2 dilate 4 / blur 10.5
  2. hover-over-fx       white ellipse, OVERLAY blend, shadow dilate 2 /
                         blur 3 / dx 1
  3. hover-over-fx       white ellipse (the tall one on the light orb),
                         OVERLAY, same shadow, foreground blur 1.5
  4. hover-over-fx-      ellipse at fill-opacity 0.01 — invisible fill
     transparent         whose shadow ring is the point — OVERLAY

  Every layer is its own ellipse with its own transform (rotate 76.9° /
  80.92° / 86.24° / 79.95°, skewX ≈ 8°, scaleY 0.99) and slightly offset
  center — the stack's misalignment is the organic, not-a-perfect-circle
  quality. Shadows composite OUTSIDE the shape only (Figma's feComposite
  operator="out").

  Baking note: overlay blending needs a backdrop. In the comp the backdrop
  is the frame; in a floating asset there is none, so overlay layers are
  weighted by the alpha of what's beneath them IN the asset (over the void
  they contribute nothing — which is exactly how they behave over the
  comp's black frame). The live-DOM alternative (real mix-blend-mode
  against the page surface) is a follow-up experiment.

  Grain: the comp's noise effect does not survive SVG export (Figma
  rasterizes noise), so film grain is re-added procedurally — the same
  move as the signature wordmark's feTurbulence. Luminance-modulating,
  stronger in the halo than the core.

HDR model: the comp is authored in SDR — its white core IS the
beyond-white register. So the SDR composite is rendered faithfully first,
then luminance is expanded through a knee: pixels below KNEE stay exactly
the SDR look (nits = 203 * Y), pixels approaching 1.0 lift toward
PEAK_NITS. The SDR fallback file is therefore the untouched Figma look,
and the fringe keeps its chroma inside SDR range (over-range luminance
carries no chroma).

Assets:
  orb-light.png      768px RGBA — the light orb, PQ/cICP, core → 1000 nits
  orb-light-sdr.png  same composite without expansion, 8-bit sRGB
  orb-dark.png       the dark orb (void + rim) — SDR by nature, 8-bit
  white-<n>.png      flat tiles at n nits for the luminance ladder
  ramp-nits.png      stepped bands 203→1600 nits — headroom probe

Run:  python3 hdr-prototype/generate_assets.py
"""

import math
import os
import struct
import sys
import zlib

OUT_DIR = os.path.join(
    os.path.dirname(__file__), "..", "priv", "static", "images", "hdr-lab"
)

# ---- luminance constants -------------------------------------------------

SDR_WHITE_NITS = 203.0  # BT.2408 diffuse white; browsers map this to SDR white
PEAK_NITS = 1000.0      # orb core — ~5x headroom, within common EDR ceilings
KNEE = 0.85             # SDR luminance above which expansion begins
LADDER_NITS = [203, 400, 800, 1300]
RAMP_BANDS = [203, 300, 400, 500, 600, 800, 1000, 1300, 1600]

# Halo color measured from the comp's shadow feColorMatrix: #B19FF2.
HALO_SRGB = (0.694118, 0.623529, 0.949020)

# Grain (re-added; see module doc). Amplitudes in gamma space.
GRAIN_CELL_PX = 4       # cell size at render scale — survives display downscale
GRAIN_CORE = 0.04
GRAIN_HALO = 0.18

# ---- PQ (SMPTE ST 2084) inverse EOTF --------------------------------------

PQ_M1 = 2610 / 16384
PQ_M2 = 2523 / 4096 * 128
PQ_C1 = 3424 / 4096
PQ_C2 = 2413 / 4096 * 32
PQ_C3 = 2392 / 4096 * 32


def pq_encode(nits: float) -> float:
    y = max(nits, 0.0) / 10000.0
    ym = y**PQ_M1
    return ((PQ_C1 + PQ_C2 * ym) / (1.0 + PQ_C3 * ym)) ** PQ_M2


# ---- color spaces ----------------------------------------------------------

M_SRGB_TO_XYZ = (
    (0.4123908, 0.3575843, 0.1804808),
    (0.2126390, 0.7151687, 0.0721923),
    (0.0193308, 0.1191948, 0.9505322),
)
M_XYZ_TO_2020 = (
    (1.7166512, -0.3556708, -0.2533663),
    (-0.6666844, 1.6164812, 0.0157685),
    (0.0176399, -0.0427706, 0.9421031),
)


def matmul3(a, b):
    return tuple(
        tuple(sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3))
        for i in range(3)
    )


M_SRGB_TO_2020 = matmul3(M_XYZ_TO_2020, M_SRGB_TO_XYZ)


def srgb_to_linear(v: float) -> float:
    return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4


def linear_to_srgb(v: float) -> float:
    v = min(max(v, 0.0), 1.0)
    return 12.92 * v if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055


def srgb_lin_to_2020_lin(rgb):
    m = M_SRGB_TO_2020
    return tuple(
        max(m[i][0] * rgb[0] + m[i][1] * rgb[1] + m[i][2] * rgb[2], 0.0)
        for i in range(3)
    )


# ---- minimal PNG writer ----------------------------------------------------

# cICP payload: BT.2020 primaries (9), PQ transfer (16), RGB matrix (0),
# full-range (1). Must precede IDAT.
CICP_PQ = bytes((9, 16, 0, 1))


def png_chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def write_png(path, width, height, rows, depth, alpha, cicp=None):
    """rows: iterable of rows; each row is a flat list of channel ints."""
    color_type = 6 if alpha else 2
    ihdr = struct.pack(">IIBBBBB", width, height, depth, color_type, 0, 0, 0)
    fmt = ">H" if depth == 16 else ">B"
    raw = bytearray()
    for row in rows:
        raw.append(0)  # filter: None
        for v in row:
            raw += struct.pack(fmt, v)
    out = b"\x89PNG\r\n\x1a\n" + png_chunk(b"IHDR", ihdr)
    if cicp:
        out += png_chunk(b"cICP", cicp)
    out += png_chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    out += png_chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(out)
    return len(out)


def verify_png(path):
    """Return ordered chunk names — sanity check that cICP precedes IDAT."""
    with open(path, "rb") as f:
        data = f.read()
    pos, names = 8, []
    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos : pos + 4])
        names.append(data[pos + 4 : pos + 8].decode("ascii"))
        pos += 12 + length
    return names


# ---- the layer stack (measured from the comp) ------------------------------

WHITE = (1.0, 1.0, 1.0)
BLACK = (0.0, 0.0, 0.0)


class Layer:
    """One comp layer: an ellipse with transform, fill, drop shadow, blend."""

    def __init__(self, cx, cy, rx, ry, rot_deg, skew_deg, fill, fill_opacity,
                 blend, sh_dilate, sh_dx, sh_sigma, fg_blur):
        self.cx, self.cy, self.rx, self.ry = cx, cy, rx, ry
        self.fill, self.fill_opacity, self.blend = fill, fill_opacity, blend
        self.sh_dilate, self.sh_dx, self.sh_sigma = sh_dilate, sh_dx, sh_sigma
        self.fg_blur = fg_blur
        # CSS transform list `rotate(θ) scaleY(.99) skewX(s)` applies right-to-
        # left; we invert it to map group space → ellipse space.
        th = math.radians(rot_deg)
        self.cos, self.sin = math.cos(-th), math.sin(-th)
        self.tan_skew = math.tan(math.radians(skew_deg))
        self.inv_sy = 1.0 / 0.99

    def local(self, x, y):
        """Group coords → the ellipse's own space (inverse transform)."""
        x, y = x - self.cx, y - self.cy
        x, y = x * self.cos - y * self.sin, x * self.sin + y * self.cos
        y *= self.inv_sy
        x -= y * self.tan_skew
        return x, y

    def sdf(self, x, y, dx=0.0):
        """Approximate signed distance to the ellipse edge (px, <0 inside)."""
        x -= dx
        e = math.hypot(x / self.rx, y / self.ry)
        return (e - 1.0) * math.sqrt(self.rx * self.ry)


def gauss_coverage(d, sigma):
    """Coverage of a gaussian-blurred edge at signed distance d outside it."""
    return 0.5 * (1.0 - math.erf(d / (sigma * math.sqrt(2.0))))


def overlay(b, s):
    return 2.0 * b * s if b <= 0.5 else 1.0 - 2.0 * (1.0 - b) * (1.0 - s)


def light_orb_layers():
    return [
        Layer(53.71, 61.09, 45.43, 46.57, 76.90, 8.11, WHITE, 1.00, "normal", 4, 0, 10.5, 0),
        Layer(51.27, 59.03, 45.89, 46.12, 80.92, 8.23, WHITE, 1.00, "overlay", 2, 1, 3.0, 0),
        Layer(55.42, 57.44, 46.50, 53.52, 86.24, 8.13, WHITE, 1.00, "overlay", 2, 1, 3.0, 1.5),
        Layer(51.88, 59.55, 45.77, 46.23, 79.95, 8.21, WHITE, 0.01, "overlay", 2, 1, 3.0, 0),
    ]


def dark_orb_layers():
    # Same skeleton over a black base; its 4th (transparent) layer carries no
    # shadow in the comp, so it contributes nothing and is omitted. The comp's
    # hairline black ring is invisible against the black fill and is skipped.
    return [
        Layer(53.71, 61.09, 45.43, 46.57, 76.90, 8.11, BLACK, 1.00, "normal", 4, 0, 10.5, 0.5),
        Layer(51.27, 59.03, 45.89, 46.12, 80.92, 8.23, WHITE, 1.00, "overlay", 2, 1, 3.0, 0),
        Layer(47.57, 55.78, 46.50, 45.49, 86.24, 8.13, WHITE, 1.00, "overlay", 2, 1, 3.0, 1.5),
    ]


def hash01(ix, iy, salt):
    x = (ix * 374761393 + iy * 668265263 + salt * 2246822519) & 0xFFFFFFFF
    x = ((x ^ (x >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((x ^ (x >> 16)) & 0xFFFF) / 65535.0


def render_orb(layers, size, extent=172.0, center=(52.5, 59.5), aa_sigma=0.7):
    """Composite the comp's layer stack in gamma sRGB over transparency.

    The render window is centered on the orb cluster (the comp group's box
    includes one-sided shadow bleed, so its own center is off-orb). extent
    spans core + dilate + 3 sigma of the big halo, plus padding.

    Returns rows of (r, g, b, a) — gamma-encoded color 0..1, straight alpha.
    """
    scale = size / extent
    rows = []
    for j in range(size):
        row = []
        gy = (j - size / 2.0) / scale + center[1]
        for i in range(size):
            gx = (i - size / 2.0) / scale + center[0]
            acc_r = acc_g = acc_b = 0.0  # premultiplied, gamma space
            acc_a = 0.0
            for ly in layers:
                lx, lyy = ly.local(gx, gy)
                d = ly.sdf(lx, lyy) * scale  # px at render scale
                # shape coverage (foreground blur or plain antialias)
                sig = max(ly.fg_blur * scale, aa_sigma)
                a_shape = gauss_coverage(d, sig) * ly.fill_opacity
                # drop shadow: dilate, offset, blur — outside the shape only
                dsh = ly.sdf(lx, lyy, dx=ly.sh_dx) * scale
                a_sh = gauss_coverage(
                    dsh - ly.sh_dilate * scale, ly.sh_sigma * scale
                )
                a_sh *= 1.0 - gauss_coverage(d, aa_sigma)
                # layer = shadow under fill
                a_l = a_shape + a_sh * (1.0 - a_shape)
                if a_l < 1e-4:
                    continue
                col = tuple(
                    (ly.fill[c] * a_shape + HALO_SRGB[c] * a_sh * (1.0 - a_shape))
                    / a_l
                    for c in range(3)
                )
                # overlay needs a backdrop: weight by what's beneath in the
                # asset (over the void it must vanish, as it does in the comp)
                if ly.blend == "overlay":
                    a_l *= acc_a
                    if a_l < 1e-4:
                        continue
                    ub = (
                        (acc_r / acc_a, acc_g / acc_a, acc_b / acc_a)
                        if acc_a > 1e-4
                        else (0.0, 0.0, 0.0)
                    )
                    col = tuple(
                        (1.0 - acc_a) * col[c] + acc_a * overlay(ub[c], col[c])
                        for c in range(3)
                    )
                acc_r = col[0] * a_l + acc_r * (1.0 - a_l)
                acc_g = col[1] * a_l + acc_g * (1.0 - a_l)
                acc_b = col[2] * a_l + acc_b * (1.0 - a_l)
                acc_a = a_l + acc_a * (1.0 - a_l)
            if acc_a < 1e-4:
                row.append((0.0, 0.0, 0.0, 0.0))
                continue
            r, g, b = acc_r / acc_a, acc_g / acc_a, acc_b / acc_a
            # grain — luminance-modulating, heavier in the halo than the core
            cell = GRAIN_CELL_PX
            n = hash01(i // cell, j // cell, 7)
            luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
            amp = GRAIN_CORE + (GRAIN_HALO - GRAIN_CORE) * (1.0 - luma)
            m = 1.0 + amp * (n - 0.5)
            r, g, b = (min(max(v * m, 0.0), 1.0) for v in (r, g, b))
            # alpha grain keeps the texture visible once the halo composites
            # translucently over the page surface
            if acc_a < 0.97:
                n2 = hash01(i // cell, j // cell, 13)
                acc_a = min(max(acc_a * (1.0 + 0.5 * amp * (n2 - 0.5)), 0.0), 1.0)
            row.append((r, g, b, acc_a))
        rows.append(row)
    return rows


def expand_to_nits(r, g, b):
    """SDR gamma color → linear nits with the knee expansion (hue-preserving)."""
    rl, gl, bl = srgb_to_linear(r), srgb_to_linear(g), srgb_to_linear(b)
    y = 0.2126 * rl + 0.7152 * gl + 0.0722 * bl
    if y <= 1e-6:
        return (0.0, 0.0, 0.0)
    t = min(max((y - KNEE) / (1.0 - KNEE), 0.0), 1.0)
    t = t * t * (3.0 - 2.0 * t)
    target = SDR_WHITE_NITS * y * (1.0 - t) + PEAK_NITS * t
    gain = target / (SDR_WHITE_NITS * y)
    return (
        rl * SDR_WHITE_NITS * gain,
        gl * SDR_WHITE_NITS * gain,
        bl * SDR_WHITE_NITS * gain,
    )


def orb_hdr_rows(rendered):
    for row in rendered:
        flat = []
        for r, g, b, a in row:
            nits = expand_to_nits(r, g, b)
            r2020 = srgb_lin_to_2020_lin(nits)
            flat += [round(pq_encode(n) * 65535) for n in r2020]
            flat.append(round(a * 65535))
        yield flat


def orb_sdr_rows(rendered):
    for row in rendered:
        flat = []
        for r, g, b, a in row:
            flat += [round(r * 255), round(g * 255), round(b * 255), round(a * 255)]
        yield flat


def flat_rows(width, height, nits):
    val = round(pq_encode(nits) * 65535)
    row = [val, val, val] * width
    for _ in range(height):
        yield row


def ramp_rows(band_width, height, bands):
    row = []
    for nits in bands:
        val = round(pq_encode(nits) * 65535)
        row += [val, val, val] * band_width
    for _ in range(height):
        yield row


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    written = []
    size = 768

    light = render_orb(light_orb_layers(), size)
    p = os.path.join(OUT_DIR, "orb-light.png")
    write_png(p, size, size, orb_hdr_rows(light), 16, alpha=True, cicp=CICP_PQ)
    written.append(p)
    p = os.path.join(OUT_DIR, "orb-light-sdr.png")
    write_png(p, size, size, orb_sdr_rows(light), 8, alpha=True)
    written.append(p)

    dark = render_orb(dark_orb_layers(), size)
    p = os.path.join(OUT_DIR, "orb-dark.png")
    write_png(p, size, size, orb_sdr_rows(dark), 8, alpha=True)
    written.append(p)

    for nits in LADDER_NITS:
        p = os.path.join(OUT_DIR, f"white-{nits}.png")
        write_png(p, 32, 32, flat_rows(32, 32, nits), 16, alpha=False, cicp=CICP_PQ)
        written.append(p)

    band_w, ramp_h = 120, 72
    p = os.path.join(OUT_DIR, "ramp-nits.png")
    write_png(
        p,
        band_w * len(RAMP_BANDS),
        ramp_h,
        ramp_rows(band_w, ramp_h, RAMP_BANDS),
        16,
        alpha=False,
        cicp=CICP_PQ,
    )
    written.append(p)

    ok = True
    for path in written:
        names = verify_png(path)
        hdr = "cICP" in names
        if hdr and names.index("cICP") > names.index("IDAT"):
            ok = False
        kb = os.path.getsize(path) / 1024
        print(f"{os.path.basename(path):22s} {kb:8.1f} KB  chunks: {names}")
    if not ok:
        print("FAIL: cICP after IDAT", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
