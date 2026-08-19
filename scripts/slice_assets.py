from __future__ import annotations

from pathlib import Path
from typing import Final

from PIL import Image, ImageDraw, ImageFont


ROOT: Final = Path(__file__).resolve().parents[1]
OUTPUT_ROOT: Final = ROOT / "assets" / "questions"
PREVIEW_ROOT: Final = ROOT / "assets" / "previews"

SIZES: Final = {
    "scene": (1200, 720),
    "prompt": (1200, 200),
    "option": (720, 400),
}

# Crop rectangles are expressed in source-image pixels: left, top, right, bottom.
QUESTIONS: Final = [
    {
        "id": "q01",
        "source": "01.第一關_登上學習飛船_問題圖示_750x1000.png",
        "scene": (0, 0, 1086, 607),
        "prompt": (132, 599, 966, 731),
        "options": {
            "a": (54, 739, 532, 1047),
            "b": (545, 739, 1033, 1047),
            "c": (54, 1055, 532, 1349),
            "d": (545, 1055, 1033, 1349),
        },
    },
    {
        "id": "q02",
        "source": "02第二關_神秘星球_問題圖示_750x1000.png",
        "scene": (0, 0, 750, 401),
        "prompt": (111, 397, 638, 500),
        "options": {
            "a": (19, 503, 369, 708),
            "b": (378, 503, 731, 708),
            "c": (19, 716, 369, 923),
            "d": (378, 716, 731, 923),
        },
    },
    {
        "id": "q03",
        "source": "03.第三關_遇到學習風暴_問題圖示_750x1000.png",
        "scene": (0, 0, 750, 472),
        "prompt": (116, 467, 639, 552),
        "options": {
            "a": (19, 552, 370, 751),
            "b": (378, 552, 731, 751),
            "c": (19, 756, 370, 951),
            "d": (378, 756, 731, 951),
        },
    },
    {
        "id": "q04",
        "source": "04第四關_四顆神秘星球_750x1000_2.15MB_正式版.png",
        "scene": (0, 0, 750, 436),
        "prompt": (109, 428, 640, 524),
        "options": {
            "a": (32, 532, 368, 738),
            "b": (377, 532, 719, 738),
            "c": (32, 745, 368, 932),
            "d": (377, 745, 719, 932),
        },
    },
    {
        "id": "q05",
        "source": "05.第五關_星際圖書館_問題圖示_750x1000.png",
        "scene": (0, 0, 1086, 654),
        "prompt": (198, 645, 914, 783),
        "options": {
            "a": (51, 788, 529, 1065),
            "b": (545, 788, 1035, 1065),
            "c": (51, 1076, 529, 1337),
            "d": (545, 1076, 1035, 1337),
        },
    },
    {
        "id": "q06",
        "source": "06.第六關_找到孩子的學習星_問題圖示_750x1000.png",
        "scene": (0, 0, 750, 470),
        "prompt": (95, 462, 644, 558),
        "options": {
            "a": (33, 562, 370, 747),
            "b": (378, 562, 719, 747),
            "c": (33, 753, 370, 934),
            "d": (378, 753, 719, 934),
        },
    },
]


def fit_on_canvas(
    source: Image.Image,
    size: tuple[int, int],
    background: tuple[int, int, int],
    padding: int = 0,
) -> Image.Image:
    canvas = Image.new("RGB", size, background)
    available = (size[0] - padding * 2, size[1] - padding * 2)
    scale = min(available[0] / source.width, available[1] / source.height)
    resized_size = (
        max(1, round(source.width * scale)),
        max(1, round(source.height * scale)),
    )
    resized = source.resize(resized_size, Image.Resampling.LANCZOS)
    position = ((size[0] - resized.width) // 2, (size[1] - resized.height) // 2)
    canvas.paste(resized, position)
    return canvas


def save_asset(image: Image.Image, path_without_suffix: Path) -> None:
    image.save(path_without_suffix.with_suffix(".png"), optimize=True)
    image.save(path_without_suffix.with_suffix(".webp"), "WEBP", quality=91, method=6)


def create_preview(question_id: str, parts: dict[str, Image.Image]) -> None:
    preview = Image.new("RGB", (1200, 1420), (3, 11, 35))
    preview.paste(parts["scene"].resize((1000, 600), Image.Resampling.LANCZOS), (100, 60))
    preview.paste(parts["prompt"].resize((1000, 167), Image.Resampling.LANCZOS), (100, 680))
    positions = {
        "option-a": (100, 870),
        "option-b": (610, 870),
        "option-c": (100, 1145),
        "option-d": (610, 1145),
    }
    for name, position in positions.items():
        preview.paste(parts[name].resize((490, 272), Image.Resampling.LANCZOS), position)

    draw = ImageDraw.Draw(preview)
    font = ImageFont.load_default(size=28)
    draw.text((28, 18), question_id.upper(), fill=(255, 210, 55), font=font)
    PREVIEW_ROOT.mkdir(parents=True, exist_ok=True)
    preview.save(PREVIEW_ROOT / f"{question_id}-overview.jpg", quality=90, optimize=True)


def main() -> None:
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)

    for question in QUESTIONS:
        source_path = ROOT / question["source"]
        with Image.open(source_path) as loaded:
            source = loaded.convert("RGB")

        question_output = OUTPUT_ROOT / question["id"]
        question_output.mkdir(parents=True, exist_ok=True)

        scene_crop = source.crop(question["scene"])
        prompt_crop = source.crop(question["prompt"])
        parts: dict[str, Image.Image] = {
            "scene": fit_on_canvas(scene_crop, SIZES["scene"], (2, 10, 31)),
            "prompt": fit_on_canvas(prompt_crop, SIZES["prompt"], (4, 22, 57), 4),
        }

        for letter, crop_box in question["options"].items():
            option_crop = source.crop(crop_box)
            parts[f"option-{letter}"] = fit_on_canvas(
                option_crop,
                SIZES["option"],
                (246, 245, 242),
                8,
            )

        for name, image in parts.items():
            save_asset(image, question_output / name)

        create_preview(question["id"], parts)
        print(f"Generated {question['id']} from {question['source']}")


if __name__ == "__main__":
    main()
