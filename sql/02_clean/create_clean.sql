-- =============================================================
-- Clean Layer: Apply deduplication and data quality rules
-- =============================================================

-- 01. clean_borrowers (deduplicated)
CREATE TABLE IF NOT EXISTS clean.borrowers AS
SELECT *
FROM staging.borrowers
WHERE row_rank = 1;
-- Result: 11,015 rows (from 30,600 raw)
-- Rule: Keep latest record per borrower_id

-- 02. clean_accounts (no dedup needed, PKs are unique)
CREATE TABLE IF NOT EXISTS clean.accounts AS
SELECT * FROM staging.accounts;

-- 03. clean_agents (deduplicated to canonical identity)
CREATE TABLE IF NOT EXISTS clean.agents AS
SELECT *
FROM staging.agents
WHERE row_rank = 1;
-- Result: 1,000 rows (from 30,000 raw)
-- Rule: Keep latest record per agent_id

-- 04. clean_payments (CRITICAL: multi-level deduplication)
-- Step 1: Remove PK duplicates (keep latest event)
-- Step 2: For SUCCESS payments with same reference, keep first only
CREATE TABLE IF NOT EXISTS clean.payments AS
WITH pk_deduped AS (
    SELECT *
    FROM staging.payments
    WHERE pk_rank = 1
),
success_deduped AS (
    -- For SUCCESS status, keep only first per payment_reference
    SELECT *
    FROM pk_deduped
    WHERE payment_status = 'SUCCESS'
      AND ref_rank = 1
),
non_success AS (
    SELECT *
    FROM pk_deduped
    WHERE payment_status != 'SUCCESS'
)
SELECT * FROM success_deduped
UNION ALL
SELECT * FROM non_success;
-- IMPACT: Raw SUCCESS ₹1,341M → Clean SUCCESS ₹1,150M (14.3% reduction)

-- 05. clean_calls (deduplicated + timezone normalized)
CREATE TABLE IF NOT EXISTS clean.calls AS
SELECT *
FROM staging.calls
WHERE pk_rank = 1;

-- 06. clean_call_dispositions
CREATE TABLE IF NOT EXISTS clean.call_dispositions AS
SELECT *
FROM staging.call_dispositions
WHERE pk_rank = 1;
