from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "source-images/redraw-workbench/masters/q01/foreground-mobile-raw.png"
OUTPUT = ROOT / "assets/scenes/q01/midground-rocket.png"


def main() -> None:
    source = Image.open(SOURCE).convert("RGB")
    rocket = source.crop((310, 190, 500, 380))
    scale = 4
    silhouette = Image.new("L", (rocket.width * scale, rocket.height * scale), 0)
    draw = ImageDraw.Draw(silhouette)
    polygons = [
        [(145, 29), (165, 20), (171, 29), (164, 51), (146, 72), (128, 91), (111, 118), (89, 140), (72, 133), (63, 120), (71, 101), (93, 77), (119, 50)],
        [(121, 50), (86, 53), (53, 72), (36, 102), (70, 96), (96, 77)],
        [(112, 110), (110, 142), (89, 168), (80, 136)],
        [(76, 126), (64, 151), (29, 179), (38, 147), (57, 116)],
        [(58, 108), (93, 128), (79, 149), (51, 130)],
    ]
    for polygon in polygons:
        draw.polygon([(x * scale, y * scale) for x, y in polygon], fill=255)
    silhouette = silhouette.resize(rocket.size, Image.Resampling.LANCZOS)
    rgb = np.asarray(rocket, dtype=np.int16)
    red, green, blue = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    seed = (
        (rgb.max(axis=2) > 175)
        | ((blue > 90) & (blue > red * 1.08))
        | ((red > 155) & (red > green * 1.35))
    )
    seed_alpha = Image.fromarray(np.where(seed, 255, 0).astype(np.uint8), "L")
    seed_alpha = seed_alpha.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.MinFilter(3))
    alpha = ImageChops.multiply(silhouette, seed_alpha).filter(ImageFilter.GaussianBlur(0.55))
    result = rocket.convert("RGBA")
    result.putalpha(alpha)
    bbox = alpha.point(lambda value: 255 if value > 8 else 0).getbbox()
    if not bbox:
        raise RuntimeError("Rocket extraction produced an empty mask")
    left, top, right, bottom = bbox
    padding = 4
    result = result.crop((max(0, left - padding), max(0, top - padding), min(result.width, right + padding), min(result.height, bottom + padding)))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    result.save(OUTPUT)
    result.save(OUTPUT.with_suffix(".webp"), "WEBP", lossless=True, quality=92, method=6)


if __name__ == "__main__":
    main()
