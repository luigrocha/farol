-- V24__create_recurring_rules.sql
-- Creates recurring_rules and recurring_occurrences tables.
-- Replaces the isFixed+copy pattern with a proper recurrence engine.

-- ── recurring_rules ──────────────────────────────────────────────────────────

CREATE TABLE recurring_rules (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    category_id           UUID REFERENCES categories(id) ON DELETE SET NULL,
    category_slug         TEXT,

    -- Identity
    name                  TEXT NOT NULL,
    description           TEXT,

    -- Amount
    base_amount           NUMERIC(12,2) NOT NULL CHECK (base_amount > 0),
    amount_type           TEXT NOT NULL DEFAULT 'fixed'
                            CHECK (amount_type IN ('fixed', 'variable', 'range')),
    amount_min            NUMERIC(12,2),
    amount_max            NUMERIC(12,2),

    -- Frequency
    frequency             TEXT NOT NULL
                            CHECK (frequency IN (
                                'weekly', 'biweekly', 'monthly',
                                'quarterly', 'semiannual', 'yearly'
                            )),
    interval_count        INT NOT NULL DEFAULT 1 CHECK (interval_count >= 1),
    day_of_month          INT CHECK (day_of_month BETWEEN 1 AND 28),
    month_of_year         INT[],          -- e.g. {1, 7} for semiannual Jan+Jul

    -- Lifespan
    starts_on             DATE NOT NULL,
    ends_on               DATE,
    ends_after_n          INT CHECK (ends_after_n > 0),

    -- State
    status                TEXT NOT NULL DEFAULT 'active'
                            CHECK (status IN ('active', 'paused', 'cancelled')),
    paused_until          DATE,

    -- Payment
    payment_method        TEXT,

    -- Auto-detection metadata
    is_auto_detected      BOOLEAN NOT NULL DEFAULT FALSE,
    detection_confidence  NUMERIC(4,3) CHECK (detection_confidence BETWEEN 0 AND 1),

    -- Migration traceability
    legacy_expense_id     BIGINT REFERENCES expenses(id) ON DELETE SET NULL,

    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── recurring_occurrences ─────────────────────────────────────────────────────

CREATE TABLE recurring_occurrences (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_id           UUID REFERENCES recurring_rules(id) ON DELETE CASCADE NOT NULL,
    user_id           UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,

    scheduled_date    DATE NOT NULL,
    expected_amount   NUMERIC(12,2) NOT NULL,

    status            TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'paid', 'skipped', 'overridden')),
    paid_date         DATE,
    actual_amount     NUMERIC(12,2),

    -- bigint to match expenses.id PK type
    expense_id        BIGINT REFERENCES expenses(id) ON DELETE SET NULL,

    is_exception      BOOLEAN NOT NULL DEFAULT FALSE,
    exception_notes   TEXT,

    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (rule_id, scheduled_date)
);

-- ── Indexes ───────────────────────────────────────────────────────────────────

-- ObligationEngine: pending occurrences in a date range
CREATE INDEX idx_recurring_occurrences_pending
    ON recurring_occurrences (user_id, scheduled_date, status)
    WHERE status = 'pending';

-- Dashboard: active rules per user
CREATE INDEX idx_recurring_rules_active
    ON recurring_rules (user_id, status)
    WHERE status = 'active';

-- Lookup by category
CREATE INDEX idx_recurring_rules_category
    ON recurring_rules (user_id, category_slug);

-- ── RLS Policies ─────────────────────────────────────────────────────────────

ALTER TABLE recurring_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_own_recurring_rules"
    ON recurring_rules
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

ALTER TABLE recurring_occurrences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_own_recurring_occurrences"
    ON recurring_occurrences
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
