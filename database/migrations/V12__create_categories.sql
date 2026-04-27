-- V12__create_categories.sql
-- Create categories table for dynamic category management

CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    db_value TEXT NOT NULL,
    name TEXT NOT NULL,
    emoji TEXT NOT NULL,
    is_swile BOOLEAN DEFAULT FALSE,
    is_system BOOLEAN DEFAULT FALSE,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, db_value)
);

-- Enable RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'categories' AND policyname = 'Users can manage their own categories'
    ) THEN
        CREATE POLICY "Users can manage their own categories" ON categories
            FOR ALL USING (auth.uid() = user_id);
    END IF;
END
$$;

-- Seed initial categories for existing users? 
-- Actually, it's better to let the app seed them on first load or use a trigger.
-- For now, we just create the table.
