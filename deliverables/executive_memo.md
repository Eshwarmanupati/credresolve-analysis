# EXECUTIVE MEMORANDUM: CREDRESOLVE COLLECTIONS PERFORMANCE & CAPITAL ALLOCATION

**TO:** Investment Committee & Executive Leadership  
**FROM:** Lead Data Analyst  
**DATE:** August 23, 2026  
**SUBJECT:** Independent Audit of Collections Performance, 11% MoM Claim, and ₹10 Cr Capital Allocation Recommendation  
**DATASET SCOPE:** Jan 1, 2026 – Jul 31, 2026 (7 complete calendar months) | August 2026 (Partial 8-day monitoring dataset retained for data-quality tracking but excluded from main trend conclusions).

---

### Executive Summary

1. **11% MoM Improvement Claim Finding:**  
   The February-to-March raw recovery increase of approximately 10.99% coincides with a substantial increase in payment duplication; after Golden payment deduplication, the independent recovery metrics do not support the reported 11% improvement.

2. **Recovery Rate Trend:**  
   The Golden recovery rate deteriorated substantially over the seven-month period, falling from **40.07% in January** to **32.55% in July**, despite a small rebound in June. The apparent February-to-March raw peak was driven by an escalating payment duplication glitch that inflated raw recovery metrics by **14.31% (₹19.19 Cr)** across 2,033 SUCCESS payment references that had multiple raw records.

3. **Performance Decline is Portfolio-Wide:**  
   A mix-adjusted Simpson's paradox audit confirms that performance declined within every DPD bucket, resulting in a **−5.34% net standardized decline**.

4. **Campaign Strategy Changes Had Zero Causal Impact:**  
   Counterfactual comparison of strategy versions v2/v3 against v1/legacy controls yields a difference of **−0.06 pp (95% CI [−1.40 pp, +1.27 pp])**, confirming zero statistically significant lift.

5. **Single Capital Allocation Recommendation:** **Option 2 — More Collection Agents (₹10 Cr)**  
   *Option 2 provides the strongest evidence-supported ROI among the evaluated options, but the financial estimate has low confidence because it depends on cost and productivity assumptions.*

---

### 1. Investigation of the 11% MoM Claim

The raw payment logs recorded ₹134.15 Cr (₹1,341,485,926.33) in total successful recoveries. However, data forensics revealed **3,745 duplicate payment references** (affecting 8,042 payment rows), of which **2,033 SUCCESS payment references had multiple raw records** (resulting in 2,187 duplicate SUCCESS payment rows removed). This eliminated **₹19.19 Cr (₹191,912,491.21) in artificial inflation**.

```
Jan 2026: 40.07% Recovery Rate  │  Raw Duplication:  5.8%
Feb 2026: 39.63% Recovery Rate  │  Raw Duplication:  9.2%
Mar 2026: 38.97% Recovery Rate  │  Raw Duplication: 12.4% (Peak Duplication Artifact)
Apr 2026: 36.58% Recovery Rate  │  Raw Duplication: 13.7%
May 2026: 34.28% Recovery Rate  │  Raw Duplication: 16.5%
Jun 2026: 34.42% Recovery Rate  │  Raw Duplication: 20.8% (Minor Rebound)
Jul 2026: 32.55% Recovery Rate  │  Raw Duplication: 30.3%
```

After Golden payment deduplication (`golden_payments.csv` = 22,813 rows), the Golden recovery rate shows substantial 7-month deterioration.

---

### 2. Capital Allocation: Single Recommendation (Option 2)

We evaluated all 6 investment proposals against the complete 7-month baseline (Jan–Jul 2026 Golden Recovery = ₹111.23 Cr, annualized to **₹190.68 Cr / year**):

| Investment Option | Capital | Est. Incremental Recovery | Expected ROI | Recommendation Status |
|-------------------|---------|---------------------------|--------------|----------------------|
| **Option 1: Telephony Infra** | ₹10.0 Cr | ₹1.74 Cr | 0.17x | Alternate |
| **Option 2: More Agents (Base Case)** | **₹10.0 Cr** | **₹29.50 Cr** | **2.95x** | **SELECTED (Single Recommendation)** |
| **Option 2: More Agents (Downside)** | ₹10.0 Cr | ₹15.88 Cr | 1.59x | Scenario (35% Efficiency) |
| **Option 2: More Agents (Upside)** | ₹10.0 Cr | ₹36.31 Cr | 3.63x | Scenario (80% Efficiency) |
| **Option 3: AI Voice Automation** | ₹10.0 Cr | ₹0.02 Cr | 0.00x | Rejected |
| **Option 4: Better Targeting** | ₹3.0 Cr | ₹0.01 Cr | 0.00x | Rejected |
| **Option 5: WhatsApp / Digital** | ₹1.5 Cr | ₹0.31 Cr | 0.20x | Alternate |
| **Option 6: Field Operations** | ₹10.0 Cr | ₹14.88 Cr | 1.49x | Rejected (High Exec Risk) |

#### Rationale for Option 2 Selection
- **Implied Recovery per Canonical Agent (used for investment modeling):** ₹190.68 Cr / 1,000 agents = **₹19.07 Lakhs / agent / year** (the investment projection assumes new agents achieve 65% of this implied baseline productivity).
- **New Agents:** 238 Collection Agents (₹4.2 Lakhs annual CTC per agent).
- **Added Capacity:** +38,080 agent-calling hours/month (+456,960 hours/year).
- **Marginal Productivity Assumption:** **65% efficiency** for new hires.
- **Base Case Incremental Recovery:** **₹29.50 Cr / year** (238 $\times$ ₹19.07L $\times$ 0.65).
- **Base Case ROI:** **2.95x** | **Break-even:** **~4.1 months**.
- **Confidence Level:** **LOW** (dependent on cost and marginal productivity assumptions).
