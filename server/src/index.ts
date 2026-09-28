import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { serve } from '@hono/node-server'
import { initDB } from './db'
import authRoutes from './routes/auth'
import contentRoutes from './routes/contents'
import chatRoutes from './routes/chat'
import clientRoutes from './routes/clients'
import taskRoutes from './routes/tasks'
import fileRoutes from './routes/files'
import emailRoutes from './routes/emails'
import trashRoutes from './routes/trash'
import activityRoutes from './routes/activity'
import settingsRoutes from './routes/settings'

const app = new Hono()

// Global CORS Middleware
app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization']
}))

// Health Check
app.get('/health', (c) => {
  return c.json({
    status: 'ok',
    service: 'Looplyn V2 Hono API',
    speed: '⚡ Ultra-fast',
    timestamp: new Date().toISOString()
  })
})

// Mount Routes
app.route('/api/v1/auth', authRoutes)
app.route('/api/v1/contents', contentRoutes)
app.route('/api/v1/chat', chatRoutes)
app.route('/api/v1/clients', clientRoutes)
app.route('/api/v1/tasks', taskRoutes)
app.route('/api/v1/files', fileRoutes)
app.route('/api/v1/emails', emailRoutes)
app.route('/api/v1/trash', trashRoutes)
app.route('/api/v1/activity', activityRoutes)
app.route('/api/v1/settings', settingsRoutes)

// 404 Handler
app.notFound((c) => {
  return c.json({ success: false, error: 'Endpoint not found' }, 404)
})

// Error Handler
app.onError((err, c) => {
  console.error('Unhandled server error:', err)
  return c.json({ success: false, error: err.message || 'Internal Server Error' }, 500)
})

const port = Number(process.env.PORT) || 5000

initDB().then(() => {
  console.log(`🚀 Looplyn V2 Server running on http://localhost:${port}`)
  serve({
    fetch: app.fetch,
    port
  })
})

export default app
