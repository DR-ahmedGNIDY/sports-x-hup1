"""Generates every bundled brand asset from the sources in `assets/brand/`.

The sources are deliberately *not* listed in pubspec.yaml — they are input
files, not shipped ones. What ships is sized for its largest real use:

* `logo_{white,black}.png` — the SXH wordmark. The masters are white-on-black
  JPEG/PNG artwork with no transparency, so luminance becomes alpha and the
  mark is then painted in white (for dark surfaces) and black (for light
  ones). The tallest AppLogo in the app is 96, so 1x is sized to that.
* `mark_{white,black}.png` — the X mark on its own, for places too small
  for the wordmark.
* `home_banner.jpg` / `sidebar_promo.jpg` — the dashboard banner and the
  desktop sidebar card, recompressed from multi-megabyte PNGs.
* `web/favicon.png` and `web/icons/*` — the mark, white on the brand black.

Run from `frontend/`:

    python tool/generate_logo_variants.py

Requires Pillow (`pip install pillow`). Re-run only when a source changes;
the output is committed. Run tool/generate_ios_splash.py afterwards — it
reads the transparent wordmark this script writes to `assets/brand/`.
"""

from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parent.parent
BRAND = ROOT / "assets" / "brand"
IMAGES = ROOT / "assets" / "images"
WEB = ROOT / "web"

# AppColors.black — also manifest.json's theme/background color.
BRAND_BLACK = (0x0A, 0x0A, 0x0A, 255)

WHITE = (255, 255, 255)
BLACK = (0x0A, 0x0A, 0x0A)


def mask_from_luminance(path: Path) -> Image.Image:
    """White artwork on black → an alpha mask cropped to the artwork.

    The low/high clamps swallow JPEG ringing around the edges, which would
    otherwise show up as a grey halo once the black is gone.
    """
    grey = Image.open(path).convert("L")
    low, high = 40, 215
    mask = grey.point(lambda v: 0 if v <= low else 255 if v >= high else round((v - low) * 255 / (high - low)))
    return mask.crop(mask.getbbox())


def paint(mask: Image.Image, rgb: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGBA", mask.size, rgb + (0,))
    image.putalpha(mask)
    return image


def save_scaled(image: Image.Image, name: str, base_height: int) -> None:
    for scale in (1, 2, 3):
        height = base_height * scale
        width = max(1, round(image.width * height / image.height))
        directory = IMAGES if scale == 1 else IMAGES / f"{scale}.0x"
        directory.mkdir(parents=True, exist_ok=True)
        path = directory / name
        image.resize((width, height), Image.LANCZOS).save(path, "PNG", optimize=True)
        report(path)


def save_photo(source: Path, name: str, base_width: int, scales: tuple[int, ...]) -> None:
    photo = ImageOps.exif_transpose(Image.open(source)).convert("RGB")
    for scale in scales:
        width = min(photo.width, base_width * scale)
        height = round(photo.height * width / photo.width)
        directory = IMAGES if scale == 1 else IMAGES / f"{scale}.0x"
        directory.mkdir(parents=True, exist_ok=True)
        path = directory / name
        photo.resize((width, height), Image.LANCZOS).save(
            path, "JPEG", quality=80, optimize=True, progressive=True
        )
        report(path)


def square_icon(mark: Image.Image, size: int, fill: float) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), BRAND_BLACK)
    target = round(size * fill)
    scale = target / max(mark.width, mark.height)
    scaled = mark.resize((max(1, round(mark.width * scale)), max(1, round(mark.height * scale))), Image.LANCZOS)
    canvas.paste(scaled, ((size - scaled.width) // 2, (size - scaled.height) // 2), scaled)
    return canvas.convert("RGB")


def report(path: Path) -> None:
    size = Image.open(path).size
    print(f"{path.relative_to(ROOT)}  {size[0]}x{size[1]}  {path.stat().st_size / 1024:.0f} KB")


def main() -> None:
    logo = mask_from_luminance(BRAND / "logo_source.jpg")
    mark = mask_from_luminance(BRAND / "mark_source.png")

    # Transparent white wordmark — the splash generator's input.
    master = paint(logo, WHITE)
    master.save(BRAND / "logo_master.png", "PNG", optimize=True)
    report(BRAND / "logo_master.png")

    save_scaled(paint(logo, WHITE), "logo_white.png", 96)
    save_scaled(paint(logo, BLACK), "logo_black.png", 96)
    save_scaled(paint(mark, WHITE), "mark_white.png", 64)
    save_scaled(paint(mark, BLACK), "mark_black.png", 64)

    # Rendered up to ~1240 logical px wide on desktop.
    save_photo(BRAND / "home_banner_source.jpg", "home_banner.jpg", 1100, (1, 2))
    # Rendered ~210 logical px wide in the sidebar.
    save_photo(BRAND / "sidebar_promo_source.jpg", "sidebar_promo.jpg", 240, (1, 2, 3))

    white_mark = paint(mark, WHITE)
    square_icon(white_mark, 32, 0.78).save(WEB / "favicon.png", "PNG", optimize=True)
    report(WEB / "favicon.png")
    for size in (192, 512):
        path = WEB / "icons" / f"Icon-{size}.png"
        square_icon(white_mark, size, 0.62).save(path, "PNG", optimize=True)
        report(path)
        # Maskable icons get cropped to a circle: keep the mark inside the
        # 80% safe zone with room to spare.
        path = WEB / "icons" / f"Icon-maskable-{size}.png"
        square_icon(white_mark, size, 0.46).save(path, "PNG", optimize=True)
        report(path)
    # A 1024 square for flutter_launcher_icons (Android/iOS native icons).
    path = BRAND / "app_icon.png"
    square_icon(white_mark, 1024, 0.56).save(path, "PNG", optimize=True)
    report(path)


if __name__ == "__main__":
    main()
