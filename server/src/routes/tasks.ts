import { Hono } from 'hono'
import { query } from '../db'
import { authMiddleware, requireRoles, UserPayload, AuthEnv } from '../middleware/auth'

const taskRoutes = new Hono<AuthEnv>()

taskRoutes.use('*', authMiddleware)

// 1. List Tasks (with client isolation & filtering)
taskRoutes.get('/', async (c) => {
  const user = c.get('user') as UserPayload
  const clientId = c.req.query('client_id')
  const status = c.req.query('status')
  const priority = c.req.query('priority')

  try {
    let sql = `
      SELECT 
        t.id, t.title, t.description, t.status, t.priority, t.due_date, t.tags,
        t.created_at, t.updated_at,
        cl.id AS client_id, cl.name AS client_name, cl.logo_url AS client_logo,
        u.id AS assignee_id, u.name AS assignee_name, u.avatar_url AS assignee_avatar
      FROM tasks t
      LEFT JOIN clients cl ON cl.id = t.client_id
      LEFT JOIN users u ON u.id = t.assigned_to
      WHERE t.deleted_at IS NULL
    `
    const params: any[] = []

    if (user.role === 'client') {
      if (!user.clientId) {
        return c.json({ success: true, tasks: [] })
      }
      params.push(user.clientId)
      sql += ` AND t.client_id = $${params.length}`
    } else if (clientId) {
      params.push(clientId)
      sql += ` AND t.client_id = $${params.length}`
    }

    if (status) {
      params.push(status.toUpperCase())
      sql += ` AND UPPER(t.status) = $${params.length}`
    }

    if (priority) {
      params.push(priority.toUpperCase())
      sql += ` AND UPPER(t.priority) = $${params.length}`
    }

    sql += ` ORDER BY t.due_date ASC NULLS LAST, t.created_at DESC`

    const res = await query(sql, params)
    return c.json({ success: true, tasks: res.rows })
  } catch (err) {
    console.error('Fetch tasks error:', err)
    return c.json({ success: false, error: 'Failed to fetch tasks' }, 500)
  }
})

// 2. Create Task
taskRoutes.post('/', requireRoles('admin', 'staff', 'super_admin'), async (c) => {
  const user = c.get('user') as UserPayload
  try {
    const {
      title,
      description,
      client_id,
      status = 'TODO',
      priority = 'MEDIUM',
      assigned_to,
      due_date,
      tags = []
    } = await c.req.json()

    if (!title || !title.trim()) {
      return c.json({ success: false, error: 'Task title is required' }, 400)
    }

    const res = await query(
      `INSERT INTO tasks (
        title, description, client_id, status, priority, assigned_to, due_date, tags
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *`,
      [
        title.trim(),
        description || '',
        client_id || null,
        status.toUpperCase(),
        priority.toUpperCase(),
        assigned_to || null,
        due_date ? new Date(due_date) : null,
        JSON.stringify(tags)
      ]
    )

    await query(
      `INSERT INTO activity_logs (user_id, user_name, action, entity_type, entity_id, entity_title)
       VALUES ($1, $2, 'created task', 'task', $3, $4)`,
      [user.id, user.name || 'User', res.rows[0].id, title.trim()]
    )

    return c.json({ success: true, message: 'Task created successfully', task: res.rows[0] })
  } catch (err) {
    console.error('Create task error:', err)
    return c.json({ success: false, error: 'Failed to create task' }, 500)
  }
})

// 3. Update Task (PUT / PATCH)
const handleUpdateTask = async (c: any) => {
  const id = c.req.param('id')
  const user = c.get('user') as UserPayload

  try {
    const body = await c.req.json()
    const fields: string[] = []
    const values: any[] = []

    const allowed = ['title', 'description', 'client_id', 'status', 'priority', 'assigned_to', 'due_date', 'tags']

    for (const key of allowed) {
      if (body[key] !== undefined) {
        let val = body[key]
        if (key === 'status' || key === 'priority') {
          val = String(val).toUpperCase()
        }
        if (key === 'tags') {
          val = JSON.stringify(val)
        }
        if (key === 'due_date' && val) {
          val = new Date(val)
        }
        values.push(val)
        fields.push(`${key} = $${values.length}`)
      }
    }

    if (fields.length === 0) {
      return c.json({ success: false, error: 'No fields to update' }, 400)
    }

    values.push(id)
    const sql = `
      UPDATE tasks 
      SET ${fields.join(', ')}, updated_at = NOW() 
      WHERE id = $${values.length} 
      RETURNING *
    `

    const res = await query(sql, values)
    if (res.rows.length === 0) {
      return c.json({ success: false, error: 'Task not found' }, 404)
    }

    return c.json({ success: true, message: 'Task updated successfully', task: res.rows[0] })
  } catch (err) {
    console.error('Update task error:', err)
    return c.json({ success: false, error: 'Failed to update task' }, 500)
  }
}

taskRoutes.put('/:id', handleUpdateTask)
taskRoutes.patch('/:id', handleUpdateTask)

// 4. Soft Delete Task
taskRoutes.delete('/:id', requireRoles('admin', 'staff', 'super_admin'), async (c) => {
  const id = c.req.param('id')
  const isPermanent = c.req.query('permanent') === 'true'

  try {
    if (isPermanent) {
      const res = await query('DELETE FROM tasks WHERE id = $1 RETURNING id', [id])
      if (res.rows.length === 0) {
        return c.json({ success: false, error: 'Task not found' }, 404)
      }
      return c.json({ success: true, message: 'Task permanently deleted' })
    } else {
      const res = await query('UPDATE tasks SET deleted_at = NOW() WHERE id = $1 RETURNING id', [id])
      if (res.rows.length === 0) {
        return c.json({ success: false, error: 'Task not found' }, 404)
      }
      return c.json({ success: true, message: 'Task moved to trash' })
    }
  } catch (err) {
    return c.json({ success: false, error: 'Failed to delete task' }, 500)
  }
})

export default taskRoutes
