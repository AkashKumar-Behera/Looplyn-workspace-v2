import { Hono } from 'hono'
import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'
import crypto from 'crypto'
import { query } from '../db'
import { authMiddleware, requireRoles, UserPayload, AuthEnv } from '../middleware/auth'

const authRoutes = new Hono<AuthEnv>()
const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_looplyn_jwt_2026_key_production'

// 1. Login Endpoint
authRoutes.post('/login', async (c) => {
  try {
    const { email, password } = await c.req.json()

    if (!email || !password) {
      return c.json({ success: false, error: 'Email and password are required' }, 400)
    }

    const cleanEmail = email.trim().toLowerCase()
    const superAdminEmail = (process.env.SUPER_ADMIN_EMAIL || 'admin@looplyn.tech').toLowerCase()
    const superAdminPassword = process.env.SUPER_ADMIN_PASSWORD || 'SuperAdminSecretPassword123!'

    // Direct Super Admin Authentication Verification
    if (cleanEmail === superAdminEmail && password === superAdminPassword) {
      try {
        const userId = '00000000-0000-0000-0000-000000000001'
        const hashed = await bcrypt.hash(superAdminPassword, 10)
        await query(
          `INSERT INTO users (id, email, password_hash, name, role, status)
           VALUES ($1, $2, $3, 'Super Admin', 'super_admin', 'ACTIVE')
           ON CONFLICT (email) DO UPDATE SET password_hash = $3, status = 'ACTIVE'`,
          [userId, superAdminEmail, hashed]
        )
      } catch (dbErr) {
        console.warn('Superadmin DB sync notice (DB starting/unreachable):', dbErr)
      }

      const tokenPayload: UserPayload = {
        id: '00000000-0000-0000-0000-000000000001',
        email: superAdminEmail,
        role: 'super_admin',
        name: 'Super Admin',
        clientId: undefined
      }

      const token = jwt.sign(tokenPayload, JWT_SECRET, { expiresIn: '30d' })

      return c.json({
        success: true,
        token,
        user: {
          id: '00000000-0000-0000-0000-000000000001',
          email: superAdminEmail,
          name: 'Super Admin',
          role: 'super_admin',
          status: 'ACTIVE'
        }
      })
    }

    // Standard Users lookup in PostgreSQL DB
    let res
    try {
      res = await query('SELECT * FROM users WHERE LOWER(email) = LOWER($1)', [cleanEmail])
    } catch (dbError) {
      console.error('Database connection error during login:', dbError)
      return c.json({ success: false, error: 'Database service is starting or unreachable. Please try in a moment.' }, 503)
    }

    if (!res || res.rows.length === 0) {
      return c.json({ success: false, error: 'Invalid email or password' }, 401)
    }

    const user = res.rows[0]
    const isMatch = await bcrypt.compare(password, user.password_hash)
    if (!isMatch) {
      return c.json({ success: false, error: 'Invalid email or password' }, 401)
    }

    if (user.status !== 'ACTIVE') {
      return c.json({ success: false, error: 'Account is deactivated' }, 403)
    }

    const tokenPayload: UserPayload = {
      id: user.id,
      email: user.email,
      role: user.role,
      name: user.name,
      clientId: user.client_id
    }

    const token = jwt.sign(tokenPayload, JWT_SECRET, { expiresIn: '30d' })

    return c.json({
      success: true,
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        custom_role: user.custom_role,
        avatar_url: user.avatar_url,
        client_id: user.client_id
      }
    })
  } catch (err: any) {
    console.error('Login error:', err)
    return c.json({ success: false, error: err.message || 'Internal server error' }, 500)
  }
})

// 2. Get Current Authenticated Profile
authRoutes.get('/me', authMiddleware, async (c) => {
  const tokenUser = c.get('user') as UserPayload
  try {
    const res = await query('SELECT id, email, name, role, custom_role, phone, avatar_url, client_id, status FROM users WHERE id = $1', [tokenUser.id])
    if (res.rows.length === 0) {
      return c.json({ success: false, error: 'User not found' }, 404)
    }
    return c.json({ success: true, user: res.rows[0] })
  } catch (err) {
    return c.json({ success: false, error: 'Failed to fetch user' }, 500)
  }
})

// 3. Super Admin creates Agency Admin Account
authRoutes.post('/create-admin', authMiddleware, requireRoles('super_admin'), async (c) => {
  try {
    const { email, password, name } = await c.req.json()
    if (!email || !password || !name) {
      return c.json({ success: false, error: 'Email, password and name are required' }, 400)
    }

    const existing = await query('SELECT id FROM users WHERE LOWER(email) = LOWER($1)', [email.trim()])
    if (existing.rows.length > 0) {
      return c.json({ success: false, error: 'Email is already registered' }, 400)
    }

    const hashed = await bcrypt.hash(password, 10)
    const result = await query(
      `INSERT INTO users (email, password_hash, name, role, status)
       VALUES ($1, $2, $3, 'admin', 'ACTIVE')
       RETURNING id, email, name, role, created_at`,
      [email.trim().toLowerCase(), hashed, name.trim()]
    )

    return c.json({ success: true, message: 'Agency Admin created successfully', admin: result.rows[0] })
  } catch (err) {
    console.error('Create admin error:', err)
    return c.json({ success: false, error: 'Failed to create admin' }, 500)
  }
})

// 4. Admin creates Staff or Client Account
authRoutes.post('/create-user', authMiddleware, requireRoles('admin', 'super_admin'), async (c) => {
  try {
    const { email, password, name, role, custom_role, client_id, phone } = await c.req.json()

    if (!email || !password || !name || !role) {
      return c.json({ success: false, error: 'Email, password, name and role are required' }, 400)
    }

    if (!['staff', 'client'].includes(role)) {
      return c.json({ success: false, error: 'Role must be either staff or client' }, 400)
    }

    const existing = await query('SELECT id FROM users WHERE LOWER(email) = LOWER($1)', [email.trim()])
    if (existing.rows.length > 0) {
      return c.json({ success: false, error: 'Email is already registered' }, 400)
    }

    const hashed = await bcrypt.hash(password, 10)
    const result = await query(
      `INSERT INTO users (email, password_hash, name, role, custom_role, client_id, phone, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'ACTIVE')
       RETURNING id, email, name, role, custom_role, client_id, phone, created_at`,
      [email.trim().toLowerCase(), hashed, name.trim(), role, custom_role || null, client_id || null, phone || null]
    )

    return c.json({ success: true, message: `${role.toUpperCase()} user created successfully`, user: result.rows[0] })
  } catch (err) {
    console.error('Create user error:', err)
    return c.json({ success: false, error: 'Failed to create user' }, 500)
  }
})

// 5. Request Password Reset Link (Forgot Password)
authRoutes.post('/forgot-password', async (c) => {
  try {
    const { email } = await c.req.json()
    if (!email) {
      return c.json({ success: false, error: 'Email is required' }, 400)
    }

    const res = await query('SELECT id, email, name FROM users WHERE LOWER(email) = LOWER($1)', [email.trim()])
    
    // Security: Always return generic success to avoid email enumeration
    if (res.rows.length === 0) {
      return c.json({ success: true, message: 'If this email exists, a password reset link has been dispatched.' })
    }

    const user = res.rows[0]
    const resetToken = crypto.randomBytes(32).toString('hex')
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000) // 15 minutes validity

    await query(
      `INSERT INTO password_resets (user_id, token, expires_at)
       VALUES ($1, $2, $3)`,
      [user.id, resetToken, expiresAt]
    )

    const frontendUrl = process.env.FRONTEND_URL || 'https://workspace.looplyn.tech'
    const resetLink = `${frontendUrl}/reset-password?token=${resetToken}`
    console.log(`🔗 Password Reset Link for ${user.email}: ${resetLink}`)

    const resendKey = process.env.RESEND_API_KEY
    if (resendKey && !resendKey.startsWith('re_1234')) {
      fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${resendKey}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          from: 'Looplyn Security <security@looplyn.tech>',
          to: [user.email],
          subject: 'Reset your Looplyn password',
          html: `<p>Hello ${user.name},</p><p>Click the link below to reset your password (valid for 15 minutes):</p><p><a href="${resetLink}">Reset Password</a></p>`
        })
      }).catch(err => console.error('Failed to send Resend email:', err))
    }

    return c.json({
      success: true,
      message: 'If this email exists, a password reset link has been dispatched.',
      ...(process.env.NODE_ENV !== 'production' ? { devResetLink: resetLink } : {})
    })
  } catch (err) {
    console.error('Forgot password error:', err)
    return c.json({ success: false, error: 'Failed to process request' }, 500)
  }
})

// 6. Verify Reset Token
authRoutes.get('/verify-reset-token', async (c) => {
  const token = c.req.query('token')
  if (!token) {
    return c.json({ success: false, error: 'Missing token' }, 400)
  }

  const res = await query(
    `SELECT r.id, r.user_id, r.expires_at, r.used, u.email, u.name
     FROM password_resets r
     JOIN users u ON u.id = r.user_id
     WHERE r.token = $1`,
    [token]
  )

  if (res.rows.length === 0) {
    return c.json({ success: false, error: 'Invalid reset link' }, 404)
  }

  const record = res.rows[0]
  if (record.used) {
    return c.json({ success: false, error: 'This reset link has already been used' }, 400)
  }

  if (new Date(record.expires_at) < new Date()) {
    return c.json({ success: false, error: 'This reset link has expired' }, 400)
  }

  return c.json({ success: true, email: record.email, name: record.name })
})

// 7. Reset Password Action
authRoutes.post('/reset-password', async (c) => {
  try {
    const { token, newPassword } = await c.req.json()

    if (!token || !newPassword || newPassword.length < 6) {
      return c.json({ success: false, error: 'Token and minimum 6 character password required' }, 400)
    }

    const res = await query(
      `SELECT id, user_id, expires_at, used
       FROM password_resets
       WHERE token = $1`,
      [token]
    )

    if (res.rows.length === 0) {
      return c.json({ success: false, error: 'Invalid reset link' }, 404)
    }

    const record = res.rows[0]
    if (record.used || new Date(record.expires_at) < new Date()) {
      return c.json({ success: false, error: 'Reset link has expired or been used' }, 400)
    }

    const hashed = await bcrypt.hash(newPassword, 10)

    await query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2', [hashed, record.user_id])
    await query('UPDATE password_resets SET used = TRUE WHERE id = $1', [record.id])

    return c.json({ success: true, message: 'Password reset successfully. You can now login.' })
  } catch (err) {
    console.error('Reset password error:', err)
    return c.json({ success: false, error: 'Failed to reset password' }, 500)
  }
})

export default authRoutes
