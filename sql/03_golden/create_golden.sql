-- =============================================================
-- Golden Layer: Analytical-ready joined tables
-- =============================================================

-- 01. golden_payments_enriched
-- Payments joined with account attributes and borrower geography
CREATE TABLE IF NOT EXISTS golden.payments_enriched AS
SELECT
    p.payment_id,
    p.account_id,
    p.borrower_id,
    p.event_at,
    p.payment_reference,
    p.amount,
    p.payment_status,
    p.payment_method,
    p.provider_id,
    DATE_TRUNC('month', p.event_at) AS payment_month,
    a.loan_type,
    a.dpd,
    a.dpd_bucket,
    a.risk_segment,
    a.outstanding_amount,
    a.status AS account_status,
    b.city,
    b.state
FROM clean.payments p
LEFT JOIN clean.accounts a ON p.account_id = a.account_id
LEFT JOIN clean.borrowers b ON p.borrower_id = b.borrower_id;

-- 02. golden_calls_enriched
-- Calls joined with agent metadata, campaign info
CREATE TABLE IF NOT EXISTS golden.calls_enriched AS
SELECT
    c.call_id,
    c.account_id,
    c.event_at,
    c.event_at_ist,
    EXTRACT(HOUR FROM c.event_at_ist) AS hour_ist,
    DATE_TRUNC('month', c.event_at_ist) AS call_month,
    c.agent_id,
    c.campaign_id,
    c.direction,
    c.vendor_id,
    c.call_status,
    c.duration_sec,
    c.timezone AS call_timezone,
    ag.employee_code,
    ag.team,
    ag.tenure_days,
    ag.agent_name,
    camp.campaign_name,
    camp.strategy_version,
    camp.channel AS campaign_channel,
    camp.target_definition,
    a.dpd,
    a.dpd_bucket,
    a.risk_segment,
    a.loan_type,
    vt.vendor_name,
    vt.timezone AS vendor_timezone
FROM clean.calls c
LEFT JOIN clean.agents ag ON c.agent_id = ag.agent_id
LEFT JOIN clean.accounts a ON c.account_id = a.account_id
LEFT JOIN raw.campaigns camp ON c.campaign_id = camp.campaign_id
LEFT JOIN raw.vendor_telephony vt ON c.vendor_id = vt.vendor_id;

-- 03. golden_monthly_targeting
-- Monthly targeting population for denominator calculations
CREATE TABLE IF NOT EXISTS golden.monthly_targeting AS
SELECT
    DATE_TRUNC('month', dt.target_date) AS month,
    COUNT(DISTINCT dt.account_id) AS targeted_accounts,
    COUNT(*) AS total_targets,
    COUNT(DISTINCT dt.campaign_id) AS campaigns_active,
    a.dpd_bucket,
    a.risk_segment,
    a.loan_type
FROM raw.daily_targeting dt
LEFT JOIN clean.accounts a ON dt.account_id = a.account_id
GROUP BY 1, 5, 6, 7;

-- 04. golden_recovery_funnel
-- Monthly funnel: targeted → contacted → PTP → paid
CREATE TABLE IF NOT EXISTS golden.recovery_funnel AS
WITH monthly_targeted AS (
    SELECT
        DATE_TRUNC('month', target_date) AS month,
        COUNT(DISTINCT account_id) AS targeted_accounts
    FROM raw.daily_targeting
    GROUP BY 1
),
monthly_contacted AS (
    SELECT
        DATE_TRUNC('month', event_at_ist) AS month,
        COUNT(DISTINCT account_id) AS contacted_accounts
    FROM clean.calls
    WHERE call_status = 'ANSWERED'
    GROUP BY 1
),
monthly_ptp AS (
    SELECT
        DATE_TRUNC('month', event_at) AS month,
        COUNT(DISTINCT account_id) AS ptp_accounts
    FROM raw.promises_to_pay
    GROUP BY 1
),
monthly_paid AS (
    SELECT
        DATE_TRUNC('month', event_at) AS month,
        COUNT(DISTINCT account_id) AS paid_accounts,
        SUM(amount) AS recovered_amount
    FROM clean.payments
    WHERE payment_status = 'SUCCESS'
    GROUP BY 1
)
SELECT
    t.month,
    t.targeted_accounts,
    c.contacted_accounts,
    p.ptp_accounts,
    pd.paid_accounts,
    pd.recovered_amount,
    -- Rates
    c.contacted_accounts::FLOAT / NULLIF(t.targeted_accounts, 0) AS contact_rate,
    p.ptp_accounts::FLOAT / NULLIF(c.contacted_accounts, 0) AS ptp_rate,
    pd.paid_accounts::FLOAT / NULLIF(t.targeted_accounts, 0) AS recovery_rate,
    pd.recovered_amount / NULLIF(t.targeted_accounts, 0) AS recovery_per_account
FROM monthly_targeted t
LEFT JOIN monthly_contacted c ON t.month = c.month
LEFT JOIN monthly_ptp p ON t.month = p.month
LEFT JOIN monthly_paid pd ON t.month = pd.month
ORDER BY t.month;
