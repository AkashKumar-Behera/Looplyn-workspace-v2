import { Hono } from 'hono'
import bcrypt from 'bcryptjs'
import { query } from '../db'
import { authMiddleware, requireRoles, AuthEnv } from '../middleware/auth'

const clientRoutes = new Hono<AuthEnv>()

// 1. Get All Clients (with aggregated Open Items count)
clientRoutes.get('/', authMiddleware, async (c) => {
  try {
    const res = await query(`
      SELECT 
        c.id,
        c.name,
        c.email,
        c.phone,
        c.industry as company,
        c.logo_url,
        c.status,
        c.created_at,
        COUNT(cnt.id) FILTER (WHERE cnt.status IS NOT NULL AND cnt.status != 'PUBLISHED') as open_items_count
      FROM clients c
      LEFT JOIN contents cnt ON cnt.client_id = c.id
      GROUP BY c.id
      ORDER BY c.created_at DESC
    `)
    return c.json({ success: true, clients: res.rows })
  } catch (err: any) {
    console.error('Fetch clients error:', err)
    return c.json({ success: false, error: 'Failed to fetch clients' }, 500)
  }
})

// 2. Create Client (Brand + Optional Client Portal User Login)
clientRoutes.post('/', authMiddleware, requireRoles('admin', 'super_admin'), async (c) => {
  try {
    const { name, company, email, phone, password, industry } = await c.req.json()

    if (!name || name.trim().isEmpty) {
      return c.json({ success: false, error: 'Client name is required' }, 400)
    }

    const companyName = company || industry || name.trim()
    const cleanEmail = email ? email.trim().toLowerCase() : null

    // 1. Insert Client Record
    const clientRes = await query(
      `INSERT INTO clients (name, email, phone, industry, status)
       VALUES ($1, $2, $3, $4, 'ACTIVE')
       RETURNING id, name, email, phone, industry as company, logo_url, status, created_at`,
      [name.trim(), cleanEmail, phone ? phone.trim() : null, companyName]
    )
    const newClient = clientRes.rows[0]

    // 2. If email & password provided, create Client Portal Login Account in `users` table
    if (cleanEmail && password && password.trim().length >= 6) {
      const existingUser = await query('SELECT id FROM users WHERE LOWER(email) = LOWER($1)', [cleanEmail])
      if (existingUser.rows.length === 0) {
        const hashed = await bcrypt.hash(password.trim(), 10)
        await query(
          `INSERT INTO users (email, password_hash, name, role, client_id, phone, status)
           VALUES ($1, $2, $3, 'client', $4, $5, 'ACTIVE')`,
          [cleanEmail, hashed, name.trim(), newClient.id, phone ? phone.trim() : null]
        )
      }
    }

    return c.json({ success: true, message: 'Client created successfully', client: newClient })
  } catch (err: any) {
    console.error('Create client error:', err)
    return c.json({ success: false, error: err.message || 'Failed to create client' }, 500)
  }
})

// 3. Update Client Details
clientRoutes.patch('/:id', authMiddleware, requireRoles('admin', 'super_admin'), async (c) => {
  try {
    const id = c.req.param('id')
    const { name, company, email, phone, status } = await c.req.json()

    const fields: string[] = []
    const values: any[] = []
    let idx = 1

    if (name) { fields.push(`name = $${idx++}`); values.push(name.trim()); }
    if (company) { fields.push(`industry = $${idx++}`); values.push(company.trim()); }
    if (email) { fields.push(`email = $${idx++}`); values.push(email.trim().toLowerCase()); }
    if (phone) { fields.push(`phone = $${idx++}`); values.push(phone.trim()); }
    if (status) { fields.push(`status = $${idx++}`); values.push(status); }

    if (fields.length === 0) {
      return c.json({ success: false, error: 'No fields to update' }, 400)
    }

    fields.push(`updated_at = CURRENT_TIMESTAMP`)
    values.push(id)

    const res = await query(
      `UPDATE clients SET ${fields.join(', ')} WHERE id = $${idx} RETURNING id, name, email, phone, industry as company, status, updated_at`,
      values
    )

    if (res.rows.length === 0) {
      return c.json({ success: false, error: 'Client not found' }, 404)
    }

    return c.json({ success: true, message: 'Client updated successfully', client: res.rows[0] })
  } catch (err: any) {
    console.error('Update client error:', err)
    return c.json({ success: false, error: 'Failed to update client' }, 500)
  }
})

// 4. Delete Client
clientRoutes.delete('/:id', authMiddleware, requireRoles('admin', 'super_admin'), async (c) => {
  try {
    const id = c.req.param('id')
    await query('DELETE FROM clients WHERE id = $1', [id])
    return c.json({ success: true, message: 'Client deleted successfully' })
  } catch (err: any) {
    console.error('Delete client error:', err)
    return c.json({ success: false, error: 'Failed to delete client' }, 500)
  }
})

// 5. Get All Staff Members (role in 'staff', 'admin')
clientRoutes.get('/staff', authMiddleware, async (c) => {
  try {
    const res = await query(`
      SELECT 
        u.id,
        u.name,
        u.email,
        u.phone,
        u.role,
        u.custom_role,
        u.avatar_url,
        u.status,
        u.created_at,
        COUNT(cnt.id) FILTER (WHERE cnt.status IS NOT NULL AND cnt.status != 'PUBLISHED') as open_items_count
      FROM users u
      LEFT JOIN contents cnt ON cnt.assigned_staff_id = u.id
      WHERE u.role IN ('staff', 'admin')
      GROUP BY u.id
      ORDER BY u.created_at DESC
    `)
    return c.json({ success: true, staff: res.rows })
  } catch (err: any) {
    console.error('Fetch staff error:', err)
    return c.json({ success: false, error: 'Failed to fetch staff members' }, 500)
  }
})

// 6. Create Staff Member
clientRoutes.post('/staff', authMiddleware, requireRoles('admin', 'super_admin'), async (c) => {
  try {
    const { name, email, phone, custom_role, password, role } = await c.req.json()

    if (!name || !email || !password) {
      return c.json({ success: false, error: 'Name, email, and password are required' }, 400)
    }

    if (password.length < 6) {
      return c.json({ success: false, error: 'Password must be at least 6 characters' }, 400)
    }

    const cleanEmail = email.trim().toLowerCase()
    const existing = await query('SELECT id FROM users WHERE LOWER(email) = LOWER($1)', [cleanEmail])
    if (existing.rows.length > 0) {
      return c.json({ success: false, error: 'User with this email already exists' }, 400)
    }

    const hashed = await bcrypt.hash(password.trim(), 10)
    const userRole = role === 'admin' ? 'admin' : 'staff'

    const res = await query(
      `INSERT INTO users (name, email, password_hash, role, custom_role, phone, status)
       VALUES ($1, $2, $3, $4, $5, $6, 'ACTIVE')
       RETURNING id, name, email, role, custom_role, phone, status, created_at`,
      [name.trim(), cleanEmail, hashed, userRole, custom_role ? custom_role.trim() : 'Designer', phone ? phone.trim() : null]
    )

    return c.json({ success: true, message: 'Staff member created successfully', staff: res.rows[0] })
  } catch (err: any) {
    console.error('Create staff error:', err)
    return c.json({ success: false, error: err.message || 'Failed to create staff member' }, 500)
  }
})

// 7. Delete Staff Member
clientRoutes.delete('/staff/:id', authMiddleware, requireRoles('admin', 'super_admin'), async (c) => {
  try {
    const id = c.req.param('id')
    await query('DELETE FROM users WHERE id = $1 AND role IN (\'staff\', \'admin\')', [id])
    return c.json({ success: true, message: 'Staff member deleted successfully' })
  } catch (err: any) {
    console.error('Delete staff error:', err)
    return c.json({ success: false, error: 'Failed to delete staff member' }, 500)
  }
})

export default clientRoutes
