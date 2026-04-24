-- Add unique constraint on (user_id, category) for budget_goals upsert support
ALTER TABLE budget_goals
  ADD CONSTRAINT budget_goals_user_category_unique
  UNIQUE (user_id, category);
