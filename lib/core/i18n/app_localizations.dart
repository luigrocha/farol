import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = {
    'en': {
      'app_name': 'Farol',
      'dashboard': 'Dashboard',
      'transactions': 'Transactions',
      'analytics': 'Analytics',
      'investments': 'Investments',
      'settings': 'Settings',
      'income': 'Income',
      'expenses': 'Expenses',
      'net_worth': 'Net Worth',
      'health_score': 'Financial Health',
      'add_expense': 'Add Expense',
      'save': 'Save',
      'cancel': 'Cancel',
      'category': 'Category',
      'amount': 'Amount',
      'date': 'Date',
      'payment_method': 'Payment Method',
      'fixed_cost': 'Fixed Cost',
      'installments': 'Installments',
      'language': 'Language',
      'spanish': 'Spanish',
      'portuguese': 'Portuguese',
      'english': 'English',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'system_mode': 'System',
      'profile': 'Profile',
      'budget_goals': 'Budget Goals',
      'net_salary': 'Net Salary',
      'swile': 'Swile',
      'available_total': 'Total Available',
      'cash_expenses': 'Cash Expenses',
      'monthly_balance': 'Monthly Balance',
      'savings_rate': 'Savings Rate',
      'swile_remaining': 'Swile Remaining',
      'expense_by_cat': 'Expenses by Category',
      'no_expenses': 'No registered expenses',
      'no_expenses_hint': 'Add an expense to see your spending breakdown.',
      'no_net_worth': 'No net worth data',
      'score_desc': 'Score from 0 to 10',
      'months': [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ],
      // Enums
      'cat_housing': 'Housing',
      'cat_transport': 'Transport',
      'cat_food': 'Food & Grocery',
      'cat_health': 'Health',
      'cat_subs': 'Subscriptions',
      'cat_leisure': 'Leisure',
      'cat_edu': 'Education',
      'cat_card': 'Card Installments',
      'cat_other': 'Other',
      'income_net_salary': 'Net Salary',
      'income_swile_meal': 'Swile Meal',
      'income_swile_food': 'Swile Food',
      'income_bonus': 'Bonus',
      'income_13th': '13th Salary',
      'income_overtime': 'Overtime',
      'income_other': 'Other',
      'health_healthy': 'HEALTHY',
      'health_warning': 'WARNING',
      'health_critical': 'CRITICAL',
      'health_excellent': 'Excellent! Your finances are healthy.',
      'health_good': 'Very good! Keep it up.',
      'health_fair': 'Fair. There is room for improvement.',
      'health_warning_desc': 'Warning! Review your spending.',
      'health_critical_desc': 'Critical! Urgent action is needed.',
      'total_consolidated': 'TOTAL CONSOLIDATED',
      'asset_allocation': 'Asset Allocation',
      'ia_suggestion': 'AI Suggestion',
      'current_balance': 'CURRENT BALANCE',
      'portfolio': 'Portfolio',
      'monthly_goal': 'Monthly Goal',
      'missing': 'Missing',
      'to_reach_goal': 'to reach your savings goal this month.',
      'onboarding_title': 'Clarity for every dollar.',
      'onboarding_subtitle':
          'Your money on the right track. Financial planning that guides every decision with clarity.',
      'onboarding_f1': 'Bank-grade security and integrated Pix',
      'onboarding_f2': 'AI that understands your salary and benefits',
      'onboarding_f3': 'Support in your language, 24/7',
      'onboarding_button': 'Create my Farol account',
      'onboarding_login': 'Already a client · Log in',
      'pay_debit': 'Debit',
      'pay_pix': 'PIX',
      'pay_credit': 'Credit',
      'pay_credit_inst': 'Credit (Installments)',
      'pay_swile_meal': 'Swile Saldo Libre',
      'pay_swile_food': 'Swile Food',
      // Toast messages
      'net_worth_saved': 'Net worth saved!',
      'budget_saved': 'Budget saved!',
      'budget_goals_saved': 'Budget goals saved!',
      'expense_saved': 'Expense saved!',
      'invalid_amount': 'Enter a valid amount',
      'email_required': 'Enter your email first',
      'recovery_email_sent': 'Recovery email sent',
      'verification_email_resent': 'Verification email resent',
      'error_saving': 'Error saving',
      // Edit / Delete
      'edit': 'Edit',
      'delete': 'Delete',
      'edit_expense': 'Edit Expense',
      'confirm_delete': 'Delete this expense?',
      'cannot_undo': 'This action cannot be undone.',
      'transaction_deleted': 'Expense deleted',
      'transaction_updated': 'Expense updated!',
      // Authentication
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
      // Investments
      'add_investment': 'Add Investment',
      'amount_invested': 'Amount invested',
      'investment_added': 'Investment added',
      'delete_investment': 'Delete investment?',
      'no_investments_yet': 'No investments yet.\nTap + to add one.',
      'current_balance_differs': 'Current balance differs from invested',
      'remove': 'Remove',
      // Budget
      'monthly_budget': 'Monthly Budget',
      'save_budget': 'Save Budget',
      'could_not_load_budget': 'Could not load budget',
      'could_not_load_net_worth': 'Could not load net worth',
      // Profile & Settings
      'edit_profile': 'Edit Profile',
      'appearance': 'Appearance',
      'customize_interface':
          'Customize your interface for maximum visual comfort.',
      'concierge_support': 'Concierge Support',
      'corporate_benefits': 'Corporate Benefits',
      // Transactions & Benefits
      'recent_transactions': 'Recent Transactions',
      'monthly_spending': 'Monthly Spending',
      'last_7_days': 'Last 7 days',
      'see_all': 'See all',
      // Login Extra
      'welcome': 'Welcome\n',
      'back': 'back.',
      'login_subtitle': 'Sign in and continue lighting your financial path.',
      'email': 'Email',
      'password': 'Password',
      'invalid_email': 'Invalid email',
      'min_6_chars': 'Minimum 6 characters',
      'dont_have_account': 'Don\'t have an account? ',
      // Settings Extra
      'data_privacy': 'Data & Privacy',
      'export_transactions': 'Export Transactions',
      'income_statement': 'Income Statement',
      'full_backup': 'Full Backup',
      'monthly_report_pdf': 'Monthly Report PDF',
      'category_budgets': 'Category Budgets',
      'set_spending_limits': 'Set spending limits per category',
      'financial_period': 'Financial Period',
      'period_start': 'Start of period',
      'day_of_each_month': 'Day of each month',
      'select_period_start':
          'Select the day your financial period begins (1-28):',
      'salary_configured': 'Salary Configured',
      'configure_salary': 'Configure Salary',
      'salary_calculated': 'Taxes automatically calculated',
      'net_worth_configured': 'Net Worth Configured',
      'configure_net_worth': 'Configure Net Worth',
      'net_worth_desc': 'Real Estate, Investments, etc.',
      'chat_24_7': 'Chat 24/7',
      'vip_call': 'VIP Call',
      // Toasts
      'settings_saved': 'Settings saved successfully',
      'export_success': 'File exported successfully',
      'salary_saved': 'Salary settings saved successfully',
      'enter_gross_salary': 'Please enter gross salary',
      'error': 'Error',
      // Signup & Other
      'account_created_check_email':
          'Account created! Check your email to continue.',
      'create_your': 'Create your\n',
      'farol_account': 'Farol account.',
      'start_illuminating': 'Start illuminating your financial path today.',
      'set_planned_income':
          'Set your planned monthly income. The dashboard will track remaining amounts as you add transactions.',
      'passwords_dont_match': 'Passwords do not match',
      'create_account_arrow': 'Create account →',
      'already_have_account': 'Already have an account? ',
      'very_weak': 'Very weak',
      'weak': 'Weak',
      'good': 'Good',
      'strong': 'Strong',
      'we_sent_verification':
          'We sent a verification link to your email. Please check it to continue.',
      'new_password_title_1': 'New\n',
      'new_password_title_2': 'password.',
      'choose_strong_password':
          'Choose a strong password to protect your account.',
      'new_password': 'New password',
      'min_8_chars': 'Minimum 8 characters',
      'confirm_new_password': 'Confirm new password',
      'update_password_arrow': 'Update password →',
      'type': 'Type',
      'current_balance_input': 'Current balance',
      'product_name': 'Product name',
      'institution': 'Institution / Broker',
      'notes_optional': 'Notes (optional)',
      'enter_product_name': 'Enter a product name',
      'enter_institution': 'Enter the institution',
      'enter_invested_amount': 'Enter the invested amount',
      'enter_valid_balance': 'Enter a valid current balance',
      'set_monthly_spending_limits': 'Set monthly spending limits per category',
      'current_spending': 'Current',
      'budget_amount': 'Budget amount',
      'cash_budget': 'Cash Budget',
      'swile_budget': 'Swile Budget',
      'swile_balance': 'Swile balance',
      'of_swile_balance': 'of Swile balance',
      'name': 'Name',
      'name_required': 'Name is required',
      'full_name': 'Full name',
      'full_name_required': 'Full name is required',
      'cpf_optional': 'CPF (optional)',
      'cpf_invalid': 'Invalid CPF',
      'terms_accept': 'I accept the ',
      'terms_link': 'terms of use',
      'terms_required': 'You must accept the terms to continue',
      'avatar_optional': 'Avatar URL (optional)',
      'new_installment': 'New Installment',
      'description_required': 'Description *',
      'desc_example': 'e.g. Laptop, Phone...',
      'monthly_installment_amount': 'Monthly installment amount',
      'num_installments': 'Number of installments',
      'current_installment': 'Current installment',
      'of': 'of',
      'purchased_on': 'Purchased on',
      'enter_description': 'Enter description',
      'enter_installment_amount': 'Enter installment amount',
      'installment_added': 'Installment added!',
      'total': 'Total',
      'remaining': 'Remaining',
      'remaining_balance': 'Remaining balance',
      // Settings – hardcoded strings
      'could_not_load_salary': 'Could not load salary settings',
      'lbl_gross': 'Gross',
      'lbl_net': 'Net',
      'per_month': '/ month',
      'tap_configure_budgets': 'Tap to configure your income budgets',
      'salary': 'Salary',
      'simulators': 'Simulators',
      'simulator_13th': '13th Salary Simulator',
      'simulator_13th_desc': 'Calculate installments, INSS and IRRF',
      'simulator_fgts': 'FGTS Anniversary Withdrawal',
      'simulator_fgts_desc': 'Simulate annual withdrawal and 3-year projection',
      'hide_values': 'Hide values',
      'hide_values_desc': 'Masks amounts throughout the app',
      // ── Categories Management ──
      'categories': 'Categories',
      'manage_categories': 'Manage your expense categories',
      'no_categories_found': 'No categories found',
      'add_first_category': 'Add your first category',
      'add_category': 'Add Category',
      'edit_category': 'Edit Category',
      'new_category': 'New Category',
      'category_name': 'Category name',
      'category_emoji': 'Emoji',
      'category_emoji_hint': 'e.g. 🏠',
      'category_name_hint': 'e.g. Rent',
      'swile_category': 'Swile Category',
      'swile_category_desc': 'Used for meal/food vouchers',
      'category_updated': 'Category updated',
      'category_added': 'Category added',
      'category_deleted': 'Category deleted',
      'delete_category': 'Delete category?',
      'delete_category_desc': 'This will not delete existing expenses, but the category will be removed from active categories.',
      'required': 'Required',
      // ── Budget Rebalance ──
      'rebalance_budget': 'Rebalance Budget',
      'rebalance_subtitle': 'Adjust percentages to reach exactly 100%',
      'normalize': 'Normalize',
      'preview_changes': 'Preview changes',
      'budget_rebalanced': 'Budget rebalanced successfully',
      'over_limit': 'Over by %s%% — adjust first',
      'under_limit': 'Under by %s%% — adjust first',
      // ── Period Budget ──
      'period_budget': 'Period Budget',
      'copy_from_previous': 'Copy from previous period',
      'no_budgets_period': 'No budgets for this period',
      'budgets_hint': 'Add budget goals in Settings to see defaults here',
      'reset_to_goal': 'Reset to goal amount?',
      'reset_to_goal_desc': 'This will remove the custom amount and revert to your goal.',
      'remove_budget': 'Remove budget for %s?',
      'reset': 'Reset',
      'edit_budget': 'Edit Budget',
      'new_budget': 'New Budget',
      'copied_budgets': 'Copied %d budget(s) from previous period',
      'no_budgets_to_copy': 'No new budgets to copy',
      'spent': 'Spent',
      'left': 'Left',
      'over': 'Over',
      'goal': 'Goal',
    },
    'es': {
      'app_name': 'Farol',
      'dashboard': 'Panel',
      'transactions': 'Gastos',
      'analytics': 'Análisis',
      'investments': 'Inversiones',
      'settings': 'Ajustes',
      'income': 'Ingresos',
      'expenses': 'Gastos',
      'net_worth': 'Patrimonio',
      'health_score': 'Salud Financiera',
      'add_expense': 'Añadir Gasto',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'category': 'Categoría',
      'amount': 'Monto',
      'date': 'Fecha',
      'payment_method': 'Método de Pago',
      'fixed_cost': 'Costo Fijo',
      'installments': 'Cuotas',
      'language': 'Idioma',
      'spanish': 'Español',
      'portuguese': 'Portugués',
      'english': 'Inglés',
      'theme': 'Tema',
      'dark_mode': 'Modo Oscuro',
      'light_mode': 'Modo Claro',
      'system_mode': 'Sistema',
      'profile': 'Perfil',
      'budget_goals': 'Metas de Presupuesto',
      'net_salary': 'Salario Neto',
      'swile': 'Beneficios',
      'available_total': 'Total Disponible',
      'cash_expenses': 'Gastos en Efectivo',
      'monthly_balance': 'Saldo Mensual',
      'savings_rate': 'Tasa de Ahorro',
      'swile_remaining': 'Swile Disponible',
      'expense_by_cat': 'Gastos por Categoría',
      'no_expenses': 'Sin gastos registrados',
      'no_expenses_hint': 'Agrega un gasto para ver el desglose de tus gastos.',
      'no_net_worth': 'Sin datos de patrimonio',
      'score_desc': 'Puntaje de 0 a 10',
      'months': [
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic'
      ],
      // Enums
      'cat_housing': 'Vivienda',
      'cat_transport': 'Transporte',
      'cat_food': 'Alimentación',
      'cat_health': 'Salud',
      'cat_subs': 'Suscripciones',
      'cat_leisure': 'Ocio',
      'cat_edu': 'Educación',
      'cat_card': 'Cuotas de Tarjeta',
      'cat_other': 'Otros',
      'income_net_salary': 'Salario Neto',
      'income_swile_meal': 'Swile Comida',
      'income_swile_food': 'Swile Alimentación',
      'income_bonus': 'Bono',
      'income_13th': '13° Salario',
      'income_overtime': 'Horas Extra',
      'income_other': 'Otros',
      'health_healthy': 'SALUDABLE',
      'health_warning': 'ADVERTENCIA',
      'health_critical': 'CRÍTICO',
      'health_excellent': '¡Excelente! Tus finanzas están saludables.',
      'health_good': '¡Muy bien! Continúa así.',
      'health_fair': 'Razonable. Hay espacio para mejorar.',
      'health_warning_desc': '¡Atención! Revisa tus gastos.',
      'health_critical_desc': '¡Crítico! Es necesario actuar ahora.',
      'total_consolidated': 'TOTAL CONSOLIDADO',
      'asset_allocation': 'Asignación de Activos',
      'ia_suggestion': 'Sugerencia IA',
      'current_balance': 'SALDO ACTUAL',
      'portfolio': 'Portafolio',
      'monthly_goal': 'Meta Mensual',
      'missing': 'Faltan',
      'to_reach_goal': 'para alcanzar tu meta de ahorro este mes.',
      'onboarding_title': 'Claridad para cada centavo.',
      'onboarding_subtitle':
          'Tu dinero en el rumbo correcto. Planificación financiera que guía cada decisión con claridad.',
      'onboarding_f1': 'Seguridad bancaria y Pix integrado',
      'onboarding_f2': 'IA que entiende tu salario y beneficios',
      'onboarding_f3': 'Soporte en tu idioma, 24/7',
      'onboarding_button': 'Crear mi cuenta Farol',
      'onboarding_login': 'Ya soy cliente · Iniciar sesión',
      'pay_debit': 'Débito',
      'pay_pix': 'PIX',
      'pay_credit': 'Crédito',
      'pay_credit_inst': 'Crédito (Cuotas)',
      'pay_swile_meal': 'Swile Saldo Libre',
      'pay_swile_food': 'Vale Alimento',
      // Toast messages
      'net_worth_saved': '¡Patrimonio guardado!',
      'budget_saved': '¡Presupuesto guardado!',
      'budget_goals_saved': '¡Metas de presupuesto guardadas!',
      'expense_saved': '¡Gasto guardado!',
      'invalid_amount': 'Ingresa un monto válido',
      'email_required': 'Primero ingresa tu correo',
      'recovery_email_sent': 'Correo de recuperación enviado',
      'verification_email_resent': 'Correo de verificación reenviado',
      'error_saving': 'Error al guardar',
      // Edit / Delete
      'edit': 'Editar',
      'delete': 'Eliminar',
      'edit_expense': 'Editar Gasto',
      'confirm_delete': '¿Eliminar este gasto?',
      'cannot_undo': 'Esta acción no se puede deshacer.',
      'transaction_deleted': 'Gasto eliminado',
      'transaction_updated': '¡Gasto actualizado!',
      // Authentication
      'sign_in': 'Iniciar Sesión',
      'sign_up': 'Registrarse',
      'sign_out': 'Cerrar Sesión',
      'forgot_password': '¿Olvidaste la contraseña?',
      'verify_email': 'Verifica tu correo',
      'resend_email': 'Reenviar correo',
      'set_new_password': 'Establecer Nueva Contraseña',
      'update_password': 'Actualizar Contraseña',
      'or_sign_in_with': 'O inicia sesión con',
      'something_went_wrong': 'Algo salió mal. Reinicia la app.',
      'retry': 'Reintentar',
      // Investments
      'add_investment': 'Agregar Inversión',
      'amount_invested': 'Monto invertido',
      'investment_added': '¡Inversión agregada!',
      'delete_investment': '¿Eliminar inversión?',
      'no_investments_yet': 'Sin inversiones aún.\nToca + para agregar una.',
      'current_balance_differs': 'El saldo actual difiere del invertido',
      'remove': 'Eliminar',
      // Budget
      'monthly_budget': 'Presupuesto Mensual',
      'save_budget': 'Guardar Presupuesto',
      'could_not_load_budget': 'No se pudo cargar el presupuesto',
      'could_not_load_net_worth': 'No se pudo cargar el patrimonio',
      // Profile & Settings
      'edit_profile': 'Editar Perfil',
      'appearance': 'Apariencia',
      'customize_interface':
          'Personaliza tu interfaz para máximo confort visual.',
      'concierge_support': 'Soporte Concierge',
      'corporate_benefits': 'Beneficios Corporativos',
      // Transactions & Benefits
      'recent_transactions': 'Gastos Recientes',
      'monthly_spending': 'Gastos Mensuales',
      'last_7_days': 'Últimos 7 días',
      'see_all': 'Ver Todo',
      // Login Extra
      'welcome': 'Bienvenido\n',
      'back': 'de vuelta.',
      'login_subtitle':
          'Inicia sesión y continúa iluminando tu camino financiero.',
      'email': 'Correo',
      'password': 'Contraseña',
      'invalid_email': 'Correo inválido',
      'min_6_chars': 'Mínimo 6 caracteres',
      'dont_have_account': '¿Aún no tienes cuenta? ',
      // Settings Extra
      'data_privacy': 'Datos y Privacidad',
      'export_transactions': 'Exportar gastos',
      'income_statement': 'Estado de Resultados',
      'full_backup': 'Respaldo Completo',
      'monthly_report_pdf': 'Resumen Mensual PDF',
      'category_budgets': 'Presupuestos por Categoría',
      'set_spending_limits': 'Establece límites de gasto',
      'financial_period': 'Período financiero',
      'period_start': 'Inicio del período',
      'day_of_each_month': 'Día de cada mes',
      'select_period_start':
          'Selecciona el día en que comienza tu período (1–28):',
      'salary_configured': 'Salario Configurado',
      'configure_salary': 'Configurar Salario',
      'salary_calculated': 'Impuestos calculados automáticamente',
      'net_worth_configured': 'Patrimonio Configurado',
      'configure_net_worth': 'Configurar Patrimonio',
      'net_worth_desc': 'Inmuebles, Inversiones, etc.',
      'chat_24_7': 'Chat 24/7',
      'vip_call': 'Llamada VIP',
      // Toasts
      'settings_saved': 'Configuración guardada exitosamente',
      'export_success': 'Archivo exportado con éxito',
      'salary_saved': 'Configuración de salario guardada',
      'enter_gross_salary': 'Ingrese el salario bruto',
      'error': 'Error',
      // Signup & Other
      'account_created_check_email':
          '¡Cuenta creada! Revisa tu correo para continuar.',
      'create_your': 'Crea tu\n',
      'farol_account': 'cuenta Farol.',
      'start_illuminating': 'Empieza a iluminar tu camino financiero hoy.',
      'set_planned_income':
          'Establece tu ingreso mensual planeado. El dashboard rastreará los montos restantes a medida que agregues gastos.',
      'passwords_dont_match': 'Las contraseñas no coinciden',
      'create_account_arrow': 'Crear cuenta →',
      'already_have_account': '¿Ya tienes una cuenta? ',
      'very_weak': 'Muy débil',
      'weak': 'Débil',
      'good': 'Buena',
      'strong': 'Fuerte',
      'we_sent_verification':
          'Enviamos un enlace de verificación a tu correo. Revísalo para continuar.',
      'new_password_title_1': 'Nueva\n',
      'new_password_title_2': 'contraseña.',
      'choose_strong_password':
          'Elige una contraseña fuerte para proteger tu cuenta.',
      'new_password': 'Nueva contraseña',
      'min_8_chars': 'Mínimo 8 caracteres',
      'confirm_new_password': 'Confirmar nueva contraseña',
      'update_password_arrow': 'Actualizar contraseña →',
      'type': 'Tipo',
      'current_balance_input': 'Saldo actual',
      'product_name': 'Nombre del producto',
      'institution': 'Institución / Broker',
      'notes_optional': 'Notas (opcional)',
      'enter_product_name': 'Ingresa el nombre del producto',
      'enter_institution': 'Ingresa la institución',
      'enter_invested_amount': 'Ingresa el monto invertido',
      'enter_valid_balance': 'Ingresa un saldo actual válido',
      'set_monthly_spending_limits':
          'Establece límites de gasto mensual por categoría',
      'current_spending': 'Actual',
      'budget_amount': 'Monto del presupuesto',
      'cash_budget': 'Presupuesto Cash',
      'swile_budget': 'Presupuesto Swile',
      'swile_balance': 'Saldo Swile',
      'of_swile_balance': 'del saldo Swile',
      'name': 'Nombre',
      'name_required': 'El nombre es obligatorio',
      'full_name': 'Nombre completo',
      'full_name_required': 'El nombre completo es obligatorio',
      'cpf_optional': 'CPF (opcional)',
      'cpf_invalid': 'CPF inválido',
      'terms_accept': 'Acepto los ',
      'terms_link': 'términos de uso',
      'terms_required': 'Debes aceptar los términos para continuar',
      'avatar_optional': 'URL de Avatar (opcional)',
      'new_installment': 'Nueva Cuota',
      'description_required': 'Descripción *',
      'desc_example': 'ej: Portátil, Celular...',
      'monthly_installment_amount': 'Monto mensual de la cuota',
      'num_installments': 'Número de cuotas',
      'current_installment': 'Cuota actual',
      'of': 'de',
      'purchased_on': 'Comprado el',
      'enter_description': 'Ingresa la descripción',
      'enter_installment_amount': 'Ingresa el monto de la cuota',
      'installment_added': '¡Cuota agregada!',
      'total': 'Total',
      'remaining': 'Restan',
      'remaining_balance': 'Saldo restante',
      // Settings – hardcoded strings
      'could_not_load_salary': 'No se pudo cargar la configuración de salario',
      'lbl_gross': 'Bruto',
      'lbl_net': 'Neto',
      'per_month': '/ mes',
      'tap_configure_budgets': 'Toca para configurar tus presupuestos',
      'salary': 'Salario',
      'simulators': 'Simuladores',
      'simulator_13th': 'Simulador 13° Salario',
      'simulator_13th_desc': 'Calcula cuotas, INSS e IRRF',
      'simulator_fgts': 'Retiro Aniversario FGTS',
      'simulator_fgts_desc': 'Simula el retiro anual y proyección 3 años',
      'hide_values': 'Ocultar valores',
      'hide_values_desc': 'Enmascara montos en toda la app',
      // ── Categories Management ──
      'categories': 'Categorías',
      'manage_categories': 'Gestiona tus categorías de gastos',
      'no_categories_found': 'No se encontraron categorías',
      'add_first_category': 'Agregar tu primera categoría',
      'add_category': 'Agregar Categoría',
      'edit_category': 'Editar Categoría',
      'new_category': 'Nueva Categoría',
      'category_name': 'Nombre de la categoría',
      'category_emoji': 'Emoji',
      'category_emoji_hint': 'ej. 🏠',
      'category_name_hint': 'ej. Alquiler',
      'swile_category': 'Categoría Swile',
      'swile_category_desc': 'Usada para vales de comida/restaurante',
      'category_updated': 'Categoría actualizada',
      'category_added': 'Categoría agregada',
      'category_deleted': 'Categoría eliminada',
      'delete_category': '¿Eliminar categoría?',
      'delete_category_desc': 'No eliminará gastos existentes, pero la categoría dejará de aparecer en tus categorías activas.',
      'required': 'Requerido',
      // ── Budget Rebalance ──
      'rebalance_budget': 'Rebalancear Presupuesto',
      'rebalance_subtitle': 'Ajusta los porcentajes para llegar al 100%',
      'normalize': 'Normalizar',
      'preview_changes': 'Vista previa de cambios',
      'budget_rebalanced': 'Presupuesto rebalanceado exitosamente',
      'over_limit': 'Excedido por %s%% — ajusta primero',
      'under_limit': 'Faltan %s%% — ajusta primero',
      // ── Period Budget ──
      'period_budget': 'Presupuesto de Período',
      'copy_from_previous': 'Copiar del período anterior',
      'no_budgets_period': 'Sin presupuestos para este período',
      'budgets_hint': 'Agrega metas en Ajustes para ver los valores aquí',
      'reset_to_goal': '¿Restablecer al monto de la meta?',
      'reset_to_goal_desc': 'Esto eliminará el monto personalizado y volverá a tu meta.',
      'remove_budget': '¿Eliminar presupuesto de %s?',
      'reset': 'Restablecer',
      'edit_budget': 'Editar Presupuesto',
      'new_budget': 'Nuevo Presupuesto',
      'copied_budgets': 'Se copiaron %d presupuesto(s) del período anterior',
      'no_budgets_to_copy': 'No hay presupuestos nuevos para copiar',
      'spent': 'Gastado',
      'left': 'Restan',
      'over': 'Excedido',
      'goal': 'Meta',
    },
    'pt': {
      'app_name': 'Farol',
      'dashboard': 'Início',
      'transactions': 'Transações',
      'analytics': 'Análises',
      'investments': 'Investir',
      'settings': 'Configurações',
      'income': 'Receitas',
      'expenses': 'Despesas',
      'net_worth': 'Patrimônio',
      'health_score': 'Saúde Financeira',
      'add_expense': 'Adicionar Despesa',
      'save': 'Salvar',
      'cancel': 'Cancelar',
      'category': 'Categoria',
      'amount': 'Valor',
      'date': 'Data',
      'payment_method': 'Forma de Pagamento',
      'fixed_cost': 'Custo Fixo',
      'installments': 'Parcelas',
      'language': 'Idioma',
      'spanish': 'Espanhol',
      'portuguese': 'Português',
      'english': 'Inglês',
      'theme': 'Tema',
      'dark_mode': 'Modo Escuro',
      'light_mode': 'Modo Claro',
      'system_mode': 'Sistema',
      'profile': 'Perfil',
      'budget_goals': 'Metas de Orçamento',
      'net_salary': 'Salário Líquido',
      'swile': 'Benefícios',
      'available_total': 'Total Disponível',
      'cash_expenses': 'Despesas em Dinheiro',
      'monthly_balance': 'Saldo Mensal',
      'savings_rate': 'Taxa de Poupança',
      'swile_remaining': 'Swile Disponível',
      'expense_by_cat': 'Gastos por Categoria',
      'no_expenses': 'Sem gastos registrados',
      'no_expenses_hint': 'Adicione um gasto para ver o detalhamento dos seus gastos.',
      'no_net_worth': 'Sem dados de patrimônio',
      'score_desc': 'Pontuação de 0 a 10',
      'months': [
        'Jan',
        'Fev',
        'Mar',
        'Abr',
        'Mai',
        'Jun',
        'Jul',
        'Ago',
        'Set',
        'Out',
        'Nov',
        'Dez'
      ],
      // Enums
      'cat_housing': 'Moradia',
      'cat_transport': 'Transporte',
      'cat_food': 'Alimentação',
      'cat_health': 'Saúde',
      'cat_subs': 'Assinaturas',
      'cat_leisure': 'Lazer',
      'cat_edu': 'Educação',
      'cat_card': 'Parcelas Cartão',
      'cat_other': 'Outros',
      'income_net_salary': 'Salário Líquido',
      'income_swile_meal': 'Swile Refeição',
      'income_swile_food': 'Swile Alimentação',
      'income_bonus': 'Bônus',
      'income_13th': '13° Salário',
      'income_overtime': 'Hora Extra',
      'income_other': 'Outros',
      'health_healthy': 'SAUDÁVEL',
      'health_warning': 'ATENÇÃO',
      'health_critical': 'CRÍTICO',
      'health_excellent': 'Excelente! Suas finanças estão saudáveis.',
      'health_good': 'Muito bom! Continue assim.',
      'health_fair': 'Razoável. Há espaço para melhorar.',
      'health_warning_desc': 'Atenção! Revise seus gastos.',
      'health_critical_desc': 'Crítico! É preciso agir agora.',
      'total_consolidated': 'TOTAL CONSOLIDADO',
      'asset_allocation': 'Alocação de Ativos',
      'ia_suggestion': 'Sugestão IA',
      'current_balance': 'SALDO ATUAL',
      'portfolio': 'Portfólio',
      'monthly_goal': 'Meta Mensal',
      'missing': 'Faltam',
      'to_reach_goal': 'para atingir sua meta de economia este mês.',
      'onboarding_title': 'Clareza para cada real.',
      'onboarding_subtitle':
          'Seu dinheiro no rumo certo. Planejamento financeiro que guia cada decisão com clareza.',
      'onboarding_f1': 'Segurança bancária e Pix integrado',
      'onboarding_f2': 'IA que entende seu salário CLT e FGTS',
      'onboarding_f3': 'Suporte em português, 24/7',
      'onboarding_button': 'Criar minha conta Farol',
      'onboarding_login': 'Já sou cliente · Entrar',
      'pay_debit': 'Débito',
      'pay_pix': 'PIX',
      'pay_credit': 'Crédito à Vista',
      'pay_credit_inst': 'Crédito Parcelado',
      'pay_swile_meal': 'Swile Saldo Livre',
      'pay_swile_food': 'Swile Alimentação',
      // Toast messages
      'net_worth_saved': 'Patrimônio salvo!',
      'budget_saved': 'Orçamento salvo!',
      'budget_goals_saved': 'Metas de orçamento salvas!',
      'expense_saved': 'Despesa salva!',
      'invalid_amount': 'Insira um valor válido',
      'email_required': 'Primeiro insira seu e-mail',
      'recovery_email_sent': 'E-mail de recuperação enviado',
      'verification_email_resent': 'E-mail de verificação reenviado',
      'error_saving': 'Erro ao salvar',
      // Edit / Delete
      'edit': 'Editar',
      'delete': 'Excluir',
      'edit_expense': 'Editar Despesa',
      'confirm_delete': 'Excluir esta despesa?',
      'cannot_undo': 'Esta ação não pode ser desfeita.',
      'transaction_deleted': 'Despesa excluída',
      'transaction_updated': 'Despesa atualizada!',
      // Authentication
      'sign_in': 'Fazer Login',
      'sign_up': 'Criar Conta',
      'sign_out': 'Sair',
      'forgot_password': 'Esqueceu a senha?',
      'verify_email': 'Verifique seu e-mail',
      'resend_email': 'Reenviar e-mail',
      'set_new_password': 'Definir Nova Senha',
      'update_password': 'Atualizar Senha',
      'or_sign_in_with': 'Ou faça login com',
      'something_went_wrong': 'Algo deu errado. Reinicie o app.',
      'retry': 'Tentar Novamente',
      // Investments
      'add_investment': 'Adicionar Investimento',
      'amount_invested': 'Valor investido',
      'investment_added': 'Investimento adicionado!',
      'delete_investment': 'Excluir investimento?',
      'no_investments_yet':
          'Nenhum investimento ainda.\nToque + para adicionar um.',
      'current_balance_differs': 'Saldo atual diferente do investido',
      'remove': 'Remover',
      // Budget
      'monthly_budget': 'Orçamento Mensal',
      'save_budget': 'Salvar Orçamento',
      'could_not_load_budget': 'Não foi possível carregar o orçamento',
      'could_not_load_net_worth': 'Não foi possível carregar o patrimônio',
      // Profile & Settings
      'edit_profile': 'Editar Perfil',
      'appearance': 'Aparência',
      'customize_interface':
          'Personalize sua interface para o máximo conforto visual.',
      'concierge_support': 'Suporte Concierge',
      'corporate_benefits': 'Benefícios Corporativos',
      // Transactions & Benefits
      'recent_transactions': 'Transações Recentes',
      'monthly_spending': 'Gastos Mensais',
      'last_7_days': 'Últimos 7 dias',
      'see_all': 'Ver Tudo',
      // Login Extra
      'welcome': 'Bem-vindo\n',
      'back': 'de volta.',
      'login_subtitle': 'Entre e continue iluminando seu caminho financeiro.',
      'email': 'E-mail',
      'password': 'Senha',
      'invalid_email': 'E-mail inválido',
      'min_6_chars': 'Mínimo 6 caracteres',
      'dont_have_account': 'Ainda não tem conta? ',
      // Settings Extra
      'data_privacy': 'Dados e Privacidade',
      'export_transactions': 'Exportar Transações',
      'income_statement': 'Demonstrativo de Resultados',
      'full_backup': 'Backup Completo',
      'monthly_report_pdf': 'Relatório Mensal PDF',
      'category_budgets': 'Orçamentos por Categoria',
      'set_spending_limits': 'Defina limites de gastos',
      'financial_period': 'Período financeiro',
      'period_start': 'Início do período',
      'day_of_each_month': 'Dia de cada mês',
      'select_period_start': 'Selecione o dia que inicia seu período (1-28):',
      'salary_configured': 'Salário Configurado',
      'configure_salary': 'Configurar Salário',
      'salary_calculated': 'Impostos calculados automaticamente',
      'net_worth_configured': 'Patrimônio Configurado',
      'configure_net_worth': 'Configurar Patrimônio',
      'net_worth_desc': 'Imóveis, Investimentos, FGTS...',
      'chat_24_7': 'Chat 24/7',
      'vip_call': 'Chamada VIP',
      // Toasts
      'settings_saved': 'Configurações salvas com sucesso',
      'export_success': 'Arquivo exportado com sucesso',
      'salary_saved': 'Configuração de salário salva',
      'enter_gross_salary': 'Informe o salário bruto',
      'error': 'Erro',
      // Signup & Other
      'account_created_check_email':
          'Conta criada! Verifique seu e-mail para continuar.',
      'create_your': 'Criar sua\n',
      'farol_account': 'conta Farol.',
      'start_illuminating': 'Comece a iluminar seu caminho financeiro hoje.',
      'set_planned_income':
          'Defina sua renda mensal planejada. O dashboard rastreará os valores restantes à medida que você adiciona transações.',
      'passwords_dont_match': 'As senhas não coincidem',
      'create_account_arrow': 'Criar conta →',
      'already_have_account': 'Já tem uma conta? ',
      'very_weak': 'Muito fraca',
      'weak': 'Fraca',
      'good': 'Boa',
      'strong': 'Forte',
      'we_sent_verification':
          'Enviamos um link de verificação para o seu e-mail. Verifique-o para continuar.',
      'new_password_title_1': 'Nova\n',
      'new_password_title_2': 'senha.',
      'choose_strong_password':
          'Escolha uma senha forte para proteger sua conta.',
      'new_password': 'Nova senha',
      'min_8_chars': 'Mínimo 8 caracteres',
      'confirm_new_password': 'Confirmar nova senha',
      'update_password_arrow': 'Atualizar senha →',
      'type': 'Tipo',
      'current_balance_input': 'Saldo atual',
      'product_name': 'Nome do produto',
      'institution': 'Instituição / Corretora',
      'notes_optional': 'Notas (opcional)',
      'enter_product_name': 'Informe o nome do produto',
      'enter_institution': 'Informe a instituição',
      'enter_invested_amount': 'Informe o valor investido',
      'enter_valid_balance': 'Informe um saldo atual válido',
      'set_monthly_spending_limits':
          'Defina limites de gastos mensais por categoria',
      'current_spending': 'Atual',
      'budget_amount': 'Valor do orçamento',
      'cash_budget': 'Orçamento Caixa',
      'swile_budget': 'Orçamento Swile',
      'swile_balance': 'Saldo Swile',
      'of_swile_balance': 'do saldo Swile',
      'name': 'Nome',
      'name_required': 'O nome é obrigatório',
      'full_name': 'Nome completo',
      'full_name_required': 'O nome completo é obrigatório',
      'cpf_optional': 'CPF (opcional)',
      'cpf_invalid': 'CPF inválido',
      'terms_accept': 'Aceito os ',
      'terms_link': 'termos de uso',
      'terms_required': 'Você deve aceitar os termos para continuar',
      'avatar_optional': 'URL do Avatar (opcional)',
      'new_installment': 'Nova Parcela',
      'description_required': 'Descrição *',
      'desc_example': 'ex: Notebook, Celular…',
      'monthly_installment_amount': 'Valor da parcela mensal',
      'num_installments': 'Número de parcelas',
      'current_installment': 'Parcela atual',
      'of': 'de',
      'purchased_on': 'Compra em',
      'enter_description': 'Informe a descrição',
      'enter_installment_amount': 'Informe o valor da parcela',
      'installment_added': 'Parcela adicionada!',
      'total': 'Total',
      'remaining': 'Restam',
      'remaining_balance': 'Saldo restante',
      // Settings – hardcoded strings
      'could_not_load_salary': 'Não foi possível carregar as configurações de salário',
      'lbl_gross': 'Bruto',
      'lbl_net': 'Líquido',
      'per_month': '/ mês',
      'tap_configure_budgets': 'Toque para configurar seus orçamentos',
      'salary': 'Salário',
      'simulators': 'Simuladores',
      'simulator_13th': 'Simulador 13º Salário',
      'simulator_13th_desc': 'Calcule parcelas, INSS e IRRF',
      'simulator_fgts': 'Saque Aniversário FGTS',
      'simulator_fgts_desc': 'Simule o saque anual e projeção 3 anos',
      'hide_values': 'Ocultar valores',
      'hide_values_desc': 'Oculta os valores em todo o app',
      // ── Categories Management ──
      'categories': 'Categorias',
      'manage_categories': 'Gerencie suas categorias de despesas',
      'no_categories_found': 'Nenhuma categoria encontrada',
      'add_first_category': 'Adicionar primeira categoria',
      'add_category': 'Adicionar Categoria',
      'edit_category': 'Editar Categoria',
      'new_category': 'Nova Categoria',
      'category_name': 'Nome da categoria',
      'category_emoji': 'Emoji',
      'category_emoji_hint': 'ex. 🏠',
      'category_name_hint': 'ex. Aluguel',
      'swile_category': 'Categoria Swile',
      'swile_category_desc': 'Usada para vale-refeição/alimentação',
      'category_updated': 'Categoria atualizada',
      'category_added': 'Categoria adicionada',
      'category_deleted': 'Categoria excluída',
      'delete_category': 'Excluir categoria?',
      'delete_category_desc': 'Os gastos existentes não serão excluídos, mas a categoria deixará de aparecer nas categorias ativas.',
      'required': 'Obrigatório',
      // ── Budget Rebalance ──
      'rebalance_budget': 'Rebalancear Orçamento',
      'rebalance_subtitle': 'Ajuste os percentuais para chegar a 100%',
      'normalize': 'Normalizar',
      'preview_changes': 'Pré-visualizar alterações',
      'budget_rebalanced': 'Orçamento rebalanceado com sucesso',
      'over_limit': 'Excedido em %s%% — ajuste primeiro',
      'under_limit': 'Faltam %s%% — ajuste primeiro',
      // ── Period Budget ──
      'period_budget': 'Orçamento do Período',
      'copy_from_previous': 'Copiar do período anterior',
      'no_budgets_period': 'Sem orçamentos para este período',
      'budgets_hint': 'Adicione metas em Configurações para ver os valores aqui',
      'reset_to_goal': 'Redefinir para o valor da meta?',
      'reset_to_goal_desc': 'Isso removerá o valor personalizado e voltará à sua meta.',
      'remove_budget': 'Remover orçamento de %s?',
      'reset': 'Redefinir',
      'edit_budget': 'Editar Orçamento',
      'new_budget': 'Novo Orçamento',
      'copied_budgets': '%d orçamento(s) copiado(s) do período anterior',
      'no_budgets_to_copy': 'Nenhum orçamento novo para copiar',
      'spent': 'Gasto',
      'left': 'Restam',
      'over': 'Excedido',
      'goal': 'Meta',
    },
  };

  String translate(String key) {
    final value = _localizedValues[locale.languageCode]?[key];
    if (value is String) return value;
    return key;
  }

  static String translateStatic(String languageCode, String key) {
    final value = _localizedValues[languageCode]?[key];
    if (value is String) return value;
    return key;
  }

  static List<String> monthsForLocale(String languageCode) =>
      (_localizedValues[languageCode]?['months'] as List<String>?) ??
      (_localizedValues['en']!['months'] as List<String>);

  String get appName => translate('app_name');
  String get dashboard => translate('dashboard');
  String get transactions => translate('transactions');
  String get analytics => translate('analytics');
  String get investments => translate('investments');
  String get settings => translate('settings');
  String get income => translate('income');
  String get expenses => translate('expenses');
  String get netWorth => translate('net_worth');
  String get healthScore => translate('health_score');
  String get addExpense => translate('add_expense');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get category => translate('category');
  String get amount => translate('amount');
  String get date => translate('date');
  String get paymentMethod => translate('payment_method');
  String get fixedCost => translate('fixed_cost');
  String get installments => translate('installments');
  String get language => translate('language');
  String get spanish => translate('spanish');
  String get portuguese => translate('portuguese');
  String get english => translate('english');
  String get theme => translate('theme');
  String get darkMode => translate('dark_mode');
  String get lightMode => translate('light_mode');
  String get systemMode => translate('system_mode');
  List<String> get months =>
      (_localizedValues[locale.languageCode]?['months'] as List<String>?) ??
      [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];

  String get healthHealthy => translate('health_healthy');
  String get healthWarning => translate('health_warning');
  String get healthCritical => translate('health_critical');
  String get healthExcellentDesc => translate('health_excellent');
  String get healthGoodDesc => translate('health_good');
  String get healthFairDesc => translate('health_fair');
  String get healthWarningDesc => translate('health_warning_desc');
  String get healthCriticalDesc => translate('health_critical_desc');

  String get netWorthSaved => translate('net_worth_saved');
  String get budgetSaved => translate('budget_saved');
  String get budgetGoalsSaved => translate('budget_goals_saved');
  String get expenseSaved => translate('expense_saved');
  String get invalidAmount => translate('invalid_amount');
  String get emailRequired => translate('email_required');
  String get recoveryEmailSent => translate('recovery_email_sent');
  String get verificationEmailResent => translate('verification_email_resent');
  String get errorSaving => translate('error_saving');
  String get edit => translate('edit');
  String get delete => translate('delete');
  String get editExpense => translate('edit_expense');
  String get confirmDelete => translate('confirm_delete');
  String get cannotUndo => translate('cannot_undo');
  String get transactionDeleted => translate('transaction_deleted');
  String get transactionUpdated => translate('transaction_updated');

  // Authentication
  String get signIn => translate('sign_in');
  String get signUp => translate('sign_up');
  String get signOut => translate('sign_out');
  String get forgotPassword => translate('forgot_password');
  String get verifyEmail => translate('verify_email');
  String get resendEmail => translate('resend_email');
  String get setNewPassword => translate('set_new_password');
  String get updatePassword => translate('update_password');
  String get orSignInWith => translate('or_sign_in_with');
  String get somethingWentWrong => translate('something_went_wrong');
  String get retry => translate('retry');

  // Investments
  String get addInvestment => translate('add_investment');
  String get amountInvested => translate('amount_invested');
  String get investmentAdded => translate('investment_added');
  String get deleteInvestment => translate('delete_investment');
  String get noInvestmentsYet => translate('no_investments_yet');
  String get currentBalanceDiffers => translate('current_balance_differs');
  String get remove => translate('remove');

  // Budget
  String get monthlyBudget => translate('monthly_budget');
  String get saveBudget => translate('save_budget');
  String get couldNotLoadBudget => translate('could_not_load_budget');
  String get couldNotLoadNetWorth => translate('could_not_load_net_worth');

  // Profile & Settings
  String get editProfile => translate('edit_profile');
  String get appearance => translate('appearance');
  String get customizeInterface => translate('customize_interface');
  String get conciergeSupport => translate('concierge_support');
  String get corporateBenefits => translate('corporate_benefits');

  // Transactions & Benefits
  String get recentTransactions => translate('recent_transactions');
  String get monthlySpending => translate('monthly_spending');
  String get last7Days => translate('last_7_days');
  String get seeAll => translate('see_all');

  // Settings
  String get couldNotLoadSalary => translate('could_not_load_salary');
  String get lblGross => translate('lbl_gross');
  String get lblNet => translate('lbl_net');
  String get perMonth => translate('per_month');
  String get tapConfigureBudgets => translate('tap_configure_budgets');
  String get salary => translate('salary');
  String get simulators => translate('simulators');
  String get simulator13th => translate('simulator_13th');
  String get simulator13thDesc => translate('simulator_13th_desc');
  String get simulatorFgts => translate('simulator_fgts');
  String get simulatorFgtsDesc => translate('simulator_fgts_desc');
  String get hideValues => translate('hide_values');
  String get hideValuesDesc => translate('hide_values_desc');

  // ── Categories Management ──
  String get categories => translate('categories');
  String get manageCategories => translate('manage_categories');
  String get noCategoriesFound => translate('no_categories_found');
  String get addFirstCategory => translate('add_first_category');
  String get addCategory => translate('add_category');
  String get editCategory => translate('edit_category');
  String get newCategory => translate('new_category');
  String get categoryName => translate('category_name');
  String get categoryEmoji => translate('category_emoji');
  String get categoryEmojiHint => translate('category_emoji_hint');
  String get categoryNameHint => translate('category_name_hint');
  String get swileCategory => translate('swile_category');
  String get swileCategoryDesc => translate('swile_category_desc');
  String get categoryUpdated => translate('category_updated');
  String get categoryAdded => translate('category_added');
  String get categoryDeleted => translate('category_deleted');
  String get deleteCategory => translate('delete_category');
  String get deleteCategoryDesc => translate('delete_category_desc');
  String get required => translate('required');

  // ── Budget Rebalance ──
  String get rebalanceBudget => translate('rebalance_budget');
  String get rebalanceSubtitle => translate('rebalance_subtitle');
  String get normalize => translate('normalize');
  String get previewChanges => translate('preview_changes');
  String get budgetRebalanced => translate('budget_rebalanced');

  // ── Period Budget ──
  String get periodBudget => translate('period_budget');
  String get copyFromPrevious => translate('copy_from_previous');
  String get noBudgetsPeriod => translate('no_budgets_period');
  String get budgetsHint => translate('budgets_hint');
  String get resetToGoal => translate('reset_to_goal');
  String get resetToGoalDesc => translate('reset_to_goal_desc');
  String get reset => translate('reset');
  String get editBudget => translate('edit_budget');
  String get newBudget => translate('new_budget');
  String get spent => translate('spent');
  String get left => translate('left');
  String get over => translate('over');
  String get goal => translate('goal');
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
