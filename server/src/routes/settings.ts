import { Hono } from 'hono'
import bcrypt from 'bcryptjs'
import { query } from '../db'
import { authMiddleware, requireRoles, UserPayload, AuthEnv } from '../middleware/auth'

const settingsRoutes = new Hono<AuthEnv>()

settingsRoutes.use('*', authMiddleware)

// 1. Get Current User Profile & Studio Stats
settingsRoutes.get('/profile', async (c) => {
  const user = c.get('user') as UserPayload

  try {
    const res = await query(
      `SELECT id, name, email, role, custom_role, phone, avatar_url, status, created_at 
       FROM users WHERE id = $1`,
      [user.id]
    )

    if (res.rows.length === 0) {
      return c.json({ success: false, error: 'User not found' }, 404)
    }

    return c.json({ success: true, user: res.rows[0] })
  } catch (err) {
    return c.json({ success: false, error: 'Failed to fetch profile' }, 500)
  }
})

// 2. Update Profile
settingsRoutes.put('/profile', async (c) => {
  const user = c.get('user') as UserPayload

  try {
    const { name, phone, avatar_url, custom_role } = await c.req.json()

    const res = await query(
      `UPDATE users 
       SET name = COALESCE($1, name),
           phone = COALESCE($2, phone),
           avatar_url = COALESCE($3, avatar_url),
           custom_role = COALESCE($4, custom_role),
           updated_at = NOW()
       WHERE id = $5
       RETURNING id, name, email, role, custom_role, phone, avatar_url, status`,
      [name, phone, avatar_url, custom_role, user.id]
    )

    return c.json({ success: true, message: 'Profile updated successfully', user: res.rows[0] })
  } catch (err) {
    return c.json({ success: false, error: 'Failed to update profile' }, 500)
  }
})

// 3. Change Password
settingsRoutes.post('/change-password', async (c) => {
  const user = c.get('user') as UserPayload

  try {
    const { current_password, new_password } = await c.req.json()

    if (!new_password || new_password.length < 6) {
      return c.json({ success: false, error: 'New password must be at least 6 characters' }, 400)
    }

    const userRes = await query(`SELECT password_hash FROM users WHERE id = $1`, [user.id])
    if (userRes.rows.length === 0) {
      return c.json({ success: false, error: 'User not found' }, 404)
    }

    if (current_password) {
      const isMatch = await bcrypt.compare(current_password, userRes.rows[0].password_hash)
      if (!isMatch) {
        return c.json({ success: false, error: 'Current password does not match' }, 400)
      }
    }

    const hashedNew = await bcrypt.hash(new_password, 10)
    await query(`UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2`, [hashedNew, user.id])

    return c.json({ success: true, message: 'Password changed successfully' })
  } catch (err) {
    return c.json({ success: false, error: 'Failed to change password' }, 500)
  }
})

// 4. List Team / Studio Users (Admin Only)
settingsRoutes.get('/team', requireRoles('admin', 'super_admin'), async (c) => {
  try {
    const res = await query(`
      SELECT id, name, email, role, custom_role, phone, avatar_url, status, created_at 
      FROM users 
      WHERE role != 'super_admin'
      ORDER BY role ASC, created_at DESC
    `)
    return c.json({ success: true, members: res.rows })
  } catch (err) {
    return c.json({ success: false, error: 'Failed to fetch team' }, 500)
  }
})

export default settingsRoutes
