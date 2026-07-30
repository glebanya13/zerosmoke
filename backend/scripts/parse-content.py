#!/usr/bin/env python3
"""Normalize the supplied Antismoke DOCX/PDF files into validated JSON."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

from docx import Document
from pypdf import PdfReader


AGE_FILES = {
    "AGE_6": {
        "sections": "8+ все разделы (15).docx",
        "tests": "8 + ТЕСТЫ ПО ВОПРОСУ С РАЗДЕЛА.docx",
        "expected_sections": 15,
        "expected_tests": 15,
    },
    "AGE_16": {
        "sections": "12 +.docx",
        "tests": "16+ тесты (20 ШТУК).docx",
        "expected_sections": 15,
        "expected_tests": 20,
    },
    "AGE_18": {
        "sections": "18 +.docx",
        "tests": "18+ 20 тестов.docx",
        "expected_sections": 10,
        "expected_tests": 20,
    },
}

# The legacy 8+ test file uses a different numbering order than its section bank.
AGE_6_TEST_SECTION_MAP = {
    1: 1,
    2: 2,
    3: 3,
    4: 6,
    5: 7,
    6: 8,
    7: 9,
    8: 13,
    9: 15,
    10: 14,
    11: 11,
    12: 12,
    13: 13,
    14: 14,
    15: 15,
}


def normalize(value: str) -> str:
    return " ".join(value.replace("\xa0", " ").split()).strip()


def paragraphs(path: Path) -> list[str]:
    return [
        value
        for paragraph in Document(path).paragraphs
        if (value := normalize(paragraph.text))
    ]


def split_numeric_answer(value: str) -> list[str]:
    match = re.search(r"(?i)(?=(?:Правильный\s+)?Ответ\s*:\s*\d+)", value)
    if not match or match.start() == 0:
        return [value]
    return [value[: match.start()].strip(), value[match.start() :].strip()]


def clean_option(value: str) -> str:
    return re.sub(r"^\s*\d+\s*[.)]\s*", "", value).strip()


def clean_prompt(value: str) -> str:
    value = re.sub(r"(?i)^Вопрос\s*:\s*", "", value)
    value = re.sub(
        r"(?i)^Вопрос\s*№\s*\d+(?:\s*\([^)]*\))?\s*[:.)-]?\s*",
        "",
        value,
    )
    value = re.sub(r"^№\s*\d+\s*[.)-]?\s*", "", value)
    value = re.sub(r"(?i)\s*Варианты ответов\s*:\s*$", "", value)
    return value.strip()


def clean_material(values: list[str]) -> str | None:
    value = " ".join(values)
    value = re.sub(
        r"(?i)^Вопрос\s*№\s*\d+(?:\s*\([^)]*\))?\s*", "", value
    )
    value = re.sub(r"(?i)^№\s*\d+\s*\([^)]*\)\s*", "", value)
    value = re.sub(
        r"(?i)^Материал перед вопросом\s*№?\s*\d+\s*\([^)]*\)\s*",
        "",
        value,
    )
    value = re.sub(r"(?i)^Материал\s*:\s*", "", value)
    value = re.sub(r"^\d+\.\s*", "", value)
    value = value.strip()
    return value or None


def answer_index(raw_answer: str, options: list[str]) -> int:
    raw_answer = raw_answer.strip().rstrip(".")
    if raw_answer.isdigit():
        return int(raw_answer)

    def key(value: str) -> str:
        return re.sub(r"[^а-яa-z0-9]+", "", value.lower().replace("ё", "е"))

    matches = [
        index + 1
        for index, option in enumerate(options)
        if key(raw_answer) == key(option)
        or key(raw_answer) in key(option)
        or key(option) in key(raw_answer)
    ]
    if len(matches) != 1:
        raise ValueError(f"Cannot match answer {raw_answer!r} to {options!r}")
    return matches[0]


def parse_question_group(group: list[str]) -> dict:
    answer_match = re.search(
        r"(?i)(?:Правильный\s+)?Ответ\s*:\s*(.+)$", group[-1]
    )
    if not answer_match or len(group) < 6:
        raise ValueError(f"Invalid question group: {group!r}")

    body = group[:-1]
    options = [clean_option(value) for value in body[-4:]]
    prefix = [
        value
        for value in body[:-4]
        if not re.fullmatch(
            r"(?i)Вопрос\s*№\s*\d+(?:\s*\([^)]*\))?\s*[.:]?\s*", value
        )
    ]
    if not prefix:
        raise ValueError(f"Question text is missing: {group!r}")

    # In the source files the final pre-option paragraph is usually the prompt.
    # Some legacy paragraphs glue "Материал:" and the prompt together.
    prompt_index = len(prefix) - 1
    candidate = clean_material([prefix[prompt_index]]) or ""
    question_starts = list(
        re.finditer(
            r"(?<![а-яА-ЯёЁ])(?:Что|Почему|Как|Какие|Какой|Каково|Чем|Кто|Где|Когда|Можно ли|Верно ли|Действительно ли|Правда ли|Является ли|Существует ли|Способно ли|Может ли|Стоит ли|Насколько|От чего|Для чего|С какой|В чем|В чём|Чье|Чьё)\b",
            candidate,
        )
    )
    sentence_starts = list(re.finditer(r"(?<=[.!])(?=[А-ЯЁ])", candidate))
    if (
        "Материал" in prefix[prompt_index]
        and candidate.endswith("?")
        and (sentence_starts or question_starts)
    ):
        split_at = (
            sentence_starts[-1].start()
            if sentence_starts
            else question_starts[-1].start()
        )
        prompt = candidate[split_at:].strip()
        material_parts = prefix[:prompt_index] + [candidate[:split_at].strip()]
        material = clean_material(material_parts)
    else:
        prompt = clean_prompt(prefix[prompt_index])
        material = clean_material(prefix[:prompt_index] + prefix[prompt_index + 1 :])
    correct = answer_index(answer_match.group(1), options)
    if not prompt or len(options) != 4 or not 1 <= correct <= 4:
        raise ValueError(f"Incomplete question: {group!r}")
    return {
        "material": material,
        "text": prompt,
        "options": options,
        "correctOption": correct,
    }


def section_title(heading: str) -> str:
    value = re.sub(r"(?i)^Раздел\s*№\s*\d+\s*[.:]?\s*", "", heading)
    return value.strip(" «»\"")


def parse_sections(path: Path, audience: str) -> list[dict]:
    values = paragraphs(path)
    starts = [
        index
        for index, value in enumerate(values)
        if re.match(r"(?i)^Раздел\s*№\s*\d+", value)
    ]
    sections = []
    for section_index, start in enumerate(starts):
        end = starts[section_index + 1] if section_index + 1 < len(starts) else len(values)
        tokens = []
        for value in values[start + 1 : end]:
            tokens.extend(split_numeric_answer(value))

        questions = []
        group = []
        for token in tokens:
            group.append(token)
            if re.match(r"(?i)^(?:Правильный\s+)?Ответ\s*:\s*\d+", token):
                question = parse_question_group(group)
                question["position"] = len(questions) + 1
                questions.append(question)
                group = []
        if group:
            raise ValueError(f"Unparsed content in {path.name}, section {section_index + 1}")
        sections.append(
            {
                "audience": audience,
                "position": section_index + 1,
                "title": section_title(values[start]),
                "sourceFile": path.name,
                "questions": questions,
            }
        )
    return sections


def parse_age_6_tests(path: Path) -> list[dict]:
    values = paragraphs(path)
    test_starts = [
        index
        for index, value in enumerate(values)
        if re.match(r"(?i)^ТЕСТ\s*№\s*\d+", value)
    ]
    tests = []
    for test_index, start in enumerate(test_starts):
        end = (
            test_starts[test_index + 1]
            if test_index + 1 < len(test_starts)
            else len(values)
        )
        body = values[start + 1 : end]
        section_starts = [
            index
            for index, value in enumerate(body)
            if re.match(r"(?i)^Раздел\s*№\s*\d+", value)
        ]
        questions = []
        for question_index, section_start in enumerate(section_starts):
            question_end = (
                section_starts[question_index + 1]
                if question_index + 1 < len(section_starts)
                else len(body)
            )
            heading = body[section_start]
            source_position = int(
                re.match(r"(?i)^Раздел\s*№\s*(\d+)", heading).group(1)
            )
            group = []
            for value in body[section_start + 1 : question_end]:
                group.extend(split_numeric_answer(value))
            question = parse_question_group(group)
            question.update(
                {
                    "position": question_index + 1,
                    "sectionPosition": AGE_6_TEST_SECTION_MAP[source_position],
                }
            )
            questions.append(question)
        tests.append(
            {
                "audience": "AGE_6",
                "position": test_index + 1,
                "title": f"Тест {test_index + 1}",
                "description": "Смешанный тест по материалам разделов для категории 6+",
                "sourceFile": path.name,
                "isPublished": True,
                "questions": questions,
            }
        )
    return tests


def split_answer(value: str) -> list[str]:
    match = re.search(r"(?i)(?=(?:Правильный\s+)?Ответ\s*:)", value)
    if not match or match.start() == 0:
        return [value]
    return [value[: match.start()].strip(), value[match.start() :].strip()]


def complete_answer(value: str) -> bool:
    match = re.match(r"(?i)^(?:Правильный\s+)?Ответ\s*:\s*(.+)$", value)
    return bool(match and match.group(1).strip())


def embedded_heading_prompt(heading: str) -> str | None:
    markers = list(re.finditer(r"№\s*\d+\s*[.:]?\s*", heading, re.I))
    if len(markers) < 2:
        return None
    value = heading[markers[-1].end() :].strip()
    return value or None


def parse_mixed_question_group(group: list[str]) -> dict:
    section_markers = [
        index
        for index, value in enumerate(group[:-1])
        if re.match(r"(?i)^Раздел\s*№\s*\d+", value)
    ]
    embedded_prompt = None
    if section_markers:
        group = group[section_markers[-1] :]
        embedded_prompt = embedded_heading_prompt(group[0])
        group = group[1:]
    if embedded_prompt:
        group = [embedded_prompt] + group
    return parse_question_group(group)


def split_test_documents(path: Path) -> dict[int, list[str]]:
    values = paragraphs(path)
    starts = [
        (index, int(match.group(1)))
        for index, value in enumerate(values)
        if (match := re.match(r"(?i)^ТЕСТ\s*№\s*(\d+)", value))
    ]
    return {
        number: values[start + 1 : starts[index + 1][0] if index + 1 < len(starts) else len(values)]
        for index, (start, number) in enumerate(starts)
    }


def parse_complete_groups(values: list[str]) -> tuple[list[dict], list[str]]:
    questions = []
    group = []
    for value in values:
        for token in split_answer(value):
            group.append(token)
            if complete_answer(token):
                questions.append(parse_mixed_question_group(group))
                group = []
    return questions, group


def semantic_key(value: str) -> str:
    return re.sub(r"[^а-яa-z0-9]+", "", value.lower().replace("ё", "е"))


def recover_truncated_age_16_test(
    questions: list[dict], leftover: list[str], bank_sections: list[dict], test_number: int
) -> list[dict]:
    if test_number != 11 or len(questions) != 12:
        raise ValueError(
            f"Unexpected truncated test {test_number}: {len(questions)} complete questions"
        )

    prompt = next(
        (
            clean_prompt(value)
            for value in leftover
            if re.match(r"(?i)^Вопрос\s*:", value)
        ),
        None,
    )
    duplicate = next(
        (question for question in questions if prompt and semantic_key(question["text"]) == semantic_key(prompt)),
        None,
    )
    if not duplicate:
        raise ValueError("Cannot recover the partially written question in test 11")
    recovered_duplicate = dict(duplicate)
    recovered_duplicate["recoveredFrom"] = "duplicate question in the same DOCX"
    questions.append(recovered_duplicate)

    for section_position in (14, 15):
        recovered = dict(bank_sections[section_position - 1]["questions"][test_number - 1])
        recovered["recoveredFrom"] = "section bank; source test ends before this question"
        questions.append(recovered)
    return questions


def parse_mixed_tests(
    path: Path,
    audience: str,
    expected_questions: int,
    bank_sections: list[dict],
) -> list[dict]:
    tests = []
    for test_number, values in sorted(split_test_documents(path).items()):
        questions, leftover = parse_complete_groups(values)
        if len(questions) > expected_questions:
            # Test 12 in the 16+ file contains an interrupted draft followed by
            # the complete version. Keep the final complete sequence.
            questions = questions[-expected_questions:]
            leftover = []
        if len(questions) < expected_questions:
            questions = recover_truncated_age_16_test(
                questions, leftover, bank_sections, test_number
            )
        if len(questions) != expected_questions:
            raise ValueError(
                f"{path.name}: test {test_number} has {len(questions)} questions"
            )
        normalized_questions = []
        for position, question in enumerate(questions, start=1):
            normalized = dict(question)
            normalized.update({"position": position, "sectionPosition": position})
            normalized_questions.append(normalized)
        label = audience.replace("AGE_", "") + "+"
        tests.append(
            {
                "audience": audience,
                "position": test_number,
                "title": f"Тест {test_number}",
                "description": f"Смешанный тест по материалам разделов для категории {label}",
                "sourceFile": path.name,
                "isPublished": True,
                "questions": normalized_questions,
            }
        )
    return tests


def tests_from_question_bank(
    audience: str, source_file: str, sections: list[dict], count: int
) -> list[dict]:
    label = audience.replace("AGE_", "") + "+"
    return [
        {
            "audience": audience,
            "position": test_position,
            "title": f"Тест {test_position}",
            "description": f"Смешанный тест: по одному вопросу из каждого раздела категории {label}",
            "sourceFile": source_file,
            "isPublished": True,
            "questions": [
                {
                    **section["questions"][test_position - 1],
                    "position": question_position,
                    "sectionPosition": section["position"],
                }
                for question_position, section in enumerate(sections, start=1)
            ],
        }
        for test_position in range(1, count + 1)
    ]


def parse_guide(path: Path) -> dict:
    reader = PdfReader(path)
    pages = [
        "\n".join(
            line
            for raw_line in (page.extract_text() or "").splitlines()
            if (line := normalize(raw_line))
        )
        for page in reader.pages
    ]
    full_text = "\n\n".join(page for page in pages if page)
    heading_pattern = re.compile(r"(?m)(?=^\d+\.\s+[^\n]+$)")
    parts = [part.strip() for part in heading_pattern.split(full_text) if part.strip()]
    intro = parts[0] if parts and not re.match(r"^\d+\.", parts[0]) else ""
    sections = []
    for part in parts[1 if intro else 0 :]:
        first, _, rest = part.partition("\n")
        match = re.match(r"^(\d+)\.\s*(.+)$", first)
        if match:
            sections.append(
                {
                    "position": int(match.group(1)),
                    "title": match.group(2).strip(),
                    "text": rest.strip(),
                }
            )
    return {
        "slug": "parent-smoking-prevention",
        "title": "Памятка для родителей: профилактика курения у детей и подростков",
        "sourceFile": path.name,
        "pageCount": len(reader.pages),
        "content": {"intro": intro, "sections": sections, "fullText": full_text},
    }


def validate(payload: dict) -> None:
    expected_section_counts = {"AGE_6": 15, "AGE_16": 15, "AGE_18": 10}
    expected_test_counts = {"AGE_6": 15, "AGE_16": 20, "AGE_18": 20}
    expected_test_question_counts = {"AGE_6": 225, "AGE_16": 300, "AGE_18": 200}
    for audience in AGE_FILES:
        sections = [row for row in payload["sections"] if row["audience"] == audience]
        tests = [row for row in payload["tests"] if row["audience"] == audience]
        assert len(sections) == expected_section_counts[audience]
        assert len(tests) == expected_test_counts[audience]
        assert all(len(section["questions"]) == 20 for section in sections)
        assert sum(len(test["questions"]) for test in tests) == expected_test_question_counts[audience]
    all_questions = [
        question
        for section in payload["sections"]
        for question in section["questions"]
    ] + [question for test in payload["tests"] for question in test["questions"]]
    assert all(question["text"] for question in all_questions)
    assert all(len(question["options"]) == 4 for question in all_questions)
    assert all(1 <= question["correctOption"] <= 4 for question in all_questions)
    assert payload["guide"]["pageCount"] == 5


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_dir", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    sections = []
    sections_by_age = {}
    for audience, config in AGE_FILES.items():
        parsed = parse_sections(args.source_dir / config["sections"], audience)
        sections.extend(parsed)
        sections_by_age[audience] = parsed

    tests = parse_age_6_tests(args.source_dir / AGE_FILES["AGE_6"]["tests"])
    tests.extend(
        parse_mixed_tests(
            args.source_dir / AGE_FILES["AGE_16"]["tests"],
            "AGE_16",
            15,
            sections_by_age["AGE_16"],
        )
    )
    tests.extend(
        parse_mixed_tests(
            args.source_dir / AGE_FILES["AGE_18"]["tests"],
            "AGE_18",
            10,
            sections_by_age["AGE_18"],
        )
    )

    payload = {
        "sections": sections,
        "tests": tests,
        "guide": parse_guide(args.source_dir / "Памятка для родителей.pdf"),
        "meta": {
            "sectionCount": len(sections),
            "sectionQuestionCount": sum(len(row["questions"]) for row in sections),
            "testCount": len(tests),
            "testQuestionCount": sum(len(row["questions"]) for row in tests),
        },
    }
    validate(payload)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
    print(json.dumps(payload["meta"], ensure_ascii=False))


if __name__ == "__main__":
    main()
