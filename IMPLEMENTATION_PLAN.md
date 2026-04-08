# Authentication Implementation Plan

## Phase 1: Backend Authentication

### 1.1 Update Dependencies
- Add `python-jose[cryptography]` for JWT
- Add `passlib[bcrypt]` for password hashing
- Update `requirements.txt`

### 1.2 Update User Model
- Add `password_hash` field
- Add `is_active` field
- Add `last_login` field
- Create password verification methods

### 1.3 Create Auth Module
- Create `backend/auth.py` with:
  - Password hashing functions
  - JWT token generation/validation
  - Current user dependency

### 1.4 Add Auth Endpoints
- `POST /auth/register` - User registration
- `POST /auth/login` - Login with JWT
- `GET /auth/me` - Get current user info
- `POST /auth/logout` - Logout (optional for JWT)

### 1.5 Protect Existing Endpoints
- Add auth requirements to sensitive endpoints
- Keep public endpoints accessible

## Phase 2: Frontend Authentication

### 2.1 Add Dependencies
- `flutter_secure_storage` for token storage
- Update `pubspec.yaml`

### 2.2 Create Auth Pages
- Login page (`login.dart`)
- Register page (`register.dart`)

### 2.3 Update State Management
- Create `AuthProvider` in `providers.dart`
- Manage user state and token

### 2.4 Update API Service
- Add auth header injection
- Add login/register/logout methods
- Handle 401 responses

### 2.5 Update Navigation
- Add login/register to navigation
- Show/hide pages based on auth state
- Update home page buttons

## Phase 3: Integration & Testing

### 3.1 Test Backend Auth
- Register new users
- Login and get tokens
- Access protected endpoints

### 3.2 Test Frontend Auth
- Login flow
- Register flow
- Token persistence
- Auto-login on app start

### 3.3 Update Existing Features
- Link race results to authenticated users
- Add user info to admin panel
- Update file upload to track uploader

## Estimated Timeline
- Backend: 2-3 hours
- Frontend: 3-4 hours
- Testing: 1-2 hours
- **Total: 6-9 hours**