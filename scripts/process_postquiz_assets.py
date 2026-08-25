from __future__ import annotations

from collections import deque
from pathlib import Path
from typing import Final

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


ROOT: Final = Path(__file__).resolve().parents[1]
MASTERS: Final = ROOT / "source-images" / "redraw-workbench" / "masters" / "postquiz"
PREVIEW: Final = ROOT / "source-images" / "redraw-workbench" / "previews" / "postquiz-assets.jpg"


def remove_baked_checkerboard(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = np.asarray(rgba.getchannel("A"))
    if alpha.min() < 240:
        return rgba
    rgb = np.asarray(rgba.convert("RGB"), dtype=np.int16)
    candidate = ((rgb.max(axis=2) - rgb.min(axis=2)) < 18) & (rgb.mean(axis=2) > 205)
    height, width = candidate.shape
    visited = np.zeros_like(candidate, dtype=bool)
    queue: deque[tuple[int, int]] = deque()
    for x in range(width):
        if candidate[0, x]: queue.append((0, x))
        if candidate[height - 1, x]: queue.append((height - 1, x))
    for y in range(height):
        if candidate[y, 0]: queue.append((y, 0))
        if candidate[y, width - 1]: queue.append((y, width - 1))
    while queue:
        y, x = queue.popleft()
        if visited[y, x] or not candidate[y, x]:
            continue
        visited[y, x] = True
        for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
            if 0 <= ny < height and 0 <= nx < width:
                queue.append((ny, nx))
    rgba.putalpha(Image.fromarray(np.where(visited, 0, 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(.6)))
    return rgba


def keep_largest_component(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    solid = np.asarray(rgba.getchannel("A")) > 12
    height, width = solid.shape
    visited = np.zeros_like(solid, dtype=bool)
    groups: list[list[tuple[int, int]]] = []
    for y in range(height):
        for x in range(width):
            if visited[y, x] or not solid[y, x]:
                continue
            group, queue = [], deque([(y, x)])
            visited[y, x] = True
            while queue:
                cy, cx = queue.popleft(); group.append((cy, cx))
                for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
                    if 0 <= ny < height and 0 <= nx < width and solid[ny, nx] and not visited[ny, nx]:
                        visited[ny, nx] = True; queue.append((ny, nx))
            groups.append(group)
    keep = np.zeros_like(solid)
    if groups:
        ys, xs = zip(*max(groups, key=len)); keep[np.asarray(ys), np.asarray(xs)] = True
    original_alpha = np.asarray(rgba.getchannel("A"))
    rgba.putalpha(Image.fromarray(np.where(keep, original_alpha, 0).astype(np.uint8), "L"))
    return rgba


def trim(image: Image.Image, padding: int = 16) -> Image.Image:
    rgba = image.convert("RGBA")
    bbox = rgba.getchannel("A").point(lambda value: 255 if value > 8 else 0).getbbox()
    if not bbox:
        raise ValueError("Generated asset contains no visible alpha pixels")
    left, top, right, bottom = bbox
    return rgba.crop((max(0, left - padding), max(0, top - padding), min(rgba.width, right + padding), min(rgba.height, bottom + padding)))


def save(image: Image.Image, target: Path) -> Image.Image:
    image = trim(image)
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target.with_suffix(".png"), optimize=True)
    image.save(target.with_suffix(".webp"), "WEBP", quality=92, method=6)
    return image


def crop_grid(image: Image.Image, columns: int, rows: int, names: list[tuple[Path, str]], clean_components: bool = False) -> list[tuple[str, Image.Image]]:
    output: list[tuple[str, Image.Image]] = []
    for index, (folder, name) in enumerate(names):
        column, row = index % columns, index // columns
        box = (
            round(image.width * column / columns), round(image.height * row / rows),
            round(image.width * (column + 1) / columns), round(image.height * (row + 1) / rows),
        )
        sprite = image.crop(box)
        if clean_components:
            sprite = keep_largest_component(sprite)
        sprite = save(sprite, ROOT / "assets" / folder / name)
        output.append((name, sprite))
    return output


def main() -> None:
    sprites: list[tuple[str, Image.Image]] = []
    with Image.open(MASTERS / "result-foreground.png") as source:
        sprites.append(("result foreground", save(remove_baked_checkerboard(source), ROOT / "assets" / "result" / "foreground")))
    with Image.open(MASTERS / "finish-foreground.png") as source:
        sprites.append(("finish foreground", save(source, ROOT / "assets" / "finish" / "foreground")))
    with Image.open(MASTERS / "result-icons-atlas.png") as source:
        sprites += crop_grid(source.convert("RGBA"), 3, 2, [
            (Path("result/icons"), "target"), (Path("result/icons"), "explore"), (Path("result/icons"), "growth"),
            (Path("result/traits"), "flag"), (Path("result/traits"), "trophy"), (Path("result/traits"), "rocket"),
        ])
    with Image.open(MASTERS / "contact-atlas.png") as source:
        sprites += crop_grid(source.convert("RGBA"), 2, 2, [
            (Path("contact"), "robot-reading"), (Path("contact"), "robot-waving"),
            (Path("contact"), "gift"), (Path("contact"), "learning-book"),
        ], clean_components=True)

    canvas = Image.new("RGB", (1280, 960), "#071a46")
    draw = ImageDraw.Draw(canvas)
    for index, (name, sprite) in enumerate(sprites):
        col, row = index % 4, index // 4
        scale = min(260 / sprite.width, 230 / sprite.height, 1)
        thumb = sprite.resize((round(sprite.width * scale), round(sprite.height * scale)), Image.Resampling.LANCZOS)
        x, y = col * 320 + (320 - thumb.width) // 2, row * 300 + 36
        canvas.paste(thumb, (x, y), thumb)
        draw.text((col * 320 + 12, row * 300 + 10), name, fill="white")
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(PREVIEW, quality=92)
    print(f"Processed {len(sprites)} post-quiz assets")


if __name__ == "__main__":
    main()
