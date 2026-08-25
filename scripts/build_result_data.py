from __future__ import annotations

import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "source-images" / "originals" / "3.result" / "result.csv"
TARGET = ROOT / "js" / "result-data.js"
FIELDS = ["Result_ID", "result_name", "result_subtitle", "result_intro", "trait_1", "trait_2", "trait_3", "result_type", "UI顯示備註", "sub_title", "core_sentence", "full_description", "life_signs_4", "life_example", "parent_sentence"]


def main() -> None:
    with SOURCE.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames != FIELDS:
            raise ValueError(f"Unexpected result.csv fields: {reader.fieldnames}")
        rows = list(reader)
    if [row["Result_ID"] for row in rows] != [f"R0{i}" for i in range(1, 8)]:
        raise ValueError("result.csv must contain R01 through R07 in order")
    if any(not row[field].strip() for row in rows for field in FIELDS):
        raise ValueError("result.csv contains an empty required field")

    data = {}
    for row in rows:
        life_signs = [item.strip() for item in row["life_signs_4"].split("｜")]
        if len(life_signs) != 4:
            raise ValueError(f'{row["Result_ID"]} must contain four life signs')
        data[row["Result_ID"]] = {
            "id": row["Result_ID"], "name": row["result_name"], "subtitle": row["result_subtitle"],
            "intro": row["result_intro"], "traits": [row[f"trait_{index}"] for index in range(1, 4)],
            "type": row["result_type"], "uiNote": row["UI顯示備註"],
            "detail": {"subtitle": row["sub_title"], "coreSentence": row["core_sentence"],
                "fullDescription": row["full_description"], "lifeSigns": life_signs,
                "lifeExample": row["life_example"], "parentSentence": row["parent_sentence"]},
        }
    payload = json.dumps(data, ensure_ascii=False, indent=2)
    TARGET.write_text('"use strict";\nwindow.LearningStarsResults = ' + payload + ';\n', encoding="utf-8", newline="\n")
    print(f"Built {TARGET.relative_to(ROOT)} with {len(data)} results")


if __name__ == "__main__":
    main()
