# Plan: Signup + Edit Profile — Mejoras por Fases

> Objetivo: alinear signup y perfil al diseño objetivo, extender el modelo de datos y mejorar la UX sin romper lo que ya funciona.

---

## Estado actual

| Pantalla | Campos actuales | Problemas |
|---|---|---|
| Signup | email, password, confirm password | Falta nombre, CPF, términos |
| Edit Profile | nombre, avatar URL (texto) | Sin secciones, sin teléfono/empresa/cargo, sin foto real |
| `UserProfile` (modelo) | uid, email, displayName, photoUrl, createdAt, metadata | Faltan: phone, cpf, company, role, plan |
| `profiles` (Supabase) | id, email, display_name, photo_url, created_at, metadata, updated_at | Faltan columnas para nuevos campos |

---

## Fase 1 — Signup: nombre + CPF opcional + términos

**Objetivo:** alinear el formulario de registro a la captura de pantalla.

**Cambios Flutter:**
- `signup_screen.dart`:
  - Agregar campo **Nombre completo** (obligatorio, antes del email)
  - Agregar campo **CPF** (opcional, formato `000.000.000-00`, máscara en input)
  - Agregar checkbox **Acepto los Términos de Uso y Política de Privacidad** (obligatorio para continuar)
  - Pasar `full_name` y `cpf` al metadata de Supabase en el `signUpWithEmail`
- `auth_repository.dart`: incluir `full_name` y `cpf` en `userMetadata` del `signUp`

**Sin cambios de BD** — CPF va al `metadata` de Supabase Auth hasta que se cree la columna en Fase 3.

**Inconsistencias a verificar:**
- ¿El método `signUpWithEmail` en auth_repository acepta metadata adicional?
- ¿El `AppUser.fromSupabase` ya lee `full_name` del metadata? (sí, línea 27)

---

## Fase 2 — Edit Profile: rediseño UI con secciones

**Objetivo:** rediseñar `edit_profile_screen.dart` para coincidir con la captura (sin cambiar el modelo de datos aún).

**Cambios Flutter:**
- Header con avatar circular (iniciales mientras no haya foto), nombre debajo, sub-línea "Farol desde [mes año] · Plano Free/Premium"
- Sección **DADOS PESSOAIS**:
  - `Nome` — editable
  - `E-mail` — read-only (con badge verde ✓ si verificado)
  - `Telefone` — editable, opcional por ahora (guarda en `metadata`)
  - `CPF` — read-only si ya tiene valor (icono candado), editable si está vacío (guarda en `metadata`)
- Sección **PERFIL PROFISSIONAL**:
  - `Empresa` — editable, opcional (guarda en `metadata`)
  - `Cargo` — editable, opcional (guarda en `metadata`)
- Botón **Salvar** en AppBar (texto) + botón primario al fondo
- Reemplazar campo "Avatar URL" por botón de cámara (stub visual, upload real en Fase 5)

**Datos pendientes de modelo:**
- Teléfono, empresa, cargo se guardan en `UserProfile.metadata` como clave-valor hasta Fase 3.

**Inconsistencias a verificar:**
- `currentProfileProvider` hace `getProfile` por uid — ¿devuelve metadata completo?
- ¿`saveProfile` llama a `updateProfile` que hace upsert con `metadata`?

---

## Fase 3 — Modelo de datos: extender `profiles` en Supabase + Flutter

**Objetivo:** sacar los campos del `metadata` blob y darles columnas propias.

**Migración Supabase (SQL):**
```sql
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS cpf TEXT,
  ADD COLUMN IF NOT EXISTS company TEXT,
  ADD COLUMN IF NOT EXISTS role TEXT,
  ADD COLUMN IF NOT EXISTS plan TEXT DEFAULT 'free';
```

**Cambios Flutter:**
- `UserProfile`: agregar campos `phone`, `cpf`, `company`, `role`, `plan`
- `UserProfile.fromSupabase`: mapear las nuevas columnas
- `UserProfile.toSupabase`: incluir las nuevas columnas
- `ProfileRepository.updateProfile`: aceptar los nuevos parámetros
- `ProfileNotifier.saveProfile`: pasar todos los campos
- Migrar datos existentes desde `metadata` → columnas nuevas (script SQL de backfill)

**Inconsistencias a verificar:**
- Row Level Security en `profiles` — ¿permite UPDATE en nuevas columnas?
- ¿Supabase Auth `user.userMetadata` duplica `cpf`? → limpiar

---

## Fase 4 — Validación + UX: máscaras, badges, CPF read-only

**Objetivo:** pulir la experiencia de formularios.

**Cambios:**
- Máscara CPF `000.000.000-00` — usar paquete `mask_text_input_formatter` o implementar manualmente
- Máscara teléfono `+55 (00) 00000-0000`
- Validación CPF real (algoritmo módulo 11)
- Badge ✓ verde en E-mail si `user.emailConfirmedAt != null`
- Badge ✓ verde en Telefone si verificado (flag futuro)
- CPF: si ya tiene valor guardado → read-only (icono candado), no editable; si vacío → editable una sola vez
- Nombre en signup → `trim()` + mínimo 2 caracteres

**Inconsistencias a verificar:**
- ¿`mask_text_input_formatter` ya es dependencia? (`pubspec.yaml`)
- Alternativamente implementar máscara simple con `TextInputFormatter`

---

## Fase 5 — Avatar: upload real a Supabase Storage

**Objetivo:** reemplazar el campo URL-texto por cámara/galería → upload → URL en perfil.

**Cambios:**
- Botón cámara sobre avatar circular → `image_picker`
- Upload a Supabase Storage bucket `avatars/{uid}.jpg`
- Obtener URL pública y guardar en `profiles.photo_url`
- Mostrar foto en `_Avatar` (transacciones, dashboard, perfil)
- Fallback a iniciales si no hay foto

**Dependencias nuevas:**
- `image_picker: ^1.x`
- Verificar que `supabase_flutter` ya incluye Storage client

**Inconsistencias a verificar:**
- ¿Bucket `avatars` existe en Supabase? RLS policy para upload por uid
- ¿`AppUser.photoUrl` ya se lee del metadata? → conectar con columna real

---

## Orden de implementación sugerido

```
Fase 1 → Fase 2 → Fase 3 → Fase 4 → Fase 5
```

Cada fase es independientemente verificable en la app antes de avanzar a la siguiente.

---

## Archivos afectados por fase

| Archivo | F1 | F2 | F3 | F4 | F5 |
|---|---|---|---|---|---|
| `signup_screen.dart` | ✅ | — | — | ✅ | — |
| `auth_repository.dart` | ✅ | — | — | — | — |
| `edit_profile_screen.dart` | — | ✅ | — | ✅ | ✅ |
| `profile_repository.dart` | — | — | ✅ | — | ✅ |
| `profile_providers.dart` | — | — | ✅ | — | — |
| `app_user.dart` | — | — | ✅ | — | — |
| `UserProfile` model | — | — | ✅ | — | — |
| Supabase SQL migration | — | — | ✅ | — | ✅ |
| `app_localizations.dart` | ✅ | ✅ | — | ✅ | — |
