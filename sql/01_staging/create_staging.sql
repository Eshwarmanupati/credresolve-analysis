-- =============================================================
-- Staging Layer: Load raw CSVs into structured tables
-- =============================================================
-- Assumes CSV files are loaded into raw schema tables first

-- 01. staging_borrowers
CREATE TABLE IF NOT EXISTS staging.borrowers AS
SELECT
    borrower_id,
    name,
    phone::BIGINT,
    email,
    city,
    created_at::TIMESTAMP,
    updated_at::TIMESTAMP,
    state,
    -- Data quality flags
    CASE WHEN updated_at < created_at THEN TRUE ELSE FALSE END AS flag_backward_dates,
    CASE WHEN phone IS NULL THEN TRUE ELSE FALSE END AS flag_missing_phone,
    CASE WHEN email IS NULL THEN TRUE ELSE FALSE END AS flag_missing_email,
    ROW_NUMBER() OVER (
        PARTITION BY borrower_id 
        ORDER BY updated_at DESC NULLS LAST
    ) AS row_rank
FROM raw.borrowers;

-- 02. staging_accounts
CREATE TABLE IF NOT EXISTS staging.accounts AS
SELECT
    account_id,
    borrower_id,
    loan_type,
    principal_amount,
    outstanding_amount,
    dpd,
    risk_segment,
    status,
    opened_at::TIMESTAMP,
    timezone,
    schema_version,
    -- DPD bucket for analysis
    CASE 
        WHEN dpd <= 30 THEN '0-30'
        WHEN dpd <= 60 THEN '31-60'
        WHEN dpd <= 90 THEN '61-90'
        WHEN dpd <= 180 THEN '91-180'
        ELSE '180+'
    END AS dpd_bucket,
    -- Data quality flags
    CASE WHEN borrower_id IS NULL THEN TRUE ELSE FALSE END AS flag_missing_borrower
FROM raw.accounts;

-- 03. staging_agents
CREATE TABLE IF NOT EXISTS staging.agents AS
SELECT
    agent_id,
    employee_code,
    agent_name,
    vendor_id,
    team,
    status,
    joined_at::TIMESTAMP,
    updated_at::TIMESTAMP,
    -- Tenure calculation
    EXTRACT(DAY FROM updated_at::TIMESTAMP - joined_at::TIMESTAMP) AS tenure_days,
    -- Dedup rank: keep latest record per agent_id
    ROW_NUMBER() OVER (
        PARTITION BY agent_id 
        ORDER BY updated_at DESC NULLS LAST
    ) AS row_rank
FROM raw.agents;

-- 04. staging_payments
CREATE TABLE IF NOT EXISTS staging.payments AS
SELECT
    payment_id,
    account_id,
    borrower_id,
    event_at::TIMESTAMP,
    payment_reference,
    amount,
    payment_status,
    payment_method,
    provider_id,
    -- Duplicate detection flags
    ROW_NUMBER() OVER (
        PARTITION BY payment_id 
        ORDER BY event_at DESC
    ) AS pk_rank,
    ROW_NUMBER() OVER (
        PARTITION BY payment_reference, payment_status 
        ORDER BY event_at ASC
    ) AS ref_rank,
    -- Lag for near-duplicate detection
    LAG(event_at::TIMESTAMP) OVER (
        PARTITION BY account_id, amount 
        ORDER BY event_at
    ) AS prev_same_amount_event,
    EXTRACT(EPOCH FROM (
        event_at::TIMESTAMP - LAG(event_at::TIMESTAMP) OVER (
            PARTITION BY account_id, amount 
            ORDER BY event_at
        )
    )) / 3600.0 AS hours_since_prev_same_amount
FROM raw.payments;

-- 05. staging_calls
CREATE TABLE IF NOT EXISTS staging.calls AS
SELECT
    call_id,
    account_id,
    borrower_id,
    event_at::TIMESTAMP,
    agent_id,
    campaign_id,
    direction,
    vendor_id,
    call_status,
    duration_sec,
    timezone,
    -- Timezone normalization to IST
    CASE timezone
        WHEN 'UTC' THEN event_at::TIMESTAMP + INTERVAL '5 hours 30 minutes'
        WHEN 'Asia/Dubai' THEN event_at::TIMESTAMP + INTERVAL '1 hour 30 minutes'
        WHEN 'Asia/Kolkata' THEN event_at::TIMESTAMP
        ELSE event_at::TIMESTAMP
    END AS event_at_ist,
    -- Dedup
    ROW_NUMBER() OVER (
        PARTITION BY call_id 
        ORDER BY event_at DESC
    ) AS pk_rank
FROM raw.calls;

-- 06. staging_call_dispositions
CREATE TABLE IF NOT EXISTS staging.call_dispositions AS
SELECT
    disposition_id,
    account_id,
    borrower_id,
    event_at::TIMESTAMP,
    call_id,
    agent_id,
    disposition_code,
    disposition_version,
    -- Harmonize codes
    CASE 
        WHEN disposition_code = 'PROMISE_TO_PAY' THEN 'PTP'
        ELSE disposition_code
    END AS disposition_code_clean,
    -- Dedup
    ROW_NUMBER() OVER (
        PARTITION BY disposition_id 
        ORDER BY event_at DESC
    ) AS pk_rank
FROM raw.call_dispositions;
