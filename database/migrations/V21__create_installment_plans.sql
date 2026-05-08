-- V21__create_installment_plans.sql
-- New installment system: installment_plans + installment_payments.
-- The legacy card_installments table is kept intact during migration (Fase 3).

CREATE TABLE installment_plans (
    id                         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id                UUID REFERENCES categories(id) ON DELETE SET NULL,

    description                TEXT NOT NULL,
    store_name                 TEXT,
    purchase_date              DATE NOT NULL,

    total_amount               NUMERIC(12,2) NOT NULL CHECK (total_amount > 0),
    num_installments           INT NOT NULL CHECK (num_installments >= 2),
    installment_amount         NUMERIC(12,2) NOT NULL,

    payment_method             TEXT NOT NULL,

    first_due_date             DATE NOT NULL,

    status                     TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'completed', 'cancelled', 'paused')),

    -- Link to the original purchase expense (bigint to match expenses.id)
    original_expense_id        BIGINT REFERENCES expenses(id) ON DELETE SET NULL,

    -- Backward compat: reference to legacy card_installments row
    legacy_card_installment_id BIGINT,

    created_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE installment_payments (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id          UUID NOT NULL REFERENCES installment_plans(id) ON DELETE CASCADE,
    user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    installment_num  INT NOT NULL CHECK (installment_num >= 1),
    due_date         DATE NOT NULL,
    amount           NUMERIC(12,2) NOT NULL,

    status           TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'paid', 'overdue', 'skipped')),
    paid_date        DATE,
    paid_amount      NUMERIC(12,2),

    -- Link to the real expense created when paying (bigint to match expenses.id)
    expense_id       BIGINT REFERENCES expenses(id) ON DELETE SET NULL,

    financial_period_start  DATE,
    financial_period_end    DATE,

    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (plan_id, installment_num)
);

-- Indexes for ForecastingEngine queries
CREATE INDEX idx_installment_payments_pending
    ON installment_payments(user_id, due_date)
    WHERE status = 'pending';

CREATE INDEX idx_installment_payments_period
    ON installment_payments(user_id, financial_period_start, financial_period_end);

CREATE INDEX idx_installment_plans_user_status
    ON installment_plans(user_id, status);

-- RLS
ALTER TABLE installment_plans    ENABLE ROW LEVEL SECURITY;
ALTER TABLE installment_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_own_installment_plans" ON installment_plans
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "users_own_installment_payments" ON installment_payments
    FOR ALL USING (auth.uid() = user_id);
