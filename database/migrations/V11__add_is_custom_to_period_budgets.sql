-- Add is_custom flag: TRUE when the user has manually overridden the
-- budget goal amount for a specific period. FALSE (default) means the
-- period budget was seeded from the parent goal without modification.

ALTER TABLE period_budgets
  ADD COLUMN is_custom boolean NOT NULL DEFAULT FALSE;

-- Update RPC to expose is_custom in the result set.
DROP FUNCTION IF EXISTS get_period_budgets_with_spending(uuid, date, date);

CREATE FUNCTION get_period_budgets_with_spending(
  p_user_id    uuid,
  p_period_start date,
  p_period_end   date
)
RETURNS TABLE (
  id           uuid,
  user_id      uuid,
  category     text,
  period_start date,
  period_end   date,
  amount       numeric,
  is_custom    boolean,
  created_at   timestamptz,
  updated_at   timestamptz,
  spent        numeric
)
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT
    pb.id,
    pb.user_id,
    pb.category,
    pb.period_start,
    pb.period_end,
    pb.amount,
    pb.is_custom,
    pb.created_at,
    pb.updated_at,
    COALESCE(SUM(e.amount), 0) AS spent
  FROM period_budgets pb
  LEFT JOIN expenses e
    ON e.user_id      = pb.user_id
   AND e.category     = pb.category
   AND e.transaction_date BETWEEN pb.period_start AND pb.period_end
   AND e.pay_type    != 'Swile'
  WHERE pb.user_id      = p_user_id
    AND pb.period_start = p_period_start
    AND pb.period_end   = p_period_end
  GROUP BY pb.id;
$$;
