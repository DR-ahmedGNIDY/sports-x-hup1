"""Generates the bundled, resolution-aware logo assets from the brand master.

`assets/images/logo.png` used to be the 1024x1024 master itself: 1.2 MB
downloaded on first paint, to draw a mark that is never taller than 96
logical pixels anywhere in the app (see AppLogo's call sites). It sits in the
app bar of every screen, so it was the single largest thing standing between
a phone on mobile data and a first frame.

This writes the three variants Flutter resolves by device pixel ratio, sized
for the largest real use. The master stays in `assets/brand/`, which is
deliberately *not* listed in pubspec.yaml — it is a source file, not a
shipped one, and it remains the input for tool/generate_ios_splash.py, whose
launch images do need the full resolution.

Run from `frontend/`:

    python tool/generate_logo_variants.py

Requires Pillow (`pip install pillow`). Re-run only when the logo changes;
the output is committed.
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
MASTER = ROOT / "assets" / "brand" / "logo_master.png"
OUTPUT_DIR = ROOT / "assets" / "images"

# The tallest AppLogo in the app is 96 (the marketing hero); every other use
# is 24-72. 1x is sized to that ceiling, and the 2x/3x variants follow.
BASE_HEIGHT = 96


def main() -> None:
    logo = Image.open(MASTER).convert("RGBA")
    # The master carries ~12% transparent padding. Cropping it here means the
    # bundled variants are all mark and no empty pixels, and that `height:` at
    # a call site is the height of the mark rather than of its bounding box.
    logo = logo.crop(logo.getbbox())

    for scale in (1, 2, 3):
        height = BASE_HEIGHT * scale
        width = max(1, round(logo.width * height / logo.height))
        variant = logo.resize((width, height), Image.LANCZOS)

        directory = OUTPUT_DIR if scale == 1 else OUTPUT_DIR / f"{scale}.0x"
        directory.mkdir(parents=True, exist_ok=True)
        path = directory / "logo.png"
        variant.save(path, "PNG", optimize=True)

        print(f"{path.relative_to(ROOT)}  {width}x{height}  {path.stat().st_size / 1024:.0f} KB")


if __name__ == "__main__":
    main()
