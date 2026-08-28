from __future__ import annotations

import csv
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "score2.csv"
OUTPUT = ROOT / "js" / "question-data.js"
COLORS = {"A": "#bd2026", "B": "#16833e", "C": "#1769ba", "D": "#6339a7"}


def normalize(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


def split_option(value: str) -> tuple[str, str]:
    normalized = normalize(value)
    head, separator, tail = normalized.partition(" ")
    return head, tail if separator else ""


def split_question(value: str) -> tuple[str, str]:
    normalized = normalize(value)
    boundary = normalized.rfind("。")
    if boundary == -1 or boundary == len(normalized) - 1:
        return "", normalized
    return normalized[: boundary + 1], normalized[boundary + 1 :].strip()


def load_rows() -> list[dict[str, str]]:
    lines = SOURCE.read_text(encoding="utf-8-sig").splitlines()
    header_index = next(
        index for index, line in enumerate(lines) if "answer_key,題號,題目,選項,答案文字" in line
    )
    return list(csv.DictReader(lines[header_index:]))


def build_questions(rows: list[dict[str, str]]) -> list[dict[str, object]]:
    questions: list[dict[str, object]] = []
    for number in range(1, 7):
        key = f"Q{number}"
        group = [row for row in rows if row["題號"] == key]
        if [row["選項"] for row in group] != list("ABCD"):
            raise ValueError(f"{key} must contain exactly A, B, C, D in order")

        scene_title = normalize(group[0][""])
        scene_description, question = split_question(group[0]["題目"])
        options = []
        for row in group:
            title, subtitle = split_option(row["答案文字"])
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
                "sceneDescription": scene_description,
                "question": question,
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
