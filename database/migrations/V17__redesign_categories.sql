-- V17__redesign_categories.sql
-- Redesign categories table: integer id → UUID, db_value → slug,
-- add financial_type, parent_id, color_hex, is_fixed, is_archived, display_order.
-- System categories seeded globally (user_id NULL).

-- Drop existing table and dependent objects (RLS policies dropped automatically)
DROP TABLE IF EXISTS categories CASCADE;

CREATE TABLE categories (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    parent_id      UUID REFERENCES categories(id) ON DELETE SET NULL,
    slug           TEXT NOT NULL,
    name           TEXT NOT NULL,
    emoji          TEXT NOT NULL DEFAULT '📋',
    color_hex      TEXT,
    financial_type TEXT NOT NULL DEFAULT 'want'
        CHECK (financial_type IN ('need', 'want', 'investment', 'income', 'transfer')),
    is_system      BOOLEAN NOT NULL DEFAULT FALSE,
    is_swile       BOOLEAN NOT NULL DEFAULT FALSE,
    is_fixed       BOOLEAN NOT NULL DEFAULT FALSE,
    is_archived    BOOLEAN NOT NULL DEFAULT FALSE,
    display_order  INT NOT NULL DEFAULT 0,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, slug)
);

-- RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_own_categories" ON categories
    FOR ALL USING (auth.uid() = user_id OR user_id IS NULL);

-- Seed system categories (user_id NULL = global, visible to all users)
INSERT INTO categories (slug, name, emoji, financial_type, is_system, is_swile, display_order) VALUES
    ('housing',           'Moradia',         '🏠', 'need', TRUE, FALSE, 0),
    ('transport',         'Transporte',      '🚗', 'need', TRUE, FALSE, 1),
    ('food_grocery',      'Alimentação',     '🛒', 'need', TRUE, TRUE,  2),
    ('health',            'Saúde',           '🏥', 'need', TRUE, FALSE, 3),
    ('subscriptions',     'Assinaturas',     '📱', 'want', TRUE, FALSE, 4),
    ('leisure',           'Lazer',           '🎮', 'want', TRUE, FALSE, 5),
    ('education',         'Educação',        '📚', 'want', TRUE, FALSE, 6),
    ('card_installments', 'Parcelas Cartão', '💳', 'want', TRUE, FALSE, 7),
    ('other',             'Outros',          '📋', 'want', TRUE, FALSE, 8);
