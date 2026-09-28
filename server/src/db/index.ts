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

// Clean Schema Initialization & Auto-Seed
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
        client_feedback TEXT,
        deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `)

    // Ensure deleted_at and client_feedback columns exist in contents if table existed
    await query(`
      DO $$ 
      BEGIN 
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='contents' AND column_name='deleted_at') THEN
          ALTER TABLE contents ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='contents' AND column_name='client_feedback') THEN
          ALTER TABLE contents ADD COLUMN client_feedback TEXT;
        END IF;
      END $$;
    `)

    // 4. Tasks Table (Studio Creative / Production Tasks)
    await query(`
      CREATE TABLE IF NOT EXISTS tasks (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        status VARCHAR(50) DEFAULT 'TODO',
        priority VARCHAR(50) DEFAULT 'MEDIUM',
        assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
        due_date TIMESTAMP WITH TIME ZONE,
        tags JSONB DEFAULT '[]'::jsonb,
        deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `)

    // 5. Files & Asset Library Table
    await query(`
      CREATE TABLE IF NOT EXISTS files (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        url TEXT NOT NULL,
        file_type VARCHAR(50) DEFAULT 'file',
        size_bytes BIGINT DEFAULT 0,
        category VARCHAR(50) DEFAULT 'documents',
        uploader_id UUID REFERENCES users(id) ON DELETE SET NULL,
        deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `)

    // 6. Email Templates Table
    await query(`
      CREATE TABLE IF NOT EXISTS email_templates (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        subject VARCHAR(255) NOT NULL,
        body_html TEXT NOT NULL,
        category VARCHAR(50) DEFAULT 'studio',
        variables JSONB DEFAULT '["client_name", "post_title", "review_link", "feedback_notes"]'::jsonb,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `)

    // 7. Activity Logs Table
    await query(`
      CREATE TABLE IF NOT EXISTS activity_logs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        user_name VARCHAR(255),
        action VARCHAR(100) NOT NULL,
        entity_type VARCHAR(50),
        entity_id UUID,
        entity_title VARCHAR(255),
        details JSONB DEFAULT '{}'::jsonb,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `)

    // 8. Content Feedback / Comments
    await query(`
      CREATE TABLE IF NOT EXISTS content_comments (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        content_id UUID REFERENCES contents(id) ON DELETE CASCADE,
        author_id UUID REFERENCES users(id) ON DELETE CASCADE,
        comment TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `)

    // 9. Chat Channels
    await query(`
      CREATE TABLE IF NOT EXISTS channels (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        type VARCHAR(50) DEFAULT 'PUBLIC',
        client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `)

    // 10. Channel & Direct Messages
    await query(`
      CREATE TABLE IF NOT EXISTS messages (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        channel_id UUID REFERENCES channels(id) ON DELETE CASCADE,
        recipient_id UUID REFERENCES users(id) ON DELETE CASCADE,
        sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
        text TEXT,
        attachments JSONB DEFAULT '[]'::jsonb,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `)

    // 11. Password Resets Table
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

    // Auto-seed Akash Admin user
    const akashPass = await bcrypt.hash('Ak123456', 10)
    await query(`
      INSERT INTO users (id, email, password_hash, name, role, status)
      VALUES ('00000000-0000-0000-0000-000000000002', 'akashkumar48874@gmail.com', $1, 'Akash', 'admin', 'ACTIVE')
      ON CONFLICT (email) DO UPDATE SET password_hash = $1, role = 'admin', status = 'ACTIVE';
    `, [akashPass])

    // Seed default Email Templates if table is empty
    const templateCount = await query(`SELECT COUNT(*) FROM email_templates`)
    if (parseInt(templateCount.rows[0].count) === 0) {
      await query(`
        INSERT INTO email_templates (name, subject, body_html, category, variables)
        VALUES 
        (
          'Review Request Notification',
          'New Creative Ready for Review: {{post_title}}',
          '<h2>Hi {{client_name}},</h2><p>Our creative team has uploaded a new draft for <strong>{{post_title}}</strong>. Please review and provide your approval or feedback.</p><p><a href="{{review_link}}" style="background: #C0151C; color: #fff; padding: 10px 20px; text-decoration: none; border-radius: 6px;">Open Review Portal</a></p>',
          'review',
          '["client_name", "post_title", "review_link"]'::jsonb
        ),
        (
          'Post Approved Confirmation',
          'Content Approved: {{post_title}} is ready for scheduling',
          '<h2>Content Approved!</h2><p>Great news! The content <strong>{{post_title}}</strong> has been approved and scheduled for publishing.</p>',
          'approval',
          '["client_name", "post_title"]'::jsonb
        ),
        (
          'Changes Requested Notice',
          'Revision Requested on {{post_title}}',
          '<h2>Revision Requested</h2><p>{{client_name}} has requested revisions on <strong>{{post_title}}</strong> with feedback:</p><blockquote>{{feedback_notes}}</blockquote>',
          'revision',
          '["client_name", "post_title", "feedback_notes"]'::jsonb
        );
      `)
    }

    console.log('✅ PostgreSQL Schema, Tables & Seed Data initialized successfully.')
  } catch (err) {
    console.error('❌ Database initialization error:', err)
  }
}
