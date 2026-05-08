-- V23__migrate_card_installments.sql
-- Migrates legacy card_installments → installment_plans + installment_payments.
--
-- Strategy:
--   • first_due_date estimated as purchase_date + 1 month (field didn't exist)
--   • Installments 1..current_installment → status='paid' (no linked expense, no paid_date)
--   • Installments current+1..num_installments → status='pending'
--   • Rounding: FLOOR to cents for all but last; last absorbs the remainder
--   • Settled/cancelled card_installments → status='completed'/'cancelled' in plan
--   • legacy_card_installment_id preserved for traceability

-- ── Step 1: Create installment_plans from card_installments ─────────────────

INSERT INTO installment_plans (
    user_id,
    description,
    purchase_date,
    total_amount,
    num_installments,
    installment_amount,
    payment_method,
    first_due_date,
    status,
    legacy_card_installment_id,
    created_at,
    updated_at
)
SELECT
    user_id,
    description,
    purchase_date::date,
    total_value,
    num_installments,
    -- Base installment amount (floored to cents)
    FLOOR(total_value / num_installments * 100) / 100.0,
    'CREDIT_CARD',  -- legacy table had no payment_method
    -- Estimate first due date: one month after purchase
    (purchase_date + INTERVAL '1 month')::date,
    CASE status
        WHEN 'Settled'   THEN 'completed'
        WHEN 'Cancelled' THEN 'cancelled'
        ELSE 'active'
    END,
    id,
    created_at,
    NOW()
FROM card_installments;

-- ── Step 2: Generate installment_payments for each migrated plan ─────────────
-- Uses a generate_series to expand each plan into N payment rows.

INSERT INTO installment_payments (
    plan_id,
    user_id,
    installment_num,
    due_date,
    amount,
    status,
    created_at,
    updated_at
)
SELECT
    p.id                    AS plan_id,
    p.user_id,
    s.num                   AS installment_num,
    -- due_date: first_due_date + (num - 1) months, day clamped to month end
    (
        DATE_TRUNC('month', p.first_due_date + ((s.num - 1) || ' months')::INTERVAL)
        + (LEAST(
            EXTRACT(DAY FROM p.first_due_date)::INT,
            EXTRACT(DAY FROM (
                DATE_TRUNC('month', p.first_due_date + (s.num || ' months')::INTERVAL)
                - INTERVAL '1 day'
            ))::INT
          ) - 1) * INTERVAL '1 day'
    )::date                 AS due_date,
    -- Last installment absorbs rounding remainder
    CASE
        WHEN s.num = p.num_installments
        THEN ROUND(
            (p.total_amount - p.installment_amount * (p.num_installments - 1))::NUMERIC,
            2
        )
        ELSE p.installment_amount
    END                     AS amount,
    -- Installments up to current_installment are already paid
    CASE
        WHEN s.num <= ci.current_installment THEN 'paid'
        ELSE 'pending'
    END                     AS status,
    p.created_at,
    NOW()
FROM installment_plans p
JOIN card_installments ci ON ci.id = p.legacy_card_installment_id
CROSS JOIN LATERAL generate_series(1, p.num_installments) AS s(num)
WHERE p.legacy_card_installment_id IS NOT NULL;

-- ── Step 3: Verification ─────────────────────────────────────────────────────
-- Run these queries manually after migration to validate:
--
-- 1. Count match:
--    SELECT COUNT(*) FROM card_installments;               -- should equal
--    SELECT COUNT(*) FROM installment_plans
--      WHERE legacy_card_installment_id IS NOT NULL;
--
-- 2. Payment counts per plan:
--    SELECT p.description, p.num_installments,
--           COUNT(ip.id) AS payment_rows
--    FROM installment_plans p
--    LEFT JOIN installment_payments ip ON ip.plan_id = p.id
--    WHERE p.legacy_card_installment_id IS NOT NULL
--    GROUP BY p.id, p.description, p.num_installments
--    HAVING COUNT(ip.id) != p.num_installments;
--    -- Must return 0 rows
--
-- 3. Rounding check (sum of payments == total_amount):
--    SELECT p.description, p.total_amount,
--           SUM(ip.amount) AS payments_sum,
--           ABS(p.total_amount - SUM(ip.amount)) AS diff
--    FROM installment_plans p
--    JOIN installment_payments ip ON ip.plan_id = p.id
--    WHERE p.legacy_card_installment_id IS NOT NULL
--    GROUP BY p.id, p.description, p.total_amount
--    HAVING ABS(p.total_amount - SUM(ip.amount)) > 0.01;
--    -- Must return 0 rows
