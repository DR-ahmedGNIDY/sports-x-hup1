"""Generates the iOS PWA launch images referenced by `web/index.html`.

iOS is the one platform that ignores `manifest.json`'s `background_color`
when an installed PWA launches — without an `apple-touch-startup-image`
matching the device's exact pixel size it shows a blank white screen before
the app boots. Every other platform is covered by the manifest plus the
in-page loader in `web/index.html`.

Run from `frontend/`:

    python tool/generate_ios_splash.py

Requires Pillow (`pip install pillow`). Re-run only when the logo or the
brand background color changes — the output is committed, so a normal
build/deploy never needs this script.
"""

from pathlib import Path

from PIL import Image

# AppColors.black — the app's dark scaffold background, and the same value
# used for `theme_color`/`background_color` in web/manifest.json.
BACKGROUND = (0x0B, 0x0E, 0x14, 255)

# Fraction of the device's shorter edge the logo occupies. Matches the
# in-page loader's logo sizing in web/index.html so the handoff from the
# native launch image to the HTML loader is invisible.
LOGO_RATIO = 0.42

ROOT = Path(__file__).resolve().parent.parent
SOURCE_LOGO = ROOT / "assets" / "images" / "logo.png"
OUTPUT_DIR = ROOT / "web" / "splash"

# (css_width, css_height, device_pixel_ratio) for every iPhone/iPad still
# receiving iOS updates. Portrait only — web/manifest.json locks the app to
# `portrait-primary`, so a landscape launch image would never be shown.
DEVICES = [
    (440, 956, 3),   # iPhone 16 Pro Max
    (430, 932, 3),   # iPhone 15/16 Plus, 14 Pro Max
    (402, 874, 3),   # iPhone 16 / 16 Pro
    (393, 852, 3),   # iPhone 14 Pro, 15, 16e
    (428, 926, 3),   # iPhone 12/13 Pro Max
    (390, 844, 3),   # iPhone 12/13/14
    (375, 812, 3),   # iPhone X/XS/11 Pro, 13 mini
    (414, 896, 3),   # iPhone XS Max, 11 Pro Max
    (414, 896, 2),   # iPhone XR, 11
    (375, 667, 2),   # iPhone SE (2nd/3rd gen), 8
    (414, 736, 3),   # iPhone 8 Plus
    (1024, 1366, 2),  # iPad Pro 12.9"
    (834, 1194, 2),  # iPad Pro 11"
    (820, 1180, 2),  # iPad Air 10.9"
    (810, 1080, 2),  # iPad 10.2"
    (744, 1133, 2),  # iPad mini 6
    (768, 1024, 2),  # iPad 9.7"
]


def build(logo: Image.Image, css_width: int, css_height: int, ratio: int) -> Image.Image:
    width, height = css_width * ratio, css_height * ratio
    canvas = Image.new("RGBA", (width, height), BACKGROUND)

    target = int(min(width, height) * LOGO_RATIO)
    scaled_height = max(1, round(logo.height * target / logo.width))
    scaled = logo.resize((target, scaled_height), Image.LANCZOS)

    canvas.paste(
        scaled,
        ((width - scaled.width) // 2, (height - scaled.height) // 2),
        scaled,
    )
    # A flat brand background plus a two-tone logo needs nowhere near 24-bit
    # color. Quantizing keeps these visually identical while cutting the set
    # from ~2 MB to a few hundred KB — worth it for files an installed iOS
    # app fetches on launch.
    return canvas.convert("RGB").quantize(colors=128, method=Image.MEDIANCUT)


def main() -> None:
    logo = Image.open(SOURCE_LOGO).convert("RGBA")
    # The source asset is a 1024² canvas with ~12% transparent padding baked
    # in. Cropping to the mark itself is what makes LOGO_RATIO mean what it
    # says instead of silently shrinking every launch image's logo.
    logo = logo.crop(logo.getbbox())
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    for css_width, css_height, ratio in DEVICES:
        image = build(logo, css_width, css_height, ratio)
        path = OUTPUT_DIR / f"launch-{css_width}x{css_height}@{ratio}x.png"
        image.save(path, "PNG", optimize=True)
        print(f"{path.relative_to(ROOT)}  {image.width}x{image.height}")

    print(f"\n{len(DEVICES)} launch images written to {OUTPUT_DIR.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
