import { Hono } from 'hono'
import { query } from '../db'
import { authMiddleware, requireRoles, UserPayload, AuthEnv } from '../middleware/auth'

const contentRoutes = new Hono<AuthEnv>()

// Apply Auth to all content endpoints
contentRoutes.use('*', authMiddleware)

// 1. List Contents / Calendar Posts (with RBAC isolation)
contentRoutes.get('/', async (c) => {
  const user = c.get('user') as UserPayload
  const clientId = c.req.query('client_id')
  const status = c.req.query('status')
  const platform = c.req.query('platform')

  try {
    let sql = `
      SELECT 
        c.id, c.title, c.description, c.platform, c.format, c.status, 
        c.priority, c.scheduled_date, c.media_urls, c.caption, c.created_at,
        cl.id AS client_id, cl.name AS client_name, cl.logo_url AS client_logo,
        u.id AS staff_id, u.name AS staff_name, u.avatar_url AS staff_avatar
      FROM contents c
      LEFT JOIN clients cl ON cl.id = c.client_id
      LEFT JOIN users u ON u.id = c.assigned_staff_id
      WHERE 1=1
    `
    const params: any[] = []

    // Strict Client Isolation: If logged in as client, only show their client_id
    if (user.role === 'client') {
      if (!user.clientId) {
        return c.json({ success: true, contents: [] })
      }
      params.push(user.clientId)
      sql += ` AND c.client_id = $${params.length}`
    } else if (clientId) {
      params.push(clientId)
      sql += ` AND c.client_id = $${params.length}`
    }

    if (status) {
      params.push(status.toUpperCase())
      sql += ` AND UPPER(c.status) = $${params.length}`
    }

    if (platform) {
      params.push(platform.toUpperCase())
      sql += ` AND UPPER(c.platform) = $${params.length}`
    }

    sql += ` ORDER BY c.scheduled_date ASC NULLS LAST, c.created_at DESC`

    const res = await query(sql, params)
    return c.json({ success: true, contents: res.rows })
  } catch (err) {
    console.error('Fetch contents error:', err)
    return c.json({ success: false, error: 'Failed to fetch contents' }, 500)
  }
})

// 2. Get Single Content Item Details
contentRoutes.get('/:id', async (c) => {
  const id = c.req.param('id')
  const user = c.get('user') as UserPayload

  try {
    const res = await query(
      `SELECT 
        c.*, 
        cl.name AS client_name, cl.logo_url AS client_logo,
        u.name AS staff_name, u.avatar_url AS staff_avatar
       FROM contents c
       LEFT JOIN clients cl ON cl.id = c.client_id
       LEFT JOIN users u ON u.id = c.assigned_staff_id
       WHERE c.id = $1`,
      [id]
    )

    if (res.rows.length === 0) {
      return c.json({ success: false, error: 'Content item not found' }, 404)
    }

    const item = res.rows[0]

    // Client role check
    if (user.role === 'client' && item.client_id !== user.clientId) {
      return c.json({ success: false, error: 'Forbidden' }, 403)
    }

    return c.json({ success: true, content: item })
  } catch (err) {
    return c.json({ success: false, error: 'Failed to fetch content details' }, 500)
  }
})

// 3. Create Content Item (Admin & Staff)
contentRoutes.post('/', requireRoles('admin', 'staff', 'super_admin'), async (c) => {
  try {
    const {
      title,
      description,
      client_id,
      platform = 'INSTAGRAM',
      format = 'REEL',
      status = 'IDEA',
      priority = 'Medium',
      assigned_staff_id,
      scheduled_date,
      media_urls = [],
      caption = ''
    } = await c.req.json()

    if (!title || !title.trim()) {
      return c.json({ success: false, error: 'Title is required' }, 400)
    }

    const res = await query(
      `INSERT INTO contents (
        title, description, client_id, platform, format, status, priority, 
        assigned_staff_id, scheduled_date, media_urls, caption
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      RETURNING *`,
      [
        title.trim(),
        description || '',
        client_id || null,
        platform.toUpperCase(),
        format.toUpperCase(),
        status.toUpperCase(),
        priority,
        assigned_staff_id || null,
        scheduled_date ? new Date(scheduled_date) : null,
        JSON.stringify(media_urls),
        caption
      ]
    )

    return c.json({ success: true, message: 'Content created successfully', content: res.rows[0] })
  } catch (err) {
    console.error('Create content error:', err)
    return c.json({ success: false, error: 'Failed to create content' }, 500)
  }
})

// 4. Update Content Item (Supports both PUT & PATCH for drag-and-drop & status updates)
const handleUpdateContent = async (c: any) => {
  const id = c.req.param('id')
  const user = c.get('user') as UserPayload

  try {
    const body = await c.req.json()
    const fields: string[] = []
    const values: any[] = []

    const allowedUpdates = [
      'title', 'description', 'client_id', 'platform', 'format', 
      'status', 'priority', 'assigned_staff_id', 'scheduled_date', 
      'media_urls', 'caption'
    ]

    for (const key of allowedUpdates) {
      if (body[key] !== undefined) {
        let val = body[key]
        if (key === 'platform' || key === 'format' || key === 'status') {
          val = String(val).toUpperCase()
        }
        if (key === 'media_urls') {
          val = JSON.stringify(val)
        }
        if (key === 'scheduled_date' && val) {
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
      UPDATE contents 
      SET ${fields.join(', ')}, updated_at = NOW() 
      WHERE id = $${values.length} 
      RETURNING *
    `

    const res = await query(sql, values)
    if (res.rows.length === 0) {
      return c.json({ success: false, error: 'Content item not found' }, 404)
    }

    return c.json({ success: true, message: 'Content updated successfully', content: res.rows[0] })
  } catch (err) {
    console.error('Update content error:', err)
    return c.json({ success: false, error: 'Failed to update content' }, 500)
  }
}

contentRoutes.put('/:id', handleUpdateContent)
contentRoutes.patch('/:id', handleUpdateContent)

// 5. Client 1-Tap Approve Endpoint
contentRoutes.post('/:id/approve', async (c) => {
  const id = c.req.param('id')
  const user = c.get('user') as UserPayload

  try {
    const res = await query(
      `UPDATE contents 
       SET status = 'APPROVED', updated_at = NOW() 
       WHERE id = $1 
       RETURNING *`,
      [id]
    )

    if (res.rows.length === 0) {
      return c.json({ success: false, error: 'Content item not found' }, 404)
    }

    // Optional: Auto log approval comment
    await query(
      `INSERT INTO content_comments (content_id, author_id, comment)
       VALUES ($1, $2, '✅ Approved the content')`,
      [id, user.id]
    )

    return c.json({ success: true, message: 'Content approved successfully!', content: res.rows[0] })
  } catch (err) {
    console.error('Approve content error:', err)
    return c.json({ success: false, error: 'Failed to approve content' }, 500)
  }
})

// 6. Client Request Changes Endpoint
contentRoutes.post('/:id/request-changes', async (c) => {
  const id = c.req.param('id')
  const user = c.get('user') as UserPayload
  const { feedback } = await c.req.json()

  try {
    const res = await query(
      `UPDATE contents 
       SET status = 'IN_PROGRESS', updated_at = NOW() 
       WHERE id = $1 
       RETURNING *`,
      [id]
    )

    if (res.rows.length === 0) {
      return c.json({ success: false, error: 'Content item not found' }, 404)
    }

    if (feedback && feedback.trim()) {
      await query(
        `INSERT INTO content_comments (content_id, author_id, comment)
         VALUES ($1, $2, $3)`,
        [id, user.id, `❌ Changes Requested: ${feedback.trim()}`]
      )
    }

    return c.json({ success: true, message: 'Changes requested successfully', content: res.rows[0] })
  } catch (err) {
    console.error('Request changes error:', err)
    return c.json({ success: false, error: 'Failed to request changes' }, 500)
  }
})

// 7. Get Comments Thread for Content Item
contentRoutes.get('/:id/comments', async (c) => {
  const id = c.req.param('id')

  try {
    const res = await query(
      `SELECT 
        cc.id, cc.comment, cc.created_at,
        u.id AS author_id, u.name AS author_name, u.role AS author_role, u.avatar_url AS author_avatar
       FROM content_comments cc
       JOIN users u ON u.id = cc.author_id
       WHERE cc.content_id = $1
       ORDER BY cc.created_at ASC`,
      [id]
    )
    return c.json({ success: true, comments: res.rows })
  } catch (err) {
    return c.json({ success: false, error: 'Failed to fetch comments' }, 500)
  }
})

// 8. Add Comment to Content Item
contentRoutes.post('/:id/comments', async (c) => {
  const id = c.req.param('id')
  const user = c.get('user') as UserPayload
  const { comment } = await c.req.json()

  if (!comment || !comment.trim()) {
    return c.json({ success: false, error: 'Comment cannot be empty' }, 400)
  }

  try {
    const res = await query(
      `INSERT INTO content_comments (content_id, author_id, comment)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [id, user.id, comment.trim()]
    )
    return c.json({ success: true, comment: res.rows[0] })
  } catch (err) {
    return c.json({ success: false, error: 'Failed to post comment' }, 500)
  }
})

// 9. Delete Content Item (Admin Only)
contentRoutes.delete('/:id', requireRoles('admin', 'super_admin'), async (c) => {
  const id = c.req.param('id')
  try {
    const res = await query('DELETE FROM contents WHERE id = $1 RETURNING id', [id])
    if (res.rows.length === 0) {
      return c.json({ success: false, error: 'Content item not found' }, 404)
    }
    return c.json({ success: true, message: 'Content item deleted' })
  } catch (err) {
    return c.json({ success: false, error: 'Failed to delete content' }, 500)
  }
})

export default contentRoutes
