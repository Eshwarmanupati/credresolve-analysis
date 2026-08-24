# Credresolve Collections Analytics — Data Analyst Assignment Submission

> **Executive Investigation, Data Quality Audit, Counterfactual Strategy Evaluation & Capital Allocation Model**  
> **Dataset Scope:** Jan 1, 2026 – Jul 31, 2026 (7 complete calendar months) | August 2026 (Partial 8-day monitoring dataset retained for data-quality tracking but excluded from main trend conclusions).

---

## Executive Summary & Primary Analytical Findings

1. **11% MoM Improvement Claim:** **NOT SUPPORTED**
   - The February-to-March raw recovery increase of approximately 10.99% coincides with a substantial increase in payment duplication; after Golden payment deduplication, the independent recovery metrics do not support the reported 11% improvement.
   - **Recovery Trend:** The Golden recovery rate deteriorated substantially over the seven-month period, falling from **40.07% in January** to **32.55% in July**, despite a small rebound in June.
   - Raw data recovery figures were inflated by **14.31% (₹19.19 Cr)** due to growing payment reference duplication (2,033 SUCCESS payment references had multiple raw records).

2. **Simpson's Paradox Check:** **NOT PRESENT**
   - Performance deteriorated within every DPD bucket. Standardized mix-adjusted recovery declined by **−5.34%** over the period.

3. **Campaign Strategy Lift:** **CORRELATION ONLY**
   - Strategy v2/v3 accounts achieved a 38.90% recovery rate vs 38.96% for v1/legacy controls. The difference of **−0.06 pp (95% CI [−1.40 pp, +1.27 pp])** includes zero and is statistically indistinguishable from zero.

4. **Single Capital Allocation Recommendation:** **Option 2 — More Collection Agents (₹10 Cr)**
   - *Option 2 provides the strongest evidence-supported ROI among the evaluated options, but the financial estimate has low confidence because it depends on cost and productivity assumptions.*
   - **Capital:** ₹10.0 Cr | **New Agents:** 238 | **Added Capacity:** +38,080 agent-hours/month.
   - **Baseline 7-Month Total Recovery (Jan–Jul 2026):** ₹111.23 Cr (₹1,112,329,046.57).
   - **Annualized Baseline Recovery (Jan–Jul 7-Month Baseline $\times 12/7$):** **₹190.68 Cr / year**.
   - **Base Case Incremental Recovery:** **₹29.50 Cr / year** | **Base ROI:** **2.95x** | **Break-even:** **~4.1 months**.
   - **Scenario Sensitivity:** Downside (35% efficiency) = **1.59x ROI** | Upside (80% efficiency) = **3.63x ROI**.

---

## Data Architecture & Option A Golden Dataset

The supplied synthetic collections dataset contains **17 business tables** totaling **639,185 raw records**.

```
RAW DATA (17 Tables: 639,185 Rows)
   │
   ├─► Exact Deduplication (-2,957 Rows Rejected)
   ├─► Surrogate PK Collapse & Reference Deduplication (-50,265 Rows Corrected)
   │
   ▼
GOLDEN DATASET (Option A — 17 Exported Tables: 585,963 Rows)
   ├── golden_borrowers.csv (11,015 rows)
   ├── golden_accounts.csv (30,000 rows)
   ├── golden_agents.csv (1,000 rows)
   ├── golden_agent_sessions.csv (15,000 rows)
   ├── golden_campaigns.csv (120 rows)
   ├── golden_daily_targeting.csv (45,000 rows)
   ├── golden_calls.csv (90,000 rows)
   ├── golden_call_attempts.csv (120,000 rows)
   ├── golden_call_dispositions.csv (35,000 rows)
   ├── golden_whatsapp_events.csv (60,000 rows)
   ├── golden_sms_events.csv (45,000 rows)
   ├── golden_field_visits.csv (25,000 rows)
   ├── golden_promises_to_pay.csv (18,000 rows)
   ├── golden_payments.csv (22,813 rows)
   ├── golden_vendor_telephony.csv (15 rows)
   ├── golden_complaints.csv (8,000 rows)
   └── golden_account_status_history.csv (60,000 rows)
```

---

## Key Reconciled Metric Contracts (Uncapped)

| Metric | Analytical Definition | Jan–Jul 2026 Average |
|--------|----------------------|----------------------|
| **Contact Rate** | `contacted_accounts / targeted_accounts` (`contacted_accounts` = unique accounts with answered calls) | **42.2%** |
| **Call Answer Rate** | `answered_calls / total_calls` | **19.9%** |
| **RPC Rate** | `rpc_accounts / accounts_called` | **24.9%** |
| **PTP Rate (Targeted)** | `ptp_accounts / targeted_accounts` | **42.5%** |
| **PTP Rate (Called)** | `ptp_accounts / accounts_called` | **23.5%** |
| **PTP Kept Rate** | `ptp_kept_accounts / ptp_accounts` (within 7 days) | **38.6%** |
| **Recovery Rate** | `recovered_accounts / targeted_accounts` | **36.6%** (Jan: 40.1% → Jul: 32.5%) |
| **Cost per ₹ Recovered**| `(agent_hours * ₹250) / recovered_amount` | **₹0.015** (1.5% collection cost ratio) |

---

## Financial Amounts (Exact Crore Conversion: 1 Cr = ₹10,000,000)

- **Raw SUCCESS Payment Amount:** ₹1,341,485,926.33 = **₹134.15 Cr**
- **Golden SUCCESS Payment Amount:** ₹1,149,573,435.12 = **₹114.96 Cr**
- **Duplicate Inflation Removed:** ₹191,912,491.21 = **₹19.19 Cr** (14.31%)
- **Jan–Jul 7-Month Total Recovery:** ₹1,112,329,046.57 = **₹111.23 Cr**
- **Annualized Baseline Recovery:** **₹190.68 Cr / year**

---

## Directory Structure & Project Deliverables

- [`config.py`](file:///Users/eshwar/myProjects/credresolve-analysis/config.py): Centralized paths, dataset definitions, and metric contracts.
- [`scripts/02_full_analysis.py`](file:///Users/eshwar/myProjects/credresolve-analysis/scripts/02_full_analysis.py): Master analysis script (10 phases).
- [`notebooks/credresolve_analysis.ipynb`](file:///Users/eshwar/myProjects/credresolve-analysis/notebooks/credresolve_analysis.ipynb): Master executable Jupyter Notebook with live pandas code and executed outputs.
- [`sql/`](file:///Users/eshwar/myProjects/credresolve-analysis/sql/): SQL staging, clean, golden, and metrics views.
- [`output/golden/`](file:///Users/eshwar/myProjects/credresolve-analysis/output/golden/): 17 Golden CSV tables (585,963 records).
- [`output/charts/`](file:///Users/eshwar/myProjects/credresolve-analysis/output/charts/): 5 PNG visualization charts.
- [`deliverables/executive_memo.md`](file:///Users/eshwar/myProjects/credresolve-analysis/deliverables/executive_memo.md): 2-page C-suite Memo.
- [`deliverables/data_quality_report.md`](file:///Users/eshwar/myProjects/credresolve-analysis/deliverables/data_quality_report.md): Technical Data Quality & Forensics Report.
- [`deliverables/architecture.md`](file:///Users/eshwar/myProjects/credresolve-analysis/deliverables/architecture.md): Production Analytics Data Architecture Specification.
- [`deliverables/architecture.png`](file:///Users/eshwar/myProjects/credresolve-analysis/deliverables/architecture.png): Production Architecture Diagram Image.
- [`dashboard/`](file:///Users/eshwar/myProjects/credresolve-analysis/dashboard/): Interactive Web Dashboard (`http://localhost:8000`).
- [`FINAL_SUBMISSION_CHECK.md`](file:///Users/eshwar/myProjects/credresolve-analysis/FINAL_SUBMISSION_CHECK.md): 22-point audit verification checklist.

---

## Quick Start

1. **Install Dependencies:**
   ```bash
   pip install -r requirements.txt
   ```
2. **Run Analysis & Reproduce Pipeline:**
   ```bash
   python3 scripts/02_full_analysis.py
   ```
3. **Launch Local Dashboard:**
   ```bash
   cd dashboard && python3 -m http.server 8000
   ```
4. **Open Dashboard URL:**
   Navigate to `http://localhost:8000/` in your browser.
5. **Review Deliverables & Audit Reports:**
   Inspect `deliverables/executive_memo.md`, `deliverables/data_quality_report.md`, and `FINAL_SUBMISSION_CHECK.md`.

