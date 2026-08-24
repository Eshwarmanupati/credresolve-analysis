"""
Credresolve Collections Analytics — Central Configuration
=========================================================
All configurable paths, constants, and metric definitions.
"""
import os

# ── Paths ──────────────────────────────────────────────────────
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(PROJECT_ROOT, "dataset")
DATASET_DIR = DATA_DIR  # Alias for backward compatibility
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "output")
GOLDEN_DIR = os.path.join(OUTPUT_DIR, "golden")
CHARTS_DIR = os.path.join(OUTPUT_DIR, "charts")
SQL_DIR = os.path.join(PROJECT_ROOT, "sql")

for d in [OUTPUT_DIR, GOLDEN_DIR, CHARTS_DIR, SQL_DIR]:
    os.makedirs(d, exist_ok=True)

# ── Timezone Mapping ───────────────────────────────────────────
# Standard timezone for all analysis output
CANONICAL_TZ = "Asia/Kolkata"

TZ_OFFSETS = {
    "Asia/Kolkata": 5.5,   # UTC+5:30
    "Asia/Dubai":   4.0,   # UTC+4:00
    "UTC":          0.0,
}

# ── Payment Deduplication ──────────────────────────────────────
# Two payments are considered duplicates if they share these fields
# AND occur within this time window
PAYMENT_DEDUP_WINDOW_HOURS = 24
PAYMENT_DEDUP_FIELDS = ["account_id", "amount", "payment_method"]

# ── Attribution Windows ────────────────────────────────────────
# A payment is attributed to an interaction if it occurs within
# this many days AFTER the interaction
ATTRIBUTION_WINDOW_DAYS = 7

# ── Metric Definitions ─────────────────────────────────────────
# Recovery Rate denominator: all active accounts in the month
# Contact Rate denominator: all targeted accounts in the month
# PTP Kept window: payment received within 7 days of promised_date

PTP_KEPT_WINDOW_DAYS = 7

# ── Agent Cost Assumptions (industry estimates) ────────────────
AGENT_MONTHLY_CTC = 35000       # ₹35,000/month all-in
AGENT_WORKING_DAYS_PER_MONTH = 22
AGENT_HOURS_PER_DAY = 8
TELEPHONY_COST_PER_MIN = 1.5    # ₹1.5/min

DATASETS = [
    "borrowers", "accounts", "agents", "agent_sessions",
    "campaigns", "daily_targeting", "calls", "call_attempts",
    "call_dispositions", "whatsapp_events", "sms_events",
    "field_visits", "promises_to_pay", "payments",
    "vendor_telephony", "complaints", "account_status_history",
]

METRIC_CONTRACTS = {
    "recovery_rate": "Unique Paid Accounts / Unique Targeted Accounts",
    "contact_rate": "Unique Phone Contacted Accounts / Unique Targeted Accounts",
    "call_answer_rate": "Answered Call Attempts / Total Call Attempts",
    "rpc_rate": "Unique RPC Accounts / Unique Accounts Called",
    "ptp_rate_targeted": "Unique PTP Accounts / Unique Targeted Accounts",
    "ptp_rate_called": "Unique PTP Accounts / Unique Accounts Called",
    "ptp_kept_rate": "Unique PTP Accounts with Payment within 7 Days / Total PTP Accounts",
    "recovery_per_account": "Total Golden Recovery Amount / Unique Targeted Accounts",
}

