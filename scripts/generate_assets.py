from __future__ import annotations

from pathlib import Path
from typing import Final

from PIL import Image, ImageDraw, ImageFont


ROOT: Final = Path(__file__).resolve().parents[1]
SOURCES: Final = ROOT / "source-images" / "originals"
OUTPUT: Final = ROOT / "assets" / "questions"
PREVIEWS: Final = ROOT / "source-images" / "previews" / "option-art"
SCENE_SIZE: Final = (1200, 720)
ART_SIZE: Final = (1000, 400)

QUESTIONS: Final = [
    {
        "id": "q01",
        "source": "01.第一關_登上學習飛船_問題圖示_750x1000.png",
        "scene": (0, 0, 1086, 607),
        "art": {
            "a": (90, 815, 520, 994),
            "b": (595, 800, 1025, 994),
            "c": (80, 1140, 520, 1285),
            "d": (610, 1110, 1015, 1285),
        },
    },
    {
        "id": "q02",
        "source": "02第二關_神秘星球_問題圖示_750x1000.png",
        "scene": (0, 0, 750, 401),
        "art": {
            "a": (35, 548, 360, 669),
            "b": (393, 548, 725, 669),
            "c": (35, 763, 360, 882),
            "d": (393, 763, 725, 882),
        },
    },
    {
        "id": "q03",
        "source": "03.第三關_遇到學習風暴_問題圖示_750x1000.png",
        "scene": (0, 0, 750, 472),
        "art": {
            "a": (35, 603, 365, 706),
            "b": (394, 604, 725, 706),
            "c": (35, 806, 365, 908),
            "d": (394, 806, 725, 908),
        },
    },
    {
        "id": "q04",
        "source": "04第四關_四顆神秘星球_750x1000_2.15MB_正式版.png",
        "scene": (0, 0, 750, 436),
        "art": {
            "a": (52, 600, 360, 731),
            "b": (397, 598, 712, 731),
            "c": (52, 800, 360, 927),
            "d": (397, 800, 712, 927),
        },
    },
    {
        "id": "q05",
        "source": "05.第五關_星際圖書館_問題圖示_750x1000.png",
        "scene": (0, 0, 1086, 654),
        "art": {
            "a": (75, 885, 520, 1058),
            "b": (580, 885, 1025, 1058),
            "c": (75, 1180, 520, 1328),
            "d": (580, 1180, 1025, 1328),
        },
    },
    {
        "id": "q06",
        "source": "06.第六關_找到孩子的學習星_問題圖示_750x1000.png",
        "scene": (0, 0, 750, 470),
        "art": {
            "a": (45, 660, 365, 741),
            "b": (390, 660, 712, 741),
            "c": (45, 845, 365, 927),
            "d": (390, 845, 712, 927),
        },
    },
]


def cover(source: Image.Image, size: tuple[int, int]) -> Image.Image:
    target_ratio = size[0] / size[1]
    source_ratio = source.width / source.height
    if source_ratio > target_ratio:
        crop_width = round(source.height * target_ratio)
        left = (source.width - crop_width) // 2
        source = source.crop((left, 0, left + crop_width, source.height))
    elif source_ratio < target_ratio:
        crop_height = round(source.width / target_ratio)
        top = (source.height - crop_height) // 2
        source = source.crop((0, top, source.width, top + crop_height))
    return source.resize(size, Image.Resampling.LANCZOS)


def contain(source: Image.Image, size: tuple[int, int], color: tuple[int, int, int]) -> Image.Image:
    canvas = Image.new("RGB", size, color)
    scale = min(size[0] / source.width, size[1] / source.height)
    resized = source.resize((round(source.width * scale), round(source.height * scale)), Image.Resampling.LANCZOS)
    canvas.paste(resized, ((size[0] - resized.width) // 2, (size[1] - resized.height) // 2))
    return canvas


def save(image: Image.Image, base: Path) -> None:
    image.save(base.with_suffix(".png"), optimize=True)
    image.save(base.with_suffix(".webp"), "WEBP", quality=92, method=6)


def make_preview(question_id: str, scene: Image.Image, arts: dict[str, Image.Image]) -> None:
    preview = Image.new("RGB", (1200, 1120), (2, 11, 35))
    preview.paste(scene.resize((1000, 600), Image.Resampling.LANCZOS), (100, 60))
    positions = {"a": (100, 700), "b": (610, 700), "c": (100, 905), "d": (610, 905)}
    for letter, position in positions.items():
        preview.paste(arts[letter].resize((490, 196), Image.Resampling.LANCZOS), position)
    draw = ImageDraw.Draw(preview)
    draw.text((28, 18), question_id.upper(), fill=(255, 210, 55), font=ImageFont.load_default(size=28))
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    preview.save(PREVIEWS / f"{question_id}-art.jpg", quality=91, optimize=True)


def main() -> None:
    for question in QUESTIONS:
        with Image.open(SOURCES / question["source"]) as loaded:
            source = loaded.convert("RGB")
        folder = OUTPUT / question["id"]
        folder.mkdir(parents=True, exist_ok=True)
        scene = contain(source.crop(question["scene"]), SCENE_SIZE, (2, 10, 31))
        arts: dict[str, Image.Image] = {}
        for letter, box in question["art"].items():
            arts[letter] = cover(source.crop(box), ART_SIZE)
            save(arts[letter], folder / f"option-{letter}-art")
        make_preview(question["id"], scene, arts)
        print(f"Generated {question['id']}")


if __name__ == "__main__":
    main()
