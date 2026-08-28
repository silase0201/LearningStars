from __future__ import annotations

import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "score.csv"
OUTPUT = ROOT / "js" / "question-data.js"
COLORS = {"A": "#bd2026", "B": "#16833e", "C": "#1769ba", "D": "#6339a7"}


def split_once(value: str) -> tuple[str, str]:
    head, separator, tail = value.partition("｜")
    return head.strip(), tail.strip() if separator else ""


def load_rows() -> list[dict[str, str]]:
    lines = SOURCE.read_text(encoding="utf-8-sig").splitlines()
    header_index = next(index for index, line in enumerate(lines) if line.startswith("answer_key,"))
    return list(csv.DictReader(lines[header_index:]))


def build_questions(rows: list[dict[str, str]]) -> list[dict[str, object]]:
    questions: list[dict[str, object]] = []
    for number in range(1, 7):
        key = f"Q{number}"
        group = [row for row in rows if row["題號"] == key]
        if [row["選項"] for row in group] != list("ABCD"):
            raise ValueError(f"{key} must contain exactly A, B, C, D in order")

        _, scene_title = split_once(group[0]["關卡名稱"])
        options = []
        for row in group:
            title, subtitle = split_once(row["答案文字"])
            letter = row["選項"]
            options.append(
                {
                    "letter": letter,
                    "title": title,
                    "subtitle": subtitle,
                    "color": COLORS[letter],
                }
            )

        questions.append(
            {
                "id": f"q{number:02d}",
                "sceneTitle": scene_title,
                "sceneDescription": group[0]["場景"].strip(),
                "question": group[0]["題目"].strip(),
                "options": options,
            }
        )

    return questions


def main() -> None:
    questions = build_questions(load_rows())
    payload = json.dumps(questions, ensure_ascii=False, indent=2)
    OUTPUT.write_text(
        '"use strict";\n\nwindow.LearningStarsQuestions = ' + payload + ";\n",
        encoding="utf-8",
        newline="\n",
    )
    print(f"generated {len(questions)} questions and {sum(len(q['options']) for q in questions)} options")


if __name__ == "__main__":
    main()
