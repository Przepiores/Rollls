"""Generuje ikony aplikacji (Android, iOS, web) i małe logo do nagłówka z assets/images/logo.png.

Na ikonie jest okrąg z kubkiem rolek z logo na białym tle; napis
"Ice Rolls" byłby nieczytelny w rozmiarze ikony.

Uruchom z katalogu głównego repo: python3 tool/generate_icons.py
"""

import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
LOGO = ROOT / "assets/images/logo.png"
# Okrąg z kubkiem w logo.png (wyliczony z ciemnych pikseli obrysu).
CIRCLE_BOX = (210, 21, 564, 379)
WHITE = (255, 255, 255, 255)


def emblem() -> Image.Image:
    """Okrąg z logo, przezroczysty poza czarnym obrysem."""
    e = Image.open(LOGO).convert("RGBA").crop(CIRCLE_BOX)
    scale = 4  # maska rysowana większa i zmniejszana, żeby krawędź była gładka
    mask = Image.new("L", (e.width * scale, e.height * scale), 0)
    ImageDraw.Draw(mask).ellipse((scale * 3, scale * 3, (e.width - 3) * scale, (e.height - 3) * scale), fill=255)
    e.putalpha(mask.resize(e.size, Image.LANCZOS))
    return e


def icon(size: int, scale: float, background=WHITE) -> Image.Image:
    """Kwadrat size x size z okręgiem zajmującym `scale` szerokości."""
    canvas = Image.new("RGBA", (size, size), background)
    e = emblem()
    target = round(size * scale)
    e = e.resize((target, round(target * e.height / e.width)), Image.LANCZOS)
    canvas.alpha_composite(e, ((size - e.width) // 2, (size - e.height) // 2))
    return canvas


def android() -> None:
    res = ROOT / "android/app/src/main/res"
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for name, f in densities.items():
        d = res / f"mipmap-{name}"
        # Okrągła ikona: sam okrąg z logo, bez tła dookoła.
        round_icon = icon(round(48 * f), 0.96, background=(0, 0, 0, 0))
        round_icon.save(d / "ic_launcher.png")
        round_icon.save(d / "ic_launcher_round.png")
        # Adaptacyjna ikona: 108 dp, launcher pokazuje koło ~72 dp, obrys logo leży przy jego krawędzi.
        icon(round(108 * f), 0.69, background=(0, 0, 0, 0)).save(d / "ic_launcher_foreground.png")
    v26 = res / "mipmap-anydpi-v26"
    v26.mkdir(exist_ok=True)
    adaptive = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        "</adaptive-icon>\n"
    )
    (v26 / "ic_launcher.xml").write_text(adaptive)
    (v26 / "ic_launcher_round.xml").write_text(adaptive)
    (res / "values/colors.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        '    <color name="ic_launcher_background">#FFFFFF</color>\n'
        "</resources>\n"
    )


def ios() -> None:
    d = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((d / "Contents.json").read_text())
    for img in contents["images"]:
        pt = float(img["size"].split("x")[0])
        px = round(pt * int(img["scale"].rstrip("x")))
        # iOS nie przyjmuje przezroczystości w ikonie i zawsze przycina ją do zaokrąglonego
        # kwadratu, więc okrąg leży na białym tle.
        icon(px, 0.9).convert("RGB").save(d / img["filename"])


def web() -> None:
    d = ROOT / "web"
    icon(32, 0.96, background=(0, 0, 0, 0)).save(d / "favicon.png")
    for s in (192, 512):
        icon(s, 0.96, background=(0, 0, 0, 0)).save(d / f"icons/Icon-{s}.png")
        icon(s, 0.7).save(d / f"icons/Icon-maskable-{s}.png")
    # Safari na iPhonie zamienia przezroczystość na czarne tło, więc ikona ekranu
    # początkowego ma białe tło, jak ikona aplikacji iOS.
    icon(180, 0.9).convert("RGB").save(d / "icons/apple-touch-icon.png")


def emblem_asset() -> None:
    """Sam okrąg z logo do małego logo w nagłówku aplikacji."""
    icon(256, 1.0, background=(0, 0, 0, 0)).save(ROOT / "assets/images/logo_emblem.png")


if __name__ == "__main__":
    emblem_asset()
    android()
    ios()
    web()
