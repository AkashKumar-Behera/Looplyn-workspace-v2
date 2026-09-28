import { Context, Next } from 'hono'
import jwt from 'jsonwebtoken'

const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_looplyn_jwt_2026_key_production'

export interface UserPayload {
  id: string
  email: string
  role: 'super_admin' | 'admin' | 'staff' | 'client'
  name: string
  clientId?: string
  avatarUrl?: string
}

export type AuthEnv = {
  Variables: {
    user: UserPayload
  }
}

export const authMiddleware = async (c: Context<AuthEnv>, next: Next) => {
  const authHeader = c.req.header('Authorization')

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ success: false, error: 'Unauthorized: Missing or invalid token' }, 401)
  }

  const token = authHeader.split('Bearer ')[1].trim()

  try {
    const decoded = jwt.verify(token, JWT_SECRET) as UserPayload
    c.set('user', decoded)
    await next()
  } catch (err) {
    return c.json({ success: false, error: 'Unauthorized: Token expired or invalid' }, 401)
  }
}

export const requireRoles = (...allowedRoles: string[]) => {
  return async (c: Context<AuthEnv>, next: Next) => {
    const user = c.get('user')
    if (!user || !allowedRoles.includes(user.role)) {
      return c.json({ success: false, error: 'Forbidden: Insufficient role permissions' }, 403)
    }
    await next()
  }
}
