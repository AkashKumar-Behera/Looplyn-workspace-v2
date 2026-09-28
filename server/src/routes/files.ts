import { Hono } from 'hono'
import { query } from '../db'
import { authMiddleware, requireRoles, UserPayload, AuthEnv } from '../middleware/auth'

const fileRoutes = new Hono<AuthEnv>()

fileRoutes.use('*', authMiddleware)

// 1. List Files (with category / client filter)
fileRoutes.get('/', async (c) => {
  const user = c.get('user') as UserPayload
  const clientId = c.req.query('client_id')
  const category = c.req.query('category')

  try {
    let sql = `
      SELECT 
        f.id, f.name, f.url, f.file_type, f.size_bytes, f.category, f.created_at,
        cl.id AS client_id, cl.name AS client_name,
        u.id AS uploader_id, u.name AS uploader_name
      FROM files f
      LEFT JOIN clients cl ON cl.id = f.client_id
      LEFT JOIN users u ON u.id = f.uploader_id
      WHERE f.deleted_at IS NULL
    `
    const params: any[] = []

    if (user.role === 'client') {
      if (!user.clientId) {
        return c.json({ success: true, files: [] })
      }
      params.push(user.clientId)
      sql += ` AND f.client_id = $${params.length}`
    } else if (clientId) {
      params.push(clientId)
      sql += ` AND f.client_id = $${params.length}`
    }

    if (category && category.toLowerCase() !== 'all') {
      params.push(category.toLowerCase())
      sql += ` AND LOWER(f.category) = $${params.length}`
    }

    sql += ` ORDER BY f.created_at DESC`

    const res = await query(sql, params)
    return c.json({ success: true, files: res.rows })
  } catch (err) {
    console.error('Fetch files error:', err)
    return c.json({ success: false, error: 'Failed to fetch files' }, 500)
  }
})

// 2. Add / Link File Asset
fileRoutes.post('/', requireRoles('admin', 'staff', 'super_admin'), async (c) => {
  const user = c.get('user') as UserPayload
  try {
    const { name, url, client_id, file_type = 'file', size_bytes = 0, category = 'documents' } = await c.req.json()

    if (!name || !name.trim() || !url || !url.trim()) {
      return c.json({ success: false, error: 'File name and valid URL are required' }, 400)
    }

    const res = await query(
      `INSERT INTO files (name, url, client_id, file_type, size_bytes, category, uploader_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [name.trim(), url.trim(), client_id || null, file_type, size_bytes, category.toLowerCase(), user.id]
    )

    await query(
      `INSERT INTO activity_logs (user_id, user_name, action, entity_type, entity_id, entity_title)
       VALUES ($1, $2, 'uploaded asset', 'file', $3, $4)`,
      [user.id, user.name || 'User', res.rows[0].id, name.trim()]
    )

    return c.json({ success: true, message: 'File asset added successfully', file: res.rows[0] })
  } catch (err) {
    console.error('Add file error:', err)
    return c.json({ success: false, error: 'Failed to add file' }, 500)
  }
})

// 3. Delete File (Soft / Permanent)
fileRoutes.delete('/:id', requireRoles('admin', 'staff', 'super_admin'), async (c) => {
  const id = c.req.param('id')
  const isPermanent = c.req.query('permanent') === 'true'

  try {
    if (isPermanent) {
      const res = await query('DELETE FROM files WHERE id = $1 RETURNING id', [id])
      if (res.rows.length === 0) {
        return c.json({ success: false, error: 'File not found' }, 404)
      }
      return c.json({ success: true, message: 'File permanently deleted' })
    } else {
      const res = await query('UPDATE files SET deleted_at = NOW() WHERE id = $1 RETURNING id', [id])
      if (res.rows.length === 0) {
        return c.json({ success: false, error: 'File not found' }, 404)
      }
      return c.json({ success: true, message: 'File moved to trash' })
    }
  } catch (err) {
    return c.json({ success: false, error: 'Failed to delete file' }, 500)
  }
})

export default fileRoutes
