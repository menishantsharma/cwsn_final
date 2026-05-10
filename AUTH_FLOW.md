# Auth Flow — Architecture & Walkthrough

This document explains how login works end-to-end: the architecture, the files involved, and what happens on every screen the user sees.

---

## 1. The Big Picture

The app uses **phone number + WhatsApp OTP** login (no passwords). Once verified, every new user must complete a one-time **onboarding** form (name, age, gender, location). After onboarding they reach the main app.

So there are three "places" a user can be:

| Where they are                       | Auth state        | Screen            |
| ------------------------------------ | ----------------- | ----------------- |
| Not logged in                        | `unauthenticated` | Phone Input       |
| Logged in but hasn't done onboarding | `onboarding`      | Onboarding Form   |
| Fully set up                         | `authenticated`   | Categories (home) |

The OTP entry is **not** a separate state — it's a bottom sheet that opens on top of the Phone Input screen.

---

## 2. Architecture (Clean Architecture, 3 layers)

```
┌─────────────────────────────────────────────────────────┐
│ PRESENTATION   What the user sees + Riverpod glue       │
│   pages/    →  PhoneInputPage, OnboardingPage, Splash   │
│   providers/→  AuthNotifier (the brain)                 │
├─────────────────────────────────────────────────────────┤
│ DOMAIN         Pure Dart contracts, no Flutter/Dio      │
│   models/   →  AuthModel, MeModel                       │
│   repositories/ → AuthRepository (abstract interface)   │
├─────────────────────────────────────────────────────────┤
│ DATA           Talks to the network                     │
│   sources/  →  AuthRemoteSource (Dio HTTP calls)        │
│   repositories/→ AuthRepositoryImpl (interface impl)    │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
                 Backend (Django + Twilio Verify)
```

**Why three layers?** The presentation layer doesn't know about Dio. The domain layer doesn't know about anything except Dart. This makes the notifier easy to test (you can swap in a fake `AuthRepository`) and means swapping HTTP libraries later only changes the data layer.

---

## 3. File Map

```
frontend/lib/
├── app/
│   └── app_router.dart                   GoRouter + redirect logic (THE traffic cop)
│
├── core/
│   ├── storage/secure_storage.dart       Saves/reads the token (encrypted on device)
│   └── network/interceptors/
│       ├── auth_interceptor.dart         Adds "Authorization: Token <x>" to every request
│       └── error_interceptor.dart        Wraps Dio errors into AppException
│
└── features/auth/
    ├── domain/
    │   ├── models/auth_model.dart        AuthModel (after verify), MeModel (from /me)
    │   └── repositories/auth_repository.dart   Abstract interface
    │
    ├── data/
    │   ├── sources/auth_remote_source.dart     Hits 4 endpoints via Dio
    │   └── repositories/auth_repository_impl.dart  Implements the interface
    │
    └── presentation/
        ├── providers/
        │   ├── auth_state.dart           AuthState + AuthStatus enum
        │   └── auth_provider.dart        AuthNotifier + authProvider
        └── pages/
            ├── splash_page.dart          Loader while auth resolves on app start
            ├── phone_input_page.dart     Phone number screen + the OTP bottom sheet
            └── onboarding_page.dart      Name/age/gender/location form
```

---

## 4. The State Object

[frontend/lib/features/auth/presentation/providers/auth_state.dart](frontend/lib/features/auth/presentation/providers/auth_state.dart)

```dart
enum AuthStatus { authenticated, unauthenticated, onboarding }

class AuthState {
  final int? userId;
  final AuthStatus status;
}
```

That's it. Deliberately minimal — token lives in `SecureStorage`, phone number is passed as a method param, and the OTP sheet is a UI concern, not state.

---

## 5. The Brain: `AuthNotifier`

[frontend/lib/features/auth/presentation/providers/auth_provider.dart](frontend/lib/features/auth/presentation/providers/auth_provider.dart)

`AuthNotifier extends AsyncNotifier<AuthState>`. It exposes four operations:

### `build()` — runs once on app start
1. Check `SecureStorage` for a saved token.
2. **No token** → return `AuthState(unauthenticated)`. Done.
3. **Token exists** → call `/auth/me/` to ask the server "who am I and have I done onboarding?"
   - Success → return `authenticated` or `onboarding` based on `me.hasCompletedOnboarding`.
   - Failure (token rejected) → delete token, return `unauthenticated`.
4. Also subscribes to `unauthorizedEventProvider` — if any other API call returns 401, log out automatically.

### `sendOtp(phone)`
Sets state to loading, hits `POST /auth/send-otp/`, then restores the previous state (or `unauthenticated` if none). It does **not** transition to an "otpSent" state — there is no such state.

### `verifyOtp(phone, code)` → returns `bool` success
1. Sets state to loading.
2. Hits `POST /auth/verify-otp/`.
3. Saves the returned token to `SecureStorage`.
4. Returns either `authenticated` or `onboarding` based on `user.hasCompletedOnboarding`.
5. Returns `true` on success, `false` on failure (so the OTP sheet can show "Invalid code" inline).

### `completeOnboarding()`
Called after the onboarding form submits successfully. Hits `POST /auth/onboarded/` and flips state from `onboarding` → `authenticated`.

### `logout()`
Deletes token, invalidates **every** other Riverpod provider (categories, services, profile, requests, notifications, etc.) so cached user-specific data is wiped, then sets state to `unauthenticated`.

---

## 6. The Router (Auto-Navigation)

[frontend/lib/app/app_router.dart](frontend/lib/app/app_router.dart)

**Key idea:** No screen ever calls `context.go()` or `context.push()` for auth-driven navigation. The router watches `authProvider` and redirects automatically.

```dart
redirect: (context, state) {
  final auth = authNotifier.value;

  if (auth == null) return AppRoutes.splash;          // still loading

  if (auth.status == unauthenticated) return phoneInput;
  if (auth.status == onboarding)      return onboarding;

  // authenticated — kick them out of any auth screen
  if (loc == splash || loc == phoneInput || loc == onboarding) {
    return categories;
  }
  return null;
}
```

**Subtle detail:** the router only listens to *resolved* states (`next.hasValue`). During the transient `AsyncLoading` of `sendOtp` / `verifyOtp` it ignores the state — otherwise it would yank the user off the screen mid-request.

---

## 7. Walkthroughs

### Walkthrough A — First-Time User

1. **App launches** → router shows `/splash`.
2. `AuthNotifier.build()` runs: no token → returns `unauthenticated`.
3. Router redirects to `/phone-input`.
4. User types `9876543210`, taps "Send OTP".
5. `sendOtp("+919876543210")` → backend → Twilio sends WhatsApp OTP.
6. The page opens an **OTP bottom sheet** (`_OtpSheet`) on top.
7. User types 6 digits → `_verify()` calls `verifyOtp(phone, code)`.
8. Backend creates the user (`User`, blank `CWSNProfile`, blank `CaregiverProfile`), returns token + `has_completed_onboarding=false`.
9. Token saved. State becomes `onboarding`.
10. Router sees `onboarding` → redirects to `/onboarding` (sheet gets dismissed naturally).
11. User fills name/age/gender, picks a location on the map.
12. Form submits via a local `_onboardingProvider` (writes to CWSN + Caregiver profile in parallel).
13. On success → `authProvider.completeOnboarding()` → `POST /auth/onboarded/` → state becomes `authenticated`.
14. The page calls `context.go(/categories)` (this is the *one* manual navigation, since the router would also send them there anyway — it just makes the transition feel instant).

### Walkthrough B — Returning User (Already Onboarded)

1. App launches → `/splash`.
2. `build()` finds a token → calls `/auth/me/` → gets `has_completed_onboarding=true`.
3. State becomes `authenticated`.
4. Router redirects splash → `/categories`. User never sees a login screen.

### Walkthrough C — Returning User (Token Was Revoked)

1. App launches → `/splash`.
2. `build()` finds a token → calls `/auth/me/` → 401.
3. Catch block deletes token, returns `unauthenticated`.
4. Router redirects to `/phone-input`.

### Walkthrough D — Wrong OTP

1. User in OTP sheet enters wrong 6 digits.
2. `verifyOtp()` hits backend → 400 "Invalid OTP" → repository throws → returns `false`.
3. The sheet shows inline "Invalid code. Please try again.", clears the pin, refocuses.
4. State stays `unauthenticated`. Router does nothing. Sheet stays open.

### Walkthrough E — Logout

1. User taps logout (somewhere in profile).
2. `authProvider.logout()` deletes token, invalidates all caches, sets state to `unauthenticated`.
3. Router redirects current screen → `/phone-input`.

---

## 8. Backend Endpoints

[backend/apps/users/urls.py](backend/apps/users/urls.py) · [backend/apps/users/views.py](backend/apps/users/views.py)

| Method | Path                          | Auth   | What it does                                                                                                                                                                                        |
| ------ | ----------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| POST   | `/api/users/auth/send-otp/`   | public | `phone_number` → Twilio Verify sends OTP                                                                                                                                                            |
| POST   | `/api/users/auth/verify-otp/` | public | `phone_number, code` → on first verify creates `User` + blank `CWSNProfile` + blank `CaregiverProfile`. Returns `token, user_id, is_new_user, is_cwsn_user, is_caregiver, has_completed_onboarding` |
| GET    | `/api/users/auth/me/`         | token  | Returns `user_id, has_completed_onboarding, is_cwsn_user, is_caregiver`                                                                                                                             |
| POST   | `/api/users/auth/onboarded/`  | token  | Sets `user.has_completed_onboarding = True`                                                                                                                                                         |

**Twilio Verify integration:** OTPs are not stored in our DB. Twilio holds them and we just check `verification_check.status == 'approved'`. Codes expire after 10 minutes.

---

## 9. How the Token Travels

[frontend/lib/core/network/interceptors/auth_interceptor.dart](frontend/lib/core/network/interceptors/auth_interceptor.dart)

Every request through `dioProvider` passes through `AuthInterceptor`. It reads the token from `SecureStorage` and sets:

```
Authorization: Token <token>
```

No screen, repository, or notifier ever touches this header manually.

If a request returns 401, the error interceptor fires `unauthorizedEventProvider`, which `AuthNotifier` listens to and reacts by logging out.

---

## 10. Provider Wiring Convention

All Riverpod providers for auth live in **one file**: `auth_provider.dart`. (Currently `authRemoteSourceProvider` and `authRepositoryProvider` are in their respective class files — these should be moved to `auth_provider.dart` to match every other feature in the codebase.)

```dart
final authRemoteSourceProvider = Provider<AuthRemoteSource>(
  (ref) => AuthRemoteSource(ref.read(dioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.read(authRemoteSourceProvider)),
);

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
```

---

## 11. Things That Look Weird But Are Intentional

- **No `otpSent` state.** OTP entry is a bottom sheet on top of the phone input screen — purely UI. There's nothing to persist across restarts.
- **`sendOtp` doesn't change status.** It just refreshes the previous state value after the loading transition. The sheet opens because the page calls `_showOtpSheet()` after `sendOtp` completes successfully — not because the router redirected.
- **`build()` calls `/auth/me/` instead of trusting the token.** This is what catches revoked tokens and synchronizes onboarding status if the user completed onboarding on another device.
- **`logout()` invalidates 17+ providers.** This is intentional: any cached user-specific data must die when the account changes, otherwise the next user sees the previous user's services/notifications/etc.
- **`onboarding_page.dart` has its own private `_onboardingProvider`.** This is form-submit state that doesn't belong in the global auth notifier — it's scoped to the page lifetime via `autoDispose`.

---

## 12. Known Issue (as of 2026-05-10)

The DB column `users_user.has_completed_onboarding` is `NOT NULL` (added by migration `0003`), but the **field is missing from `User` in [backend/apps/users/models.py](backend/apps/users/models.py)**. That causes Django's `User.objects.get_or_create()` in `verify-otp` to omit the column on INSERT, leading to a `NotNullViolation` 500.

**Fix:** add this line to the `User` model:

```python
has_completed_onboarding = models.BooleanField(default=False)
```
