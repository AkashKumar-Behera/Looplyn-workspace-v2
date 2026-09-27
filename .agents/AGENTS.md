# Looplyn V2 - Permanent Agent Guidelines, Architecture & Project Context

## 🌐 Language Rules
- Respond in Hinglish or English as requested by the user.

---

## 🚨 CRITICAL BEHAVIORAL & WORKFLOW RULES (PERMANENT)
1. **NO CODE MODIFICATIONS WITHOUT EXPLICIT PERMISSION**:
   - NEVER make unapproved code edits or file changes without prior discussion and user confirmation.
   - Any inquiry (`?`) or topic must be explained with clear technical reasoning first.
2. **DETAILED TECHNICAL REASONING REQUIRED**:
   - Explain every design decision, trade-off, and architectural choice before proposing implementations.
3. **NEVER BE OVERSMART OR ASSUME**:
   - Always ask for intent and confirm requirements.
4. **GIT PUSH DIRECTIVE**:
   - NEVER run `git push` autonomously. Only commit locally (`git commit`) when requested.
5. **SUPER ADMIN ROLE BOUNDARY**:
   - Super Admin (`admin@looplyn.tech`) is strictly and exclusively for creating & managing Agency Admin accounts.
   - NEVER expose or seed `super_admin` in chat channels, DM peer pickers, or daily content workflow.

---

## 🏗️ Core Technology Stack & Infrastructure

| Layer | Technology |
| :--- | :--- |
| **Backend API** | Hono (TypeScript + Node.js) on Port 5000 |
| **Frontend App** | Flutter 3.44+ (Multi-Platform: Android, iOS PWA/Sideload, Windows Desktop, macOS, Web) |
| **Database** | PostgreSQL 16 (Hosted on Dokploy VPS, Database name: `looplyn`) |
| **PaaS / Hosting** | Dokploy on VPS with Traefik Auto-SSL (`workspace.looplyn.tech`) |
| **Media / Storage** | Cloudflare R2 (S3-compatible, Zero Egress Fees) |
| **Auth** | JWT (30-day token) + bcryptjs password hashing |
| **Emails** | Resend API (Password reset magic links & alerts) |
| **Push Alerts** | Firebase Cloud Messaging (FCM Admin SDK) |

---

## 📊 Live Progress & Milestones Tracker

- [x] **Phase 1: Setup & Foundation**
  - [x] Hono backend API engine with CORS & Health check.
  - [x] PostgreSQL clean table schemas (`users`, `clients`, `contents`, `content_comments`, `channels`, `messages`, `password_resets`).
  - [x] Flutter multi-platform codebase generated (`client_app`).
  - [x] Looplyn Dark Theme & Dio HTTP Client with JWT interceptors.

- [x] **Phase 2: Auth & Role-Based Access**
  - [x] JWT + Bcrypt Login endpoint (`/api/v1/auth/login`).
  - [x] Role-Based Access Control middleware (`super_admin`, `admin`, `staff`, `client`).
  - [x] Firebase-style magic password reset flow with token validation.
  - [x] Flutter Login, Forgot Password, and Reset Password screens.

- [x] **Phase 3: Studio & Content Calendar**
  - [x] Contents CRUD endpoints (`/api/v1/contents`) with role isolation.
  - [x] Flutter 5-Stage Kanban Workflow Screen (`Ideas` -> `In Progress` -> `In Review` -> `Approved` -> `Published`).
  - [x] Create Content modal with social platform and format tags.

- [x] **Phase 4: Client Portal & 1-Tap Approvals**
  - [x] Content Approval (`/approve`) and Request Changes (`/request-changes`) API.
  - [x] Content comments thread API (`/comments`).
  - [x] Flutter Client Review screen with 9:16 vertical media player & floating action buttons.

- [x] **Phase 5: Chat Hub & Real-Time Messaging**
  - [x] Channels (`/chat/channels`) and Messages (`/chat/messages`) API.
  - [x] Flutter 2-Pane Slack-style Chat Hub with real-time stream layout.

- [ ] **Current Active Task: Dokploy VPS PostgreSQL & Cloudflare R2 Setup**
  - [x] Database created on Dokploy (`looplyn-db`, db: `looplyn`, user: `postgres`, password: `LooplynPostgres2026`).
  - [ ] Connect VPS PostgreSQL connection string to local `.env`.
  - [ ] Cloudflare R2 bucket configuration & presigned upload endpoint.
  - [ ] Build & Test Flutter on Chrome/Windows & Dokploy deployment.
