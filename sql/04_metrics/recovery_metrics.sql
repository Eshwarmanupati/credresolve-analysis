-- ====================================================================
-- CREDRESOLVE COLLECTIONS ANALYTICS — RECOVERY METRICS SQL LAYER
-- ====================================================================
-- Provides standard views and aggregated recovery metrics matching Python pipeline.

DROP VIEW IF EXISTS v_monthly_recovery_metrics;

CREATE VIEW v_monthly_recovery_metrics AS
WITH monthly_targeting AS (
    SELECT 
        strftime('%Y-%m', target_date) AS month,
        COUNT(DISTINCT account_id) AS targeted_accounts
    FROM golden_daily_targeting
    WHERE strftime('%Y-%m', target_date) <= '2026-07'
    GROUP BY 1
),
monthly_calls AS (
    SELECT 
        strftime('%Y-%m', event_at_ist) AS month,
        COUNT(*) AS total_calls,
        COUNT(CASE WHEN call_status = 'ANSWERED' THEN 1 END) AS answered_calls,
        COUNT(DISTINCT account_id) AS accounts_called,
        COUNT(DISTINCT CASE WHEN call_status = 'ANSWERED' THEN account_id END) AS contacted_accounts
    FROM golden_calls
    WHERE strftime('%Y-%m', event_at_ist) <= '2026-07'
    GROUP BY 1
),
monthly_ptp AS (
    SELECT 
        strftime('%Y-%m', event_at) AS month,
        COUNT(*) AS ptp_count,
        COUNT(DISTINCT account_id) AS ptp_accounts
    FROM golden_promises_to_pay
    WHERE strftime('%Y-%m', event_at) <= '2026-07'
    GROUP BY 1
),
monthly_rpc AS (
    SELECT 
        strftime('%Y-%m', event_at) AS month,
        COUNT(DISTINCT account_id) AS rpc_accounts
    FROM golden_call_dispositions
    WHERE disposition_code IN ('PTP', 'PAID', 'CALLBACK', 'REFUSED', 'DISPUTE')
      AND strftime('%Y-%m', event_at) <= '2026-07'
    GROUP BY 1
),
monthly_payments AS (
    SELECT 
        strftime('%Y-%m', event_at) AS month,
        SUM(amount) AS recovered_amount,
        COUNT(DISTINCT account_id) AS recovered_accounts
    FROM golden_payments
    WHERE payment_status = 'SUCCESS'
      AND strftime('%Y-%m', event_at) <= '2026-07'
    GROUP BY 1
),
monthly_sessions AS (
    SELECT 
        strftime('%Y-%m', login_at) AS month,
        SUM((julianday(logout_at) - julianday(login_at)) * 24.0) AS agent_hours
    FROM golden_agent_sessions
    WHERE strftime('%Y-%m', login_at) <= '2026-07'
    GROUP BY 1
)
SELECT 
    t.month,
    t.targeted_accounts,
    c.total_calls,
    c.answered_calls,
    c.accounts_called,
    c.contacted_accounts,
    p.ptp_count,
    p.ptp_accounts,
    pay.recovered_amount,
    pay.recovered_accounts,
    ROUND(CAST(c.contacted_accounts AS FLOAT) / t.targeted_accounts, 4) AS contact_rate,
    ROUND(CAST(c.answered_calls AS FLOAT) / c.total_calls, 4) AS call_answer_rate,
    ROUND(CAST(r.rpc_accounts AS FLOAT) / c.accounts_called, 4) AS rpc_rate,
    ROUND(CAST(pay.recovered_accounts AS FLOAT) / t.targeted_accounts, 4) AS recovery_rate,
    ROUND(CAST(pay.recovered_amount AS FLOAT) / t.targeted_accounts, 2) AS recovery_per_account,
    ROUND(CAST(p.ptp_accounts AS FLOAT) / t.targeted_accounts, 4) AS ptp_rate_targeted,
    ROUND(CAST(p.ptp_accounts AS FLOAT) / c.accounts_called, 4) AS ptp_rate_called,
    s.agent_hours,
    ROUND(CAST(pay.recovered_amount AS FLOAT) / s.agent_hours, 2) AS recovery_per_agent_hour,
    ROUND((s.agent_hours * 250.0) / pay.recovered_amount, 4) AS cost_per_rupee_recovered
FROM monthly_targeting t
LEFT JOIN monthly_calls c ON t.month = c.month
LEFT JOIN monthly_ptp p ON t.month = p.month
LEFT JOIN monthly_rpc r ON t.month = r.month
LEFT JOIN monthly_payments pay ON t.month = pay.month
LEFT JOIN monthly_sessions s ON t.month = s.month
ORDER BY t.month;
