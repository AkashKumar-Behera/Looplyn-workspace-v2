import { Hono } from 'hono'
import { query } from '../db'
import { authMiddleware, requireRoles, UserPayload, AuthEnv } from '../middleware/auth'

const trashRoutes = new Hono<AuthEnv>()

trashRoutes.use('*', authMiddleware)

// 1. List all deleted items (Contents, Tasks, Files)
trashRoutes.get('/', requireRoles('admin', 'super_admin'), async (c) => {
  try {
    // Deleted Contents
    const contentsRes = await query(`
      SELECT 
        c.id, c.title AS name, 'content' AS type, c.deleted_at,
        cl.name AS client_name,
        ROUND(EXTRACT(EPOCH FROM ((c.deleted_at + INTERVAL '30 days') - NOW())) / 86400) AS days_remaining
      FROM contents c
      LEFT JOIN clients cl ON cl.id = c.client_id
      WHERE c.deleted_at IS NOT NULL
      ORDER BY c.deleted_at DESC
    `)

    // Deleted Tasks
    const tasksRes = await query(`
      SELECT 
        t.id, t.title AS name, 'task' AS type, t.deleted_at,
        cl.name AS client_name,
        ROUND(EXTRACT(EPOCH FROM ((t.deleted_at + INTERVAL '30 days') - NOW())) / 86400) AS days_remaining
      FROM tasks t
      LEFT JOIN clients cl ON cl.id = t.client_id
      WHERE t.deleted_at IS NOT NULL
      ORDER BY t.deleted_at DESC
    `)

    // Deleted Files
    const filesRes = await query(`
      SELECT 
        f.id, f.name, 'file' AS type, f.deleted_at,
        cl.name AS client_name,
        ROUND(EXTRACT(EPOCH FROM ((f.deleted_at + INTERVAL '30 days') - NOW())) / 86400) AS days_remaining
      FROM files f
      LEFT JOIN clients cl ON cl.id = f.client_id
      WHERE f.deleted_at IS NOT NULL
      ORDER BY f.deleted_at DESC
    `)

    const allTrash = [...contentsRes.rows, ...tasksRes.rows, ...filesRes.rows]
    allTrash.sort((a, b) => new Date(b.deleted_at).getTime() - new Date(a.deleted_at).getTime())

    return c.json({ success: true, items: allTrash })
  } catch (err) {
    console.error('Fetch trash error:', err)
    return c.json({ success: false, error: 'Failed to fetch trash items' }, 500)
  }
})

// 2. Restore Item
trashRoutes.post('/restore/:type/:id', requireRoles('admin', 'super_admin'), async (c) => {
  const type = c.req.param('type')
  const id = c.req.param('id')

  try {
    let table = ''
    if (type === 'content') table = 'contents'
    else if (type === 'task') table = 'tasks'
    else if (type === 'file') table = 'files'
    else return c.json({ success: false, error: 'Invalid item type' }, 400)

    const res = await query(`UPDATE ${table} SET deleted_at = NULL WHERE id = $1 RETURNING id`, [id])
    if (res.rows.length === 0) {
      return c.json({ success: false, error: 'Item not found in trash' }, 404)
    }

    return c.json({ success: true, message: `Restored ${type} successfully` })
  } catch (err) {
    return c.json({ success: false, error: 'Failed to restore item' }, 500)
  }
})

// 3. Permanently Delete Item
trashRoutes.delete('/permanent/:type/:id', requireRoles('admin', 'super_admin'), async (c) => {
  const type = c.req.param('type')
  const id = c.req.param('id')

  try {
    let table = ''
    if (type === 'content') table = 'contents'
    else if (type === 'task') table = 'tasks'
    else if (type === 'file') table = 'files'
    else return c.json({ success: false, error: 'Invalid item type' }, 400)

    const res = await query(`DELETE FROM ${table} WHERE id = $1 RETURNING id`, [id])
    if (res.rows.length === 0) {
      return c.json({ success: false, error: 'Item not found' }, 404)
    }

    return c.json({ success: true, message: `Permanently deleted ${type}` })
  } catch (err) {
    return c.json({ success: false, error: 'Failed to permanently delete item' }, 500)
  }
})

// 4. Empty All Trash
trashRoutes.delete('/empty', requireRoles('admin', 'super_admin'), async (c) => {
  try {
    await query(`DELETE FROM contents WHERE deleted_at IS NOT NULL`)
    await query(`DELETE FROM tasks WHERE deleted_at IS NOT NULL`)
    await query(`DELETE FROM files WHERE deleted_at IS NOT NULL`)

    return c.json({ success: true, message: 'Trash emptied successfully' })
  } catch (err) {
    return c.json({ success: false, error: 'Failed to empty trash' }, 500)
  }
})

export default trashRoutes
