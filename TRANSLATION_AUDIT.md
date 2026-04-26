# 📋 Translation Audit - Farol App

## Summary

**Total hardcoded strings without translation: 33**

- ✅ Sistema de i18n existe en `lib/core/i18n/app_localizations.dart`
- ❌ Muchos strings en inglés hardcodeados en los features sin usar el sistema de traducciones
- 🎯 Necesidad: Integrar todos los strings al sistema de i18n

---

## 🔴 CRITICAL: Strings Sin Traducción

### Categoría: Autenticación & Cuenta

| String EN | Ubicación | PT (Português) | ES (Español) |
|-----------|-----------|---|---|
| `Sign In` | `login_screen.dart:3` | Entrar / Fazer Login | Iniciar Sesión |
| `Sign Up` | `signup_screen.dart:2` | Criar Conta / Cadastro | Crear Cuenta / Registrarse |
| `Sign Out` | `main.dart:1` | Sair | Cerrar Sesión |
| `Forgot password?` | `login_screen.dart:1` | Esqueceu a senha? | ¿Olvidaste la contraseña? |
| `Verify your email` | `main.dart:1` | Verifique seu e-mail | Verifica tu correo |
| `Resend email` | `main.dart:1` | Reenviar e-mail | Reenviar correo |
| `Set New Password` | `password_reset_screen.dart:1` | Definir Nova Senha | Establecer Nueva Contraseña |
| `Update Password` | `password_reset_screen.dart:1` | Atualizar Senha | Actualizar Contraseña |
| `Or sign in with` | `login_screen.dart:1` | Ou fazer login com | O inicia sesión con |
| `Something went wrong. Please restart the app.` | `main.dart:1` | Algo deu errado. Reinicie o app. | Algo salió mal. Reinicia la app. |
| `Retry` | `main.dart:1` | Tentar Novamente | Reintentar |

**Archivos afectados:**
- `lib/main.dart`
- `lib/features/auth/presentation/login_screen.dart`
- `lib/features/auth/presentation/signup_screen.dart`
- `lib/features/auth/presentation/password_reset_screen.dart`

---

### Categoría: Inversiones

| String EN | Ubicación | PT (Português) | ES (Español) |
|-----------|-----------|---|---|
| `Add Investment` | `add_investment_bottom_sheet.dart:1` | Adicionar Investimento | Agregar Inversión |
| `Amount invested` | `add_investment_bottom_sheet.dart:1` | Valor investido / Montante investido | Monto invertido |
| `Investment added` | `add_investment_bottom_sheet.dart:1` | Investimento adicionado! | ¡Inversión agregada! |
| `Delete investment?` | `investments_screen.dart:1` | Excluir investimento? | ¿Eliminar inversión? |
| `No investments yet.\nTap + to add one.` | `investments_screen.dart:1` | Nenhum investimento ainda.\nToque + para adicionar um. | Sin inversiones aún.\nToca + para agregar una. |
| `Current balance differs from invested` | `add_investment_bottom_sheet.dart:1` | Saldo atual diferente do investido | El saldo actual difiere del invertido |
| `This cannot be undone.` | `investments_screen.dart:1` | Isto não pode ser desfeito. | Esto no se puede deshacer. |
| `Remove` | `auth_buttons.dart:3` | Remover / Eliminar | Eliminar / Quitar |

**Archivos afectados:**
- `lib/features/investments/add_investment_bottom_sheet.dart`
- `lib/features/investments/investments_screen.dart`
- `lib/features/auth/presentation/widgets/auth_buttons.dart`

---

### Categoría: Presupuesto & Configuración

| String EN | Ubicación | PT (Português) | ES (Español) |
|-----------|-----------|---|---|
| `Monthly Budget` | `budget_settings_sheet.dart:2` | Orçamento Mensal | Presupuesto Mensual |
| `Save Budget` | `budget_goals_sheet.dart:2` | Salvar Orçamento | Guardar Presupuesto |
| `Could not load budget` | `settings_screen.dart:1` | Não foi possível carregar o orçamento | No se pudo cargar el presupuesto |
| `Could not load net worth` | `settings_screen.dart:1` | Não foi possível carregar o patrimônio | No se pudo cargar el patrimonio |

**Archivos afectados:**
- `lib/features/budget/presentation/budget_settings_sheet.dart`
- `lib/features/budget/presentation/budget_goals_sheet.dart`
- `lib/features/settings/settings_screen.dart`

---

### Categoría: Perfil & Configuración de Apariencia

| String EN | Ubicación | PT (Português) | ES (Español) |
|-----------|-----------|---|---|
| `Edit Profile` | `edit_profile_screen.dart:2` | Editar Perfil | Editar Perfil |
| `Appearance` | `settings_screen.dart:4` | Aparência | Apariencia |
| `Customize your interface for maximum visual comfort.` | `settings_screen.dart:1` | Personalize sua interface para o máximo conforto visual. | Personaliza tu interfaz para máximo confort visual. |
| `Concierge Support` | `settings_screen.dart:1` | Suporte Concierge | Soporte Concierge |
| `Corporate Benefits` | `swile_screen.dart:1` | Benefícios Corporativos | Beneficios Corporativos |

**Archivos afectados:**
- `lib/features/profile/presentation/edit_profile_screen.dart`
- `lib/features/settings/settings_screen.dart`
- `lib/features/benefits/swile_screen.dart`

---

### Categoría: gastos & Beneficios

| String EN | Ubicación | PT (Português) | ES (Español) |
|-----------|-----------|---|---|
| `Recent Transactions` | `swile_screen.dart:1` | Transações Recentes | gastos Recientes |
| `Monthly Spending` | `swile_screen.dart:1` | Gastos Mensais | Gastos Mensuales |
| `Last 7 days` | `swile_screen.dart:1` | Últimos 7 dias | Últimos 7 días |
| `See all` | `swile_screen.dart:1` | Ver Tudo | Ver Todo |

**Archivos afectados:**
- `lib/features/benefits/swile_screen.dart`

---

### Categoría: Otros

| String EN | Ubicación | PT (Português) | ES (Español) |
|-----------|-----------|---|---|
| `Type` | `app_database.dart:283` | Tipo | Tipo |

**Nota:** Este string aparece 283 veces en `app_database.dart` (probablemente comentarios o columnas de DB, no UI)

---

## 📊 Estadísticas por Archivo

| Archivo | Strings sin traducir | Prioridad |
|---------|-------|----------|
| `login_screen.dart` | 4 | 🔴 CRÍTICA |
| `settings_screen.dart` | 4 | 🔴 CRÍTICA |
| `add_investment_bottom_sheet.dart` | 3 | 🟠 ALTA |
| `investments_screen.dart` | 3 | 🟠 ALTA |
| `swile_screen.dart` | 4 | 🟠 ALTA |
| `main.dart` | 5 | 🟠 ALTA |
| `password_reset_screen.dart` | 2 | 🟠 ALTA |
| `signup_screen.dart` | 1 | 🟠 ALTA |
| `budget_goals_sheet.dart` | 1 | 🟡 MEDIA |
| `budget_settings_sheet.dart` | 1 | 🟡 MEDIA |
| `edit_profile_screen.dart` | 1 | 🟡 MEDIA |
| `auth_buttons.dart` | 1 | 🟡 MEDIA |

---

## ✅ Recommendation Plan

### Fase 1: Agregar strings a `app_localizations.dart` (Prioridad 1)

Añadir estas claves al diccionario multiidioma:

```dart
'sign_in': 'Sign In',
'sign_up': 'Sign Up',
'sign_out': 'Sign Out',
'forgot_password': 'Forgot password?',
'verify_email': 'Verify your email',
'resend_email': 'Resend email',
'set_new_password': 'Set New Password',
'update_password': 'Update Password',
'or_sign_in_with': 'Or sign in with',
'something_went_wrong': 'Something went wrong. Please restart the app.',
'retry': 'Retry',

'add_investment': 'Add Investment',
'amount_invested': 'Amount invested',
'investment_added': 'Investment added',
'delete_investment': 'Delete investment?',
'no_investments_yet': 'No investments yet.\nTap + to add one.',
'current_balance_differs': 'Current balance differs from invested',
'this_cannot_be_undone': 'This action cannot be undone.',
'remove': 'Remove',

'monthly_budget': 'Monthly Budget',
'save_budget': 'Save Budget',
'could_not_load_budget': 'Could not load budget',
'could_not_load_net_worth': 'Could not load net worth',

'edit_profile': 'Edit Profile',
'appearance': 'Appearance',
'customize_interface': 'Customize your interface for maximum visual comfort.',
'concierge_support': 'Concierge Support',
'corporate_benefits': 'Corporate Benefits',

'recent_transactions': 'Recent Transactions',
'monthly_spending': 'Monthly Spending',
'last_7_days': 'Last 7 days',
'see_all': 'See all',
```

### Fase 2: Usar l10n en lugar de hardcoded strings

Reemplazar en cada archivo:

**Antes:**
```dart
Text('Add Investment')
```

**Después:**
```dart
Text(AppLocalizations.of(context).translate('add_investment'))
// o si existe getter:
Text(l10n.addInvestment)
```

### Fase 3: Validar cobertura

Ejecutar análisis para verificar que no hay strings hardcodeados:

```bash
# Buscar Text( con strings que no sean l10n
grep -rn "Text('" lib/features --include="*.dart" | grep -v "l10n\|AppLocalizations\|translate"
```

---

## 🎯 Beneficios de completar la traducción

1. ✅ **Soporte multiidioma 100%** — Actualmente solo ~60% está traducido
2. ✅ **Mejor experiencia para usuarios en PT y ES** — Sin strings en inglés dispersos
3. ✅ **Mantenimiento más fácil** — Todos los strings en un único lugar
4. ✅ **Escalabilidad** — Agregar nuevos idiomas será trivial

---

## 📌 Nota de Implementación

El sistema `AppLocalizations` ya existe y funciona. Solo necesita:
- Agregar las nuevas claves al diccionario `_localizedValues`
- Crear getters en la clase `AppLocalizations` para cada nueva clave
- Reemplazar hardcoded strings por llamadas a `l10n.clave` o `l10n.translate('clave')`

Tiempo estimado: **2-3 horas** (incluye testing)
