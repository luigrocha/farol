ALTER TABLE net_worth_snapshots
  ADD COLUMN IF NOT EXISTS patrimony_total decimal(12,2) NOT NULL DEFAULT 0;

ALTER TABLE user_preferences
  ADD COLUMN IF NOT EXISTS privacy_mode boolean NOT NULL DEFAULT false;
