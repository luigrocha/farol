-- V20__expenses_category_id_not_null.sql
-- Makes category_id NOT NULL in expenses.
--
-- PRE-CONDITIONS (verify before running):
--   1. V19 backfill has been executed and verified.
--   2. No NULL category_id rows remain in production:
--        SELECT COUNT(*) FROM expenses WHERE category_id IS NULL;
--      Must return 0.
--   3. App version with V17-V19 has been stable in production for ≥2 weeks.
--
-- If any NULLs remain, run the backfill again first:
--   UPDATE expenses e SET category_id = (
--     SELECT c.id FROM categories c
--     WHERE LOWER(e.category) = c.slug
--       AND (c.user_id = e.user_id OR c.user_id IS NULL)
--     ORDER BY (c.user_id IS NOT NULL) DESC LIMIT 1
--   ) WHERE e.category_id IS NULL;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM expenses WHERE category_id IS NULL) THEN
    RAISE EXCEPTION 'Aborting: expenses still have NULL category_id. Run V19 backfill first.';
  END IF;
END $$;

ALTER TABLE expenses ALTER COLUMN category_id SET NOT NULL;
