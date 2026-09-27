import { Pool } from 'pg'
import * as dotenv from 'dotenv'
import bcrypt from 'bcryptjs'

dotenv.config()

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/looplyn',
  ssl: process.env.DATABASE_URL && process.env.DATABASE_URL.includes('sslmode=require')
    ? { rejectUnauthorized: false }
    : false
})

pool.on('error', (err) => {
  console.error('Unexpected error on idle PostgreSQL client:', err)
})

export const query = (text: string, params?: any[]) => pool.query(text, params)

// Clean Schema Initialization & Auto-Seed Super Admin
export const initDB = async () => {
  try {
    // 1. Users Table (RBAC: super_admin, admin, staff, client)
    await query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        role VARCHAR(50) NOT NULL DEFAULT 'staff',
        custom_role VARCHAR(100),
        phone VARCHAR(50),
        avatar_url TEXT,
        status VARCHAR(50) DEFAULT 'ACTIVE',
        client_id UUID,
        fcm_tokens TEXT[] DEFAULT ARRAY[]::TEXT[],
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `)

    // 2. Clients Table (Agency Clients)
    await query(`
      CREATE TABLE IF NOT EXISTS clients (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255),
        phone VARCHAR(50),
        industry VARCHAR(100),
        logo_url TEXT,
        status VARCHAR(50) DEFAULT 'ACTIVE',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `)

    // 3. Contents Table (Studio / Social Media Workflow)
    await query(`
      CREATE TABLE IF NOT EXISTS contents (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        platform VARCHAR(50) DEFAULT 'INSTAGRAM',
        format VARCHAR(50) DEFAULT 'REEL',
        status VARCHAR(50) DEFAULT 'IDEA',
        priority VARCHAR(50) DEFAULT 'Medium',
        assigned_staff_id UUID REFERENCES users(id) ON DELETE SET NULL,
        scheduled_date TIMESTAMP WITH TIME ZONE,
        media_urls JSONB DEFAULT '[]'::jsonb,
        caption TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `)

    // 4. Content Feedback / Comments
    await query(`
      CREATE TABLE IF NOT EXISTS content_comments (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        content_id UUID REFERENCES contents(id) ON DELETE CASCADE,
        author_id UUID REFERENCES users(id) ON DELETE CASCADE,
        comment TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `)

    // 5. Chat Channels
    await query(`
      CREATE TABLE IF NOT EXISTS channels (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        type VARCHAR(50) DEFAULT 'PUBLIC',
        client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `)

    // 6. Channel Messages
    await query(`
      CREATE TABLE IF NOT EXISTS messages (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        channel_id UUID REFERENCES channels(id) ON DELETE CASCADE,
        sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
        text TEXT,
        attachments JSONB DEFAULT '[]'::jsonb,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `)

    // 7. Password Resets Table
    await query(`
      CREATE TABLE IF NOT EXISTS password_resets (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        token VARCHAR(255) NOT NULL UNIQUE,
        expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
        used BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `)

    // Auto-seed default Super Admin
    const superAdminEmail = process.env.SUPER_ADMIN_EMAIL || 'admin@looplyn.tech'
    const superAdminPassword = process.env.SUPER_ADMIN_PASSWORD || 'SuperAdminSecretPassword123!'
    const hashedPass = await bcrypt.hash(superAdminPassword, 10)

    await query(`
      INSERT INTO users (id, email, password_hash, name, role, status)
      VALUES ('00000000-0000-0000-0000-000000000001', $1, $2, 'Super Admin', 'super_admin', 'ACTIVE')
      ON CONFLICT (email) DO NOTHING;
    `, [superAdminEmail, hashedPass])

    console.log('✅ PostgreSQL Schema & Super Admin verified successfully.')
  } catch (err) {
    console.error('❌ Database initialization error (Check connection string):', err)
  }
}
