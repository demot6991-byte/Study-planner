# Chủng Sinh Study Planner

Ứng dụng quản lý thời gian và kế hoạch tự học cá nhân dành cho chủng sinh, bao gồm theo dõi thời khóa biểu, tự học, tiếng Anh, nhật ký thiêng liêng, đọc sách, luyện đàn, và thống kê tiến độ.

## Kiến trúc

Dự án chia thành 2 repo độc lập:

```
study-planner/
├── frontend/    # Next.js — giao diện người dùng (repo riêng)
└── backend/     # Express.js — API server (repo riêng)
```

| Repo | Công nghệ | Vai trò |
|------|-----------|---------|
| `frontend` | Next.js 13, TypeScript, Tailwind, shadcn/ui | Giao diện người dùng, gọi backend API |
| `backend` | Express.js, TypeScript, Supabase | API server, xử lý auth + CRUD, kết nối Supabase |

Frontend và backend giao tiếp qua REST API. Cả hai cùng dùng chung một Supabase project.

## Tính năng chính

- **Dashboard** — Tổng quan hoạt động hiện tại, countdown đến hoạt động tiếp theo
- **Lịch hôm nay** — Timeline chi tiết các hoạt động trong ngày
- **Lịch tuần** — Xem lịch tổng quan theo tuần
- **Thời khóa biểu** — Quản lý lịch học cố định T2–T6
- **Tự học** — Smart Planner tự động tạo lịch tự học theo ưu tiên
- **Tiếng Anh** — Theo dõi 7 kỹ năng với mục tiêu tỷ lệ 50%
- **Nhật ký thiêng liêng** — 6 câu hỏi phản tỉnh, theo dõi chuỗi viết
- **Đọc sách** — Theo dõi tiến độ đọc, số trang/ngày
- **Luyện đàn** — Ghi nhận thời gian luyện tập
- **Thống kê** — Biểu đồ thời gian học, tỷ lệ tiếng Anh
- **Tổng kết tuần** — Phản tỉnh tuần, kế hoạch tuần tới
- **Cài đặt** — Tùy chỉnh giờ giấc, mục tiêu, thông báo
- **Hướng dẫn** — Onboarding modal + trang hướng dẫn sử dụng
- **Đăng nhập/Đăng ký** — Mỗi tài khoản có dữ liệu riêng biệt
- **Dark mode** — Hỗ trợ chế độ tối/sáng
- **Responsive** — Tối ưu cho cả mobile và desktop

## Bắt đầu nhanh

### 1. Chuẩn bị Supabase

1. Tạo project tại [supabase.com](https://supabase.com)
2. Lấy `Project URL` và `anon key` từ Settings → API
3. Chạy 2 file migration trong `backend/supabase/migrations/` theo thứ tự:
   - `20260922092619_create_initial_schema.sql` — tạo 15 bảng + RLS
   - `20260923012252_add_multi_user_auth.sql` — thêm user_id + RLS multi-user

> Xem hướng dẫn chi tiết trong `backend/README.md` → mục "Database Migration"

### 2. Chạy backend

```bash
cd backend
npm install
cp .env.example .env    # Điền SUPABASE_URL, SUPABASE_ANON_KEY
npm run dev             # http://localhost:3001
```

### 3. Chạy frontend

```bash
cd frontend
npm install
cp .env.example .env    # Điền NEXT_PUBLIC_API_URL, NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY
npm run dev             # http://localhost:3000
```

### 4. Sử dụng

1. Mở `http://localhost:3000` → trang đăng nhập
2. Đăng ký tài khoản mới → dữ liệu mẫu tự động tạo
3. Hướng dẫn nhanh sẽ hiện → đi qua từng bước hoặc bỏ qua
4. Vào trang "Tự học" → nhấn "Tạo lịch tự động" để tạo kế hoạch hôm nay

## Biến môi trường

### Frontend (`frontend/.env`)

```
NEXT_PUBLIC_API_URL=http://localhost:3001/api
NEXT_PUBLIC_SUPABASE_URL=https://xxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
```

### Backend (`backend/.env`)

```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
PORT=3001
FRONTEND_URL=http://localhost:3000
```

## Deploy

### Frontend → Netlify / Vercel

1. Push `frontend/` lên GitHub
2. Import vào Netlify hoặc Vercel
3. Thêm biến môi trường (same as `frontend/.env.example`)

### Backend → Render / Railway / Fly.io / VPS

1. Push `backend/` lên GitHub
2. Build: `npm install && npm run build`
3. Start: `npm start`
4. Thêm biến môi trường (same as `backend/.env.example`)

## Giấy phép

Dự án nội bộ, không phân phối công khai.
