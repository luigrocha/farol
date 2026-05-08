-- V19__backfill_category_id_in_expenses.sql
-- Populates category_id in expenses by matching the text 'category' column
-- against categories.slug (case-insensitive). System categories have user_id NULL.
-- User custom categories are matched by user_id first, then system fallback.

UPDATE expenses e
SET category_id = (
    -- Prefer user's own category, fall back to system category
    SELECT c.id
    FROM categories c
    WHERE LOWER(e.category) = c.slug
      AND (c.user_id = e.user_id OR c.user_id IS NULL)
    ORDER BY (c.user_id IS NOT NULL) DESC  -- user-owned preferred over system
    LIMIT 1
)
WHERE e.category_id IS NULL;

-- Verification query (run manually to confirm):
-- SELECT
--   COUNT(*) FILTER (WHERE category_id IS NOT NULL) AS backfilled,
--   COUNT(*) FILTER (WHERE category_id IS NULL)     AS still_null,
--   COUNT(*)                                         AS total
-- FROM expenses;
