"""Converts the official AFT scoring-scales PDF into the app's standards JSON.

Source: "Army Fitness Test Score Tables", approved 15 May 2025, effective
1 June 2025 (https://www.army.mil/e2/downloads/rv7/aft/AFT_Scoring_Scales_250601.pdf,
linked from https://www.army.mil/aft/).

Usage (Python 3.10+, `pip install pdfplumber`):
    python extract_aft_2025.py AFT_Scoring_Scales_250601.pdf \
        ../../assets/pt_standards/aft_2025-06-01.json

When the Army publishes new tables, copy this script, adjust the layout
details if they changed, generate a new JSON file, and register it in
lib/features/pt/standards.dart. The checks below fail loudly rather than
produce a wrong table.
"""

import hashlib
import json
import re
import sys

import pdfplumber

AGE_GROUPS = [
    ("17-21", 17, 21), ("22-26", 22, 26), ("27-31", 27, 31),
    ("32-36", 32, 36), ("37-41", 37, 41), ("42-46", 42, 46),
    ("47-51", 47, 51), ("52-56", 52, 56), ("57-61", 57, 61),
    ("62+", 62, None),
]

# page numbers (1-based) holding each event; better = direction of a good score
EVENTS = [
    ("MDL", "3-Rep Max Deadlift", "lbs", "higher", [1]),
    ("HRP", "Hand-Release Push-Up", "reps", "higher", [2]),
    ("SDC", "Sprint-Drag-Carry", "time", "lower", [3, 4]),
    ("PLK", "Plank", "time", "higher", [5, 6]),
    ("2MR", "2-Mile Run", "time", "lower", [7, 8]),
]

ALTERNATES = [
    ("WALK", "2.5-Mile Walk", "Walk"),
    ("BIKE", "12 km Bike", "Bike"),
    ("SWIM", "1 km Swim", "Swim"),
    ("ROW", "5 km Row", "Row"),
]

# Combat standard (sex-neutral) uses the male column ("M | C" in the PDF).
COMBAT_MOS = [
    "11A", "11B", "11C", "11Z", "12A", "12B", "13A", "13F", "18A", "180A",
    "18B", "18C", "18D", "18E", "18F", "18Z", "19A", "19C", "19D", "19K", "19Z",
]


def parse_value(token, unit):
    if token == "---":
        return None
    if unit == "time":
        m, s = token.split(":")
        return int(m) * 60 + int(s)
    return int(token)


def fail(msg):
    sys.exit(f"CHECK FAILED: {msg}")


def main(pdf_path, out_path):
    with open(pdf_path, "rb") as f:
        sha256 = hashlib.sha256(f.read()).hexdigest()
    with pdfplumber.open(pdf_path) as pdf:
        pages = [p.extract_text() or "" for p in pdf.pages]

    if "Approved: 15 May 2025" not in pages[0] or "Effective: 1 June 2025" not in pages[0]:
        fail("unexpected document version")

    events = []
    for event_id, name, unit, better, page_nums in EVENTS:
        rows = {}
        for n in page_nums:
            for line in pages[n - 1].splitlines():
                if not re.match(r"^\d{1,3} ", line):
                    continue
                tokens = line.split()
                if len(tokens) != 22 or tokens[0] != tokens[-1]:
                    fail(f"{event_id}: malformed row {line!r}")
                points = int(tokens[0])
                values = [parse_value(t, unit) for t in tokens[1:21]]
                male, female = values[0::2], values[1::2]
                if points in rows and rows[points] != (male, female):
                    fail(f"{event_id}: row {points} differs between pages")
                rows[points] = (male, female)

        expected = set(range(60, 101)) | {50, 40, 30, 20, 10, 0}
        if unit == "time":
            expected = set(range(0, 101))
        if set(rows) != expected:
            fail(f"{event_id}: rows {sorted(expected - set(rows))} missing")

        table = [
            {"points": p, "male": rows[p][0], "female": rows[p][1]}
            for p in sorted(rows, reverse=True)
        ]

        # Each column must get easier as points drop
        for col in ("male", "female"):
            for g in range(len(AGE_GROUPS)):
                seq = [r[col][g] for r in table if r[col][g] is not None]
                ok = all(
                    (a >= b) if better == "higher" else (a <= b)
                    for a, b in zip(seq, seq[1:])
                )
                if not ok:
                    fail(f"{event_id} {col} {AGE_GROUPS[g][0]} not monotonic")
                if table[0][col][g] is None or table[-1][col][g] is None:
                    fail(f"{event_id} {col} {AGE_GROUPS[g][0]} missing 100 or 0")

        events.append({
            "id": event_id, "name": name, "unit": unit, "better": better,
            "table": table,
        })

    alternates = []
    alt_lines = pages[8].splitlines()
    for alt_id, name, label in ALTERNATES:
        line = next((l for l in alt_lines if l.startswith(label + " ")), None)
        if line is None:
            fail(f"alternate {label} not found")
        values = [parse_value(t, "time") for t in line.split()[1:]]
        if len(values) != 20:
            fail(f"alternate {label}: expected 20 values")
        alternates.append({
            "id": alt_id, "name": name,
            "male": values[0::2], "female": values[1::2],
        })

    standard = {
        "id": "aft-2025-06-01",
        "name": "Army Fitness Test (AFT)",
        "shortName": "AFT",
        "approved": "2025-05-15",
        "effective": "2025-06-01",
        "source": {
            "title": "Army Fitness Test Score Tables",
            "url": "https://www.army.mil/e2/downloads/rv7/aft/AFT_Scoring_Scales_250601.pdf",
            "sha256": sha256,
        },
        "minPointsPerEvent": 60,
        "minTotal": {"general": 300, "combat": 350},
        "combatMos": COMBAT_MOS,
        "notes": [
            "Combat standard (sex-neutral) applies to Soldiers in the listed "
            "combat MOSs/AOCs; effective 1 Jan 2026 (active) and 1 Jun 2026 "
            "(Army National Guard and Army Reserve).",
            "Use your age on the day of the test.",
        ],
        "ageGroups": [
            {"label": label, "min": lo, "max": hi} for label, lo, hi in AGE_GROUPS
        ],
        "events": events,
        "alternates": alternates,
    }

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(standard, f, indent=1)
        f.write("\n")
    print(f"wrote {out_path}: {len(events)} events, {len(alternates)} alternates")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: extract_aft_2025.py <scoring-scales.pdf> <out.json>")
    main(sys.argv[1], sys.argv[2])
