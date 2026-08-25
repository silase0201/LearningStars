from __future__ import annotations

from pathlib import Path
from typing import Final

from PIL import Image, ImageDraw


ROOT: Final = Path(__file__).resolve().parents[1]
ASSETS: Final = ROOT / "assets" / "scenes"
EXTRACTED_COMPONENTS: Final = ROOT / "source-images" / "redraw-workbench" / "extracted-components"
STAR: Final = ROOT / "assets" / "backgrounds" / "stars-static.png"
OUTPUT: Final = ROOT / "source-images" / "redraw-workbench" / "previews" / "scenes"

SCENES: Final = {
    "q01": [("environment-cockpit",50,103,104,50),("character-child",72,93,29,45),("character-robot",88,64,19,44),("story-controls",49,101,30,55)],
    "q02": [("environment-ground",50,104,106,20),("environment-lander",83,96,35,25),("story-mystery-box",53,98,32,35),("character-child",16,100,26,45)],
    "q03": [("environment-cockpit",50,103,105,50),("story-warning-display",50,98,27,55),("story-main-asteroid",78,70,25,35),("character-child",19,89,25,45)],
    "q04": [("environment-cockpit",50,103,105,50),("character-child",18,88,25,45),("story-planet-volcano",34,66,17,35),("story-planet-discovery",51,66,17,35),("story-planet-adventure",68,66,17,35),("story-planet-create",85,66,17,35)],
    "q05": [("environment-library",82,80,39,25),("character-child",14,99,25,45),("story-book-challenge",37,96,16,38),("story-book-exploration",54,96,16,38),("story-book-experiment",71,96,16,38),("story-book-creative",88,96,16,38)],
    "q06": [("environment-cockpit-map",50,103,105,50),("character-child",22,86,25,45),("story-star-task",34,65,15,35),("story-star-puzzle",51,65,15,35),("story-star-growth",68,65,15,35),("story-star-creative",85,65,15,35)],
}

MOBILE: Final = {
    "q01": {"environment-cockpit":(50,104,116),"character-child":(76,91,35),"character-robot":(88,64,23),"story-controls":(49,101,36)},
    "q02": {"environment-ground":(50,104,120),"environment-lander":(82,94,42),"story-mystery-box":(55,98,39),"character-child":(16,100,32)},
    "q03": {"environment-cockpit":(50,104,117),"story-warning-display":(50,98,34),"story-main-asteroid":(82,68,29),"character-child":(18,88,31)},
    "q04": {"environment-cockpit":(50,104,117),"character-child":(18,87,31),"story-planet-volcano":(33,66,20),"story-planet-discovery":(50,66,20),"story-planet-adventure":(67,66,20),"story-planet-create":(84,66,20)},
    "q05": {"environment-library":(79,76,45),"character-child":(13,99,31),"story-book-challenge":(31,96,20),"story-book-exploration":(51,96,20),"story-book-experiment":(71,96,20),"story-book-creative":(90,96,20)},
    "q06": {"environment-cockpit-map":(50,104,117),"character-child":(21,84,31),"story-star-task":(33,65,18),"story-star-puzzle":(50,65,18),"story-star-growth":(67,65,18),"story-star-creative":(84,65,18)},
}


def background(size: tuple[int, int]) -> Image.Image:
    canvas = Image.new("RGBA", size, (2, 9, 29, 255))
    with Image.open(STAR) as loaded:
        tile = loaded.convert("RGBA")
    for y in range(0, size[1], tile.height):
        for x in range(0, size[0], tile.width):
            canvas.alpha_composite(tile, (x, y))
    return canvas


def component_path(question_id: str, name: str) -> Path:
    active = ASSETS / question_id / "components" / f"{name}.png"
    return active if active.exists() else EXTRACTED_COMPONENTS / question_id / f"{name}.png"


def compose(question_id: str, size: tuple[int, int]) -> Image.Image:
    canvas = background(size)
    for name, x, y, width, z in sorted(SCENES[question_id], key=lambda item: item[4]):
        if size[0] == size[1]:
            x, y, width = MOBILE[question_id][name]
        with Image.open(component_path(question_id, name)) as loaded:
            sprite = loaded.convert("RGBA")
        target_width = round(size[0] * width / 100)
        scale = target_width / sprite.width
        resized = sprite.resize((target_width, max(1, round(sprite.height * scale))), Image.Resampling.LANCZOS)
        left = round(size[0] * x / 100 - resized.width / 2)
        top = round(size[1] * y / 100 - resized.height)
        canvas.alpha_composite(resized, (left, top))
    draw = ImageDraw.Draw(canvas, "RGBA")
    panel_width = round(size[0] * (0.72 if size[0] > size[1] else 0.82))
    panel_height = round(size[1] * (0.31 if size[0] > size[1] else 0.34))
    left = (size[0] - panel_width) // 2
    top = round(size[1] * 0.04)
    draw.rounded_rectangle((left, top, left + panel_width, top + panel_height), radius=28, fill=(5, 19, 55, 225), outline=(143, 185, 255, 150), width=2)
    draw.text((left + 24, top + 20), f"{question_id.upper()} HTML COPY SAFE AREA", fill=(255, 226, 105, 255))
    return canvas


def make_contact(size: tuple[int, int], name: str) -> None:
    thumb_size = (600, round(600 * size[1] / size[0]))
    contact = Image.new("RGB", (thumb_size[0] * 3, thumb_size[1] * 2), (1, 5, 18))
    for index, question_id in enumerate(SCENES):
        preview = compose(question_id, size)
        OUTPUT.mkdir(parents=True, exist_ok=True)
        preview.convert("RGB").save(OUTPUT / f"{question_id}-{name}.jpg", quality=90, optimize=True)
        thumb = preview.resize(thumb_size, Image.Resampling.LANCZOS).convert("RGB")
        contact.paste(thumb, ((index % 3) * thumb_size[0], (index // 3) * thumb_size[1]))
    contact.save(OUTPUT / f"contact-{name}.jpg", quality=91, optimize=True)


def main() -> None:
    make_contact((1200, 720), "desktop")
    make_contact((900, 900), "mobile")
    print(f"Rendered previews to {OUTPUT}")


if __name__ == "__main__":
    main()
