# Dashboard Workbook Schema

This dashboard expects a single control sheet named `DASH_FEED` in the uploaded Excel workbook.

The sheet must be simple, human-editable, and deterministic. No merged cells, no subtotal formulas required, and no sheet-specific formatting is needed.

## Sheet: `DASH_FEED`

The sheet is divided into four sections:

1. Meta
2. KPIs
3. Bridge
4. Revenue & Margin
5. SG&A
6. Key Findings

Use the exact section headers and column layout shown below.

---

## 1. Meta

This section contains single values for the client and reporting labels.

| A | B |
|---|---|
| `Meta` | *(literal section marker)* |
| `Client Name` | Poolesville Veterinary Clinic |
| `Period PY` | TTM Mar-25 |
| `Period CY` | TTM Mar-26 |
| `Purchase Price` | 4000000 |

Notes:
- `Purchase Price` should be a numeric value in dollars.
- `Period PY` and `Period CY` are the exact period labels shown in the dashboard.

---

## 2. KPIs

This section contains the headline KPI values for both periods.

| A | B | C |
|---|---|---|
| `KPIs` | *(literal section marker)* | |
| `Metric` | `PY Value` | `CY Value` |
| `Revenue` | 2568154 | 2621078 |
| `Diligence Adj EBITDA` | 282553 | 236745 |
| `Adj EBITDA Margin` | 11.0% | 9.0% |
| `Implied Multiple` | 14.2 | 16.9 |

Notes:
- Percent values may be entered as percentages or decimals.
- `Implied Multiple` is a numeric ratio.

---

## 3. Bridge

The bridge section is a plain table with one row per line item.

| A | B | C | D | E |
|---|---|---|---|---|
| `Bridge` | *(literal section marker)* | | | |
| `Label` | `Ref` | `PY Value` | `CY Value` | `Type` |
| Reported EBITDA | | 39495 | -10017 | `reported` |
| Seller Adjusted EBITDA | | 84231 | 31200 | `subtotal` |
| A Nonrecurring Expenses | A | 44825 | 41217 | `adjustment` |
| B DVM Compensation | B | 180191 | 188262 | `adjustment` |
| C Proforma Insurance | C | 0 | 0 | `adjustment` |
| D Rent Normalization | D | -14276 | -189 | `adjustment` |
| E Family on Payroll | E | 9065 | 8397 | `adjustment` |
| F Non-recurring Legal Fees | F | -1800 | 9075 | `adjustment` |
| G Loss on Disposal of Asset | G | 25053 | 0 | `adjustment` |
| Diligence Adjusted EBITDA | | 282553 | 236745 | `subtotal` |

Notes:
- `Ref` should be the letter code for adjustments A–G, left blank for reported and subtotal rows.
- `Type` must be one of: `reported`, `adjustment`, `subtotal`.
- The two subtotal rows supply the bridge boundaries.

---

## 4. Revenue & Margin

This section provides period revenue/COGS/gross-profit values and the 12-month gross margin series.

### Summary table

| A | B | C |
|---|---|---|
| `RevenueMargin` | *(literal section marker)* | |
| `Metric` | `PY Value` | `CY Value` |
| Revenue | 2568154 | 2621078 |
| COGS | 718953 | 735422 |
| Gross Profit | 1919191 | 1885656 |

### Monthly gross margin series

| A | B |
|---|---|
| `Gross Margin Months` | *(literal section marker)* |
| `Month` | `Gross Margin %` |
| Apr | 73.9% |
| May | 70.2% |
| Jun | 74.1% |
| Jul | 71.0% |
| Aug | 73.5% |
| Sep | 72.8% |
| Oct | 70.9% |
| Nov | 74.3% |
| Dec | 69.1% |
| Jan | 72.0% |
| Feb | 71.6% |
| Mar | 73.2% |

Notes:
- The dashboard expects exactly 12 rows for the monthly series.
- The month names should be the standard three-letter abbreviations.

---

## 5. SG&A

This section contains the opex mix values for the current year.

| A | B | C |
|---|---|---|
| `SG&A` | *(literal section marker)* | |
| `Category` | `CY Value` | `Notes` |
| Labor - DVM | 563795 | |
| Labor - Staff | 621863 | |
| Labor & Fringe | 181370 | |
| Facility & Equip | 143254 | |
| Admin | 88385 | |
| Fee/Collection | 60779 | |
| Marketing | 22442 | |
| D&A | 66388 | |

Notes:
- `CY Value` is the adjusted current-year operating expense amount.
- The `Notes` column is optional and may be left blank.

---

## 6. Key Findings

This section is a simple list of bullet strings.

| A | B |
|---|---|
| `Key Findings` | *(literal section marker)* |
| `Finding 1` | Dr. Eeg (owner) moves to 20% of production post-close; comp normalized in Adjustment B. |
| `Finding 2` | ~2.5% gross-margin decline Mar-25 → Mar-26, attributed to IDEXX price increases & higher 1099 relief-vet use. |
| `Finding 3` | CareVet valuation revised: FY25 Adj. EBITDA $350K → $250K after ~$100K revenue reduction (discounts/rebates). |
| `Finding 4` | Cash proof analysis for the twelve months ended Mar-26 nets to a $0 variance. |

Notes:
- Additional findings may be added as rows below the section marker.
- Only the text in column B is used.

---

## General rules

- The dashboard parser should locate each section by the first column marker in column A.
- Section titles are case-sensitive and must exactly match `Meta`, `KPIs`, `Bridge`, `RevenueMargin`, `Gross Margin Months`, `SG&A`, and `Key Findings`.
- Blank rows are allowed between sections but not inside the expected table structure for each section.
- All numeric values should be raw numbers, not formulas, when possible.
- Percent values may be entered as percentages or decimals.
