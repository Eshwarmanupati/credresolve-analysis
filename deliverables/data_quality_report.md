# CREDRESOLVE DATA QUALITY & DATA FORENSICS AUDIT REPORT

**Author:** Lead Data Analyst  
**Audit Scope:** 17 Supplied Business Tables + Central Config  
**Dataset Scope:** Jan 1, 2026 – Jul 31, 2026 (7 complete calendar months) | August 2026 (Partial 8-day monitoring dataset retained for data-quality tracking but excluded from main trend conclusions).

---

## 1. Option A Golden Dataset Reconciliation Summary

The supplied synthetic collections dataset contains **17 business data tables** totaling **639,185 raw records**.

```
===================================================================================
TABLE NAME                 RAW RECORDS   REJECTED   CORRECTED   GOLDEN RECORDS
===================================================================================
borrowers                       30,600        600      18,985           11,015
accounts                        30,000          0           0           30,000
agents                          30,000          0      29,000            1,000
agent_sessions                  15,000          0           0           15,000
campaigns                          120          0           0              120
daily_targeting                 45,000          0           0           45,000
calls                           91,350      1,271          79           90,000
call_attempts                  120,000          0           0          120,000
call_dispositions               35,000          0           0           35,000
whatsapp_events                 60,600        600           0           60,000
sms_events                      45,000          0           0           45,000
field_visits                    25,000          0           0           25,000
promises_to_pay                 18,000          0           0           18,000
payments                        25,500        486       2,201           22,813
vendor_telephony                    15          0           0               15
complaints                       8,000          0           0            8,000
account_status_history          60,000          0           0           60,000
-----------------------------------------------------------------------------------
TOTAL RAW BUSINESS ROWS:       639,185      2,957      50,265          585,963
===================================================================================
```

### Reconciliation Mathematical Proof
$$\text{Raw Rows (639,185)} - \text{Rejected Exact Dupes (2,957)} - \text{Corrected PK/Ref Dupes (50,265)} = \mathbf{\text{Golden Rows (585,963)}}$$

- **Category Relationship:** `Rejected Rows` (exact 100% duplicate records discarded in Phase 1) and `Corrected Rows` (valid entity records collapsed to canonical state or deduplicated by unique reference ID in Phase 2) are **mutually exclusive** and sequential.

---

## 2. Core Forensic Findings (Crore Conversion: 1 Cr = ₹10,000,000)

### A. Payment Duplication Glitch
- **Duplicate Payment References (all statuses):** 3,745 references
- **SUCCESS Payment References with Multiple Records:** 2,033 references
- **Affected Raw Payment Rows:** 8,042 payment rows
- **SUCCESS Payment Rows Removed by Deduplication:** 2,187 rows
- **Golden Payments Count (`golden_payments.csv`):** 22,813 rows
- **Raw SUCCESS Payment Amount:** ₹1,341,485,926.33 = **₹134.15 Cr**
- **Golden SUCCESS Payment Amount:** ₹1,149,573,435.12 = **₹114.96 Cr**
- **Monetary Inflation Removed:** **₹191,912,491.21 = ₹19.19 Cr (14.31%)**

### B. Agent Identity Resolution
- **Raw Agent Rows:** 30,000 rows
- **Canonical Agents Resolved:** 1,000 agents (`agent_id` deduped keeping latest timestamp).

### C. Timezone Normalization
- All telephony timestamps converted from UTC/Dubai offsets to **IST (UTC+5:30)**.

---

## 3. Layer Classification Across 17 Tables

| Source Table | Layer Status | Pipeline Treatment |
|--------------|--------------|-------------------|
| `borrowers` | `GOLDEN` | Deduplicated to 11,015 canonical borrower profiles (`golden_borrowers.csv`). |
| `accounts` | `GOLDEN` | Core account dimension (`golden_accounts.csv`). |
| `agents` | `GOLDEN` | Identity resolved to 1,000 canonical agents (`golden_agents.csv`). |
| `agent_sessions` | `GOLDEN` | Session duration aggregated for agent-hours (`golden_agent_sessions.csv`). |
| `campaigns` | `GOLDEN` | Strategy version classification (`golden_campaigns.csv`). |
| `daily_targeting` | `GOLDEN` | Portfolio denominator base (`golden_daily_targeting.csv`). |
| `calls` | `GOLDEN` | Normalized to IST and PK deduplicated (`golden_calls.csv`). |
| `call_attempts` | `GOLDEN` | Call attempt log (`golden_call_attempts.csv`). |
| `call_dispositions` | `GOLDEN` | RPC disposition classification (`golden_call_dispositions.csv`). |
| `whatsapp_events` | `GOLDEN` | WhatsApp engagement log (`golden_whatsapp_events.csv`). |
| `sms_events` | `GOLDEN` | SMS engagement log (`golden_sms_events.csv`). |
| `field_visits` | `GOLDEN` | Field visit log (`golden_field_visits.csv`). |
| `promises_to_pay` | `GOLDEN` | PTP tracking log (`golden_promises_to_pay.csv`). |
| `payments` | `GOLDEN` | Cleaned 3-level payment deduplication (`golden_payments.csv`: 22,813 rows). |
| `vendor_telephony` | `REFERENCE` | Vendor telephony parameters (`golden_vendor_telephony.csv`). |
| `complaints` | `GOLDEN` | Borrower complaints log (`golden_complaints.csv`). |
| `account_status_history` | `GOLDEN` | DPD & status history (`golden_account_status_history.csv`). |
