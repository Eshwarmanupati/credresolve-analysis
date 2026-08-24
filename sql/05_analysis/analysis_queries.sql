-- =============================================================
-- Analysis Layer: Driver analysis, counterfactual, and investigation queries
-- =============================================================

-- 01. Recovery by DPD bucket and period
CREATE VIEW IF NOT EXISTS analysis.recovery_by_dpd AS
SELECT
    a.dpd_bucket,
    CASE 
        WHEN DATE_TRUNC('month', p.event_at) < '2026-04-01' THEN 'EARLY'
        ELSE 'LATE'
    END AS period,
    COUNT(DISTINCT p.account_id) AS recovered_accounts,
    SUM(p.amount) AS total_recovered,
    AVG(p.amount) AS avg_recovered
FROM clean.payments p
JOIN clean.accounts a ON p.account_id = a.account_id
WHERE p.payment_status = 'SUCCESS'
GROUP BY 1, 2
ORDER BY 1, 2;

-- 02. Recovery by risk segment and period
CREATE VIEW IF NOT EXISTS analysis.recovery_by_risk AS
SELECT
    a.risk_segment,
    CASE 
        WHEN DATE_TRUNC('month', p.event_at) < '2026-04-01' THEN 'EARLY'
        ELSE 'LATE'
    END AS period,
    COUNT(DISTINCT p.account_id) AS recovered_accounts,
    SUM(p.amount) AS total_recovered
FROM clean.payments p
JOIN clean.accounts a ON p.account_id = a.account_id
WHERE p.payment_status = 'SUCCESS'
GROUP BY 1, 2
ORDER BY 1, 2;

-- 03. Portfolio mix shift analysis
-- Shows how the targeting population composition changed over time
CREATE VIEW IF NOT EXISTS analysis.portfolio_mix_shift AS
SELECT
    DATE_TRUNC('month', dt.target_date) AS month,
    a.dpd_bucket,
    a.risk_segment,
    COUNT(DISTINCT dt.account_id) AS targeted_accounts,
    COUNT(DISTINCT dt.account_id)::FLOAT / 
        SUM(COUNT(DISTINCT dt.account_id)) OVER (
            PARTITION BY DATE_TRUNC('month', dt.target_date)
        ) * 100 AS pct_of_month
FROM raw.daily_targeting dt
JOIN clean.accounts a ON dt.account_id = a.account_id
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

-- 04. Counterfactual: Treatment vs Control by strategy version
CREATE VIEW IF NOT EXISTS analysis.counterfactual_strategy AS
WITH account_strategy AS (
    SELECT
        dt.account_id,
        MAX(CASE WHEN c.strategy_version IN ('v2', 'v3') THEN 1 ELSE 0 END) AS ever_new_strategy,
        COUNT(*) AS targeting_count
    FROM raw.daily_targeting dt
    JOIN raw.campaigns c ON dt.campaign_id = c.campaign_id
    GROUP BY 1
),
account_recovery AS (
    SELECT
        account_id,
        SUM(amount) AS total_recovered,
        COUNT(*) AS payment_count
    FROM clean.payments
    WHERE payment_status = 'SUCCESS'
    GROUP BY 1
)
SELECT
    s.ever_new_strategy,
    COUNT(DISTINCT s.account_id) AS accounts,
    COUNT(DISTINCT r.account_id) AS paid_accounts,
    COUNT(DISTINCT r.account_id)::FLOAT / COUNT(DISTINCT s.account_id) AS recovery_rate,
    COALESCE(SUM(r.total_recovered), 0) AS total_recovered,
    COALESCE(AVG(r.total_recovered), 0) AS avg_recovered,
    -- Account characteristics
    AVG(a.dpd) AS avg_dpd,
    AVG(a.outstanding_amount) AS avg_outstanding
FROM account_strategy s
LEFT JOIN account_recovery r ON s.account_id = r.account_id
LEFT JOIN clean.accounts a ON s.account_id = a.account_id
GROUP BY 1;

-- 05. Denominator manipulation detection
-- Tracks which accounts enter/leave the targeting population
CREATE VIEW IF NOT EXISTS analysis.targeting_churn AS
WITH monthly_targeting AS (
    SELECT
        DATE_TRUNC('month', target_date) AS month,
        account_id
    FROM raw.daily_targeting
    GROUP BY 1, 2
),
targeting_pairs AS (
    SELECT
        t1.month AS month_from,
        t2.month AS month_to,
        COUNT(DISTINCT t1.account_id) AS accounts_from,
        COUNT(DISTINCT t2.account_id) AS accounts_to,
        COUNT(DISTINCT CASE WHEN t2.account_id IS NOT NULL THEN t1.account_id END) AS continued,
        COUNT(DISTINCT CASE WHEN t2.account_id IS NULL THEN t1.account_id END) AS dropped,
        COUNT(DISTINCT CASE WHEN t1.account_id IS NULL THEN t2.account_id END) AS added
    FROM monthly_targeting t1
    FULL OUTER JOIN monthly_targeting t2 
        ON t1.account_id = t2.account_id 
        AND t2.month = t1.month + INTERVAL '1 month'
    WHERE t1.month IS NOT NULL
    GROUP BY 1, 2
)
SELECT * FROM targeting_pairs
ORDER BY month_from;

-- 06. Agent performance by tenure
CREATE VIEW IF NOT EXISTS analysis.agent_performance AS
SELECT
    CASE
        WHEN ag.tenure_days <= 90 THEN '0-90d'
        WHEN ag.tenure_days <= 180 THEN '91-180d'
        WHEN ag.tenure_days <= 365 THEN '181-365d'
        ELSE '365d+'
    END AS tenure_bucket,
    COUNT(*) AS total_calls,
    COUNT(CASE WHEN c.call_status = 'ANSWERED' THEN 1 END) AS answered_calls,
    COUNT(CASE WHEN c.call_status = 'ANSWERED' THEN 1 END)::FLOAT / 
        NULLIF(COUNT(*), 0) AS answer_rate,
    COUNT(DISTINCT c.agent_id) AS unique_agents
FROM clean.calls c
JOIN clean.agents ag ON c.agent_id = ag.agent_id
GROUP BY 1
ORDER BY 1;

-- 07. Calling hour effectiveness
CREATE VIEW IF NOT EXISTS analysis.calling_hour_effectiveness AS
SELECT
    EXTRACT(HOUR FROM event_at_ist) AS hour_ist,
    COUNT(*) AS total_calls,
    COUNT(CASE WHEN call_status = 'ANSWERED' THEN 1 END) AS answered,
    COUNT(CASE WHEN call_status = 'ANSWERED' THEN 1 END)::FLOAT / 
        NULLIF(COUNT(*), 0) AS answer_rate,
    AVG(duration_sec) AS avg_duration
FROM clean.calls
GROUP BY 1
ORDER BY 1;
