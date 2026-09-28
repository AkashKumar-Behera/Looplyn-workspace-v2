import { Hono } from 'hono'
import { query } from '../db'
import { authMiddleware, requireRoles, UserPayload, AuthEnv } from '../middleware/auth'

const chatRoutes = new Hono<AuthEnv>()

chatRoutes.use('*', authMiddleware)

// 1. List Eligible Peers for Direct Messages (Admin, Staff, Client - strictly NO super_admin)
chatRoutes.get('/eligible-peers', async (c) => {
  const user = c.get('user') as UserPayload

  try {
    let sql = `
      SELECT id, name, email, role, custom_role, avatar_url, status
      FROM users
      WHERE role != 'super_admin' AND id != $1
    `
    const params: any[] = [user.id]

    // If client is logged in, they can only DM admins and assigned staff
    if (user.role === 'client') {
      sql += ` AND (role = 'admin' OR role = 'staff')`
    }

    sql += ` ORDER BY role ASC, name ASC`

    const res = await query(sql, params)
    return c.json({ success: true, peers: res.rows })
  } catch (err) {
    console.error('Fetch peers error:', err)
    return c.json({ success: false, error: 'Failed to fetch direct chat peers' }, 500)
  }
})

// 2. List Channels Accessible to Logged-in User
chatRoutes.get('/channels', async (c) => {
  const user = c.get('user') as UserPayload

  try {
    let sql = `
      SELECT 
        ch.id, ch.name, ch.type, ch.client_id, ch.created_at,
        cl.name AS client_name, cl.logo_url AS client_logo,
        (SELECT text FROM messages WHERE channel_id = ch.id ORDER BY created_at DESC LIMIT 1) AS last_message,
        (SELECT created_at FROM messages WHERE channel_id = ch.id ORDER BY created_at DESC LIMIT 1) AS last_message_time
      FROM channels ch
      LEFT JOIN clients cl ON cl.id = ch.client_id
      WHERE 1=1
    `
    const params: any[] = []

    if (user.role === 'client') {
      if (!user.clientId) {
        return c.json({ success: true, channels: [] })
      }
      params.push(user.clientId)
      sql += ` AND (ch.client_id = $${params.length})`
    } else if (user.role === 'super_admin') {
      return c.json({ success: true, channels: [] })
    }

    sql += ` ORDER BY last_message_time DESC NULLS LAST, ch.created_at DESC`

    const res = await query(sql, params)

    // Auto-seed default general channel if none exist
    if (res.rows.length === 0 && user.role !== 'client') {
      const defaultChan = await query(`
        INSERT INTO channels (name, type)
        VALUES ('general', 'PUBLIC'), ('announcements', 'PUBLIC'), ('design-feedback', 'PUBLIC')
        RETURNING *
      `)
      return c.json({ success: true, channels: defaultChan.rows })
    }

    return c.json({ success: true, channels: res.rows })
  } catch (err) {
    console.error('Fetch channels error:', err)
    return c.json({ success: false, error: 'Failed to fetch channels' }, 500)
  }
})

// 3. Create Channel (Admin & Staff)
chatRoutes.post('/channels', requireRoles('admin', 'staff'), async (c) => {
  try {
    const { name, type = 'PUBLIC', client_id } = await c.req.json()

    if (!name || !name.trim()) {
      return c.json({ success: false, error: 'Channel name is required' }, 400)
    }

    const cleanName = name.trim().toLowerCase().replace(/\s+/g, '-')
    const res = await query(
      `INSERT INTO channels (name, type, client_id)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [cleanName, type.toUpperCase(), client_id || null]
    )

    return c.json({ success: true, message: 'Channel created successfully', channel: res.rows[0] })
  } catch (err) {
    console.error('Create channel error:', err)
    return c.json({ success: false, error: 'Failed to create channel' }, 500)
  }
})

// 4. Get Messages for a Channel
chatRoutes.get('/channels/:id/messages', async (c) => {
  const channelId = c.req.param('id')

  try {
    const res = await query(
      `SELECT 
        m.id, m.text, m.attachments, m.created_at,
        u.id AS sender_id, u.name AS sender_name, u.role AS sender_role, u.avatar_url AS sender_avatar
       FROM messages m
       JOIN users u ON u.id = m.sender_id
       WHERE m.channel_id = $1
       ORDER BY m.created_at ASC
       LIMIT 100`,
      [channelId]
    )

    return c.json({ success: true, messages: res.rows })
  } catch (err) {
    console.error('Fetch messages error:', err)
    return c.json({ success: false, error: 'Failed to fetch messages' }, 500)
  }
})

// 5. Send Message to Channel
chatRoutes.post('/channels/:id/messages', async (c) => {
  const channelId = c.req.param('id')
  const user = c.get('user') as UserPayload
  const { text, attachments = [] } = await c.req.json()

  if (!text || !text.trim()) {
    return c.json({ success: false, error: 'Message cannot be empty' }, 400)
  }

  try {
    const res = await query(
      `INSERT INTO messages (channel_id, sender_id, text, attachments)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [channelId, user.id, text.trim(), JSON.stringify(attachments)]
    )

    const fullMsg = {
      ...res.rows[0],
      sender_name: user.name,
      sender_role: user.role,
      sender_avatar: user.avatarUrl
    }

    return c.json({ success: true, message: fullMsg })
  } catch (err) {
    console.error('Send message error:', err)
    return c.json({ success: false, error: 'Failed to send message' }, 500)
  }
})

// 6. Get Direct Messages Thread with a Peer
chatRoutes.get('/direct/:peerId/messages', async (c) => {
  const peerId = c.req.param('peerId')
  const user = c.get('user') as UserPayload

  try {
    const res = await query(
      `SELECT 
        m.id, m.text, m.attachments, m.created_at,
        u.id AS sender_id, u.name AS sender_name, u.role AS sender_role, u.avatar_url AS sender_avatar
       FROM messages m
       JOIN users u ON u.id = m.sender_id
       WHERE (m.sender_id = $1 AND m.recipient_id = $2)
          OR (m.sender_id = $2 AND m.recipient_id = $1)
       ORDER BY m.created_at ASC
       LIMIT 100`,
      [user.id, peerId]
    )

    return c.json({ success: true, messages: res.rows })
  } catch (err) {
    console.error('Fetch DM error:', err)
    return c.json({ success: false, error: 'Failed to fetch direct messages' }, 500)
  }
})

// 7. Send Direct Message to a Peer
chatRoutes.post('/direct/:peerId/messages', async (c) => {
  const peerId = c.req.param('peerId')
  const user = c.get('user') as UserPayload
  const { text, attachments = [] } = await c.req.json()

  if (!text || !text.trim()) {
    return c.json({ success: false, error: 'Message cannot be empty' }, 400)
  }

  try {
    const res = await query(
      `INSERT INTO messages (recipient_id, sender_id, text, attachments)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [peerId, user.id, text.trim(), JSON.stringify(attachments)]
    )

    const fullMsg = {
      ...res.rows[0],
      sender_name: user.name,
      sender_role: user.role,
      sender_avatar: user.avatarUrl
    }

    return c.json({ success: true, message: fullMsg })
  } catch (err) {
    console.error('Send DM error:', err)
    return c.json({ success: false, error: 'Failed to send direct message' }, 500)
  }
})

export default chatRoutes
