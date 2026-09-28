import { Hono } from 'hono'
import { query } from '../db'
import { authMiddleware, requireRoles, UserPayload, AuthEnv } from '../middleware/auth'

const emailRoutes = new Hono<AuthEnv>()

emailRoutes.use('*', authMiddleware)

// 1. List Templates
emailRoutes.get('/templates', async (c) => {
  try {
    const res = await query(`SELECT * FROM email_templates ORDER BY created_at DESC`)
    return c.json({ success: true, templates: res.rows })
  } catch (err) {
    return c.json({ success: false, error: 'Failed to fetch email templates' }, 500)
  }
})

// 2. Create Template
emailRoutes.post('/templates', requireRoles('admin', 'super_admin'), async (c) => {
  try {
    const { name, subject, body_html, category = 'studio', variables = [] } = await c.req.json()

    if (!name || !subject || !body_html) {
      return c.json({ success: false, error: 'Name, subject and body HTML are required' }, 400)
    }

    const res = await query(
      `INSERT INTO email_templates (name, subject, body_html, category, variables)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [name.trim(), subject.trim(), body_html, category, JSON.stringify(variables)]
    )

    return c.json({ success: true, message: 'Template created', template: res.rows[0] })
  } catch (err) {
    return c.json({ success: false, error: 'Failed to create template' }, 500)
  }
})

// 3. Update Template
emailRoutes.put('/templates/:id', requireRoles('admin', 'super_admin'), async (c) => {
  const id = c.req.param('id')
  try {
    const { name, subject, body_html, category, variables } = await c.req.json()

    const res = await query(
      `UPDATE email_templates 
       SET name = COALESCE($1, name),
           subject = COALESCE($2, subject),
           body_html = COALESCE($3, body_html),
           category = COALESCE($4, category),
           variables = COALESCE($5, variables),
           updated_at = NOW()
       WHERE id = $6
       RETURNING *`,
      [name, subject, body_html, category, variables ? JSON.stringify(variables) : null, id]
    )

    if (res.rows.length === 0) {
      return c.json({ success: false, error: 'Template not found' }, 404)
    }

    return c.json({ success: true, message: 'Template updated', template: res.rows[0] })
  } catch (err) {
    return c.json({ success: false, error: 'Failed to update template' }, 500)
  }
})

// 4. Delete Template
emailRoutes.delete('/templates/:id', requireRoles('admin', 'super_admin'), async (c) => {
  const id = c.req.param('id')
  try {
    const res = await query(`DELETE FROM email_templates WHERE id = $1 RETURNING id`, [id])
    if (res.rows.length === 0) {
      return c.json({ success: false, error: 'Template not found' }, 404)
    }
    return c.json({ success: true, message: 'Template deleted' })
  } catch (err) {
    return c.json({ success: false, error: 'Failed to delete template' }, 500)
  }
})

// 5. Send Test Email / Preview Render
emailRoutes.post('/send-test', requireRoles('admin', 'staff', 'super_admin'), async (c) => {
  const user = c.get('user') as UserPayload
  try {
    const { template_id, recipient_email, sample_data = {} } = await c.req.json()
    const targetEmail = recipient_email || user.email

    const tplRes = await query(`SELECT * FROM email_templates WHERE id = $1`, [template_id])
    if (tplRes.rows.length === 0) {
      return c.json({ success: false, error: 'Template not found' }, 404)
    }

    const tpl = tplRes.rows[0]
    let renderedSubject = tpl.subject
    let renderedBody = tpl.body_html

    // Variable interpolation
    const mergedData: Record<string, string> = {
      client_name: 'Acme Studio',
      post_title: 'Autumn Campaign 2026',
      review_link: 'https://work.looplyn.tech/review',
      feedback_notes: 'Looks fantastic, please brighten the thumbnail.',
      ...sample_data
    }

    for (const [key, val] of Object.entries(mergedData)) {
      renderedSubject = renderedSubject.replace(new RegExp(`{{${key}}}`, 'g'), val)
      renderedBody = renderedBody.replace(new RegExp(`{{${key}}}`, 'g'), val)
    }

    return c.json({
      success: true,
      message: `Test email simulated successfully to ${targetEmail}`,
      preview: {
        to: targetEmail,
        subject: renderedSubject,
        html: renderedBody
      }
    })
  } catch (err) {
    return c.json({ success: false, error: 'Failed to send test email' }, 500)
  }
})

export default emailRoutes
