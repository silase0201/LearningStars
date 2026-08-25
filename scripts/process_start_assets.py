from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

from split_redraw_atlases import ensure_transparency


ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / "source-images" / "redraw-workbench" / "masters" / "start"
OUTPUT = ROOT / "assets" / "start"
PREVIEW = ROOT / "source-images" / "redraw-workbench" / "previews" / "start-components.jpg"


def trim(image: Image.Image, padding: int = 14) -> Image.Image:
    rgba = image.convert("RGBA")
    bbox = rgba.getchannel("A").point(lambda value: 255 if value > 3 else 0).getbbox()
    if not bbox:
        raise RuntimeError("Start asset extraction produced an empty alpha channel")
    left, top, right, bottom = bbox
    return rgba.crop(
        (
            max(0, left - padding),
            max(0, top - padding),
            min(rgba.width, right + padding),
            min(rgba.height, bottom + padding),
        )
    )


def split_grid(image: Image.Image, columns: int, rows: int) -> list[Image.Image]:
    cells: list[Image.Image] = []
    for row in range(rows):
        for column in range(columns):
            left = round(image.width * column / columns)
            top = round(image.height * row / rows)
            right = round(image.width * (column + 1) / columns)
            bottom = round(image.height * (row + 1) / rows)
            cells.append(trim(image.crop((left, top, right, bottom))))
    return cells


def save_pair(image: Image.Image, relative: str) -> None:
    target = OUTPUT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target.with_suffix(".png"), optimize=True)
    image.save(target.with_suffix(".webp"), "WEBP", quality=92, method=6)


def open_transparent(name: str, force_cleanup: bool = False) -> Image.Image:
    with Image.open(MASTER / name) as loaded:
        source = loaded.convert("RGB") if force_cleanup else loaded.copy()
    return ensure_transparency("start", source)


def make_preview(assets: list[tuple[str, Image.Image]]) -> None:
    columns, cell_width, cell_height = 4, 380, 300
    rows = (len(assets) + columns - 1) // columns
    canvas = Image.new("RGB", (1600, 30 + rows * cell_height), "#06133a")
    draw = ImageDraw.Draw(canvas)
    for index, (name, asset) in enumerate(assets):
        row, column = divmod(index, columns)
        x, y = 25 + column * cell_width, 30 + row * cell_height
        scale = min(340 / asset.width, 235 / asset.height, 1)
        size = (max(1, round(asset.width * scale)), max(1, round(asset.height * scale)))
        resized = asset.resize(size, Image.Resampling.LANCZOS)
        canvas.paste(resized, (x + (340 - size[0]) // 2, y + 25), resized)
        draw.text((x, y + 265), name, fill="#f5f7ff")
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(PREVIEW, quality=92, optimize=True)


def main() -> None:
    generated: list[tuple[str, Image.Image]] = []

    foreground = open_transparent("foreground-atlas-raw.png", force_cleanup=True)
    foreground_names = ["character-child", "character-robot"]
    for name, asset in zip(foreground_names, split_grid(foreground, 2, 2)[:2]):
        save_pair(asset, f"foreground/{name}")
        generated.append((name, asset))

    terrain = trim(open_transparent("terrain-raw.png", force_cleanup=True), padding=0)
    save_pair(terrain, "foreground/terrain")
    generated.append(("terrain", terrain))

    planets = open_transparent("planets-atlas.png")
    planet_names = ["planet-challenge", "planet-explore", "planet-try", "planet-create"]
    for name, asset in zip(planet_names, split_grid(planets, 2, 2)):
        save_pair(asset, f"midground/{name}")
        generated.append((name, asset))

    accents = open_transparent("accents-atlas.png")
    accent_names = ["planet-ring", "galaxy", "mascot-star", "rocket", "clock", "heart"]
    for name, asset in zip(accent_names, split_grid(accents, 2, 3)):
        folder = "midground" if name in {"planet-ring", "galaxy", "mascot-star"} else "ui"
        save_pair(asset, f"{folder}/{name}")
        generated.append((name, asset))

    make_preview(generated)
    for name, asset in generated:
        print(f"Saved {name}: {asset.width}x{asset.height}, alpha={asset.getchannel('A').getextrema()}")


if __name__ == "__main__":
    main()
