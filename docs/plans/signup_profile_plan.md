# Plan: Signup + Edit Profile — Phased Improvements

> Goal: Align signup and profile screens with the target design, extend the data model, and improve UX without breaking existing functionality.

---

## Current State

| Screen | Current Fields | Issues |
|--------|---------------|--------|
| Signup | email, password, confirm password | Missing name, CPF, terms |
| Edit Profile | name, avatar URL (text) | No sections, no phone/company/role, no real photo |
| `UserProfile` (model) | uid, email, displayName, photoUrl, createdAt, metadata | Missing: phone, cpf, company, role, plan |
| `profiles` (Supabase) | id, email, display_name, photo_url, created_at, metadata, updated_at | Missing columns for new fields |

---

## Phase 1 — Signup: name + optional CPF + terms

**Goal:** Align the registration form with the target screenshot.

**Flutter changes:**
- `signup_screen.dart`:
  - Add **Full name** field (required, before email)
  - Add **CPF** field (optional, `000.000.000-00` format, input mask)
  - Add **I accept the Terms of Use and Privacy Policy** checkbox (required to proceed)
  - Pass `full_name` and `cpf` to Supabase metadata in `signUpWithEmail`
- `auth_repository.dart`: include `full_name` and `cpf` in `userMetadata` of `signUp`

**No DB changes** — CPF goes to Supabase Auth `metadata` until Phase 3 adds a column.

**Inconsistencies to check:**
- Does `signUpWithEmail` in auth_repository accept additional metadata?
- Does `AppUser.fromSupabase` already read `full_name` from metadata? (yes, line 27)

---

## Phase 2 — Edit Profile: UI redesign with sections

**Goal:** Redesign `edit_profile_screen.dart` to match the target screenshot (without changing the data model yet).

**Flutter changes:**
- Header with circular avatar (initials while no photo), name below, sub-line "Farol since [month year] · Free/Premium Plan"
- **PERSONAL DATA** section:
  - `Name` — editable
  - `Email` — read-only (green ✓ badge if verified)
  - `Phone` — editable, optional for now (saves to `metadata`)
  - `CPF` — read-only if already set (lock icon), editable if empty (saves to `metadata`)
- **PROFESSIONAL PROFILE** section:
  - `Company` — editable, optional (saves to `metadata`)
  - `Role` — editable, optional (saves to `metadata`)
- **Save** button in AppBar (text) + primary button at bottom
- Replace "Avatar URL" field with camera button (visual stub, real upload in Phase 5)

**Data pending model changes:**
- Phone, company, role are saved in `UserProfile.metadata` as key-value until Phase 3.

**Inconsistencies to check:**
- `currentProfileProvider` calls `getProfile` by uid — does it return full metadata?
- Does `saveProfile` call `updateProfile` which upserts with `metadata`?

---

## Phase 3 — Data model: extend `profiles` in Supabase + Flutter

**Goal:** Move fields from `metadata` blob to their own columns.

**Supabase migration (SQL):**
```sql
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS cpf TEXT,
  ADD COLUMN IF NOT EXISTS company TEXT,
  ADD COLUMN IF NOT EXISTS role TEXT,
  ADD COLUMN IF NOT EXISTS plan TEXT DEFAULT 'free';
```

**Flutter changes:**
- `UserProfile`: add `phone`, `cpf`, `company`, `role`, `plan` fields
- `UserProfile.fromSupabase`: map new columns
- `UserProfile.toSupabase`: include new columns
- `ProfileRepository.updateProfile`: accept new parameters
- `ProfileNotifier.saveProfile`: pass all fields
- Migrate existing data from `metadata` → new columns (SQL backfill script)

**Inconsistencies to check:**
- Row Level Security on `profiles` — does it allow UPDATE on new columns?
- Does Supabase Auth `user.userMetadata` duplicate `cpf`? → clean up

---

## Phase 4 — Validation + UX: masks, badges, CPF read-only

**Goal:** Polish form experience.

**Changes:**
- CPF mask `000.000.000-00` — use `mask_text_input_formatter` package or implement manually
- Phone mask `+55 (00) 00000-0000`
- Real CPF validation (modulo 11 algorithm)
- Green ✓ badge on Email if `user.emailConfirmedAt != null`
- Green ✓ badge on Phone if verified (future flag)
- CPF: if already saved → read-only (lock icon), not editable; if empty → editable once
- Signup name → `trim()` + minimum 2 characters

**Inconsistencies to check:**
- Is `mask_text_input_formatter` already a dependency? (`pubspec.yaml`)
- Alternatively implement simple mask with `TextInputFormatter`

---

## Phase 5 — Avatar: real upload to Supabase Storage

**Goal:** Replace the URL-text field with camera/gallery → upload → URL in profile.

**Changes:**
- Camera button over circular avatar → `image_picker`
- Upload to Supabase Storage bucket `avatars/{uid}.jpg`
- Get public URL and save to `profiles.photo_url`
- Show photo in `_Avatar` (transactions, dashboard, profile)
- Fallback to initials if no photo

**New dependencies:**
- `image_picker: ^1.x`
- Verify that `supabase_flutter` already includes Storage client

**Inconsistencies to check:**
- Does `avatars` bucket exist in Supabase? RLS policy for upload by uid
- Does `AppUser.photoUrl` already read from metadata? → connect with real column

---

## Suggested Implementation Order

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5
```

Each phase is independently verifiable in the app before moving to the next.

---

## Files Affected by Phase

| File | P1 | P2 | P3 | P4 | P5 |
|------|----|----|----|----|----|
| `signup_screen.dart` | ✅ | — | — | ✅ | — |
| `auth_repository.dart` | ✅ | — | — | — | — |
| `edit_profile_screen.dart` | — | ✅ | — | ✅ | ✅ |
| `profile_repository.dart` | — | — | ✅ | — | ✅ |
| `profile_providers.dart` | — | — | ✅ | — | — |
| `app_user.dart` | — | — | ✅ | — | — |
| `UserProfile` model | — | — | ✅ | — | — |
| Supabase SQL migration | — | — | ✅ | — | ✅ |
| `app_localizations.dart` | ✅ | ✅ | — | ✅ | — |
