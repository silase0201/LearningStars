from __future__ import annotations

import re
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    html = (ROOT / "index.html").read_text(encoding="utf-8")
    references = re.findall(r'(?:src|srcset)="([^"]+)"', html)
    missing = [reference for reference in references if not (ROOT / reference.split("?")[0]).exists()]
    if missing:
        raise FileNotFoundError(f"Missing HTML assets: {missing}")

    pngs = [
        *sorted((ROOT / "assets" / "result").rglob("*.png")),
        *sorted((ROOT / "assets" / "contact").rglob("*.png")),
        *sorted((ROOT / "assets" / "finish").rglob("*.png")),
    ]
    if len(pngs) != 12:
        raise ValueError(f"Expected 12 post-quiz PNGs, found {len(pngs)}")
    for path in pngs:
        with Image.open(path) as image:
            if image.mode != "RGBA" or image.getchannel("A").getextrema() != (0, 255):
                raise ValueError(f"{path.relative_to(ROOT)} is not a full-range RGBA cutout")
            print(f"{path.relative_to(ROOT)} {image.size} alpha=(0, 255)")
    print(f"Validated {len(references)} HTML asset references; none missing")


if __name__ == "__main__":
    main()
