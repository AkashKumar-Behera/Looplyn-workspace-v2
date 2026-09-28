import { Hono } from 'hono'
import { query } from '../db'
import { authMiddleware, UserPayload, AuthEnv } from '../middleware/auth'

const activityRoutes = new Hono<AuthEnv>()

activityRoutes.use('*', authMiddleware)

// 1. Get Recent Activities Feed
activityRoutes.get('/', async (c) => {
  try {
    const res = await query(`
      SELECT 
        id, user_name, action, entity_type, entity_id, entity_title, details, created_at
      FROM activity_logs
      ORDER BY created_at DESC
      LIMIT 20
    `)
    return c.json({ success: true, activities: res.rows })
  } catch (err) {
    return c.json({ success: false, error: 'Failed to fetch activities' }, 500)
  }
})

// 2. Get 7-Day Content Stats for Activity Spline Graph
activityRoutes.get('/stats', async (c) => {
  try {
    const res = await query(`
      SELECT 
        TO_CHAR(d.day, 'YYYY-MM-DD') AS date_str,
        TO_CHAR(d.day, 'DD Mon') AS label,
        COALESCE(COUNT(c.id), 0)::int AS count
      FROM (
        SELECT generate_series(
          CURRENT_DATE - INTERVAL '6 days',
          CURRENT_DATE,
          INTERVAL '1 day'
        )::date AS day
      ) d
      LEFT JOIN contents c 
        ON DATE(c.created_at) = d.day AND c.deleted_at IS NULL
      GROUP BY d.day
      ORDER BY d.day ASC
    `)

    return c.json({ success: true, stats: res.rows })
  } catch (err) {
    console.error('Stats query error:', err)
    return c.json({ success: false, error: 'Failed to fetch activity stats' }, 500)
  }
})

export default activityRoutes
