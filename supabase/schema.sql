-- Supabase Database Schema for Flutter Chat App
-- Run this SQL in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    username TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_online BOOLEAN DEFAULT FALSE
);

-- Chat rooms table
CREATE TABLE IF NOT EXISTS chat_rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    is_group BOOLEAN DEFAULT FALSE,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Chat room participants (many-to-many)
CREATE TABLE IF NOT EXISTS chat_room_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(chat_room_id, user_id)
);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_read BOOLEAN DEFAULT FALSE
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_messages_chat_room ON messages(chat_room_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_participants_user ON chat_room_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_participants_room ON chat_room_participants(chat_room_id);
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_room_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Public profiles are viewable by authenticated users"
    ON profiles FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- RLS Policies for chat_rooms
CREATE POLICY "Users can view chat rooms they participate in"
    ON chat_rooms FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM chat_room_participants
            WHERE chat_room_id = id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Authenticated users can create chat rooms"
    ON chat_rooms FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- RLS Policies for chat_room_participants
CREATE POLICY "Users can view participants of their chat rooms"
    ON chat_room_participants FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM chat_room_participants p
            WHERE p.chat_room_id = chat_room_id AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can add participants to chat rooms"
    ON chat_room_participants FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- RLS Policies for messages
CREATE POLICY "Users can view messages in their chat rooms"
    ON messages FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM chat_room_participants
            WHERE chat_room_id = messages.chat_room_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can send messages to their chat rooms"
    ON messages FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = sender_id AND
        EXISTS (
            SELECT 1 FROM chat_room_participants
            WHERE chat_room_id = messages.chat_room_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update messages in their chat rooms"
    ON messages FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM chat_room_participants
            WHERE chat_room_id = messages.chat_room_id AND user_id = auth.uid()
        )
    );

-- Function to auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, username, created_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on auth.users insert
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Enable realtime for messages
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;

