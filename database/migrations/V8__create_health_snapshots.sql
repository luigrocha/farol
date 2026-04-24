CREATE TABLE health_snapshots (
  id                    BIGSERIAL PRIMARY KEY,
  user_id               UUID REFERENCES auth.users(id) NOT NULL,
  month                 INT NOT NULL,
  year                  INT NOT NULL,
  score                 INT NOT NULL DEFAULT 0,
  savings_rate          DECIMAL(6,2) NOT NULL DEFAULT 0,
  housing_rate          DECIMAL(6,2) NOT NULL DEFAULT 0,
  monthly_balance       DECIMAL(12,2) NOT NULL DEFAULT 0,
  emergency_fund_months DECIMAL(6,2) NOT NULL DEFAULT 0,
  installments_rate     DECIMAL(6,2) NOT NULL DEFAULT 0,
  net_salary            DECIMAL(12,2) NOT NULL DEFAULT 0,
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, month, year)
);

ALTER TABLE health_snapshots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own health snapshots"
  ON health_snapshots FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
