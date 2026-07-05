#!/usr/bin/env python3
"""Generate the game's sprite assets as layered SVGs.

RISO NIGHT style: flat print inks (violet-black, coral, teal, amber, warm
paper), hard shapes, hairline outlines, and slightly misregistered duplicate
layers — like a risograph zine that came out of the machine one pass off.
Run from the repo root:

    python3 tools/gen_assets.py

Writes to assets/sprites/. All output is deterministic text — commit it.
No <filter> elements (Godot's ThorVG importer doesn't support them).
"""
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")

INK = "#171226"
PAPER = "#e9e1cf"
CORAL = "#ff5c4d"
TEAL = "#3ecfb2"
AMBER = "#ffb03a"
VIOLET = "#6a5cff"


def svg(w, h, defs, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
            f'viewBox="0 0 {w} {h}">\n<defs>\n{defs}\n</defs>\n{body}\n</svg>\n')


def radial(gid, stops, cx=0.5, cy=0.5, r=0.5, fx=None, fy=None):
    fx = cx if fx is None else fx
    fy = cy if fy is None else fy
    s = "".join(f'<stop offset="{o}" stop-color="{c}" stop-opacity="{a}"/>' for o, c, a in stops)
    return (f'<radialGradient id="{gid}" cx="{cx}" cy="{cy}" r="{r}" fx="{fx}" fy="{fy}">'
            f"{s}</radialGradient>")


def linear(gid, stops, x1=0, y1=0, x2=0, y2=1):
    s = "".join(f'<stop offset="{o}" stop-color="{c}" stop-opacity="{a}"/>' for o, c, a in stops)
    return (f'<linearGradient id="{gid}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">'
            f"{s}</linearGradient>")


def write(name, content):
    path = os.path.join(OUT, name)
    with open(path, "w") as f:
        f.write(content)
    print("wrote", path)


def muon(name, core, glow):
    """A glowing particle: flat warm disc, thin offset ring (misprint),
    soft halo. Face is drawn live in-engine."""
    defs = (
        radial("halo", [(0, glow, 0.55), (0.6, glow, 0.16), (1, glow, 0)])
        + radial("body", [(0, "#fdf8ec", 1), (0.72, core, 1), (1, core, 1)],
                 fx=0.40, fy=0.34)
    )
    body = f"""
<circle cx="64" cy="64" r="62" fill="url(#halo)"/>
<circle cx="64" cy="64" r="44" fill="url(#body)"/>
<circle cx="60" cy="60" r="46" fill="none" stroke="{CORAL}" stroke-opacity="0.85" stroke-width="2.5"/>
<circle cx="64" cy="64" r="44" fill="none" stroke="{INK}" stroke-opacity="0.9" stroke-width="3"/>
<ellipse cx="52" cy="46" rx="14" ry="8" fill="#ffffff" opacity="0.55" transform="rotate(-20 52 46)"/>
"""
    write(name, svg(128, 128, defs, body))


def cloud():
    """Flat paper cloud with a coral misprint copy behind and an ink hairline."""
    defs = linear("puff", [(0, PAPER, 1), (1, "#d4c9b2", 1)])
    lobes = [(82, 112, 70, 46), (162, 84, 88, 58), (242, 112, 64, 42), (162, 130, 112, 40)]
    shifted = "".join(
        f'<ellipse cx="{x - 9}" cy="{y - 7}" rx="{rx}" ry="{ry}" fill="{CORAL}" opacity="0.5"/>'
        for x, y, rx, ry in lobes)
    body = shifted + "".join(
        f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="url(#puff)"/>'
        for x, y, rx, ry in lobes)
    body += f"""
<ellipse cx="162" cy="130" rx="112" ry="40" fill="none" stroke="{INK}" stroke-opacity="0.5" stroke-width="2.5"/>
<ellipse cx="162" cy="84" rx="88" ry="58" fill="none" stroke="{INK}" stroke-opacity="0.5" stroke-width="2.5"/>
<ellipse cx="162" cy="146" rx="112" ry="20" fill="{INK}" opacity="0.14"/>
"""
    write("cloud.svg", svg(320, 180, defs, body))


def noctilucent():
    """Electric night cloud: teal inks, thin strata lines."""
    defs = linear("nlc", [(0, "#bfeee2", 0.8), (1, TEAL, 0.4)])
    lobes = [(76, 82, 62, 34), (150, 62, 78, 42), (224, 84, 56, 30), (150, 96, 100, 30)]
    shifted = "".join(
        f'<ellipse cx="{x - 7}" cy="{y - 5}" rx="{rx}" ry="{ry}" fill="{VIOLET}" opacity="0.35"/>'
        for x, y, rx, ry in lobes)
    body = shifted + "".join(
        f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="url(#nlc)"/>'
        for x, y, rx, ry in lobes)
    body += f"""
<line x1="52" y1="88" x2="252" y2="88" stroke="{TEAL}" stroke-opacity="0.8" stroke-width="2"/>
<line x1="70" y1="100" x2="236" y2="100" stroke="{TEAL}" stroke-opacity="0.5" stroke-width="1.5"/>
"""
    write("noctilucent.svg", svg(300, 140, defs, body))


def balloon():
    """Coral balloon, flat with one hard highlight wedge; paper instrument box."""
    defs = linear("box", [(0, PAPER, 1), (1, "#d4c9b2", 1)])
    body = f"""
<path d="M85 146 Q77 196 93 196" fill="none" stroke="{INK}" stroke-opacity="0.7" stroke-width="2.5"/>
<ellipse cx="79" cy="72" rx="56" ry="64" fill="{VIOLET}" opacity="0.45"/>
<ellipse cx="85" cy="78" rx="56" ry="64" fill="{CORAL}"/>
<path d="M60 32 A 52 60 0 0 0 38 78 L 52 78 A 40 48 0 0 1 68 42 Z" fill="#ffffff" opacity="0.35"/>
<ellipse cx="85" cy="78" rx="56" ry="64" fill="none" stroke="{INK}" stroke-opacity="0.75" stroke-width="3"/>
<path d="M78 138 L92 138 L85 150 Z" fill="{INK}"/>
<rect x="69" y="196" width="48" height="36" rx="4" fill="url(#box)" stroke="{INK}" stroke-opacity="0.8" stroke-width="3"/>
<line x1="81" y1="196" x2="81" y2="232" stroke="{INK}" stroke-opacity="0.4" stroke-width="2.5"/>
<line x1="105" y1="196" x2="105" y2="232" stroke="{INK}" stroke-opacity="0.4" stroke-width="2.5"/>
<circle cx="93" cy="214" r="4" fill="{AMBER}"/>
"""
    write("balloon.svg", svg(170, 240, defs, body))


def airplane():
    """Paper fuselage, ink line work, coral wing and tail. Poster flat."""
    defs = linear("fus", [(0, PAPER, 1), (1, "#d8cdb6", 1)])
    windows = "".join(
        f'<circle cx="{110 + i * 30}" cy="72" r="8" fill="{INK}" opacity="0.85"/>'
        for i in range(6)
    )
    body = f"""
<polygon points="52,60 86,60 74,16 46,16" fill="{CORAL}" stroke="{INK}" stroke-opacity="0.7" stroke-width="3"/>
<rect x="34" y="52" width="282" height="46" rx="23" fill="{VIOLET}" opacity="0.4"/>
<rect x="40" y="55" width="282" height="46" rx="23" fill="url(#fus)"/>
<circle cx="320" cy="78" r="23" fill="url(#fus)"/>
<rect x="40" y="55" width="282" height="46" rx="23" fill="none" stroke="{INK}" stroke-opacity="0.8" stroke-width="3"/>
<polygon points="150,94 232,94 198,132 126,132" fill="{CORAL}" stroke="{INK}" stroke-opacity="0.7" stroke-width="3"/>
<path d="M306 60 Q322 60 326 74 L306 74 Z" fill="{INK}" opacity="0.85"/>
{windows}
<line x1="46" y1="86" x2="316" y2="86" stroke="{CORAL}" stroke-opacity="0.9" stroke-width="4"/>
"""
    write("airplane.svg", svg(380, 150, defs, body))


def satellite():
    """Ink body, teal cells, amber foil — flat panels, no gloss."""
    def array(x):
        grid = "".join(
            f'<line x1="{x + 4 + c * 17}" y1="59" x2="{x + 4 + c * 17}" y2="111" '
            f'stroke="{INK}" stroke-width="2" opacity="0.65"/>' for c in range(1, 4)
        ) + "".join(
            f'<line x1="{x + 2}" y1="{59 + r * 17}" x2="{x + 72}" y2="{59 + r * 17}" '
            f'stroke="{INK}" stroke-width="2" opacity="0.65"/>' for r in range(1, 3)
        )
        return (f'<rect x="{x - 5}" y="52" width="74" height="56" rx="3" fill="{VIOLET}" opacity="0.4"/>'
                f'<rect x="{x}" y="57" width="74" height="56" rx="3" fill="{TEAL}" '
                f'stroke="{INK}" stroke-width="3"/>' + grid)

    stripes = "".join(
        f'<rect x="100" y="{62 + i * 13}" width="60" height="5" fill="{INK}" opacity="0.18"/>'
        for i in range(4)
    )
    body = f"""
{array(8)}
{array(178)}
<rect x="82" y="79" width="16" height="12" fill="{INK}" opacity="0.8"/>
<rect x="162" y="79" width="16" height="12" fill="{INK}" opacity="0.8"/>
<rect x="90" y="48" width="68" height="64" rx="5" fill="{CORAL}" opacity="0.55"/>
<rect x="96" y="53" width="68" height="64" rx="5" fill="{AMBER}"/>
{stripes}
<rect x="140" y="53" width="24" height="64" fill="{PAPER}"/>
<rect x="96" y="53" width="68" height="64" rx="5" fill="none" stroke="{INK}" stroke-width="3.5"/>
<line x1="130" y1="53" x2="130" y2="30" stroke="{INK}" stroke-width="3.5"/>
<circle cx="130" cy="25" r="6" fill="{CORAL}" stroke="{INK}" stroke-width="2"/>
"""
    write("satellite.svg", svg(260, 170, defs="", body=body))


def cms():
    """The CMS end-cap, riso-flat: rings of coral yoke segments around a
    paper disc, a teal tracker ring, the amber beam spot dead center,
    all on a violet misprint echo. 480x480, wheel center at (240, 240)."""
    import math
    segs = []
    # Outer yoke: 12 coral wedges with ink gaps.
    for i in range(12):
        a0 = i * 30 + 2
        a1 = (i + 1) * 30 - 2
        r0, r1 = 150, 218
        x0, y0 = 240 + r0 * math.cos(math.radians(a0)), 240 + r0 * math.sin(math.radians(a0))
        x1, y1 = 240 + r1 * math.cos(math.radians(a0)), 240 + r1 * math.sin(math.radians(a0))
        x2, y2 = 240 + r1 * math.cos(math.radians(a1)), 240 + r1 * math.sin(math.radians(a1))
        x3, y3 = 240 + r0 * math.cos(math.radians(a1)), 240 + r0 * math.sin(math.radians(a1))
        segs.append(
            f'<polygon points="{x0:.0f},{y0:.0f} {x1:.0f},{y1:.0f} {x2:.0f},{y2:.0f} '
            f'{x3:.0f},{y3:.0f}" fill="{CORAL}" stroke="{INK}" stroke-width="3"/>')
    bolts = "".join(
        f'<circle cx="{240 + 128 * math.cos(math.radians(b * 30 + 15)):.0f}" '
        f'cy="{240 + 128 * math.sin(math.radians(b * 30 + 15)):.0f}" r="4" fill="{INK}" opacity="0.7"/>'
        for b in range(12))
    body = f"""
<circle cx="228" cy="232" r="220" fill="{VIOLET}" opacity="0.30"/>
<circle cx="240" cy="240" r="220" fill="#4a3b35"/>
<circle cx="240" cy="240" r="220" fill="none" stroke="{INK}" stroke-width="4"/>
{''.join(segs)}
<circle cx="240" cy="240" r="146" fill="{PAPER}" stroke="{INK}" stroke-width="3.5"/>
{bolts}
<circle cx="240" cy="240" r="104" fill="#d8cdb6" stroke="{INK}" stroke-width="3"/>
<circle cx="240" cy="240" r="70" fill="{TEAL}" stroke="{INK}" stroke-width="3"/>
<circle cx="240" cy="240" r="40" fill="{PAPER}" stroke="{INK}" stroke-width="2.5"/>
<circle cx="240" cy="240" r="14" fill="{AMBER}" stroke="{INK}" stroke-width="2.5"/>
<circle cx="240" cy="240" r="5" fill="#ffffff"/>
<rect x="96" y="430" width="288" height="22" rx="4" fill="{INK}"/>
<polygon points="150,452 210,452 190,388 170,388" fill="{INK}" opacity="0.85"/>
<polygon points="270,452 330,452 310,388 290,388" fill="{INK}" opacity="0.85"/>
"""
    write("cms.svg", svg(480, 480, "", body))


def detector():
    """The observatory: warm paper block, coral roof, ink line work,
    an amber instrument dome. Architectural, not gingerbread."""
    defs = linear("wall", [(0, PAPER, 1), (1, "#d8cdb6", 1)])
    shadow = "".join(
        f'<line x1="{270 - 230 + i * 24}" y1="{288 + (i % 2) * 5}" '
        f'x2="{270 - 230 + i * 24 + 16}" y2="{288 + (i % 2) * 5}" '
        f'stroke="{INK}" stroke-opacity="0.30" stroke-width="4" stroke-linecap="round"/>'
        for i in range(20)
    )
    body = f"""
{shadow}
<rect x="72" y="112" width="380" height="162" rx="4" fill="{VIOLET}" opacity="0.35"/>
<rect x="80" y="120" width="380" height="162" rx="4" fill="url(#wall)"/>
<rect x="80" y="238" width="380" height="44" rx="4" fill="{INK}" opacity="0.14"/>
<rect x="80" y="120" width="380" height="162" rx="4" fill="none" stroke="{INK}" stroke-opacity="0.85" stroke-width="4"/>
<rect x="66" y="94" width="408" height="36" rx="4" fill="{CORAL}" stroke="{INK}" stroke-opacity="0.85" stroke-width="4"/>
<rect x="240" y="192" width="60" height="90" rx="3" fill="{INK}"/>
<circle cx="270" cy="222" r="9" fill="none" stroke="{PAPER}" stroke-width="2.5"/>
<rect x="128" y="160" width="46" height="36" rx="3" fill="{INK}" opacity="0.88"/>
<rect x="366" y="160" width="46" height="36" rx="3" fill="{INK}" opacity="0.88"/>
<rect x="132" y="164" width="18" height="28" fill="{AMBER}" opacity="0.85"/>
<rect x="370" y="164" width="18" height="28" fill="{AMBER}" opacity="0.85"/>
<rect x="170" y="136" width="200" height="32" rx="3" fill="{PAPER}" stroke="{INK}" stroke-opacity="0.85" stroke-width="3"/>
<rect x="418" y="52" width="9" height="44" fill="{INK}"/>
<circle cx="423" cy="46" r="21" fill="{AMBER}" stroke="{INK}" stroke-width="3.5"/>
<line x1="423" y1="46" x2="435" y2="30" stroke="{INK}" stroke-width="3"/>
<circle cx="110" cy="150" r="9" fill="{TEAL}" stroke="{INK}" stroke-width="2.5"/>
"""
    write("detector.svg", svg(540, 320, defs, body))


def fogband():
    """A wide printed cloud band for the 3D stage dressing: flat strata
    bars, a coral under-pass, an ink hairline. No soft ovals."""
    body = f"""
<rect x="20" y="58" width="380" height="34" rx="17" fill="{CORAL}" opacity="0.35"/>
<rect x="20" y="40" width="420" height="42" rx="21" fill="{PAPER}" opacity="0.9"/>
<rect x="70" y="22" width="260" height="30" rx="15" fill="#f6f0e2" opacity="0.85"/>
<rect x="120" y="84" width="230" height="18" rx="9" fill="{PAPER}" opacity="0.6"/>
<line x1="40" y1="94" x2="360" y2="94" stroke="{INK}" stroke-opacity="0.5" stroke-width="2.5"/>
"""
    write("fogband.svg", svg(460, 120, "", body))


def glint():
    """Four-point star glint with a coral misprint copy behind."""
    star = "M32 2 L38 26 L62 32 L38 38 L32 62 L26 38 L2 32 L26 26 Z"
    body = f"""
<path d="{star}" fill="{CORAL}" opacity="0.55" transform="translate(-3 2)"/>
<path d="{star}" fill="{PAPER}"/>
"""
    write("glint.svg", svg(64, 64, "", body))


def sparkle():
    defs = radial("core", [(0, "#ffffff", 1), (0.5, "#dff4ff", 0.9), (1, "#bfe9ff", 0)])
    body = """
<circle cx="32" cy="32" r="30" fill="url(#core)" opacity="0.6"/>
<path d="M32 4 L37 27 L60 32 L37 37 L32 60 L27 37 L4 32 L27 27 Z" fill="#ffffff"/>
<path d="M32 16 L35 29 L48 32 L35 35 L32 48 L29 35 L16 32 L29 29 Z" fill="#ffffff" opacity="0.8" transform="rotate(45 32 32)"/>
"""
    write("sparkle.svg", svg(64, 64, defs, body))


def streak():
    defs = linear("wisp", [(0, "#ffffff", 0), (0.5, "#ffffff", 0.9), (1, "#ffffff", 0)])
    body = '<rect x="3" y="2" width="6" height="60" rx="3" fill="url(#wisp)"/>'
    write("streak.svg", svg(12, 64, defs, body))


def spark_icon():
    body = f"""
<path d="M20 3 L37 20 L20 37 L3 20 Z" fill="{VIOLET}" opacity="0.6" transform="translate(2 2)"/>
<path d="M22 3 L39 22 L22 41 L5 22 Z" fill="{TEAL}" stroke="{INK}" stroke-opacity="0.8" stroke-width="2.5"/>
"""
    write("spark_icon.svg", svg(44, 44, defs="", body=body))


def main():
    os.makedirs(OUT, exist_ok=True)
    muon("muon.svg", "#f3e2c8", "#ffb03a")
    cloud()
    noctilucent()
    balloon()
    airplane()
    satellite()
    detector()
    cms()
    fogband()
    glint()
    sparkle()
    streak()
    spark_icon()


if __name__ == "__main__":
    main()
