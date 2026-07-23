# Armanino QofE Dashboard

This browser-only dashboard loads an offline Excel workbook and renders charts, tables, and findings dynamically.

## Test workbook

Use `Fake_Databook_Full.xlsx` in the repo root as the canonical test file.

## How to use

1. Open `Index.html` in a browser.
2. Upload `Fake_Databook_Full.xlsx` or another valid `.xlsx` workbook.
3. The dashboard will render if `DASH_FEED` and required sections are present.

## Notes

- The app validates required `DASH_FEED` sections and reports missing schema keys.
- Only `.xlsx` uploads are accepted.
