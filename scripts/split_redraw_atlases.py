from __future__ import annotations

from collections import deque
from pathlib import Path
import sys
from typing import Final

import numpy as np
from PIL import Image, ImageFilter


ROOT: Final = Path(__file__).resolve().parents[1]
MASTERS: Final = ROOT / "source-images" / "redraw-workbench" / "masters"
PREVIEWS: Final = ROOT / "source-images" / "redraw-workbench" / "previews"
OUTPUT: Final = ROOT / "assets" / "scenes"

COMPONENTS: Final = {
    "q01": [
        "character-child", "character-robot", "environment-cockpit",
        "story-controls", "celestial-planet-purple", "celestial-planet-blue-moon",
    ],
    "q02": [
        "character-child", "environment-ground", "environment-lander",
        "story-mystery-box", "celestial-planet-blue", "celestial-galaxy-moon",
    ],
    "q03": [
        "character-child", "environment-cockpit", "story-warning-display",
        "story-main-asteroid", "celestial-storm-vortex", "celestial-asteroid-group",
    ],
    "q04": [
        "character-child", "environment-cockpit", "story-planet-volcano",
        "story-planet-discovery", "story-planet-adventure", "story-planet-create",
    ],
    "q05": [
        "character-child", "environment-library", "story-book-challenge",
        "story-book-exploration", "story-book-experiment", "story-book-creative",
    ],
    "q06": [
        "character-child", "environment-cockpit-map", "story-star-task",
        "story-star-puzzle", "story-star-growth", "story-star-creative",
    ],
}

ENCLOSED_BACKGROUND_SEEDS: Final = {
    "q01": [(0.29, 0.56)],
    "q03": [(0.75, 1 / 6)],
    "q04": [(0.75, 1 / 6)],
    "q06": [(0.75, 1 / 6)],
}

GRID: Final = {
    "q01": {"column": 590 / 1024, "rows": [0, 680 / 1536, 1120 / 1536, 1]},
    "q02": {"column": 0.5, "rows": [0, 445 / 1278, 835 / 1278, 1]},
    "q03": {"column": 0.5, "rows": [0, 465 / 1254, 835 / 1254, 1]},
    "q04": {"column": 0.5, "rows": [0, 545 / 1536, 1010 / 1536, 1]},
    "q05": {"column": 0.5, "rows": [0, 505 / 1254, 845 / 1254, 1]},
    "q06": {"column": 0.5, "rows": [0, 535 / 1536, 1000 / 1536, 1]},
}

KEEP_COMPONENTS: Final = {
    ("q01", "character-robot"): 3,
    ("q01", "celestial-planet-blue-moon"): 2,
    ("q02", "celestial-galaxy-moon"): 2,
    ("q03", "celestial-storm-vortex"): 5,
    ("q03", "celestial-asteroid-group"): 3,
}


def connected_background(candidate: np.ndarray, seeds: list[tuple[int, int]]) -> np.ndarray:
    height, width = candidate.shape
    visited = np.zeros_like(candidate, dtype=bool)
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        if candidate[0, x]: queue.append((0, x))
        if candidate[height - 1, x]: queue.append((height - 1, x))
    for y in range(height):
        if candidate[y, 0]: queue.append((y, 0))
        if candidate[y, width - 1]: queue.append((y, width - 1))
    for x, y in seeds:
        if 0 <= x < width and 0 <= y < height and candidate[y, x]:
            queue.append((y, x))

    while queue:
        y, x = queue.popleft()
        if visited[y, x] or not candidate[y, x]:
            continue
        visited[y, x] = True
        if y: queue.append((y - 1, x))
        if y + 1 < height: queue.append((y + 1, x))
        if x: queue.append((y, x - 1))
        if x + 1 < width: queue.append((y, x + 1))
    return visited


def ensure_transparency(question_id: str, image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = np.asarray(rgba.getchannel("A"))
    if alpha.min() < 240:
        return rgba

    rgb = np.asarray(rgba.convert("RGB"), dtype=np.int16)
    channel_range = rgb.max(axis=2) - rgb.min(axis=2)
    brightness = rgb.mean(axis=2)
    candidate = (channel_range <= 13) & (brightness >= 214)
    height, width = candidate.shape
    seeds = [
        (round(x_ratio * (width - 1)), round(y_ratio * (height - 1)))
        for x_ratio, y_ratio in ENCLOSED_BACKGROUND_SEEDS.get(question_id, [])
    ]
    background = connected_background(candidate, seeds)
    alpha_image = Image.fromarray(np.where(background, 0, 255).astype(np.uint8), "L")
    alpha_image = alpha_image.filter(ImageFilter.GaussianBlur(0.65))
    rgba.putalpha(alpha_image)
    return rgba


def trim_with_padding(image: Image.Image, padding: int = 18) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.point(lambda value: 255 if value > 8 else 0).getbbox()
    if not bbox:
        return image
    left, top, right, bottom = bbox
    left, top = max(0, left - padding), max(0, top - padding)
    right, bottom = min(image.width, right + padding), min(image.height, bottom + padding)
    return image.crop((left, top, right, bottom))


def keep_largest_alpha_components(image: Image.Image, count: int) -> Image.Image:
    alpha = np.asarray(image.getchannel("A"))
    solid = alpha > 12
    height, width = solid.shape
    visited = np.zeros_like(solid, dtype=bool)
    groups: list[list[tuple[int, int]]] = []
    for y in range(height):
        for x in range(width):
            if visited[y, x] or not solid[y, x]:
                continue
            group: list[tuple[int, int]] = []
            queue: deque[tuple[int, int]] = deque([(y, x)])
            visited[y, x] = True
            while queue:
                current_y, current_x = queue.popleft()
                group.append((current_y, current_x))
                for next_y, next_x in ((current_y - 1, current_x), (current_y + 1, current_x), (current_y, current_x - 1), (current_y, current_x + 1)):
                    if 0 <= next_y < height and 0 <= next_x < width and solid[next_y, next_x] and not visited[next_y, next_x]:
                        visited[next_y, next_x] = True
                        queue.append((next_y, next_x))
            groups.append(group)
    selected = sorted(groups, key=len, reverse=True)[:count]
    keep = np.zeros_like(solid, dtype=bool)
    for group in selected:
        ys, xs = zip(*group)
        keep[np.asarray(ys), np.asarray(xs)] = True
    softened = Image.fromarray(np.where(keep, alpha, 0).astype(np.uint8), "L").filter(ImageFilter.MaxFilter(3))
    cleaned = image.copy()
    cleaned.putalpha(softened)
    return cleaned


def save_component(image: Image.Image, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target.with_suffix(".png"), optimize=True)
    image.save(target.with_suffix(".webp"), "WEBP", quality=92, method=6)


def make_preview(question_id: str, sprites: list[tuple[str, Image.Image]]) -> None:
    canvas = Image.new("RGBA", (1200, 900), (2, 10, 31, 255))
    positions = [(40, 35), (620, 35), (40, 325), (620, 325), (40, 615), (620, 615)]
    for (_, sprite), (x, y) in zip(sprites, positions):
        scale = min(520 / sprite.width, 240 / sprite.height, 1.0)
        size = (max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale)))
        resized = sprite.resize(size, Image.Resampling.LANCZOS)
        canvas.alpha_composite(resized, (x + (520 - size[0]) // 2, y + (240 - size[1]) // 2))
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(PREVIEWS / f"{question_id}-components.jpg", quality=91, optimize=True)


def main() -> None:
    requested = set(sys.argv[1:])
    selected_questions = COMPONENTS.items() if not requested else ((key, value) for key, value in COMPONENTS.items() if key in requested)
    for question_id, names in selected_questions:
        atlas_path = MASTERS / question_id / "atlas.png"
        with Image.open(atlas_path) as loaded:
            atlas = ensure_transparency(question_id, loaded)
        grid = GRID[question_id]
        column_edge = round(atlas.width * grid["column"])
        row_edges = [round(atlas.height * ratio) for ratio in grid["rows"]]
        sprites: list[tuple[str, Image.Image]] = []
        for index, name in enumerate(names):
            column, row = index % 2, index // 2
            left, right = (0, column_edge) if column == 0 else (column_edge, atlas.width)
            box = (left, row_edges[row], right, row_edges[row + 1])
            sprite = atlas.crop(box)
            sprite = keep_largest_alpha_components(sprite, KEEP_COMPONENTS.get((question_id, name), 1))
            sprite = trim_with_padding(sprite)
            save_component(sprite, OUTPUT / question_id / "components" / name)
            sprites.append((name, sprite))
        make_preview(question_id, sprites)
        print(f"Split {question_id}: {len(sprites)} components")


if __name__ == "__main__":
    main()
