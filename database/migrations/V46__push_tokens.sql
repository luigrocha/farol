-- V46: push_tokens table
--
-- Stores FCM device tokens per user per platform.
-- Used by the send-space-notification Edge Function to fan out push
-- notifications to all space members when activity occurs.
--
-- One row per (user_id, platform) — upserted by the Flutter app on startup.

-- ═══════════════════════════════════════════════════════════════
-- Table
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS push_tokens (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token      TEXT        NOT NULL,
  platform   TEXT        NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, platform)
);

CREATE INDEX IF NOT EXISTS idx_push_tokens_user
  ON push_tokens(user_id);

-- ═══════════════════════════════════════════════════════════════
-- RLS
-- ═══════════════════════════════════════════════════════════════

ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;

-- Users can read, insert, update, delete only their own tokens.
CREATE POLICY "users_manage_own_push_tokens"
  ON push_tokens FOR ALL
  USING     (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Service role (used by Edge Functions) bypasses RLS — no extra policy needed.

-- ═══════════════════════════════════════════════════════════════
-- Smoke-test queries (run manually after applying)
-- ═══════════════════════════════════════════════════════════════
-- SELECT table_name FROM information_schema.tables
--   WHERE table_schema = 'public' AND table_name = 'push_tokens';
-- → 1 row
--
-- SELECT column_name, data_type FROM information_schema.columns
--   WHERE table_name = 'push_tokens'
--   ORDER BY ordinal_position;
-- → id, user_id, token, platform, updated_at
