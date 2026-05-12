-- V39: Seed system subcategories
-- Migrates the hardcoded _subcategories map from the Flutter sheets into the DB.
-- All rows are system-owned (user_id NULL, is_system TRUE).
--
-- workspace_id: system categories (user_id IS NULL) have a workspace_id assigned
-- by V29 (the first workspace in the DB at migration time). Subcategories inherit
-- workspace_id directly from their parent category — no hardcoding needed.
--
-- Idempotency: uses INSERT ... WHERE NOT EXISTS (slug + parent_id) because
-- the UNIQUE (user_id, slug) constraint treats NULL != NULL in Postgres, so
-- ON CONFLICT DO NOTHING would not protect against duplicate system rows.
--
-- RLS: the "workspace_select_categories" policy (V31) already exposes all rows
-- where user_id IS NULL to all authenticated users, regardless of workspace_id.
-- No additional policy changes needed.

DO $$
DECLARE
  p_housing           UUID;
  p_transport         UUID;
  p_food_grocery      UUID;
  p_health            UUID;
  p_subscriptions     UUID;
  p_leisure           UUID;
  p_education         UUID;
  p_card_installments UUID;
  p_other             UUID;

  ws_housing           UUID;
  ws_transport         UUID;
  ws_food_grocery      UUID;
  ws_health            UUID;
  ws_subscriptions     UUID;
  ws_leisure           UUID;
  ws_education         UUID;
  ws_card_installments UUID;
  ws_other             UUID;
BEGIN

  -- Resolve parent IDs + their workspace_ids (inherited by subcategories)
  SELECT id, workspace_id INTO p_housing, ws_housing
    FROM categories WHERE slug = 'housing' AND user_id IS NULL;
  SELECT id, workspace_id INTO p_transport, ws_transport
    FROM categories WHERE slug = 'transport' AND user_id IS NULL;
  SELECT id, workspace_id INTO p_food_grocery, ws_food_grocery
    FROM categories WHERE slug = 'food_grocery' AND user_id IS NULL;
  SELECT id, workspace_id INTO p_health, ws_health
    FROM categories WHERE slug = 'health' AND user_id IS NULL;
  SELECT id, workspace_id INTO p_subscriptions, ws_subscriptions
    FROM categories WHERE slug = 'subscriptions' AND user_id IS NULL;
  SELECT id, workspace_id INTO p_leisure, ws_leisure
    FROM categories WHERE slug = 'leisure' AND user_id IS NULL;
  SELECT id, workspace_id INTO p_education, ws_education
    FROM categories WHERE slug = 'education' AND user_id IS NULL;
  SELECT id, workspace_id INTO p_card_installments, ws_card_installments
    FROM categories WHERE slug = 'card_installments' AND user_id IS NULL;
  SELECT id, workspace_id INTO p_other, ws_other
    FROM categories WHERE slug = 'other' AND user_id IS NULL;

  -- ── Moradia (housing) ──────────────────────────────────────────────────────
  INSERT INTO categories (parent_id, workspace_id, slug, name, emoji, financial_type, is_system, display_order)
  SELECT v.parent_id, v.workspace_id, v.slug, v.name, v.emoji, v.financial_type, v.is_system, v.display_order
  FROM (VALUES
    (p_housing, ws_housing, 'housing_rent',         'Aluguel',          '🏡', 'need'::text, TRUE, 0),
    (p_housing, ws_housing, 'housing_condo',        'Condomínio',       '🏢', 'need'::text, TRUE, 1),
    (p_housing, ws_housing, 'housing_electricity',  'Luz',              '💡', 'need'::text, TRUE, 2),
    (p_housing, ws_housing, 'housing_water',        'Água',             '🚰', 'need'::text, TRUE, 3),
    (p_housing, ws_housing, 'housing_gas',          'Gás',              '🔥', 'need'::text, TRUE, 4),
    (p_housing, ws_housing, 'housing_internet',     'Internet',         '🌐', 'need'::text, TRUE, 5),
    (p_housing, ws_housing, 'housing_property_tax', 'IPTU',             '📄', 'need'::text, TRUE, 6),
    (p_housing, ws_housing, 'housing_maintenance',  'Manutenção',       '🔧', 'need'::text, TRUE, 7)
  ) AS v(parent_id, workspace_id, slug, name, emoji, financial_type, is_system, display_order)
  WHERE NOT EXISTS (
    SELECT 1 FROM categories c WHERE c.slug = v.slug AND c.parent_id = v.parent_id
  );

  -- ── Transporte (transport) ─────────────────────────────────────────────────
  INSERT INTO categories (parent_id, workspace_id, slug, name, emoji, financial_type, is_system, display_order)
  SELECT v.parent_id, v.workspace_id, v.slug, v.name, v.emoji, v.financial_type, v.is_system, v.display_order
  FROM (VALUES
    (p_transport, ws_transport, 'transport_rideshare',   'Uber / 99',      '🚕', 'need'::text, TRUE, 0),
    (p_transport, ws_transport, 'transport_public',      'Ônibus / Metrô', '🚇', 'need'::text, TRUE, 1),
    (p_transport, ws_transport, 'transport_fuel',        'Combustível',    '⛽', 'need'::text, TRUE, 2),
    (p_transport, ws_transport, 'transport_parking',     'Estacionamento', '🅿', 'need'::text, TRUE, 3),
    (p_transport, ws_transport, 'transport_maintenance', 'Manutenção',     '🔧', 'need'::text, TRUE, 4)
  ) AS v(parent_id, workspace_id, slug, name, emoji, financial_type, is_system, display_order)
  WHERE NOT EXISTS (
    SELECT 1 FROM categories c WHERE c.slug = v.slug AND c.parent_id = v.parent_id
  );

  -- ── Alimentação (food_grocery) ─────────────────────────────────────────────
  INSERT INTO categories (parent_id, workspace_id, slug, name, emoji, financial_type, is_system, is_swile, display_order)
  SELECT v.parent_id, v.workspace_id, v.slug, v.name, v.emoji, v.financial_type, v.is_system, v.is_swile, v.display_order
  FROM (VALUES
    (p_food_grocery, ws_food_grocery, 'food_supermarket', 'Supermercado', '🛒', 'need'::text, TRUE, TRUE,  0),
    (p_food_grocery, ws_food_grocery, 'food_restaurant',  'Restaurante',  '🍽', 'want'::text, TRUE, TRUE,  1),
    (p_food_grocery, ws_food_grocery, 'food_delivery',    'Delivery',     '🛵', 'want'::text, TRUE, FALSE, 2),
    (p_food_grocery, ws_food_grocery, 'food_bakery',      'Padaria',      '🥐', 'need'::text, TRUE, TRUE,  3),
    (p_food_grocery, ws_food_grocery, 'food_fair',        'Feira',        '🥦', 'need'::text, TRUE, FALSE, 4)
  ) AS v(parent_id, workspace_id, slug, name, emoji, financial_type, is_system, is_swile, display_order)
  WHERE NOT EXISTS (
    SELECT 1 FROM categories c WHERE c.slug = v.slug AND c.parent_id = v.parent_id
  );

  -- ── Saúde (health) ─────────────────────────────────────────────────────────
  INSERT INTO categories (parent_id, workspace_id, slug, name, emoji, financial_type, is_system, display_order)
  SELECT v.parent_id, v.workspace_id, v.slug, v.name, v.emoji, v.financial_type, v.is_system, v.display_order
  FROM (VALUES
    (p_health, ws_health, 'health_pharmacy', 'Farmácia',       '💊', 'need'::text, TRUE, 0),
    (p_health, ws_health, 'health_doctor',   'Médico',         '👨', 'need'::text, TRUE, 1),
    (p_health, ws_health, 'health_plan',     'Plano de Saúde', '🏥', 'need'::text, TRUE, 2),
    (p_health, ws_health, 'health_lab',      'Exames',         '🔬', 'need'::text, TRUE, 3),
    (p_health, ws_health, 'health_gym',      'Academia',       '🏋', 'want'::text, TRUE, 4)
  ) AS v(parent_id, workspace_id, slug, name, emoji, financial_type, is_system, display_order)
  WHERE NOT EXISTS (
    SELECT 1 FROM categories c WHERE c.slug = v.slug AND c.parent_id = v.parent_id
  );

  -- ── Assinaturas (subscriptions) ────────────────────────────────────────────
  INSERT INTO categories (parent_id, workspace_id, slug, name, emoji, financial_type, is_system, display_order)
  SELECT v.parent_id, v.workspace_id, v.slug, v.name, v.emoji, v.financial_type, v.is_system, v.display_order
  FROM (VALUES
    (p_subscriptions, ws_subscriptions, 'subs_streaming', 'Streaming',   '📺', 'want'::text, TRUE, 0),
    (p_subscriptions, ws_subscriptions, 'subs_apps',      'Aplicativos', '📱', 'want'::text, TRUE, 1),
    (p_subscriptions, ws_subscriptions, 'subs_mobile',    'Celular',     '☎', 'need'::text, TRUE, 2),
    (p_subscriptions, ws_subscriptions, 'subs_gym',       'Academia',    '🏋', 'want'::text, TRUE, 3),
    (p_subscriptions, ws_subscriptions, 'subs_other',     'Outros',      '📋', 'want'::text, TRUE, 4)
  ) AS v(parent_id, workspace_id, slug, name, emoji, financial_type, is_system, display_order)
  WHERE NOT EXISTS (
    SELECT 1 FROM categories c WHERE c.slug = v.slug AND c.parent_id = v.parent_id
  );

  -- ── Lazer (leisure) ────────────────────────────────────────────────────────
  INSERT INTO categories (parent_id, workspace_id, slug, name, emoji, financial_type, is_system, display_order)
  SELECT v.parent_id, v.workspace_id, v.slug, v.name, v.emoji, v.financial_type, v.is_system, v.display_order
  FROM (VALUES
    (p_leisure, ws_leisure, 'leisure_cinema',  'Cinema',  '🎬', 'want'::text, TRUE, 0),
    (p_leisure, ws_leisure, 'leisure_travel',  'Viagem',  '✈', 'want'::text, TRUE, 1),
    (p_leisure, ws_leisure, 'leisure_bars',    'Bares',   '🍺', 'want'::text, TRUE, 2),
    (p_leisure, ws_leisure, 'leisure_games',   'Jogos',   '🎮', 'want'::text, TRUE, 3),
    (p_leisure, ws_leisure, 'leisure_hobbies', 'Hobbies', '🎨', 'want'::text, TRUE, 4)
  ) AS v(parent_id, workspace_id, slug, name, emoji, financial_type, is_system, display_order)
  WHERE NOT EXISTS (
    SELECT 1 FROM categories c WHERE c.slug = v.slug AND c.parent_id = v.parent_id
  );

  -- ── Educação (education) ───────────────────────────────────────────────────
  INSERT INTO categories (parent_id, workspace_id, slug, name, emoji, financial_type, is_system, display_order)
  SELECT v.parent_id, v.workspace_id, v.slug, v.name, v.emoji, v.financial_type, v.is_system, v.display_order
  FROM (VALUES
    (p_education, ws_education, 'edu_course',        'Curso',        '🎓', 'investment'::text, TRUE, 0),
    (p_education, ws_education, 'edu_books',         'Livros',       '📖', 'investment'::text, TRUE, 1),
    (p_education, ws_education, 'edu_certification', 'Certificação', '📜', 'investment'::text, TRUE, 2),
    (p_education, ws_education, 'edu_materials',     'Materiais',    '📐', 'investment'::text, TRUE, 3)
  ) AS v(parent_id, workspace_id, slug, name, emoji, financial_type, is_system, display_order)
  WHERE NOT EXISTS (
    SELECT 1 FROM categories c WHERE c.slug = v.slug AND c.parent_id = v.parent_id
  );

  -- ── Parcelas Cartão (card_installments) ───────────────────────────────────
  INSERT INTO categories (parent_id, workspace_id, slug, name, emoji, financial_type, is_system, display_order)
  SELECT v.parent_id, v.workspace_id, v.slug, v.name, v.emoji, v.financial_type, v.is_system, v.display_order
  FROM (VALUES
    (p_card_installments, ws_card_installments, 'installment_purchase', 'Compra Parcelada', '🛍', 'want'::text, TRUE, 0)
  ) AS v(parent_id, workspace_id, slug, name, emoji, financial_type, is_system, display_order)
  WHERE NOT EXISTS (
    SELECT 1 FROM categories c WHERE c.slug = v.slug AND c.parent_id = v.parent_id
  );

  -- ── Outros (other) ─────────────────────────────────────────────────────────
  INSERT INTO categories (parent_id, workspace_id, slug, name, emoji, financial_type, is_system, display_order)
  SELECT v.parent_id, v.workspace_id, v.slug, v.name, v.emoji, v.financial_type, v.is_system, v.display_order
  FROM (VALUES
    (p_other, ws_other, 'other_gift',       'Presente',   '🎁', 'want'::text, TRUE, 0),
    (p_other, ws_other, 'other_donation',   'Doação',     '🤝', 'want'::text, TRUE, 1),
    (p_other, ws_other, 'other_unexpected', 'Imprevisto', '⚠', 'need'::text, TRUE, 2),
    (p_other, ws_other, 'other_misc',       'Outros',     '📋', 'want'::text, TRUE, 3)
  ) AS v(parent_id, workspace_id, slug, name, emoji, financial_type, is_system, display_order)
  WHERE NOT EXISTS (
    SELECT 1 FROM categories c WHERE c.slug = v.slug AND c.parent_id = v.parent_id
  );

END $$;
