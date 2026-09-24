# Study Planner — Backend

API server cho ứng dụng quản lý thời gian và kế hoạch tự học dành cho chủng sinh. Xử lý xác thực người dùng, CRUD dữ liệu, và tạo dữ liệu mẫu. Dữ liệu lưu trong Supabase (PostgreSQL).

## Kiến trúc

```
Frontend (Next.js)  →  Backend API (Express)  →  Supabase (PostgreSQL)
```

Backend đóng vai trò trung gian:
- Xác thực token từ frontend, tạo Supabase client riêng cho từng user
- CRUD tất cả bảng dữ liệu qua route `/api/:table`
- Tải tất cả dữ liệu người dùng trong một lần qua route `/api/data`
- Tạo dữ liệu mẫu khi đăng ký tài khoản mới qua route `/api/seed`

## Công nghệ

| Công nghệ | Vai trò |
|-----------|---------|
| Express.js | Web framework (Node.js) |
| TypeScript | Ngôn ngữ lập trình |
| Supabase JS SDK | Database client + Auth |
| dotenv | Nạp biến môi trường |
| cors | Cross-origin resource sharing |

## Cấu trúc thư mục

```
backend/
├── src/
│   ├── index.ts                # Entry point: Express app, routes, CORS
│   ├── lib/
│   │   └── supabase.ts         # Supabase client + createUserClient(token)
│   ├── middleware/
│   │   └── auth.ts             # Auth middleware: verify JWT, tạo userClient
│   └── routes/
│       ├── auth.ts             # POST /api/auth/signup, /signin, /session
│       ├── data.ts             # GET /api/data — tải tất cả dữ liệu user
│       ├── crud.ts             # GET/POST/PUT/DELETE /api/:table
│       └── seed.ts             # POST /api/seed — tạo dữ liệu mẫu
│
├── supabase/
│   └── migrations/
│       ├── 20260922092619_create_initial_schema.sql  # Tạo 15 bảng + RLS
│       └── 20260923012252_add_multi_user_auth.sql    # Thêm user_id + RLS multi-user
│
├── dist/                       # Build output (tự động tạo khi build)
├── tsconfig.json               # TypeScript config
├── package.json                # Dependencies + scripts
├── .env.example                # Biến môi trường mẫu
└── .gitignore
```

## API Endpoints

### Auth (`/api/auth`)

| Method | Path | Mô tả |
|--------|------|------|
| POST | `/api/auth/signup` | Đăng ký tài khoản mới |
| POST | `/api/auth/signin` | Đăng nhập, trả về access_token + refresh_token |
| POST | `/api/auth/signout` | Đăng xuất (client-side) |
| GET | `/api/auth/session` | Kiểm tra token, trả về user info |

### Data (`/api/data`)

| Method | Path | Mô tả |
|--------|------|------|
| GET | `/api/data` | Tải tất cả dữ liệu người dùng (settings, activities, schedule, sessions, tasks, journal, books, goals, progress) |

### Seed (`/api/seed`)

| Method | Path | Mô tả |
|--------|------|------|
| POST | `/api/seed` | Tạo dữ liệu mẫu cho user mới (cài đặt, 17 hoạt động cố định, 6 môn học, thời khóa biểu, mục tiêu tiếng Anh, sách mẫu, mục tiêu học kỳ) |

### CRUD (`/api/:table`)

| Method | Path | Mô tả |
|--------|------|------|
| GET | `/api/:table` | SELECT — hỗ trợ filter, order, limit, single, maybeSingle |
| POST | `/api/:table` | INSERT — chấp nhận single object hoặc array |
| PUT | `/api/:table` | UPDATE — yêu cầu filter_field + filter_value |
| DELETE | `/api/:table` | DELETE — yêu cầu filter_field + filter_value hoặc filter_in |

**Các bảng cho phép:** `books`, `study_sessions`, `journal_entries`, `schedule_entries`, `settings`, `weekly_goals`, `instrument_practices`, `weekly_reviews`, `tasks`, `fixed_activities`, `study_subjects`, `daily_progress`

**Query params cho GET:**
- `select` — cột cần select (mặc định: `*`)
- `filter_field` + `filter_value` — lọc theo `eq`
- `filter_field` + `filter_in` — lọc theo `in` (giá trị cách nhau bằng dấu phẩy)
- `order` — sắp xếp: `column:true` (ASC) hoặc `column:false` (DESC)
- `limit` — giới hạn số dòng
- `single=true` — trả về 1 dòng (throw error nếu không có)
- `maybe_single=true` — trả về 1 dòng hoặc null

## Biến môi trường

Sao chép `.env.example` thành `.env` và điền giá trị:

```bash
cp .env.example .env
```

| Biến | Mô tả | Ví dụ |
|------|-------|------|
| `SUPABASE_URL` | URL Supabase project | `https://xxxx.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase anon key | `eyJ...` |
| `PORT` | Port chạy backend | `3001` |
| `FRONTEND_URL` | URL frontend (cho CORS) | `http://localhost:3000` |

## Cài đặt và chạy

### Yêu cầu

- Node.js 18+
- npm 9+

### Chạy local

```bash
# 1. Cài dependencies
npm install

# 2. Tạo file .env
cp .env.example .env
# Chỉnh sửa .env với Supabase URL và key của bạn

# 3. Chạy dev server (hot reload)
npm run dev

# 4. Backend chạy tại
# http://localhost:3001
```

### Build production

```bash
npm run build    # Bi dịch TypeScript → dist/
npm start        # Chạy từ dist/
```

### Kiểm tra TypeScript

```bash
npm run typecheck
```

## Database Migration

### Bước 1: Tạo Supabase project

1. Vào [supabase.com](https://supabase.com) → tạo project mới
2. Lấy `Project URL` và `anon key` từ Settings → API
3. Điền vào `.env`

### Bước 2: Chạy migration

Database có 2 file migration, chạy theo thứ tự:

**Migration 1: Tạo schema ban đầu** (`20260922092619_create_initial_schema.sql`)

Tạo 15 bảng: `settings`, `fixed_activities`, `schedule_entries`, `study_subjects`, `tasks`, `study_sessions`, `journal_entries`, `books`, `instrument_practices`, `weekly_goals`, `monthly_goals`, `semester_goals`, `daily_progress`, `weekly_reviews`, `monthly_reviews`.

Mỗi bảng có RLS bật với policy `TO anon, authenticated USING (true)` (single-user).

**Migration 2: Thêm multi-user auth** (`20260923012252_add_multi_user_auth.sql`)

- Thêm cột `user_id` (FK → `auth.users`) vào tất cả bảng
- Đặt `DEFAULT auth.uid()` cho cột `user_id`
- Cập nhật unique constraints để bao gồm `user_id`
- Thay thế tất cả RLS policies: chuyển từ `USING (true)` sang `auth.uid() = user_id`
- Tạo 4 policy riêng biệt (SELECT, INSERT, UPDATE, DELETE) cho mỗi bảng

### Cách chạy migration

**Cách 1: Qua Supabase Dashboard (khuyến nghị)**

1. Vào Supabase Dashboard → SQL Editor
2. Copy nội dung file `20260922092619_create_initial_schema.sql` → dán → Run
3. Copy nội dung file `20260923012252_add_multi_user_auth.sql` → dán → Run

**Cách 2: Qua Supabase MCP tools (nếu dùng Bolt)**

```
# Apply migration 1
mcp__supabase__apply_migration(
  filename: "20260922092619_create_initial_schema",
  content: "<nội dung file SQL>"
)

# Apply migration 2
mcp__supabase__apply_migration(
  filename: "20260923012252_add_multi_user_auth",
  content: "<nội dung file SQL>"
)
```

**Cách 3: Qua psql (command line)**

```bash
# Kết nối đến database
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres"

# Chạy migration 1
\i supabase/migrations/20260922092619_create_initial_schema.sql

# Chạy migration 2
\i supabase/migrations/20260923012252_add_multi_user_auth.sql
```

### Kiểm tra migration thành công

```sql
-- Kiểm tra số bảng đã tạo
SELECT count(*) FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
-- Kết quả mong đợi: 15

-- Kiểm tra RLS đã bật
SELECT tablename, rowsecurity FROM pg_tables
WHERE schemaname = 'public' AND rowsecurity = true;
-- Kết quả mong đợi: 15 dòng

-- Kiểm tra user_id column đã thêm
SELECT tablename FROM information_schema.columns
WHERE column_name = 'user_id' AND table_schema = 'public';
-- Kết quả mong đợi: 15 dòng
```

### Schema tổng quan

| Bảng | Mô tả | RLS |
|------|-------|-----|
| `settings` | Cài đặt cá nhân (giờ giấc, mục tiêu, thông báo) | `auth.uid() = user_id` |
| `fixed_activities` | Hoạt động cố định hàng ngày | `auth.uid() = user_id` |
| `schedule_entries` | Lịch học cố định theo thứ | `auth.uid() = user_id` |
| `study_subjects` | Môn học (Tiếng Anh, Việt văn, Đàn, Đọc sách...) | `auth.uid() = user_id` |
| `tasks` | Nhiệm vụ/bài tập cần hoàn thành | `auth.uid() = user_id` |
| `study_sessions` | Phiên tự học (tự động hoặc thủ công) | `auth.uid() = user_id` |
| `journal_entries` | Nhật ký thiêng liêng (6 câu hỏi phản tỉnh) | `auth.uid() = user_id` |
| `books` | Sách đang đọc / đã đọc | `auth.uid() = user_id` |
| `instrument_practices` | Buổi luyện đàn | `auth.uid() = user_id` |
| `weekly_goals` | Mục tiêu tuần (theo môn/kỹ năng) | `auth.uid() = user_id` |
| `monthly_goals` | Mục tiêu tháng | `auth.uid() = user_id` |
| `semester_goals` | Mục tiêu học kỳ | `auth.uid() = user_id` |
| `daily_progress` | Tiến độ mỗi ngày | `auth.uid() = user_id` |
| `weekly_reviews` | Tổng kết tuần | `auth.uid() = user_id` |
| `monthly_reviews` | Tổng kết tháng | `auth.uid() = user_id` |

## Deploy

### VPS / Docker

```bash
# Build
npm run build

# Chạy với PM2
npm install -g pm2
pm2 start npm --name "study-planner-api" -- start

# Hoặc chạy trực tiếp
npm start
```

### Render / Railway / Fly.io

1. Push code lên GitHub
2. Tạo project mới, chọn repo
3. Build command: `npm install && npm run build`
4. Start command: `npm start`
5. Thêm biến môi trường (same as `.env.example`)

## Liên kết với Frontend

Backend cung cấp API REST cho frontend. Frontend gọi:
- `NEXT_PUBLIC_API_URL` — URL backend (mặc định: `http://localhost:3001/api`)
- Tất cả request kèm `Authorization: Bearer <access_token>` header

Xem README của frontend để biết cách chạy frontend.

## Giấy phép

Dự án nội bộ, không phân phối công khai.
