-- V10: Period-based budget system
-- Adds cutoff_day to budget_settings and creates the period_budgets table with
-- an RPC that aggregates spending from expenses without N+1 queries.

-- ── 1. cutoff_day on budget_settings ─────────────────────────────────────────
ALTER TABLE budget_settings
  ADD COLUMN IF NOT EXISTS cutoff_day int NOT NULL DEFAULT 1
    CHECK (cutoff_day BETWEEN 1 AND 28);

-- ── 2. period_budgets ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS period_budgets (
  id           uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id      uuid        REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  category     text        NOT NULL,
  period_start date        NOT NULL,
  period_end   date        NOT NULL,
  amount       decimal(12,2) NOT NULL DEFAULT 0 CHECK (amount >= 0),
  created_at   timestamptz DEFAULT now() NOT NULL,
  updated_at   timestamptz DEFAULT now() NOT NULL,

  CONSTRAINT period_budgets_unique
    UNIQUE (user_id, category, period_start, period_end)
);

ALTER TABLE period_budgets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own period budgets"
  ON period_budgets FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_period_budgets_user_id
  ON period_budgets(user_id);

CREATE INDEX IF NOT EXISTS idx_period_budgets_period
  ON period_budgets(user_id, period_start, period_end);

-- ── 3. RPC: budgets + aggregated cash spending in one query ───────────────────
-- Returns every budget row for the period with the corresponding sum of
-- cash expenses (pay_type != 'Swile') whose transaction_date falls within
-- [p_period_start, p_period_end].  No N+1 – single GROUP BY scan.
CREATE OR REPLACE FUNCTION get_period_budgets_with_spending(
  p_user_id      uuid,
  p_period_start date,
  p_period_end   date
)
RETURNS TABLE (
  id           uuid,
  category     text,
  period_start date,
  period_end   date,
  amount       numeric,
  spent        numeric
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    b.id,
    b.category,
    b.period_start,
    b.period_end,
    b.amount,
    COALESCE(SUM(e.amount), 0) AS spent
  FROM period_budgets b
  LEFT JOIN expenses e
         ON e.user_id         = p_user_id
        AND e.category        = b.category
        AND e.pay_type       != 'Swile'
        AND e.transaction_date BETWEEN b.period_start AND b.period_end
  WHERE b.user_id      = p_user_id
    AND b.period_start = p_period_start
    AND b.period_end   = p_period_end
  GROUP BY b.id, b.category, b.period_start, b.period_end, b.amount
  ORDER BY b.category;
$$;

-- ── 4. RPC: copy budgets from a previous period (rollover helper) ─────────────
-- Inserts rows for the new period copying amounts from the previous one.
-- Uses ON CONFLICT DO NOTHING so existing budgets are never overwritten.
CREATE OR REPLACE FUNCTION copy_period_budgets(
  p_user_id       uuid,
  p_from_start    date,
  p_from_end      date,
  p_to_start      date,
  p_to_end        date
)
RETURNS int   -- number of rows copied
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count int;
BEGIN
  INSERT INTO period_budgets (user_id, category, period_start, period_end, amount)
  SELECT p_user_id, category, p_to_start, p_to_end, amount
  FROM   period_budgets
  WHERE  user_id      = p_user_id
    AND  period_start = p_from_start
    AND  period_end   = p_from_end
  ON CONFLICT (user_id, category, period_start, period_end) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;
