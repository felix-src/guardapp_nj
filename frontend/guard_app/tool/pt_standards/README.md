# Fitness test standards

The PT calculator, timers, and lap tracker score against official Army tables bundled with the app in `assets/pt_standards/`. They're bundled rather than downloaded so scoring works in the field without signal.

## Current standard

| File | Test | Effective | Source |
|---|---|---|---|
| `aft_2025-06-01.json` | Army Fitness Test (AFT) | 1 Jun 2025 | [Army Fitness Test Score Tables](https://www.army.mil/e2/downloads/rv7/aft/AFT_Scoring_Scales_250601.pdf), approved 15 May 2025 ([army.mil/aft](https://www.army.mil/aft/)) |

The AFT combat standard (sex-neutral, 350 total) took effect for the Army National Guard on 1 Jun 2026. The calculator offers both standards.

## When the Army publishes new tables

1. Download the new scoring-scales PDF from [army.mil/aft](https://www.army.mil/aft/) or Army Publishing Directorate.
2. Copy `extract_aft_2025.py` to a new script, and adjust it if the layout changed (events, pages, age groups, the approved/effective text it checks for).
3. Run it (needs `pip install pdfplumber`):
   ```
   python extract_aft_YYYY.py <new-tables.pdf> ../../assets/pt_standards/aft_YYYY-MM-DD.json
   ```
   The script refuses to write output if a row is missing, if a value repeated across pages disagrees, or if a column doesn't get easier as points drop.
4. Add the new file to `standardAssets` in `lib/features/pt/standards.dart`. The app automatically uses the newest standard whose effective date has passed, so the new file can ship before its effective date.
5. Update or add tests in `test/pt_scoring_test.dart` with a few values read directly from the new PDF.
6. Spot-check a handful of scores in the app against the PDF before release.

A different test (not the AFT) with different events only needs a JSON file in the same format: the scoring code is generic (points per row, higher- or lower-is-better, age groups, male/female columns, per-event and total minimums).
