# Auth Flow — Simple Explanation

## What is this app doing for login?

This app uses **phone number + OTP** login. No passwords. Here's the full journey:

---

## The Journey of a User

### First Time Opening the App

1. App opens → shows a **spinning loader** (splash screen)
2. App quietly checks: "Do I have a saved login token?"
   - **YES** → Go straight to Home. User doesn't need to log in again.
   - **NO** → Go to Phone Input screen.

### Logging In

**Step 1 — Phone Input Screen**
- User types their 10-digit phone number
- Taps "Send OTP"
- App calls the server: `POST /api/users/auth/send-otp/` with `+91<number>`
- Server sends an OTP via WhatsApp
- App automatically moves to OTP screen (router handles this, no manual navigation)

**Step 2 — OTP Verify Screen**
- User types the 6-digit OTP
- As soon as all 6 digits are entered, app automatically calls: `POST /api/users/auth/verify-otp/`
- Server returns: token, user ID, whether they're a new user, whether they're a CWSN user or caregiver
- App saves the token securely on the device
- App automatically moves to Home screen

### Logging Out
- User taps logout on Home screen
- Saved token is deleted from device
- App automatically goes back to Phone Input screen

---

## The 3 States Auth Can Be In

| State | Meaning | Which screen shows |
|-------|---------|-------------------|
| `initial` | Not logged in | Phone Input |
| `otpSent` | OTP was sent, waiting for user to enter it | OTP Verify |
| `verified` | Logged in, token saved | Home |

---

## How Navigation Works (Important!)

Navigation is handled **entirely by the router** (`app_router.dart`). No screen manually pushes to another screen.

The router watches auth state and redirects automatically:

```
authState == null (still loading)  →  stay on splash
status == otpSent, not on OTP page →  go to /otp-verify
status == verified, on splash/auth →  go to /home
status == initial, not on auth     →  go to /phone-input
```

The only UI feedback handled in screens (not router):
- Error snackbars (wrong OTP, network error etc.) — shown in the widget via `ref.listen`

---

## File Map — What Each File Does

```
lib/
├── app/
│   └── app_router.dart         — All navigation logic. Router watches auth state and redirects.
│
├── core/
│   ├── storage/
│   │   └── secure_storage.dart — Saves/reads/deletes the login token on device (encrypted)
│   └── network/
│       └── interceptors/
│           ├── auth_interceptor.dart   — Adds "Authorization: Token xxx" to every API request
│           └── error_interceptor.dart  — Converts Dio errors into AppException for cleaner errors
│
└── features/auth/
    ├── domain/
    │   ├── models/
    │   │   └── auth_model.dart         — What the server returns after login (token, userId, flags)
    │   └── repositories/
    │       └── auth_repository.dart    — Interface: defines sendOtp() and verifyOtp()
    │
    ├── data/
    │   ├── sources/
    │   │   └── auth_remote_source.dart — Actually calls the API using Dio
    │   └── repositories/
    │       └── auth_repository_impl.dart — Connects interface to real API source
    │
    └── presentation/
        ├── providers/
        │   └── auth_provider.dart      — The brain. Holds auth state, calls repository, saves token.
        └── pages/
            ├── phone_input_page.dart   — UI for entering phone number
            └── otp_verify_page.dart    — UI for entering 6-digit OTP
```

---

## The Brain: auth_provider.dart

This is the most important file. It:

1. **On app start** — checks if token exists → sets state to `verified` or `initial`
2. **sendOtp(phone)** — saves current state first, sets loading, calls API, updates state to `otpSent`
3. **verifyOtp(code)** — reads phone number from state FIRST (before loading), calls API, saves token, sets state to `verified`
4. **logout()** — deletes token, resets state to `initial`

### Why phone number is read before setting loading in verifyOtp:
Setting `state = loading` wipes `state.value`. If phone number was read after, it would be null. So it's always read first, then loading is set.

---

## What the Server Returns After OTP Verify

```json
{
  "token": "abc123...",
  "user_id": 42,
  "is_new_user": false,
  "is_cwsn_user": true,
  "is_caregiver": false
}
```

- `token` — saved to device, sent with every future API request
- `is_new_user` — can be used to show onboarding
- `is_cwsn_user` / `is_caregiver` — user role flags

---

## How the Token Gets Sent to the Server

Automatically. The `AuthInterceptor` runs before every API call and adds:
```
Authorization: Token abc123...
```
No screen needs to manually attach it.
