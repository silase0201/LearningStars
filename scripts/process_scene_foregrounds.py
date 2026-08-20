from __future__ import annotations

from pathlib import Path

from PIL import Image

from split_redraw_atlases import ensure_transparency, keep_largest_alpha_components


ROOT = Path(__file__).resolve().parents[1]
MASTERS = ROOT / "source-images" / "redraw-workbench" / "masters"
SCENES = ROOT / "assets" / "scenes"
BACKGROUNDS = ROOT / "assets" / "backgrounds"
CANVAS_SIZE = (1400, 1120)
OUTPUT_WIDTH = 1400


def fit_transparent_canvas(image: Image.Image) -> Image.Image:
    foreground = image.convert("RGBA")
    scale = min(CANVAS_SIZE[0] / foreground.width, CANVAS_SIZE[1] / foreground.height)
    size = (
        max(1, round(foreground.width * scale)),
        max(1, round(foreground.height * scale)),
    )
    resized = foreground.resize(size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    canvas.alpha_composite(
        resized,
        ((CANVAS_SIZE[0] - size[0]) // 2, (CANVAS_SIZE[1] - size[1]) // 2),
    )
    return canvas


def trim_to_output_width(image: Image.Image, padding: int = 0) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.point(lambda value: 255 if value > 8 else 0).getbbox()
    if not bbox:
        raise RuntimeError("Foreground extraction produced an empty alpha channel")
    left, top, right, bottom = bbox
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(image.width, right + padding)
    bottom = min(image.height, bottom + padding)
    trimmed = image.crop((left, top, right, bottom))
    if trimmed.width == OUTPUT_WIDTH:
        return trimmed
    height = max(1, round(trimmed.height * OUTPUT_WIDTH / trimmed.width))
    return trimmed.resize((OUTPUT_WIDTH, height), Image.Resampling.LANCZOS)


def save_pair(image: Image.Image, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target.with_suffix(".png"), optimize=True)
    image.save(target.with_suffix(".webp"), "WEBP", quality=92, method=6)


def main() -> None:
    shared_source = MASTERS / "shared" / "scene-space-static-raw.png"
    with Image.open(shared_source) as loaded:
        shared = loaded.convert("RGB")
    save_pair(shared, BACKGROUNDS / "scene-space-static")
    print(f"Saved shared background: {shared.width}x{shared.height}")

    for index in range(1, 7):
        question_id = f"q{index:02d}"
        source_name = "foreground-mobile-cropped.png" if question_id == "q01" else "foreground-layer-raw.png"
        source = MASTERS / question_id / source_name
        with Image.open(source) as loaded:
            # Generated layer edits may contain a nearly opaque alpha channel while
            # still baking a checkerboard into RGB. Force background detection for
            # q02-q06; q01 already has its approved genuine alpha.
            source_image = loaded if question_id == "q01" else loaded.convert("RGB")
            transparent = ensure_transparency(question_id, source_image)
        foreground = transparent if question_id == "q01" else trim_to_output_width(
            keep_largest_alpha_components(transparent, 1)
        )
        save_pair(foreground, SCENES / question_id / "foreground")
        alpha = foreground.getchannel("A")
        print(
            f"Saved {question_id}: {foreground.width}x{foreground.height}, "
            f"alpha={alpha.getextrema()}"
        )


if __name__ == "__main__":
    main()
