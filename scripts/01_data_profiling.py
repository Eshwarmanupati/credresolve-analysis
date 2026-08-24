"""
Phase 1: Comprehensive Data Profiling
======================================
Inspects all 17 datasets to build a complete data inventory.
For each table: row/col counts, dtypes, nulls, uniques, duplicates,
date ranges, PK/FK candidates, suspicious values, distributions.
"""
import pandas as pd
import numpy as np
import os
import sys
import json
from collections import OrderedDict

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from config import DATA_DIR, OUTPUT_DIR, DATASETS

# ── Load all datasets ──────────────────────────────────────────
print("=" * 70)
print("PHASE 1: DATA PROFILING")
print("=" * 70)

tables = {}
for name in DATASETS:
    path = os.path.join(DATA_DIR, f"{name}.csv")
    df = pd.read_csv(path, low_memory=False)
    tables[name] = df
    print(f"  Loaded {name}: {df.shape[0]:,} rows × {df.shape[1]} cols")

print(f"\nTotal datasets: {len(tables)}")
print(f"Total rows: {sum(df.shape[0] for df in tables.values()):,}")

# ── Profile each table ─────────────────────────────────────────
profiles = {}

for name, df in tables.items():
    print(f"\n{'='*70}")
    print(f"TABLE: {name}")
    print(f"{'='*70}")
    
    profile = {
        "row_count": df.shape[0],
        "col_count": df.shape[1],
        "columns": list(df.columns),
    }
    
    # ── Data types ──
    print(f"\nColumns & Types:")
    for col in df.columns:
        null_pct = df[col].isna().mean() * 100
        unique_ct = df[col].nunique()
        print(f"  {col:30s} | {str(df[col].dtype):12s} | nulls: {null_pct:5.1f}% | uniques: {unique_ct:,}")
    
    # ── Exact duplicates ──
    exact_dupes = df.duplicated().sum()
    print(f"\nExact duplicate rows: {exact_dupes:,} ({exact_dupes/len(df)*100:.1f}%)")
    profile["exact_duplicates"] = int(exact_dupes)
    
    # ── ID column duplicates ──
    id_cols = [c for c in df.columns if c.endswith("_id") and not c.startswith("borrower") 
               and not c.startswith("account") and not c.startswith("agent") 
               and not c.startswith("campaign") and not c.startswith("vendor")
               and not c.startswith("call") and not c.startswith("message")
               and not c.startswith("provider") and not c.startswith("device")]
    # Actually, let's check the FIRST column as PK candidate
    pk_candidate = df.columns[0]
    pk_dupes = df[pk_candidate].duplicated().sum()
    print(f"PK candidate '{pk_candidate}': {pk_dupes:,} duplicates ({pk_dupes/len(df)*100:.1f}%)")
    profile["pk_candidate"] = pk_candidate
    profile["pk_duplicates"] = int(pk_dupes)
    
    # ── Date columns ──
    date_cols = [c for c in df.columns if any(kw in c for kw in ["_at", "_date", "event_at"])]
    for dc in date_cols:
        try:
            parsed = pd.to_datetime(df[dc], errors='coerce')
            valid = parsed.dropna()
            if len(valid) > 0:
                print(f"  Date '{dc}': {valid.min()} → {valid.max()} (nulls: {parsed.isna().sum():,})")
        except Exception as e:
            print(f"  Date '{dc}': parse error: {e}")
    
    # ── Categorical distributions ──
    cat_cols = df.select_dtypes(include=['object']).columns
    for cc in cat_cols:
        nunique = df[cc].nunique()
        if nunique <= 20 and cc not in date_cols:
            print(f"\n  Distribution of '{cc}' ({nunique} values):")
            vc = df[cc].value_counts(dropna=False)
            for val, cnt in vc.items():
                pct = cnt / len(df) * 100
                print(f"    {str(val):30s}: {cnt:>7,} ({pct:5.1f}%)")
    
    # ── Numeric summaries ──
    num_cols = df.select_dtypes(include=[np.number]).columns
    if len(num_cols) > 0:
        print(f"\n  Numeric summary:")
        for nc in num_cols:
            vals = df[nc].dropna()
            if len(vals) > 0:
                print(f"    {nc}: min={vals.min():,.2f}, median={vals.median():,.2f}, "
                      f"mean={vals.mean():,.2f}, max={vals.max():,.2f}, "
                      f"zeros={int((vals==0).sum()):,}, negatives={int((vals<0).sum()):,}")
    
    # ── Timezone column ──
    if 'timezone' in df.columns:
        print(f"\n  Timezone distribution:")
        vc = df['timezone'].value_counts(dropna=False)
        for val, cnt in vc.items():
            print(f"    {str(val):20s}: {cnt:>7,} ({cnt/len(df)*100:.1f}%)")
    
    # ── Schema version ──
    if 'schema_version' in df.columns:
        print(f"\n  Schema version distribution:")
        vc = df['schema_version'].value_counts(dropna=False)
        for val, cnt in vc.items():
            print(f"    {str(val):20s}: {cnt:>7,} ({cnt/len(df)*100:.1f}%)")
    
    # ── Suspicious: updated_at < created_at ──
    if 'created_at' in df.columns and 'updated_at' in df.columns:
        try:
            created = pd.to_datetime(df['created_at'], errors='coerce')
            updated = pd.to_datetime(df['updated_at'], errors='coerce')
            both_valid = created.notna() & updated.notna()
            backward = (updated[both_valid] < created[both_valid]).sum()
            print(f"\n  ⚠ updated_at < created_at: {backward:,} rows ({backward/both_valid.sum()*100:.1f}%)")
        except:
            pass
    
    # ── Foreign key candidates ──
    fk_cols = [c for c in df.columns if c.endswith("_id") and c != pk_candidate]
    if fk_cols:
        print(f"\n  FK candidates: {', '.join(fk_cols)}")
        for fk in fk_cols:
            print(f"    {fk}: {df[fk].nunique():,} unique values, {df[fk].isna().sum():,} nulls")
    
    profiles[name] = profile

# ── Cross-table FK validation ──────────────────────────────────
print(f"\n{'='*70}")
print("CROSS-TABLE FK VALIDATION")
print(f"{'='*70}")

# Key FK relationships to check
fk_checks = [
    ("accounts", "borrower_id", "borrowers", "borrower_id"),
    ("calls", "account_id", "accounts", "account_id"),
    ("calls", "agent_id", "agents", "agent_id"),
    ("calls", "campaign_id", "campaigns", "campaign_id"),
    ("calls", "vendor_id", "vendor_telephony", "vendor_id"),
    ("call_attempts", "call_id", "calls", "call_id"),
    ("call_dispositions", "call_id", "calls", "call_id"),
    ("payments", "account_id", "accounts", "account_id"),
    ("payments", "borrower_id", "borrowers", "borrower_id"),
    ("promises_to_pay", "account_id", "accounts", "account_id"),
    ("daily_targeting", "account_id", "accounts", "account_id"),
    ("daily_targeting", "campaign_id", "campaigns", "campaign_id"),
    ("agent_sessions", "agent_id", "agents", "agent_id"),
    ("field_visits", "account_id", "accounts", "account_id"),
    ("whatsapp_events", "account_id", "accounts", "account_id"),
    ("sms_events", "account_id", "accounts", "account_id"),
    ("complaints", "account_id", "accounts", "account_id"),
    ("account_status_history", "account_id", "accounts", "account_id"),
]

for child_tbl, child_col, parent_tbl, parent_col in fk_checks:
    child_vals = set(tables[child_tbl][child_col].dropna().unique())
    parent_vals = set(tables[parent_tbl][parent_col].dropna().unique())
    orphans = child_vals - parent_vals
    if orphans:
        print(f"  ⚠ {child_tbl}.{child_col} → {parent_tbl}.{parent_col}: "
              f"{len(orphans):,} orphan values ({len(orphans)/len(child_vals)*100:.1f}%)")
    else:
        print(f"  ✓ {child_tbl}.{child_col} → {parent_tbl}.{parent_col}: OK")

# ── Payment-specific profiling ─────────────────────────────────
print(f"\n{'='*70}")
print("PAYMENT DEEP-DIVE")
print(f"{'='*70}")

pay = tables['payments']
print(f"\nPayment status distribution:")
print(pay['payment_status'].value_counts(dropna=False).to_string())

print(f"\nPayment method distribution:")
print(pay['payment_method'].value_counts(dropna=False).to_string())

print(f"\nPayment amount stats:")
print(f"  Total records: {len(pay):,}")
print(f"  Unique payment_id: {pay['payment_id'].nunique():,}")
print(f"  Unique payment_reference: {pay['payment_reference'].nunique():,}")
print(f"  Unique account_id: {pay['account_id'].nunique():,}")

# Potential duplicate payments by reference
ref_dupes = pay.groupby('payment_reference').size()
multi_ref = ref_dupes[ref_dupes > 1]
print(f"\n  Payment references appearing >1 time: {len(multi_ref):,}")
if len(multi_ref) > 0:
    print(f"  Max occurrences of single reference: {multi_ref.max()}")
    print(f"  Records affected: {multi_ref.sum():,}")

# Same account + same amount within 24 hours
pay_sorted = pay.copy()
pay_sorted['event_at'] = pd.to_datetime(pay_sorted['event_at'], errors='coerce')
pay_sorted = pay_sorted.sort_values(['account_id', 'event_at'])
pay_sorted['prev_event'] = pay_sorted.groupby(['account_id', 'amount'])['event_at'].shift(1)
pay_sorted['time_diff_hours'] = (pay_sorted['event_at'] - pay_sorted['prev_event']).dt.total_seconds() / 3600
close_dupes = pay_sorted[pay_sorted['time_diff_hours'] <= 24]
print(f"  Same account+amount within 24h: {len(close_dupes):,} records")

# Successful payments summary
successful = pay[pay['payment_status'].isin(['SUCCESS', 'SETTLED'])]
print(f"\n  Successful/Settled payments: {len(successful):,}")
print(f"  Total successful amount: ₹{successful['amount'].sum():,.0f}")
print(f"  Avg successful amount: ₹{successful['amount'].mean():,.0f}")

# ── Agent identity investigation ───────────────────────────────
print(f"\n{'='*70}")
print("AGENT IDENTITY INVESTIGATION")
print(f"{'='*70}")

agents = tables['agents']
print(f"\nTotal agent records: {len(agents):,}")
print(f"Unique agent_id: {agents['agent_id'].nunique():,}")
print(f"Unique employee_code: {agents['employee_code'].nunique():,}")
print(f"Unique agent_name: {agents['agent_name'].nunique():,}")

# Same employee_code, different agent_id
emp_agent = agents.groupby('employee_code')['agent_id'].nunique()
multi_agent = emp_agent[emp_agent > 1]
print(f"\nEmployee codes with multiple agent_ids: {len(multi_agent):,}")
if len(multi_agent) > 0:
    print(f"  Max agent_ids per employee: {multi_agent.max()}")
    print(f"  Affected employee codes: {len(multi_agent):,}")
    # Show examples
    for emp in multi_agent.head(5).index:
        subset = agents[agents['employee_code'] == emp][['agent_id', 'employee_code', 'agent_name', 'vendor_id', 'team', 'status']]
        print(f"\n  Employee {emp}:")
        print(subset.to_string(index=False))

# Same agent_name, different employee_code
name_emp = agents.groupby('agent_name')['employee_code'].nunique()
multi_name = name_emp[name_emp > 1]
print(f"\nAgent names with multiple employee_codes: {len(multi_name):,}")

# ── Campaign & Strategy Analysis ──────────────────────────────
print(f"\n{'='*70}")
print("CAMPAIGN & STRATEGY ANALYSIS")
print(f"{'='*70}")

camps = tables['campaigns']
camps['start_at'] = pd.to_datetime(camps['start_at'], errors='coerce')
camps['end_at'] = pd.to_datetime(camps['end_at'], errors='coerce')

print(f"\nStrategy version distribution:")
print(camps['strategy_version'].value_counts().to_string())

print(f"\nStrategy version by month (start_at):")
camps['start_month'] = camps['start_at'].dt.to_period('M')
pivot = camps.groupby(['start_month', 'strategy_version']).size().unstack(fill_value=0)
print(pivot.to_string())

print(f"\nCampaign name distribution:")
print(camps['campaign_name'].value_counts().to_string())

print(f"\nChannel distribution:")
print(camps['channel'].value_counts().to_string())

print(f"\nTarget definition distribution:")
print(camps['target_definition'].value_counts().to_string())

# ── Account portfolio analysis ─────────────────────────────────
print(f"\n{'='*70}")
print("ACCOUNT PORTFOLIO ANALYSIS")
print(f"{'='*70}")

accts = tables['accounts']
print(f"\nLoan type distribution:")
print(accts['loan_type'].value_counts().to_string())
print(f"\nRisk segment distribution:")
print(accts['risk_segment'].value_counts().to_string())
print(f"\nAccount status distribution:")
print(accts['status'].value_counts().to_string())
print(f"\nDPD distribution:")
print(f"  min={accts['dpd'].min()}, median={accts['dpd'].median():.0f}, "
      f"mean={accts['dpd'].mean():.0f}, max={accts['dpd'].max()}")
dpd_bins = pd.cut(accts['dpd'], bins=[0,30,60,90,180,365,9999], 
                   labels=['0-30','31-60','61-90','91-180','181-365','365+'], right=True)
print(accts.groupby(dpd_bins, observed=True).size().to_string())

print(f"\nTimezone distribution:")
print(accts['timezone'].value_counts(dropna=False).to_string())
print(f"\nSchema version distribution:")
print(accts['schema_version'].value_counts(dropna=False).to_string())

print(f"\nOutstanding amount stats:")
print(f"  Total: ₹{accts['outstanding_amount'].sum():,.0f}")
print(f"  Mean: ₹{accts['outstanding_amount'].mean():,.0f}")
print(f"  Median: ₹{accts['outstanding_amount'].median():,.0f}")

# ── Disposition code analysis ──────────────────────────────────
print(f"\n{'='*70}")
print("DISPOSITION CODE ANALYSIS")
print(f"{'='*70}")

disps = tables['call_dispositions']
print(f"\nDisposition code distribution:")
print(disps['disposition_code'].value_counts().to_string())
print(f"\nDisposition version distribution:")
print(disps['disposition_version'].value_counts(dropna=False).to_string())

# Cross-tab: disposition_code by disposition_version
print(f"\nDisposition codes by version:")
ct = pd.crosstab(disps['disposition_code'], disps['disposition_version'])
print(ct.to_string())

# ── Call status distribution ───────────────────────────────────
print(f"\n{'='*70}")
print("CALL STATUS ANALYSIS")
print(f"{'='*70}")
calls = tables['calls']
print(calls['call_status'].value_counts().to_string())
print(f"\nCall direction:")
print(calls['direction'].value_counts().to_string())
print(f"\nDuration stats (seconds):")
dur = calls['duration_sec'].dropna()
print(f"  min={dur.min()}, median={dur.median():.0f}, mean={dur.mean():.0f}, max={dur.max()}")

# ── WhatsApp & SMS event types ─────────────────────────────────
print(f"\n{'='*70}")
print("DIGITAL CHANNEL ANALYSIS")
print(f"{'='*70}")
wa = tables['whatsapp_events']
print(f"\nWhatsApp event types:")
print(wa['event_type'].value_counts().to_string())

sms = tables['sms_events']
print(f"\nSMS event types:")
print(sms['event_type'].value_counts().to_string())

# ── Field visits ───────────────────────────────────────────────
print(f"\n{'='*70}")
print("FIELD VISIT ANALYSIS")
print(f"{'='*70}")
fv = tables['field_visits']
print(f"\nVisit type:")
print(fv['visit_type'].value_counts().to_string())
print(f"\nVisit outcome:")
print(fv['outcome'].value_counts().to_string())

# ── Promises to Pay ────────────────────────────────────────────
print(f"\n{'='*70}")
print("PTP ANALYSIS")
print(f"{'='*70}")
ptp = tables['promises_to_pay']
print(f"\nPTP status:")
print(ptp['status'].value_counts().to_string())
print(f"\nPTP source:")
print(ptp['source'].value_counts().to_string())
print(f"\nPromised amount stats:")
pa = ptp['promised_amount'].dropna()
print(f"  min=₹{pa.min():,.0f}, median=₹{pa.median():,.0f}, mean=₹{pa.mean():,.0f}, max=₹{pa.max():,.0f}")

# ── Complaints ─────────────────────────────────────────────────
print(f"\n{'='*70}")
print("COMPLAINTS ANALYSIS")
print(f"{'='*70}")
comp = tables['complaints']
print(f"\nComplaint type:")
print(comp['complaint_type'].value_counts().to_string())
print(f"\nSeverity:")
print(comp['severity'].value_counts().to_string())
print(f"\nStatus:")
print(comp['status'].value_counts().to_string())

# ── Account Status History ─────────────────────────────────────
print(f"\n{'='*70}")
print("ACCOUNT STATUS HISTORY")
print(f"{'='*70}")
ash = tables['account_status_history']
print(f"\nStatus values:")
print(ash['status'].value_counts().to_string())
print(f"\nChanged by:")
print(ash['changed_by'].value_counts().head(10).to_string())
print(f"\nSource:")
print(ash['source'].value_counts().to_string())

# Check for event_at vs recorded_at discrepancy
ash['event_at'] = pd.to_datetime(ash['event_at'], errors='coerce')
ash['recorded_at'] = pd.to_datetime(ash['recorded_at'], errors='coerce')
both = ash.dropna(subset=['event_at', 'recorded_at'])
late = (both['recorded_at'] - both['event_at']).dt.total_seconds()
late_arriving = (late > 3600).sum()  # More than 1 hour late
print(f"\nLate-arriving events (recorded >1h after event): {late_arriving:,} ({late_arriving/len(both)*100:.1f}%)")

# ── Borrower geography ─────────────────────────────────────────
print(f"\n{'='*70}")
print("BORROWER GEOGRAPHY")
print(f"{'='*70}")
brw = tables['borrowers']
print(f"\nTop 15 states:")
print(brw['state'].value_counts().head(15).to_string())
print(f"\nTop 15 cities:")
print(brw['city'].value_counts().head(15).to_string())

print(f"\n{'='*70}")
print("DATA PROFILING COMPLETE")
print(f"{'='*70}")
