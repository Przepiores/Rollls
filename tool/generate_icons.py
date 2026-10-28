"""Generuje ikony aplikacji Ice Rolls (Android + iOS) z assets/icon/logo_full.png.

Uruchom z katalogu repo:  python3 tool/generate_icons.py
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'assets/icon/logo_full.png'
OUT = ROOT / 'assets/icon'

# Okrąg z kubkiem w pliku logo (środek i promień w pikselach źródła).
CX, CY, R = 927, 478, 418

PINK = (255, 79, 163)    # neonPink z lib/theme.dart
PURPLE = (138, 42, 155)  # RollColors.purple


def logo_circle(size):
    """Okrąg logo bez napisu, z przezroczystym tłem poza okręgiem."""
    src = Image.open(SRC).convert('RGB').crop((CX - R, CY - R, CX + R, CY + R))
    src = src.resize((size, size), Image.LANCZOS)
    mask = Image.new('L', (size * 4, size * 4), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size * 4 - 1, size * 4 - 1), fill=255)
    out = src.convert('RGBA')
    out.putalpha(mask.resize((size, size), Image.LANCZOS))
    return out


def gradient(size):
    """Ukośny gradient róż → fiolet jak nagłówek aplikacji."""
    t = np.add.outer(np.arange(size), np.arange(size)) / (2 * (size - 1))
    rgb = [(1 - t) * a + t * b for a, b in zip(PINK, PURPLE)]
    return Image.fromarray(np.dstack(rgb).astype('uint8'), 'RGB').convert('RGBA')


def badge(size, diameter):
    """Białe koło z logo i delikatnym cieniem, na przezroczystym kwadracie."""
    layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    off = (size - diameter) // 2
    shadow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(shadow)
    d.ellipse((off, off + size * 0.015, off + diameter, off + diameter + size * 0.015), fill=(40, 0, 50, 90))
    layer.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(size * 0.02)))
    disc = Image.new('L', (diameter * 4, diameter * 4), 0)
    ImageDraw.Draw(disc).ellipse((0, 0, diameter * 4 - 1, diameter * 4 - 1), fill=255)
    white = Image.new('RGBA', (diameter, diameter), (255, 255, 255, 255))
    white.putalpha(disc.resize((diameter, diameter), Image.LANCZOS))
    layer.alpha_composite(white, (off, off))
    inner = int(diameter * 0.93)
    layer.alpha_composite(logo_circle(inner), ((size - inner) // 2,) * 2)
    return layer


def monochrome(size, diameter):
    """Sama kreska logo jako maska (ikony motywowe Androida 13+)."""
    logo = logo_circle(diameter)
    ink = 255 - np.array(logo.convert('L'), dtype=np.int32)
    alpha = (np.clip(ink * 2.5, 0, 255) * (np.array(logo)[:, :, 3] / 255)).astype('uint8')
    mark = Image.new('RGBA', (diameter, diameter), (255, 255, 255, 255))
    mark.putalpha(Image.fromarray(alpha, 'L'))
    layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    layer.alpha_composite(mark, ((size - diameter) // 2,) * 2)
    return layer


def main():
    big = 1024
    full = gradient(big)
    full.alpha_composite(badge(big, int(big * 0.76)))
    full.convert('RGB').save(OUT / 'icon.png')

    # Adaptacyjna ikona Androida: 108 dp, bezpieczna strefa to koło 66 dp.
    fg = badge(big, int(big * 0.56))
    fg.save(OUT / 'icon_foreground.png')
    gradient(big).convert('RGB').save(OUT / 'icon_background.png')
    monochrome(big, int(big * 0.54)).save(OUT / 'icon_monochrome.png')

    res = ROOT / 'android/app/src/main/res'
    for name, scale in {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}.items():
        folder = res / f'mipmap-{name}'
        folder.mkdir(exist_ok=True)
        legacy = int(48 * scale)
        full.convert('RGB').resize((legacy, legacy), Image.LANCZOS).save(folder / 'ic_launcher.png')
        layer = int(108 * scale)
        fg.resize((layer, layer), Image.LANCZOS).save(folder / 'ic_launcher_foreground.png')
        gradient(layer).convert('RGB').save(folder / 'ic_launcher_background.png')
        monochrome(big, int(big * 0.54)).resize((layer, layer), Image.LANCZOS).save(folder / 'ic_launcher_monochrome.png')

    ios = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    for png in ios.glob('Icon-App-*.png'):
        w = Image.open(png).size[0]
        full.convert('RGB').resize((w, w), Image.LANCZOS).save(png)


if __name__ == '__main__':
    main()
