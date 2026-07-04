#!/usr/bin/env python3
"""Generate the game's sprite assets as layered SVGs.

Faux-3D cartoon style: radial-gradient ball shading, soft speculars,
rim light, underside shade, gentle outlines. Run from the repo root:

    python3 tools/gen_assets.py

Writes to assets/sprites/. All output is deterministic text — commit it.
No <filter> elements (Godot's ThorVG importer doesn't support them);
softness comes from layered gradients and opacity falloff.
"""
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")

INK = "#4a4460"


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


def muon(name, hi, mid, lo, rim):
    defs = (
        radial("body", [(0, "#ffffff", 1), (0.48, hi, 1), (0.8, mid, 1), (1, lo, 1)],
               fx=0.36, fy=0.28)
        + radial("glow", [(0, "#fff8e8", 0.6), (0.7, "#fff8e8", 0.18), (1, "#fff8e8", 0)])
    )
    body = f"""
<circle cx="64" cy="64" r="60" fill="url(#glow)"/>
<circle cx="64" cy="64" r="46" fill="url(#body)"/>
<ellipse cx="64" cy="92" rx="32" ry="13" fill="{rim}" opacity="0.55"/>
<ellipse cx="88" cy="76" rx="12" ry="22" fill="{rim}" opacity="0.3" transform="rotate(-28 88 76)"/>
<circle cx="64" cy="64" r="46" fill="none" stroke="{INK}" stroke-opacity="0.42" stroke-width="6"/>
<ellipse cx="48" cy="42" rx="16" ry="10" fill="#ffffff" opacity="0.95" transform="rotate(-18 48 42)"/>
<circle cx="36" cy="57" r="4.5" fill="#ffffff" opacity="0.7"/>
"""
    write(name, svg(128, 128, defs, body))


def cloud():
    defs = (
        linear("puff", [(0, "#ffffff", 1), (1, "#d3ddf3", 1)])
        + linear("shade", [(0, "#c3cfeb", 0.0), (1, "#aebde2", 0.9)])
    )
    lobes = [(82, 112, 70, 46), (162, 84, 88, 58), (242, 112, 64, 42), (162, 130, 112, 40)]
    body = "".join(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="url(#puff)"/>'
                   for x, y, rx, ry in lobes)
    body += """
<ellipse cx="162" cy="146" rx="118" ry="24" fill="url(#shade)"/>
<ellipse cx="140" cy="58" rx="52" ry="24" fill="#ffffff" opacity="0.9"/>
<ellipse cx="72" cy="94" rx="30" ry="15" fill="#ffffff" opacity="0.7"/>
<ellipse cx="238" cy="96" rx="26" ry="13" fill="#ffffff" opacity="0.6"/>
"""
    write("cloud.svg", svg(320, 180, defs, body))


def noctilucent():
    defs = (
        linear("nlc", [(0, "#eaf3ff", 0.75), (1, "#b9d4ff", 0.45)])
        + linear("nlcrim", [(0, "#8fd0ff", 0.0), (1, "#8fd0ff", 0.55)])
    )
    lobes = [(76, 82, 62, 34), (150, 62, 78, 42), (224, 84, 56, 30), (150, 96, 100, 30)]
    body = "".join(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="url(#nlc)"/>'
                   for x, y, rx, ry in lobes)
    body += """
<ellipse cx="150" cy="106" rx="104" ry="18" fill="url(#nlcrim)"/>
<ellipse cx="130" cy="44" rx="44" ry="16" fill="#ffffff" opacity="0.75"/>
<ellipse cx="66" cy="70" rx="24" ry="10" fill="#ffffff" opacity="0.5"/>
"""
    write("noctilucent.svg", svg(300, 140, defs, body))


def balloon():
    defs = (
        radial("bal", [(0, "#ffd9df", 1), (0.55, "#ff9dad", 1), (1, "#d1546c", 1)],
               fx=0.38, fy=0.30)
        + linear("box", [(0, "#fff4de", 1), (1, "#e9d0a6", 1)])
    )
    body = f"""
<path d="M85 146 Q77 196 93 196" fill="none" stroke="{INK}" stroke-opacity="0.55" stroke-width="2.5"/>
<ellipse cx="85" cy="78" rx="56" ry="64" fill="url(#bal)"/>
<ellipse cx="85" cy="78" rx="56" ry="64" fill="none" stroke="{INK}" stroke-opacity="0.22" stroke-width="4"/>
<ellipse cx="63" cy="48" rx="14" ry="22" fill="#ffffff" opacity="0.75" transform="rotate(-18 63 48)"/>
<circle cx="58" cy="80" r="5" fill="#ffffff" opacity="0.5"/>
<path d="M78 138 L92 138 L85 150 Z" fill="#e26b81"/>
<rect x="69" y="196" width="48" height="36" rx="7" fill="url(#box)" stroke="{INK}" stroke-opacity="0.35" stroke-width="3"/>
<line x1="81" y1="196" x2="81" y2="232" stroke="{INK}" stroke-opacity="0.25" stroke-width="3"/>
<line x1="105" y1="196" x2="105" y2="232" stroke="{INK}" stroke-opacity="0.25" stroke-width="3"/>
"""
    write("balloon.svg", svg(170, 240, defs, body))


def airplane():
    defs = (
        linear("fus", [(0, "#fffdf6", 1), (1, "#dcd1b8", 1)])
        + linear("fin", [(0, "#ffb9c4", 1), (1, "#ff8fa0", 1)])
        + linear("wing", [(0, "#ffd7dd", 1), (1, "#ffadbb", 1)])
        + linear("glass", [(0, "#eaf7ff", 1), (1, "#9fd0f5", 1)])
    )
    windows = "".join(
        f'<circle cx="{110 + i * 30}" cy="72" r="9" fill="url(#glass)" stroke="{INK}" '
        f'stroke-opacity="0.3" stroke-width="2.5"/>'
        f'<circle cx="{106 + i * 30}" cy="68" r="2.6" fill="#ffffff" opacity="0.85"/>'
        for i in range(6)
    )
    body = f"""
<polygon points="52,60 86,60 74,16 46,16" fill="url(#fin)" stroke="{INK}" stroke-opacity="0.28" stroke-width="3"/>
<rect x="40" y="55" width="282" height="46" rx="23" fill="url(#fus)"/>
<circle cx="320" cy="78" r="23" fill="url(#fus)"/>
<ellipse cx="180" cy="97" rx="140" ry="10" fill="#c2b79e" opacity="0.75"/>
<rect x="40" y="55" width="282" height="46" rx="23" fill="none" stroke="{INK}" stroke-opacity="0.25" stroke-width="3.5"/>
<polygon points="150,94 232,94 198,132 126,132" fill="url(#wing)" stroke="{INK}" stroke-opacity="0.28" stroke-width="3"/>
<path d="M306 60 Q322 60 326 74 L306 74 Z" fill="url(#glass)" stroke="{INK}" stroke-opacity="0.3" stroke-width="2.5"/>
{windows}
<ellipse cx="120" cy="60" rx="52" ry="6" fill="#ffffff" opacity="0.6"/>
"""
    write("airplane.svg", svg(380, 150, defs, body))


def satellite():
    defs = (
        linear("cells", [(0, "#3f63b5", 1), (1, "#274579", 1)])
        + linear("foil", [(0, "#ffe3a6", 1), (1, "#c98f3a", 1)])
        + linear("silver", [(0, "#f6f6fa", 1), (1, "#c6cad8", 1)])
    )

    def array(x):
        grid = "".join(
            f'<line x1="{x + 4 + c * 17}" y1="59" x2="{x + 4 + c * 17}" y2="111" '
            f'stroke="#1d3560" stroke-width="2" opacity="0.7"/>' for c in range(1, 4)
        ) + "".join(
            f'<line x1="{x + 2}" y1="{59 + r * 17}" x2="{x + 72}" y2="{59 + r * 17}" '
            f'stroke="#1d3560" stroke-width="2" opacity="0.7"/>' for r in range(1, 3)
        )
        return (f'<rect x="{x}" y="57" width="74" height="56" rx="4" fill="url(#cells)" '
                f'stroke="#39466e" stroke-width="4"/>' + grid +
                f'<polygon points="{x},57 {x + 30},57 {x + 12},113 {x},113" fill="#ffffff" opacity="0.18"/>')

    stripes = "".join(
        f'<rect x="98" y="{60 + i * 13}" width="64" height="6" fill="#a86f24" opacity="0.22"/>'
        for i in range(5)
    )
    body = f"""
{array(8)}
{array(178)}
<rect x="82" y="79" width="16" height="12" fill="#9aa0b4"/>
<rect x="162" y="79" width="16" height="12" fill="#9aa0b4"/>
<rect x="96" y="53" width="68" height="64" rx="8" fill="url(#foil)"/>
{stripes}
<rect x="140" y="53" width="24" height="64" fill="url(#silver)"/>
<rect x="96" y="53" width="68" height="64" rx="8" fill="none" stroke="{INK}" stroke-opacity="0.35" stroke-width="3.5"/>
<line x1="130" y1="53" x2="130" y2="30" stroke="{INK}" stroke-opacity="0.7" stroke-width="3.5"/>
<circle cx="130" cy="25" r="6" fill="#ff8f9f"/>
<circle cx="128" cy="23" r="2" fill="#ffffff" opacity="0.8"/>
<ellipse cx="104" cy="60" rx="18" ry="5" fill="#ffffff" opacity="0.55"/>
"""
    write("satellite.svg", svg(260, 170, defs, body))


def detector():
    defs = (
        linear("wall", [(0, "#fff8e8", 1), (1, "#eeddbc", 1)])
        + linear("roof", [(0, "#ffb9c4", 1), (1, "#ff8fa0", 1)])
        + linear("door", [(0, "#7a7fc0", 1), (1, "#565b9b", 1)])
        + linear("dglass", [(0, "#e3f5f0", 1), (1, "#a8d8cf", 1)])
    )
    body = f"""
<ellipse cx="270" cy="286" rx="235" ry="18" fill="{INK}" opacity="0.18"/>
<rect x="80" y="120" width="380" height="162" rx="10" fill="url(#wall)"/>
<rect x="80" y="238" width="380" height="44" rx="10" fill="#dcc9a3" opacity="0.55"/>
<rect x="80" y="120" width="380" height="162" rx="10" fill="none" stroke="{INK}" stroke-opacity="0.4" stroke-width="4"/>
<rect x="66" y="94" width="408" height="36" rx="14" fill="url(#roof)" stroke="{INK}" stroke-opacity="0.35" stroke-width="4"/>
<rect x="74" y="99" width="392" height="7" rx="3.5" fill="#ffffff" opacity="0.5"/>
<rect x="240" y="192" width="60" height="90" rx="8" fill="url(#door)" stroke="{INK}" stroke-opacity="0.4" stroke-width="3.5"/>
<circle cx="270" cy="218" r="10" fill="#ffffff" opacity="0.85"/>
<circle cx="288" cy="240" r="3.5" fill="#ffe08a"/>
<rect x="128" y="160" width="46" height="36" rx="6" fill="url(#dglass)" stroke="{INK}" stroke-opacity="0.35" stroke-width="3"/>
<rect x="366" y="160" width="46" height="36" rx="6" fill="url(#dglass)" stroke="{INK}" stroke-opacity="0.35" stroke-width="3"/>
<polygon points="132,162 150,162 138,194 132,194" fill="#ffffff" opacity="0.5"/>
<polygon points="370,162 388,162 376,194 370,194" fill="#ffffff" opacity="0.5"/>
<rect x="170" y="136" width="200" height="32" rx="9" fill="#ffffff" stroke="{INK}" stroke-opacity="0.35" stroke-width="3"/>
<rect x="418" y="52" width="9" height="44" fill="{INK}" opacity="0.7"/>
<circle cx="423" cy="46" r="21" fill="#f2f2f6" stroke="{INK}" stroke-opacity="0.4" stroke-width="3.5"/>
<circle cx="417" cy="40" r="6" fill="#ffffff" opacity="0.8"/>
<line x1="423" y1="46" x2="435" y2="30" stroke="{INK}" stroke-opacity="0.5" stroke-width="3"/>
<circle cx="110" cy="150" r="9" fill="#d9d9de" stroke="{INK}" stroke-opacity="0.35" stroke-width="2.5"/>
"""
    write("detector.svg", svg(540, 320, defs, body))


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
    defs = linear("mint", [(0, "#d2f7ec", 1), (1, "#7ddcc8", 1)])
    body = f"""
<path d="M22 3 L39 22 L22 41 L5 22 Z" fill="url(#mint)" stroke="{INK}" stroke-opacity="0.55" stroke-width="2.5"/>
<path d="M22 10 L31 22 L22 34 L13 22 Z" fill="#ffffff" opacity="0.45"/>
"""
    write("spark_icon.svg", svg(44, 44, defs, body))


def main():
    os.makedirs(OUT, exist_ok=True)
    muon("muon.svg", "#fdf3e3", "#e9dcee", "#b9b0dc", "#a99ed6")
    cloud()
    noctilucent()
    balloon()
    airplane()
    satellite()
    detector()
    sparkle()
    streak()
    spark_icon()


if __name__ == "__main__":
    main()
