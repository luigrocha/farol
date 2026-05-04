import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // ── Translations ──────────────────────────────────────────────────────────

  static final Map<String, Map<String, Object>> _t = {
    'en': {
      // Core
      'app_name': 'Farol',
      'dashboard': 'Dashboard',
      'transactions': 'Transactions',
      'analytics': 'Analytics',
      'investments': 'Investments',
      'settings': 'Settings',
      'income': 'Income',
      'expenses': 'Expenses',
      'net_worth': 'Net Worth',
      'net_worth_title': 'Net Worth',
      'health_score': 'Financial Health',
      'save': 'Save',
      'cancel': 'Cancel',
      'edit': 'Edit',
      'delete': 'Delete',
      'remove': 'Remove',
      'reset': 'Reset',
      'retry': 'Retry',
      'total': 'Total',
      'remaining': 'Remaining',
      'remaining_balance': 'Remaining balance',
      'of': 'of',
      'goal': 'Goal',
      'spent': 'Spent',
      'left': 'Left',
      'over': 'Over',
      'type': 'Type',
      'name': 'Name',
      'name_required': 'Name is required',
      'full_name': 'Full name',
      'full_name_required': 'Full name is required',
      'description': 'Description',
      'subcategory': 'Subcategory',
      'optional': 'optional',
      'required': 'Required',
      'error': 'Error',
      'months': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
      // Expenses & Transactions
      'add_expense': 'Add Expense',
      'edit_expense': 'Edit Expense',
      'confirm_delete': 'Delete this expense?',
      'cannot_undo': 'This action cannot be undone.',
      'transaction_deleted': 'Expense deleted',
      'transaction_updated': 'Expense updated!',
      'category': 'Category',
      'amount': 'Amount',
      'date': 'Date',
      'payment_method': 'Payment Method',
      'fixed_cost': 'Fixed Cost',
      'installments': 'Installments',
      'recent_transactions': 'Recent Transactions',
      'monthly_spending': 'Monthly Spending',
      'last_7_days': 'Last 7 days',
      'see_all': 'See all',
      'expense_by_cat': 'Expenses by Category',
      'no_expenses': 'No registered expenses',
      'no_expenses_hint': 'Add an expense to see your spending breakdown.',
      // Income
      'edit_income': 'Edit Income',
      'income_updated': 'Income updated!',
      'net_value_hint': 'Net value (INSS/IRRF already deducted)',
      'dependents_irrf': 'Dependents (IRRF)',
      'calculate_net': 'Calculate net',
      'salary_breakdown': 'Salary Breakdown',
      'use_net_value': 'Use net value',
      // Net Worth Screen
      'evolution': 'Evolution',
      'period_flow': 'Period Flow',
      'no_history_data': 'No historical data yet.\nSnapshots are saved automatically.',
      'no_net_worth': 'No net worth data',
      'no_accounts_registered': 'No accounts registered',
      'filter_all_time': 'All',
      'accounts_label': 'Accounts',
      'invested_label': 'Invested',
      'estimated_total': 'Estimated total',
      'debts_installments': 'Debts (installments)',
      'internal_transfers': 'Internal transfers',
      'patrimony_real_estate': '🏠 Assets (Real Estate)',
      'emergency_fund': '💰 Emergency Fund',
      'asset_allocation': 'Asset Allocation',
      'total_consolidated': 'TOTAL CONSOLIDATED',
      'current_balance': 'CURRENT BALANCE',
      'portfolio': 'Portfolio',
      'ia_suggestion': 'AI Suggestion',
      'monthly_goal': 'Monthly Goal',
      'missing': 'Missing',
      'to_reach_goal': 'to reach your savings goal this month.',
      // Investments
      'add_investment': 'Add Investment',
      'amount_invested': 'Amount invested',
      'current_balance_input': 'Current balance',
      'current_balance_differs': 'Current balance differs from invested',
      'investment_added': 'Investment added',
      'delete_investment': 'Delete investment?',
      'no_investments_yet': 'No investments yet.\nTap + to add one.',
      'product_name': 'Product name',
      'institution': 'Institution / Broker',
      'notes_optional': 'Notes (optional)',
      'enter_product_name': 'Enter a product name',
      'enter_institution': 'Enter the institution',
      'enter_invested_amount': 'Enter the invested amount',
      'enter_valid_balance': 'Enter a valid current balance',
      // Budget & Goals
      'monthly_budget': 'Monthly Budget',
      'save_budget': 'Save Budget',
      'budget_goals': 'Budget Goals',
      'category_budgets': 'Category Budgets',
      'set_spending_limits': 'Set spending limits per category',
      'set_monthly_spending_limits': 'Set monthly spending limits per category',
      'current_spending': 'Current',
      'budget_amount': 'Budget amount',
      'cash_budget': 'Cash Budget',
      'swile_budget': 'Swile Budget',
      'period_budget': 'Period Budget',
      'copy_from_previous': 'Copy from previous period',
      'no_budgets_period': 'No budgets for this period',
      'budgets_hint': 'Add budget goals in Settings to see defaults here',
      'reset_to_goal': 'Reset to goal amount?',
      'reset_to_goal_desc': 'This will remove the custom amount and revert to your goal.',
      'remove_budget': 'Remove budget for %s?',
      'edit_budget': 'Edit Budget',
      'new_budget': 'New Budget',
      'copied_budgets': 'Copied %d budget(s) from previous period',
      'no_budgets_to_copy': 'No new budgets to copy',
      'rebalance_budget': 'Rebalance Budget',
      'rebalance_subtitle': 'Adjust percentages to reach exactly 100%',
      'normalize': 'Normalize',
      'preview_changes': 'Preview changes',
      'budget_rebalanced': 'Budget rebalanced successfully',
      'over_limit': 'Over by %s%% — adjust first',
      'under_limit': 'Under by %s%% — adjust first',
      // Salary & Settings
      'net_salary': 'Net Salary',
      'salary': 'Salary',
      'lbl_gross': 'Gross',
      'lbl_net': 'Net',
      'per_month': '/ month',
      'salary_configured': 'Salary Configured',
      'configure_salary': 'Configure Salary',
      'salary_calculated': 'Taxes automatically calculated',
      'net_worth_configured': 'Net Worth Configured',
      'configure_net_worth': 'Configure Net Worth',
      'net_worth_desc': 'Real Estate, Investments, etc.',
      'savings_rate': 'Savings Rate',
      'monthly_balance': 'Monthly Balance',
      'available_total': 'Total Available',
      'cash_expenses': 'Cash Expenses',
      'tap_configure_budgets': 'Tap to configure your income budgets',
      'score_desc': 'Score from 0 to 10',
      // Swile / Benefits
      'swile': 'Swile',
      'swile_remaining': 'Swile Remaining',
      'swile_balance': 'Swile balance',
      'of_swile_balance': 'of Swile balance',
      'swile_category': 'Swile Category',
      'swile_category_desc': 'Used for meal/food vouchers',
      // Payment methods
      'pay_debit': 'Debit',
      'pay_pix': 'PIX',
      'pay_credit': 'Credit',
      'pay_credit_inst': 'Credit (Installments)',
      'pay_swile_meal': 'Swile Free Balance',
      'pay_swile_food': 'Swile Food',
      // Installments
      'new_installment': 'New Installment',
      'description_required': 'Description *',
      'desc_example': 'e.g. Laptop, Phone...',
      'monthly_installment_amount': 'Monthly installment amount',
      'num_installments': 'Number of installments',
      'current_installment': 'Current installment',
      'purchased_on': 'Purchased on',
      'enter_description': 'Enter description',
      'enter_installment_amount': 'Enter installment amount',
      'installment_added': 'Installment added!',
      // Categories
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
      'category_updated': 'Category updated',
      'category_added': 'Category added',
      'category_deleted': 'Category deleted',
      'delete_category': 'Delete category?',
      'delete_category_desc': 'This will not delete existing expenses, but the category will be removed from active categories.',
      // Category enums
      'cat_housing': 'Housing',
      'cat_transport': 'Transport',
      'cat_food': 'Food & Grocery',
      'cat_health': 'Health',
      'cat_subs': 'Subscriptions',
      'cat_leisure': 'Leisure',
      'cat_edu': 'Education',
      'cat_card': 'Card Installments',
      'cat_other': 'Other',
      // Income enums
      'income_net_salary': 'Net Salary',
      'income_swile_meal': 'Swile Meal',
      'income_swile_food': 'Swile Food',
      'income_bonus': 'Bonus',
      'income_13th': '13th Salary',
      'income_overtime': 'Overtime',
      'income_other': 'Other',
      'chart_diversified': 'Diversified',
      // Health score
      'health_healthy': 'HEALTHY',
      'health_warning': 'WARNING',
      'health_critical': 'CRITICAL',
      'health_excellent': 'Excellent! Your finances are healthy.',
      'health_good': 'Very good! Keep it up.',
      'health_fair': 'Fair. There is room for improvement.',
      'health_warning_desc': 'Warning! Review your spending.',
      'health_critical_desc': 'Critical! Urgent action is needed.',
      // Authentication
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'sign_out': 'Sign Out',
      'forgot_password': 'Forgot password?',
      'verify_email': 'Verify your email',
      'resend_email': 'Resend email',
      'set_new_password': 'Set New Password',
      'update_password': 'Update Password',
      'update_password_arrow': 'Update password →',
      'or_sign_in_with': 'Or sign in with',
      'something_went_wrong': 'Something went wrong. Please restart the app.',
      'welcome': 'Welcome\n',
      'back': 'back.',
      'login_subtitle': 'Sign in and continue lighting your financial path.',
      'email': 'Email',
      'password': 'Password',
      'invalid_email': 'Invalid email',
      'min_6_chars': 'Minimum 6 characters',
      'min_8_chars': 'Minimum 8 characters',
      'dont_have_account': "Don't have an account? ",
      'already_have_account': 'Already have an account? ',
      'new_password': 'New password',
      'new_password_title_1': 'New\n',
      'new_password_title_2': 'password.',
      'confirm_new_password': 'Confirm new password',
      'choose_strong_password': 'Choose a strong password to protect your account.',
      'passwords_dont_match': 'Passwords do not match',
      'we_sent_verification': 'We sent a verification link to your email. Please check it to continue.',
      'very_weak': 'Very weak',
      'weak': 'Weak',
      'good': 'Good',
      'strong': 'Strong',
      // Onboarding
      'onboarding_title': 'Clarity for every dollar.',
      'onboarding_subtitle': 'Your money on the right track. Financial planning that guides every decision with clarity.',
      'onboarding_f1': 'Bank-grade security and integrated Pix',
      'onboarding_f2': 'AI that understands your salary and benefits',
      'onboarding_f3': 'Support in your language, 24/7',
      'onboarding_button': 'Create my Farol account',
      'onboarding_login': 'Already a client · Log in',
      // Signup
      'account_created_check_email': 'Account created! Check your email to continue.',
      'create_your': 'Create your\n',
      'farol_account': 'Farol account.',
      'start_illuminating': 'Start illuminating your financial path today.',
      'set_planned_income': 'Set your planned monthly income. The dashboard will track remaining amounts as you add transactions.',
      'create_account_arrow': 'Create account →',
      'cpf_optional': 'CPF (optional)',
      'cpf_invalid': 'Invalid CPF',
      'terms_accept': 'I accept the ',
      'terms_link': 'terms of use',
      'terms_required': 'You must accept the terms to continue',
      'avatar_optional': 'Avatar URL (optional)',
      // Profile & Settings
      'profile': 'Profile',
      'edit_profile': 'Edit Profile',
      'appearance': 'Appearance',
      'customize_interface': 'Customize your interface for maximum visual comfort.',
      'concierge_support': 'Concierge Support',
      'corporate_benefits': 'Corporate Benefits',
      'language': 'Language',
      'spanish': 'Spanish',
      'portuguese': 'Portuguese',
      'english': 'English',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'system_mode': 'System',
      'data_privacy': 'Data & Privacy',
      'export_transactions': 'Export Transactions',
      'income_statement': 'Income Statement',
      'full_backup': 'Full Backup',
      'monthly_report_pdf': 'Monthly Report PDF',
      'financial_period': 'Financial Period',
      'period_start': 'Start of period',
      'day_of_each_month': 'Day of each month',
      'select_period_start': 'Select the day your financial period begins (1-28):',
      'chat_24_7': 'Chat 24/7',
      'vip_call': 'VIP Call',
      'hide_values': 'Hide values',
      'hide_values_desc': 'Hide amounts throughout the app',
      // Simulators
      'simulators': 'Simulators',
      'simulator_13th': '13th Salary Simulator',
      'simulator_13th_desc': 'Calculate installments, INSS and IRRF',
      'simulator_fgts': 'FGTS Anniversary Withdrawal',
      'simulator_fgts_desc': 'Simulate annual withdrawal and 3-year projection',
      'simulator_rescission': 'CLT Rescission',
      'simulator_rescission_desc': 'Calculate your termination rights (Notice, 13th, Vacations)',
      'rescission_title': 'Rescission Simulator',
      'rescission_input_title': 'CONTRACT DATA',
      'rescission_gross_salary': 'Monthly Gross Salary',
      'rescission_fgts_balance': 'FGTS Balance for Fine',
      'rescission_start_date': 'Start Date',
      'rescission_end_date': 'End Date',
      'rescission_unjustified': 'Dismissal without cause',
      'rescission_notice_period': 'Worked notice period',
      'rescission_unused_vacation': 'Unused vacation days',
      'rescission_calculate': 'Calculate Rescission',
      'rescission_total_receive_gross': 'TOTAL GROSS TO RECEIVE',
      'rescission_disclaimer': '*Gross values. INSS and IRRF deductions may apply to salary balance and 13th.',
      'rescission_breakdown_title': 'BREAKDOWN',
      'rescission_salary_balance': 'Salary Balance',
      'rescission_proportional_13th': 'Proportional 13th',
      'rescission_proportional_vacation': 'Proportional Vacation',
      'rescission_unused_vacation_pay': 'Unused Vacations',
      'rescission_vacation_third': '1/3 Vacation Bonus',
      'rescission_notice_period_indemnified': 'Indemnified Notice Period',
      'rescission_fgts_fine': 'FGTS Fine (40%)',
      // Toast / feedback
      'net_worth_saved': 'Net worth saved!',
      'budget_saved': 'Budget saved!',
      'budget_goals_saved': 'Budget goals saved!',
      'expense_saved': 'Expense saved!',
      'invalid_amount': 'Enter a valid amount',
      'email_required': 'Enter your email first',
      'recovery_email_sent': 'Recovery email sent',
      'verification_email_resent': 'Verification email resent',
      'error_saving': 'Error saving',
      'settings_saved': 'Settings saved successfully',
      'export_success': 'File exported successfully',
      'salary_saved': 'Salary settings saved successfully',
      'enter_gross_salary': 'Please enter gross salary',
      'could_not_load_budget': 'Could not load budget',
      'could_not_load_net_worth': 'Could not load net worth',
      'could_not_load_salary': 'Could not load salary settings',
      'welcome_back': 'Welcome back!',
      'error_loading': 'Error loading',
      'save_changes': 'Save changes',
      // Budget overflow
      'budget_overflow_warning': 'Your budget allocations exceed 100%. Tap a category to adjust.',
      'rebalance': 'Rebalance',
      'allocated_over_limit': '%s%% allocated — over limit',
      // Accounts & Patrimony
      'bank_accounts': 'Bank Accounts',
      'manage_accounts_desc': 'Manage your accounts and transfers',
      'patrimony': 'Patrimony',
      'patrimony_desc': 'Consolidated view of your assets',
      // Salary sheet
      'salary_clt_title': 'CLT Salary 2026',
      'gross_monthly_salary': 'Monthly gross salary',
      'dependents': 'Dependents',
      'dependents_deduction': 'Deduction: %s / month',
      'simplified_deduction': 'Simplified deduction',
      'simplified_deduction_desc': 'R\$ 607.20 deducted from IRRF base',
      'other_deductions': 'Other deductions (health plan, etc.)',
      'net_salary_label': 'NET SALARY',
      'effective_rate_suffix': '%% effective rate',
      'monthly_reduction_applied': 'Monthly reduction applied: −%s',
      'fgts_employer_note': '* FGTS is an employer charge, not deducted from salary.',
    },
    'es': {
      // Core
      'app_name': 'Farol',
      'dashboard': 'Panel',
      'transactions': 'Movimientos',
      'analytics': 'Análisis',
      'investments': 'Inversiones',
      'settings': 'Ajustes',
      'income': 'Ingresos',
      'expenses': 'Gastos',
      'net_worth': 'Patrimonio',
      'net_worth_title': 'Patrimonio neto',
      'health_score': 'Salud Financiera',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'edit': 'Editar',
      'delete': 'Eliminar',
      'remove': 'Eliminar',
      'reset': 'Restablecer',
      'retry': 'Reintentar',
      'total': 'Total',
      'remaining': 'Restan',
      'remaining_balance': 'Saldo restante',
      'of': 'de',
      'goal': 'Meta',
      'spent': 'Gastado',
      'left': 'Restan',
      'over': 'Excedido',
      'type': 'Tipo',
      'name': 'Nombre',
      'name_required': 'El nombre es obligatorio',
      'full_name': 'Nombre completo',
      'full_name_required': 'El nombre completo es obligatorio',
      'description': 'Descripción',
      'subcategory': 'Subcategoría',
      'optional': 'opcional',
      'required': 'Requerido',
      'error': 'Error',
      'months': ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'],
      // Expenses & Transactions
      'add_expense': 'Añadir Gasto',
      'edit_expense': 'Editar Gasto',
      'confirm_delete': '¿Eliminar este gasto?',
      'cannot_undo': 'Esta acción no se puede deshacer.',
      'transaction_deleted': 'Gasto eliminado',
      'transaction_updated': '¡Gasto actualizado!',
      'category': 'Categoría',
      'amount': 'Monto',
      'date': 'Fecha',
      'payment_method': 'Método de Pago',
      'fixed_cost': 'Costo Fijo',
      'installments': 'Cuotas',
      'recent_transactions': 'Gastos Recientes',
      'monthly_spending': 'Gastos Mensuales',
      'last_7_days': 'Últimos 7 días',
      'see_all': 'Ver Todo',
      'expense_by_cat': 'Gastos por Categoría',
      'no_expenses': 'Sin gastos registrados',
      'no_expenses_hint': 'Agrega un gasto para ver el desglose de tus movimientos.',
      // Income
      'edit_income': 'Editar Ingreso',
      'income_updated': '¡Ingreso actualizado!',
      'net_value_hint': 'Valor neto (INSS/IRRF ya descontado)',
      'dependents_irrf': 'Dependientes (IRRF)',
      'calculate_net': 'Calcular neto',
      'salary_breakdown': 'Desglose del salario',
      'use_net_value': 'Usar valor neto',
      // Net Worth Screen
      'evolution': 'Evolución',
      'period_flow': 'Flujo del período',
      'no_history_data': 'Sin datos históricos aún.\nLos snapshots se guardan automáticamente.',
      'no_net_worth': 'Sin datos de patrimonio',
      'no_accounts_registered': 'Sin cuentas registradas',
      'filter_all_time': 'Todo',
      'accounts_label': 'Cuentas',
      'invested_label': 'Invertido',
      'estimated_total': 'Total estimado',
      'debts_installments': 'Deudas (cuotas)',
      'internal_transfers': 'Transferencias internas',
      'patrimony_real_estate': '🏠 Patrimonio (Inmuebles)',
      'emergency_fund': '💰 Fondo de emergencia',
      'asset_allocation': 'Asignación de Activos',
      'total_consolidated': 'TOTAL CONSOLIDADO',
      'current_balance': 'SALDO ACTUAL',
      'portfolio': 'Portafolio',
      'ia_suggestion': 'Sugerencia IA',
      'monthly_goal': 'Meta Mensual',
      'missing': 'Faltan',
      'to_reach_goal': 'para alcanzar tu meta de ahorro este mes.',
      // Investments
      'add_investment': 'Agregar Inversión',
      'amount_invested': 'Monto invertido',
      'current_balance_input': 'Saldo actual',
      'current_balance_differs': 'El saldo actual difiere del invertido',
      'investment_added': '¡Inversión agregada!',
      'delete_investment': '¿Eliminar inversión?',
      'no_investments_yet': 'Sin inversiones aún.\nToca + para agregar una.',
      'product_name': 'Nombre del producto',
      'institution': 'Institución / Broker',
      'notes_optional': 'Notas (opcional)',
      'enter_product_name': 'Ingresa el nombre del producto',
      'enter_institution': 'Ingresa la institución',
      'enter_invested_amount': 'Ingresa el monto invertido',
      'enter_valid_balance': 'Ingresa un saldo actual válido',
      // Budget & Goals
      'monthly_budget': 'Presupuesto Mensual',
      'save_budget': 'Guardar Presupuesto',
      'budget_goals': 'Metas de Presupuesto',
      'category_budgets': 'Presupuestos por Categoría',
      'set_spending_limits': 'Establece límites de gasto',
      'set_monthly_spending_limits': 'Establece límites de gasto mensual por categoría',
      'current_spending': 'Actual',
      'budget_amount': 'Monto del presupuesto',
      'cash_budget': 'Presupuesto Cash',
      'swile_budget': 'Presupuesto Swile',
      'period_budget': 'Presupuesto de Período',
      'copy_from_previous': 'Copiar del período anterior',
      'no_budgets_period': 'Sin presupuestos para este período',
      'budgets_hint': 'Agrega metas en Ajustes para ver los valores aquí',
      'reset_to_goal': '¿Restablecer al monto de la meta?',
      'reset_to_goal_desc': 'Esto eliminará el monto personalizado y volverá a tu meta.',
      'remove_budget': '¿Eliminar presupuesto de %s?',
      'edit_budget': 'Editar Presupuesto',
      'new_budget': 'Nuevo Presupuesto',
      'copied_budgets': 'Se copiaron %d presupuesto(s) del período anterior',
      'no_budgets_to_copy': 'No hay presupuestos nuevos para copiar',
      'rebalance_budget': 'Rebalancear Presupuesto',
      'rebalance_subtitle': 'Ajusta los porcentajes para llegar al 100%',
      'normalize': 'Normalizar',
      'preview_changes': 'Vista previa de cambios',
      'budget_rebalanced': 'Presupuesto rebalanceado exitosamente',
      'over_limit': 'Excedido por %s%% — ajusta primero',
      'under_limit': 'Faltan %s%% — ajusta primero',
      // Salary & Settings
      'net_salary': 'Salario Neto',
      'salary': 'Salario',
      'lbl_gross': 'Bruto',
      'lbl_net': 'Neto',
      'per_month': '/ mes',
      'salary_configured': 'Salario Configurado',
      'configure_salary': 'Configurar Salario',
      'salary_calculated': 'Impuestos calculados automáticamente',
      'net_worth_configured': 'Patrimonio Configurado',
      'configure_net_worth': 'Configurar Patrimonio',
      'net_worth_desc': 'Inmuebles, Inversiones, etc.',
      'savings_rate': 'Tasa de Ahorro',
      'monthly_balance': 'Saldo Mensual',
      'available_total': 'Total Disponible',
      'cash_expenses': 'Gastos en Efectivo',
      'tap_configure_budgets': 'Toca para configurar tus presupuestos',
      'score_desc': 'Puntaje de 0 a 10',
      // Swile / Benefits
      'swile': 'Beneficios',
      'swile_remaining': 'Swile Disponible',
      'swile_balance': 'Saldo Swile',
      'of_swile_balance': 'del saldo Swile',
      'swile_category': 'Categoría Swile',
      'swile_category_desc': 'Usada para vales de comida/restaurante',
      // Payment methods
      'pay_debit': 'Débito',
      'pay_pix': 'PIX',
      'pay_credit': 'Crédito',
      'pay_credit_inst': 'Crédito (Cuotas)',
      'pay_swile_meal': 'Swile Saldo Libre',
      'pay_swile_food': 'Vale Alimento',
      // Installments
      'new_installment': 'Nueva Cuota',
      'description_required': 'Descripción *',
      'desc_example': 'ej: Portátil, Celular...',
      'monthly_installment_amount': 'Monto mensual de la cuota',
      'num_installments': 'Número de cuotas',
      'current_installment': 'Cuota actual',
      'purchased_on': 'Comprado el',
      'enter_description': 'Ingresa la descripción',
      'enter_installment_amount': 'Ingresa el monto de la cuota',
      'installment_added': '¡Cuota agregada!',
      // Categories
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
      'category_updated': 'Categoría actualizada',
      'category_added': 'Categoría agregada',
      'category_deleted': 'Categoría eliminada',
      'delete_category': '¿Eliminar categoría?',
      'delete_category_desc': 'No eliminará gastos existentes, pero la categoría dejará de aparecer en tus categorías activas.',
      // Category enums
      'cat_housing': 'Vivienda',
      'cat_transport': 'Transporte',
      'cat_food': 'Alimentación',
      'cat_health': 'Salud',
      'cat_subs': 'Suscripciones',
      'cat_leisure': 'Ocio',
      'cat_edu': 'Educación',
      'cat_card': 'Cuotas de Tarjeta',
      'cat_other': 'Otros',
      // Income enums
      'income_net_salary': 'Salario Neto',
      'income_swile_meal': 'Swile Comida',
      'income_swile_food': 'Swile Alimentación',
      'income_bonus': 'Bono',
      'income_13th': '13° Salario',
      'income_overtime': 'Horas Extra',
      'income_other': 'Otros',
      'chart_diversified': 'Diversificada',
      // Health score
      'health_healthy': 'SALUDABLE',
      'health_warning': 'ADVERTENCIA',
      'health_critical': 'CRÍTICO',
      'health_excellent': '¡Excelente! Tus finanzas están saludables.',
      'health_good': '¡Muy bien! Continúa así.',
      'health_fair': 'Razonable. Hay espacio para mejorar.',
      'health_warning_desc': '¡Atención! Revisa tus gastos.',
      'health_critical_desc': '¡Crítico! Es necesario actuar ahora.',
      // Authentication
      'sign_in': 'Iniciar Sesión',
      'sign_up': 'Registrarse',
      'sign_out': 'Cerrar Sesión',
      'forgot_password': '¿Olvidaste la contraseña?',
      'verify_email': 'Verifica tu correo',
      'resend_email': 'Reenviar correo',
      'set_new_password': 'Establecer Nueva Contraseña',
      'update_password': 'Actualizar Contraseña',
      'update_password_arrow': 'Actualizar contraseña →',
      'or_sign_in_with': 'O inicia sesión con',
      'something_went_wrong': 'Algo salió mal. Reinicia la app.',
      'welcome': 'Bienvenido\n',
      'back': 'de vuelta.',
      'login_subtitle': 'Inicia sesión y continúa iluminando tu camino financiero.',
      'email': 'Correo',
      'password': 'Contraseña',
      'invalid_email': 'Correo inválido',
      'min_6_chars': 'Mínimo 6 caracteres',
      'min_8_chars': 'Mínimo 8 caracteres',
      'dont_have_account': '¿Aún no tienes cuenta? ',
      'already_have_account': '¿Ya tienes una cuenta? ',
      'new_password': 'Nueva contraseña',
      'new_password_title_1': 'Nueva\n',
      'new_password_title_2': 'contraseña.',
      'confirm_new_password': 'Confirmar nueva contraseña',
      'choose_strong_password': 'Elige una contraseña fuerte para proteger tu cuenta.',
      'passwords_dont_match': 'Las contraseñas no coinciden',
      'we_sent_verification': 'Enviamos un enlace de verificación a tu correo. Revísalo para continuar.',
      'very_weak': 'Muy débil',
      'weak': 'Débil',
      'good': 'Buena',
      'strong': 'Fuerte',
      // Onboarding
      'onboarding_title': 'Claridad para cada centavo.',
      'onboarding_subtitle': 'Tu dinero en el rumbo correcto. Planificación financiera que guía cada decisión con claridad.',
      'onboarding_f1': 'Seguridad bancaria y Pix integrado',
      'onboarding_f2': 'IA que entiende tu salario y beneficios',
      'onboarding_f3': 'Soporte en tu idioma, 24/7',
      'onboarding_button': 'Crear mi cuenta Farol',
      'onboarding_login': 'Ya soy cliente · Iniciar sesión',
      // Signup
      'account_created_check_email': '¡Cuenta creada! Revisa tu correo para continuar.',
      'create_your': 'Crea tu\n',
      'farol_account': 'cuenta Farol.',
      'start_illuminating': 'Empieza a iluminar tu camino financiero hoy.',
      'set_planned_income': 'Establece tu ingreso mensual planeado. El dashboard rastreará los montos restantes a medida que agregues movimientos.',
      'create_account_arrow': 'Crear cuenta →',
      'cpf_optional': 'CPF (opcional)',
      'cpf_invalid': 'CPF inválido',
      'terms_accept': 'Acepto los ',
      'terms_link': 'términos de uso',
      'terms_required': 'Debes aceptar los términos para continuar',
      'avatar_optional': 'URL de Avatar (opcional)',
      // Profile & Settings
      'profile': 'Perfil',
      'edit_profile': 'Editar Perfil',
      'appearance': 'Apariencia',
      'customize_interface': 'Personaliza tu interfaz para máximo confort visual.',
      'concierge_support': 'Soporte Concierge',
      'corporate_benefits': 'Beneficios Corporativos',
      'language': 'Idioma',
      'spanish': 'Español',
      'portuguese': 'Portugués',
      'english': 'Inglés',
      'theme': 'Tema',
      'dark_mode': 'Modo Oscuro',
      'light_mode': 'Modo Claro',
      'system_mode': 'Sistema',
      'data_privacy': 'Datos y Privacidad',
      'export_transactions': 'Exportar movimientos',
      'income_statement': 'Estado de Resultados',
      'full_backup': 'Respaldo Completo',
      'monthly_report_pdf': 'Resumen Mensual PDF',
      'financial_period': 'Período financiero',
      'period_start': 'Inicio del período',
      'day_of_each_month': 'Día de cada mes',
      'select_period_start': 'Selecciona el día en que comienza tu período (1–28):',
      'chat_24_7': 'Chat 24/7',
      'vip_call': 'Llamada VIP',
      'hide_values': 'Ocultar valores',
      'hide_values_desc': 'Enmascara montos en toda la app',
      // Simulators
      'simulators': 'Simuladores',
      'simulator_13th': 'Simulador 13° Salario',
      'simulator_13th_desc': 'Calcula cuotas, INSS e IRRF',
      'simulator_fgts': 'Retiro Aniversario FGTS',
      'simulator_fgts_desc': 'Simula el retiro anual y proyección 3 años',
      'simulator_rescission': 'Rescisión CLT',
      'simulator_rescission_desc': 'Calcula tus derechos al salir del empleo (Aviso, 13º, Vacaciones)',
      'rescission_title': 'Simulador de Rescisión',
      'rescission_input_title': 'DATOS DEL CONTRATO',
      'rescission_gross_salary': 'Salario Bruto Mensual',
      'rescission_fgts_balance': 'Saldo FGTS para Multa',
      'rescission_start_date': 'Fecha de Inicio',
      'rescission_end_date': 'Fecha de Salida',
      'rescission_unjustified': 'Despido sin causa',
      'rescission_notice_period': 'Aviso previo trabajado',
      'rescission_unused_vacation': 'Días de vacaciones vencidos',
      'rescission_calculate': 'Calcular Rescisión',
      'rescission_total_receive_gross': 'TOTAL BRUTO A RECIBIR',
      'rescission_disclaimer': '*Valores brutos. Pueden aplicarse deducciones de INSS e IRRF sobre el saldo de salario y 13º.',
      'rescission_breakdown_title': 'DETALLES',
      'rescission_salary_balance': 'Saldo de Salario',
      'rescission_proportional_13th': '13º Proporcional',
      'rescission_proportional_vacation': 'Vacaciones Proporcionales',
      'rescission_unused_vacation_pay': 'Vacaciones Vencidas',
      'rescission_vacation_third': '1/3 de Vacaciones',
      'rescission_notice_period_indemnified': 'Aviso Previo Indemnizado',
      'rescission_fgts_fine': 'Multa FGTS (40%)',
      // Toast / feedback
      'net_worth_saved': '¡Patrimonio guardado!',
      'budget_saved': '¡Presupuesto guardado!',
      'budget_goals_saved': '¡Metas de presupuesto guardadas!',
      'expense_saved': '¡Gasto guardado!',
      'invalid_amount': 'Ingresa un monto válido',
      'email_required': 'Primero ingresa tu correo',
      'recovery_email_sent': 'Correo de recuperación enviado',
      'verification_email_resent': 'Correo de verificación reenviado',
      'error_saving': 'Error al guardar',
      'settings_saved': 'Configuración guardada exitosamente',
      'export_success': 'Archivo exportado con éxito',
      'salary_saved': 'Configuración de salario guardada',
      'enter_gross_salary': 'Ingrese el salario bruto',
      'could_not_load_budget': 'No se pudo cargar el presupuesto',
      'could_not_load_net_worth': 'No se pudo cargar el patrimonio',
      'could_not_load_salary': 'No se pudo cargar la configuración de salario',
      'welcome_back': '¡Bienvenido de vuelta!',
      'error_loading': 'Error al cargar',
      'save_changes': 'Guardar cambios',
      // Budget overflow
      'budget_overflow_warning': 'Tus asignaciones de presupuesto superan el 100%. Toca una categoría para ajustar.',
      'rebalance': 'Rebalancear',
      'allocated_over_limit': '%s%% asignado — límite excedido',
      // Accounts & Patrimony
      'bank_accounts': 'Cuentas Bancarias',
      'manage_accounts_desc': 'Gestiona tus cuentas y transferencias',
      'patrimony': 'Patrimonio',
      'patrimony_desc': 'Vista consolidada de tu patrimonio',
      // Salary sheet
      'salary_clt_title': 'Salario CLT 2026',
      'gross_monthly_salary': 'Salario bruto mensual',
      'dependents': 'Dependientes',
      'dependents_deduction': 'Deducción: %s / mes',
      'simplified_deduction': 'Descuento simplificado',
      'simplified_deduction_desc': 'R\$ 607,20 deducidos de la base del IRRF',
      'other_deductions': 'Otras deducciones (plan de salud, etc.)',
      'net_salary_label': 'SALARIO NETO',
      'effective_rate_suffix': '%% alícuota efectiva',
      'monthly_reduction_applied': 'Reducción mensual aplicada: −%s',
      'fgts_employer_note': '* FGTS es un cargo del empleador, no descontado del salario.',
    },
    'pt': {
      // Core
      'app_name': 'Farol',
      'dashboard': 'Início',
      'transactions': 'Transações',
      'analytics': 'Análises',
      'investments': 'Investir',
      'settings': 'Configurações',
      'income': 'Receitas',
      'expenses': 'Despesas',
      'net_worth': 'Patrimônio',
      'net_worth_title': 'Patrimônio Líquido',
      'health_score': 'Saúde Financeira',
      'save': 'Salvar',
      'cancel': 'Cancelar',
      'edit': 'Editar',
      'delete': 'Excluir',
      'remove': 'Remover',
      'reset': 'Redefinir',
      'retry': 'Tentar Novamente',
      'total': 'Total',
      'remaining': 'Restam',
      'remaining_balance': 'Saldo restante',
      'of': 'de',
      'goal': 'Meta',
      'spent': 'Gasto',
      'left': 'Restam',
      'over': 'Excedido',
      'type': 'Tipo',
      'name': 'Nome',
      'name_required': 'O nome é obrigatório',
      'full_name': 'Nome completo',
      'full_name_required': 'O nome completo é obrigatório',
      'description': 'Descrição',
      'subcategory': 'Subcategoria',
      'optional': 'opcional',
      'required': 'Obrigatório',
      'error': 'Erro',
      'months': ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'],
      // Expenses & Transactions
      'add_expense': 'Adicionar Despesa',
      'edit_expense': 'Editar Despesa',
      'confirm_delete': 'Excluir esta despesa?',
      'cannot_undo': 'Esta ação não pode ser desfeita.',
      'transaction_deleted': 'Despesa excluída',
      'transaction_updated': 'Despesa atualizada!',
      'category': 'Categoria',
      'amount': 'Valor',
      'date': 'Data',
      'payment_method': 'Forma de Pagamento',
      'fixed_cost': 'Custo Fixo',
      'installments': 'Parcelas',
      'recent_transactions': 'Transações Recentes',
      'monthly_spending': 'Gastos Mensais',
      'last_7_days': 'Últimos 7 dias',
      'see_all': 'Ver Tudo',
      'expense_by_cat': 'Gastos por Categoria',
      'no_expenses': 'Sem gastos registrados',
      'no_expenses_hint': 'Adicione um gasto para ver o detalhamento dos seus movimentos.',
      // Income
      'edit_income': 'Editar Receita',
      'income_updated': 'Receita atualizada!',
      'net_value_hint': 'Valor líquido (INSS/IRRF já descontado)',
      'dependents_irrf': 'Dependentes (IRRF)',
      'calculate_net': 'Calcular líquido',
      'salary_breakdown': 'Detalhamento do salário',
      'use_net_value': 'Usar valor líquido',
      // Net Worth Screen
      'evolution': 'Evolução',
      'period_flow': 'Fluxo do Período',
      'no_history_data': 'Sem dados históricos ainda.\nOs snapshots são salvos automaticamente.',
      'no_net_worth': 'Sem dados de patrimônio',
      'no_accounts_registered': 'Nenhuma conta cadastrada',
      'filter_all_time': 'Tudo',
      'accounts_label': 'Contas',
      'invested_label': 'Investido',
      'estimated_total': 'Total estimado',
      'debts_installments': 'Dívidas (parcelas)',
      'internal_transfers': 'Transferências internas',
      'patrimony_real_estate': '🏠 Patrimônio (Imóveis)',
      'emergency_fund': '💰 Fundo de Emergência',
      'asset_allocation': 'Alocação de Ativos',
      'total_consolidated': 'TOTAL CONSOLIDADO',
      'current_balance': 'SALDO ATUAL',
      'portfolio': 'Portfólio',
      'ia_suggestion': 'Sugestão IA',
      'monthly_goal': 'Meta Mensal',
      'missing': 'Faltam',
      'to_reach_goal': 'para atingir sua meta de economia este mês.',
      // Investments
      'add_investment': 'Adicionar Investimento',
      'amount_invested': 'Valor investido',
      'current_balance_input': 'Saldo atual',
      'current_balance_differs': 'Saldo atual diferente do investido',
      'investment_added': 'Investimento adicionado!',
      'delete_investment': 'Excluir investimento?',
      'no_investments_yet': 'Nenhum investimento ainda.\nToque + para adicionar um.',
      'product_name': 'Nome do produto',
      'institution': 'Instituição / Corretora',
      'notes_optional': 'Notas (opcional)',
      'enter_product_name': 'Informe o nome do produto',
      'enter_institution': 'Informe a instituição',
      'enter_invested_amount': 'Informe o valor investido',
      'enter_valid_balance': 'Informe um saldo atual válido',
      // Budget & Goals
      'monthly_budget': 'Orçamento Mensal',
      'save_budget': 'Salvar Orçamento',
      'budget_goals': 'Metas de Orçamento',
      'category_budgets': 'Orçamentos por Categoria',
      'set_spending_limits': 'Defina limites de gastos',
      'set_monthly_spending_limits': 'Defina limites de gastos mensais por categoria',
      'current_spending': 'Atual',
      'budget_amount': 'Valor do orçamento',
      'cash_budget': 'Orçamento Caixa',
      'swile_budget': 'Orçamento Swile',
      'period_budget': 'Orçamento do Período',
      'copy_from_previous': 'Copiar do período anterior',
      'no_budgets_period': 'Sem orçamentos para este período',
      'budgets_hint': 'Adicione metas em Configurações para ver os valores aqui',
      'reset_to_goal': 'Redefinir para o valor da meta?',
      'reset_to_goal_desc': 'Isso removerá o valor personalizado e voltará à sua meta.',
      'remove_budget': 'Remover orçamento de %s?',
      'edit_budget': 'Editar Orçamento',
      'new_budget': 'Novo Orçamento',
      'copied_budgets': '%d orçamento(s) copiado(s) do período anterior',
      'no_budgets_to_copy': 'Nenhum orçamento novo para copiar',
      'rebalance_budget': 'Rebalancear Orçamento',
      'rebalance_subtitle': 'Ajuste os percentuais para chegar a 100%',
      'normalize': 'Normalizar',
      'preview_changes': 'Pré-visualizar alterações',
      'budget_rebalanced': 'Orçamento rebalanceado com sucesso',
      'over_limit': 'Excedido em %s%% — ajuste primeiro',
      'under_limit': 'Faltam %s%% — ajuste primeiro',
      // Salary & Settings
      'net_salary': 'Salário Líquido',
      'salary': 'Salário',
      'lbl_gross': 'Bruto',
      'lbl_net': 'Líquido',
      'per_month': '/ mês',
      'salary_configured': 'Salário Configurado',
      'configure_salary': 'Configurar Salário',
      'salary_calculated': 'Impostos calculados automaticamente',
      'net_worth_configured': 'Patrimônio Configurado',
      'configure_net_worth': 'Configurar Patrimônio',
      'net_worth_desc': 'Imóveis, Investimentos, FGTS...',
      'savings_rate': 'Taxa de Poupança',
      'monthly_balance': 'Saldo Mensal',
      'available_total': 'Total Disponível',
      'cash_expenses': 'Despesas em Dinheiro',
      'tap_configure_budgets': 'Toque para configurar seus orçamentos',
      'score_desc': 'Pontuação de 0 a 10',
      // Swile / Benefits
      'swile': 'Benefícios',
      'swile_remaining': 'Swile Disponível',
      'swile_balance': 'Saldo Swile',
      'of_swile_balance': 'do saldo Swile',
      'swile_category': 'Categoria Swile',
      'swile_category_desc': 'Usada para vale-refeição/alimentação',
      // Payment methods
      'pay_debit': 'Débito',
      'pay_pix': 'PIX',
      'pay_credit': 'Crédito à Vista',
      'pay_credit_inst': 'Crédito Parcelado',
      'pay_swile_meal': 'Swile Saldo Livre',
      'pay_swile_food': 'Swile Alimentação',
      // Installments
      'new_installment': 'Nova Parcela',
      'description_required': 'Descrição *',
      'desc_example': 'ex: Notebook, Celular…',
      'monthly_installment_amount': 'Valor da parcela mensal',
      'num_installments': 'Número de parcelas',
      'current_installment': 'Parcela atual',
      'purchased_on': 'Compra em',
      'enter_description': 'Informe a descrição',
      'enter_installment_amount': 'Informe o valor da parcela',
      'installment_added': 'Parcela adicionada!',
      // Categories
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
      'category_updated': 'Categoria atualizada',
      'category_added': 'Categoria adicionada',
      'category_deleted': 'Categoria excluída',
      'delete_category': 'Excluir categoria?',
      'delete_category_desc': 'Os gastos existentes não serão excluídos, mas a categoria deixará de aparecer nas categorias ativas.',
      // Category enums
      'cat_housing': 'Moradia',
      'cat_transport': 'Transporte',
      'cat_food': 'Alimentação',
      'cat_health': 'Saúde',
      'cat_subs': 'Assinaturas',
      'cat_leisure': 'Lazer',
      'cat_edu': 'Educação',
      'cat_card': 'Parcelas Cartão',
      'cat_other': 'Outros',
      // Income enums
      'income_net_salary': 'Salário Líquido',
      'income_swile_meal': 'Swile Refeição',
      'income_swile_food': 'Swile Alimentação',
      'income_bonus': 'Bônus',
      'income_13th': '13° Salário',
      'income_overtime': 'Hora Extra',
      'income_other': 'Outros',
      'chart_diversified': 'Diversificada',
      // Health score
      'health_healthy': 'SAUDÁVEL',
      'health_warning': 'ATENÇÃO',
      'health_critical': 'CRÍTICO',
      'health_excellent': 'Excelente! Suas finanças estão saudáveis.',
      'health_good': 'Muito bom! Continue assim.',
      'health_fair': 'Razoável. Há espaço para melhorar.',
      'health_warning_desc': 'Atenção! Revise seus gastos.',
      'health_critical_desc': 'Crítico! É preciso agir agora.',
      // Authentication
      'sign_in': 'Fazer Login',
      'sign_up': 'Criar Conta',
      'sign_out': 'Sair',
      'forgot_password': 'Esqueceu a senha?',
      'verify_email': 'Verifique seu e-mail',
      'resend_email': 'Reenviar e-mail',
      'set_new_password': 'Definir Nova Senha',
      'update_password': 'Atualizar Senha',
      'update_password_arrow': 'Atualizar senha →',
      'or_sign_in_with': 'Ou faça login com',
      'something_went_wrong': 'Algo deu errado. Reinicie o app.',
      'welcome': 'Bem-vindo\n',
      'back': 'de volta.',
      'login_subtitle': 'Entre e continue iluminando seu caminho financeiro.',
      'email': 'E-mail',
      'password': 'Senha',
      'invalid_email': 'E-mail inválido',
      'min_6_chars': 'Mínimo 6 caracteres',
      'min_8_chars': 'Mínimo 8 caracteres',
      'dont_have_account': 'Ainda não tem conta? ',
      'already_have_account': 'Já tem uma conta? ',
      'new_password': 'Nova senha',
      'new_password_title_1': 'Nova\n',
      'new_password_title_2': 'senha.',
      'confirm_new_password': 'Confirmar nova senha',
      'choose_strong_password': 'Escolha uma senha forte para proteger sua conta.',
      'passwords_dont_match': 'As senhas não coincidem',
      'we_sent_verification': 'Enviamos um link de verificação para o seu e-mail. Verifique-o para continuar.',
      'very_weak': 'Muito fraca',
      'weak': 'Fraca',
      'good': 'Boa',
      'strong': 'Forte',
      // Onboarding
      'onboarding_title': 'Clareza para cada real.',
      'onboarding_subtitle': 'Seu dinheiro no rumo certo. Planejamento financeiro que guia cada decisão com clareza.',
      'onboarding_f1': 'Segurança bancária e Pix integrado',
      'onboarding_f2': 'IA que entende seu salário CLT e FGTS',
      'onboarding_f3': 'Suporte em português, 24/7',
      'onboarding_button': 'Criar minha conta Farol',
      'onboarding_login': 'Já sou cliente · Entrar',
      // Signup
      'account_created_check_email': 'Conta criada! Verifique seu e-mail para continuar.',
      'create_your': 'Criar sua\n',
      'farol_account': 'conta Farol.',
      'start_illuminating': 'Comece a iluminar seu caminho financeiro hoje.',
      'set_planned_income': 'Defina sua renda mensal planejada. O dashboard rastreará os valores restantes à medida que você adiciona transações.',
      'create_account_arrow': 'Criar conta →',
      'cpf_optional': 'CPF (opcional)',
      'cpf_invalid': 'CPF inválido',
      'terms_accept': 'Aceito os ',
      'terms_link': 'termos de uso',
      'terms_required': 'Você deve aceitar os termos para continuar',
      'avatar_optional': 'URL do Avatar (opcional)',
      // Profile & Settings
      'profile': 'Perfil',
      'edit_profile': 'Editar Perfil',
      'appearance': 'Aparência',
      'customize_interface': 'Personalize sua interface para o máximo conforto visual.',
      'concierge_support': 'Suporte Concierge',
      'corporate_benefits': 'Benefícios Corporativos',
      'language': 'Idioma',
      'spanish': 'Espanhol',
      'portuguese': 'Português',
      'english': 'Inglês',
      'theme': 'Tema',
      'dark_mode': 'Modo Escuro',
      'light_mode': 'Modo Claro',
      'system_mode': 'Sistema',
      'data_privacy': 'Dados e Privacidade',
      'export_transactions': 'Exportar Transações',
      'income_statement': 'Demonstrativo de Resultados',
      'full_backup': 'Backup Completo',
      'monthly_report_pdf': 'Relatório Mensal PDF',
      'financial_period': 'Período financeiro',
      'period_start': 'Início do período',
      'day_of_each_month': 'Dia de cada mês',
      'select_period_start': 'Selecione o dia que inicia seu período (1-28):',
      'chat_24_7': 'Chat 24/7',
      'vip_call': 'Chamada VIP',
      'hide_values': 'Ocultar valores',
      'hide_values_desc': 'Oculta os valores em todo o app',
      // Simulators
      'simulators': 'Simuladores',
      'simulator_13th': 'Simulador 13º Salário',
      'simulator_13th_desc': 'Calcule parcelas, INSS e IRRF',
      'simulator_fgts': 'Saque Aniversário FGTS',
      'simulator_fgts_desc': 'Simule o saque anual e projeção 3 anos',
      'simulator_rescission': 'Rescisão CLT',
      'simulator_rescission_desc': 'Calcule seus direitos ao sair do emprego (Aviso, 13º, Férias)',
      'rescission_title': 'Simulador de Rescisão',
      'rescission_input_title': 'DADOS DO CONTRATO',
      'rescission_gross_salary': 'Salário Bruto Mensal',
      'rescission_fgts_balance': 'Saldo FGTS para Multa',
      'rescission_start_date': 'Data de Início',
      'rescission_end_date': 'Data de Saída',
      'rescission_unjustified': 'Demissão sem justa causa',
      'rescission_notice_period': 'Aviso Prévio',
      'rescission_unused_vacation': 'Férias Vencidas',
      'rescission_calculate': 'Calcular Rescisão',
      'rescission_total_receive_gross': 'TOTAL BRUTO A RECEBER',
      'rescission_disclaimer': '*Valores brutos. Podem incidir descontos de INSS e IRRF sobre o saldo de salário e 13º.',
      'rescission_breakdown_title': 'DETALHAMENTO',
      'rescission_salary_balance': 'Saldo de Salário',
      'rescission_proportional_13th': '13º Proporcional',
      'rescission_proportional_vacation': 'Férias Proporcionais',
      'rescission_unused_vacation_pay': 'Férias Vencidas',
      'rescission_vacation_third': '1/3 de Férias',
      'rescission_notice_period_indemnified': 'Aviso Prévio Indenizado',
      'rescission_fgts_fine': 'Multa FGTS (40%)',
      // Toast / feedback
      'net_worth_saved': 'Patrimônio salvo!',
      'budget_saved': 'Orçamento salvo!',
      'budget_goals_saved': 'Metas de orçamento salvas!',
      'expense_saved': 'Despesa salva!',
      'invalid_amount': 'Insira um valor válido',
      'email_required': 'Primeiro insira seu e-mail',
      'recovery_email_sent': 'E-mail de recuperação enviado',
      'verification_email_resent': 'E-mail de verificação reenviado',
      'error_saving': 'Erro ao salvar',
      'settings_saved': 'Configurações salvas com sucesso',
      'export_success': 'Arquivo exportado com sucesso',
      'salary_saved': 'Configuração de salário salva',
      'enter_gross_salary': 'Informe o salário bruto',
      'could_not_load_budget': 'Não foi possível carregar o orçamento',
      'could_not_load_net_worth': 'Não foi possível carregar o patrimônio',
      'could_not_load_salary': 'Não foi possível carregar as configurações de salário',
      'welcome_back': 'Bem-vindo de volta!',
      'error_loading': 'Erro ao carregar',
      'save_changes': 'Salvar alterações',
      // Budget overflow
      'budget_overflow_warning': 'Suas alocações de orçamento excedem 100%. Toque em uma categoria para ajustar.',
      'rebalance': 'Rebalancear',
      'allocated_over_limit': '%s%% alocado — limite excedido',
      // Accounts & Patrimony
      'bank_accounts': 'Contas Bancárias',
      'manage_accounts_desc': 'Gerencie suas contas e transferências',
      'patrimony': 'Patrimônio',
      'patrimony_desc': 'Visão consolidada do seu patrimônio',
      // Salary sheet
      'salary_clt_title': 'Salário CLT 2026',
      'gross_monthly_salary': 'Salário bruto mensal',
      'dependents': 'Dependentes',
      'dependents_deduction': 'Dedução: %s / mês',
      'simplified_deduction': 'Desconto simplificado',
      'simplified_deduction_desc': 'R\$ 607,20 deduzidos da base do IRRF',
      'other_deductions': 'Outras deduções (plano de saúde, etc.)',
      'net_salary_label': 'SALÁRIO LÍQUIDO',
      'effective_rate_suffix': '%% alíquota efetiva',
      'monthly_reduction_applied': 'Redução mensal aplicada: −%s',
      'fgts_employer_note': '* FGTS é encargo do empregador, não descontado do salário.',
    },
  };

  // ── Lookup ────────────────────────────────────────────────────────────────

  String translate(String key) {
    final langMap = _t[locale.languageCode];
    final value = langMap?[key] ?? _t['en']?[key];
    assert(value != null, '[l10n] Missing key "$key" in all locales');
    if (value is String) return value;
    return key;
  }

  static String translateStatic(String languageCode, String key) {
    final value = _t[languageCode]?[key] ?? _t['en']?[key];
    if (value is String) return value;
    return key;
  }

  static List<String> monthsForLocale(String languageCode) =>
      (_t[languageCode]?['months'] ?? _t['en']!['months']) as List<String>;

  List<String> get months => monthsForLocale(locale.languageCode);

  // ── Getters ───────────────────────────────────────────────────────────────
  // Core
  String get appName => translate('app_name');
  String get dashboard => translate('dashboard');
  String get transactions => translate('transactions');
  String get analytics => translate('analytics');
  String get investments => translate('investments');
  String get settings => translate('settings');
  String get income => translate('income');
  String get expenses => translate('expenses');
  String get netWorth => translate('net_worth');
  String get netWorthTitle => translate('net_worth_title');
  String get healthScore => translate('health_score');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get edit => translate('edit');
  String get delete => translate('delete');
  String get remove => translate('remove');
  String get reset => translate('reset');
  String get retry => translate('retry');
  String get total => translate('total');
  String get remaining => translate('remaining');
  String get remainingBalance => translate('remaining_balance');
  String get ofWord => translate('of');
  String get goal => translate('goal');
  String get spent => translate('spent');
  String get left => translate('left');
  String get over => translate('over');
  String get type => translate('type');
  String get name => translate('name');
  String get nameRequired => translate('name_required');
  String get fullName => translate('full_name');
  String get fullNameRequired => translate('full_name_required');
  String get description => translate('description');
  String get subcategory => translate('subcategory');
  String get optional => translate('optional');
  String get required => translate('required');
  String get error => translate('error');
  // Expenses & Transactions
  String get addExpense => translate('add_expense');
  String get editExpense => translate('edit_expense');
  String get confirmDelete => translate('confirm_delete');
  String get cannotUndo => translate('cannot_undo');
  String get transactionDeleted => translate('transaction_deleted');
  String get transactionUpdated => translate('transaction_updated');
  String get category => translate('category');
  String get amount => translate('amount');
  String get date => translate('date');
  String get paymentMethod => translate('payment_method');
  String get fixedCost => translate('fixed_cost');
  String get installments => translate('installments');
  String get recentTransactions => translate('recent_transactions');
  String get monthlySpending => translate('monthly_spending');
  String get last7Days => translate('last_7_days');
  String get seeAll => translate('see_all');
  String get expenseByCat => translate('expense_by_cat');
  String get noExpenses => translate('no_expenses');
  String get noExpensesHint => translate('no_expenses_hint');
  // Income
  String get editIncome => translate('edit_income');
  String get incomeUpdated => translate('income_updated');
  String get netValueHint => translate('net_value_hint');
  String get dependentsIrrf => translate('dependents_irrf');
  String get calculateNet => translate('calculate_net');
  String get salaryBreakdown => translate('salary_breakdown');
  String get useNetValue => translate('use_net_value');
  // Net Worth Screen
  String get evolution => translate('evolution');
  String get periodFlow => translate('period_flow');
  String get noHistoryData => translate('no_history_data');
  String get noNetWorth => translate('no_net_worth');
  String get noAccountsRegistered => translate('no_accounts_registered');
  String get filterAllTime => translate('filter_all_time');
  String get accountsLabel => translate('accounts_label');
  String get investedLabel => translate('invested_label');
  String get estimatedTotal => translate('estimated_total');
  String get debtsInstallments => translate('debts_installments');
  String get internalTransfers => translate('internal_transfers');
  String get patrimonyRealEstate => translate('patrimony_real_estate');
  String get emergencyFund => translate('emergency_fund');
  String get assetAllocation => translate('asset_allocation');
  String get totalConsolidated => translate('total_consolidated');
  String get currentBalance => translate('current_balance');
  String get portfolio => translate('portfolio');
  String get iaSuggestion => translate('ia_suggestion');
  String get monthlyGoal => translate('monthly_goal');
  String get missing => translate('missing');
  String get toReachGoal => translate('to_reach_goal');
  // Investments
  String get addInvestment => translate('add_investment');
  String get amountInvested => translate('amount_invested');
  String get currentBalanceInput => translate('current_balance_input');
  String get currentBalanceDiffers => translate('current_balance_differs');
  String get investmentAdded => translate('investment_added');
  String get deleteInvestment => translate('delete_investment');
  String get noInvestmentsYet => translate('no_investments_yet');
  String get productName => translate('product_name');
  String get institution => translate('institution');
  String get notesOptional => translate('notes_optional');
  String get enterProductName => translate('enter_product_name');
  String get enterInstitution => translate('enter_institution');
  String get enterInvestedAmount => translate('enter_invested_amount');
  String get enterValidBalance => translate('enter_valid_balance');
  // Budget & Goals
  String get monthlyBudget => translate('monthly_budget');
  String get saveBudget => translate('save_budget');
  String get budgetGoals => translate('budget_goals');
  String get categoryBudgets => translate('category_budgets');
  String get setSpendingLimits => translate('set_spending_limits');
  String get setMonthlySpendingLimits => translate('set_monthly_spending_limits');
  String get currentSpending => translate('current_spending');
  String get budgetAmount => translate('budget_amount');
  String get cashBudget => translate('cash_budget');
  String get swileBudget => translate('swile_budget');
  String get periodBudget => translate('period_budget');
  String get copyFromPrevious => translate('copy_from_previous');
  String get noBudgetsPeriod => translate('no_budgets_period');
  String get budgetsHint => translate('budgets_hint');
  String get resetToGoal => translate('reset_to_goal');
  String get resetToGoalDesc => translate('reset_to_goal_desc');
  String get editBudget => translate('edit_budget');
  String get newBudget => translate('new_budget');
  String get noBudgetsToCopy => translate('no_budgets_to_copy');
  String get rebalanceBudget => translate('rebalance_budget');
  String get rebalanceSubtitle => translate('rebalance_subtitle');
  String get normalize => translate('normalize');
  String get previewChanges => translate('preview_changes');
  String get budgetRebalanced => translate('budget_rebalanced');
  // Salary & Settings
  String get netSalary => translate('net_salary');
  String get salary => translate('salary');
  String get lblGross => translate('lbl_gross');
  String get lblNet => translate('lbl_net');
  String get perMonth => translate('per_month');
  String get salaryConfigured => translate('salary_configured');
  String get configureSalary => translate('configure_salary');
  String get salaryCalculated => translate('salary_calculated');
  String get netWorthConfigured => translate('net_worth_configured');
  String get configureNetWorth => translate('configure_net_worth');
  String get netWorthDesc => translate('net_worth_desc');
  String get savingsRate => translate('savings_rate');
  String get monthlyBalance => translate('monthly_balance');
  String get availableTotal => translate('available_total');
  String get cashExpenses => translate('cash_expenses');
  String get tapConfigureBudgets => translate('tap_configure_budgets');
  String get scoreDesc => translate('score_desc');
  // Swile / Benefits
  String get swile => translate('swile');
  String get swileRemaining => translate('swile_remaining');
  String get swileBalance => translate('swile_balance');
  String get ofSwileBalance => translate('of_swile_balance');
  String get swileCategory => translate('swile_category');
  String get swileCategoryDesc => translate('swile_category_desc');
  // Payment methods
  String get payDebit => translate('pay_debit');
  String get payPix => translate('pay_pix');
  String get payCredit => translate('pay_credit');
  String get payCreditInst => translate('pay_credit_inst');
  String get paySwileMeal => translate('pay_swile_meal');
  String get paySwileFood => translate('pay_swile_food');
  // Installments
  String get newInstallment => translate('new_installment');
  String get descriptionRequired => translate('description_required');
  String get descExample => translate('desc_example');
  String get monthlyInstallmentAmount => translate('monthly_installment_amount');
  String get numInstallments => translate('num_installments');
  String get currentInstallment => translate('current_installment');
  String get purchasedOn => translate('purchased_on');
  String get enterDescription => translate('enter_description');
  String get enterInstallmentAmount => translate('enter_installment_amount');
  String get installmentAdded => translate('installment_added');
  // Categories
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
  String get categoryUpdated => translate('category_updated');
  String get categoryAdded => translate('category_added');
  String get categoryDeleted => translate('category_deleted');
  String get deleteCategory => translate('delete_category');
  String get deleteCategoryDesc => translate('delete_category_desc');
  String get chartDiversified => translate('chart_diversified');
  // Health score
  String get healthHealthy => translate('health_healthy');
  String get healthWarning => translate('health_warning');
  String get healthCritical => translate('health_critical');
  String get healthExcellentDesc => translate('health_excellent');
  String get healthGoodDesc => translate('health_good');
  String get healthFairDesc => translate('health_fair');
  String get healthWarningDesc => translate('health_warning_desc');
  String get healthCriticalDesc => translate('health_critical_desc');
  // Authentication
  String get signIn => translate('sign_in');
  String get signUp => translate('sign_up');
  String get signOut => translate('sign_out');
  String get forgotPassword => translate('forgot_password');
  String get verifyEmail => translate('verify_email');
  String get resendEmail => translate('resend_email');
  String get setNewPassword => translate('set_new_password');
  String get updatePassword => translate('update_password');
  String get updatePasswordArrow => translate('update_password_arrow');
  String get orSignInWith => translate('or_sign_in_with');
  String get somethingWentWrong => translate('something_went_wrong');
  String get welcome => translate('welcome');
  String get back => translate('back');
  String get loginSubtitle => translate('login_subtitle');
  String get email => translate('email');
  String get password => translate('password');
  String get invalidEmail => translate('invalid_email');
  String get min6Chars => translate('min_6_chars');
  String get min8Chars => translate('min_8_chars');
  String get dontHaveAccount => translate('dont_have_account');
  String get alreadyHaveAccount => translate('already_have_account');
  String get newPassword => translate('new_password');
  String get newPasswordTitle1 => translate('new_password_title_1');
  String get newPasswordTitle2 => translate('new_password_title_2');
  String get confirmNewPassword => translate('confirm_new_password');
  String get chooseStrongPassword => translate('choose_strong_password');
  String get passwordsDontMatch => translate('passwords_dont_match');
  String get weSentVerification => translate('we_sent_verification');
  String get veryWeak => translate('very_weak');
  String get weak => translate('weak');
  String get good => translate('good');
  String get strong => translate('strong');
  // Onboarding
  String get onboardingTitle => translate('onboarding_title');
  String get onboardingSubtitle => translate('onboarding_subtitle');
  String get onboardingF1 => translate('onboarding_f1');
  String get onboardingF2 => translate('onboarding_f2');
  String get onboardingF3 => translate('onboarding_f3');
  String get onboardingButton => translate('onboarding_button');
  String get onboardingLogin => translate('onboarding_login');
  // Signup
  String get accountCreatedCheckEmail => translate('account_created_check_email');
  String get createYour => translate('create_your');
  String get farolAccount => translate('farol_account');
  String get startIlluminating => translate('start_illuminating');
  String get setPlannedIncome => translate('set_planned_income');
  String get createAccountArrow => translate('create_account_arrow');
  String get cpfOptional => translate('cpf_optional');
  String get cpfInvalid => translate('cpf_invalid');
  String get termsAccept => translate('terms_accept');
  String get termsLink => translate('terms_link');
  String get termsRequired => translate('terms_required');
  String get avatarOptional => translate('avatar_optional');
  // Profile & Settings
  String get profile => translate('profile');
  String get editProfile => translate('edit_profile');
  String get appearance => translate('appearance');
  String get customizeInterface => translate('customize_interface');
  String get conciergeSupport => translate('concierge_support');
  String get corporateBenefits => translate('corporate_benefits');
  String get language => translate('language');
  String get spanish => translate('spanish');
  String get portuguese => translate('portuguese');
  String get english => translate('english');
  String get theme => translate('theme');
  String get darkMode => translate('dark_mode');
  String get lightMode => translate('light_mode');
  String get systemMode => translate('system_mode');
  String get dataPrivacy => translate('data_privacy');
  String get exportTransactions => translate('export_transactions');
  String get incomeStatement => translate('income_statement');
  String get fullBackup => translate('full_backup');
  String get monthlyReportPdf => translate('monthly_report_pdf');
  String get financialPeriod => translate('financial_period');
  String get periodStart => translate('period_start');
  String get dayOfEachMonth => translate('day_of_each_month');
  String get selectPeriodStart => translate('select_period_start');
  String get chat247 => translate('chat_24_7');
  String get vipCall => translate('vip_call');
  String get hideValues => translate('hide_values');
  String get hideValuesDesc => translate('hide_values_desc');
  // Simulators
  String get simulators => translate('simulators');
  String get simulator13th => translate('simulator_13th');
  String get simulator13thDesc => translate('simulator_13th_desc');
  String get simulatorFgts => translate('simulator_fgts');
  String get simulatorFgtsDesc => translate('simulator_fgts_desc');
  String get simulatorRescission => translate('simulator_rescission');
  String get simulatorRescissionDesc => translate('simulator_rescission_desc');
  String get rescissionTitle => translate('rescission_title');
  String get rescissionInputTitle => translate('rescission_input_title');
  String get rescissionGrossSalary => translate('rescission_gross_salary');
  String get rescissionFgtsBalance => translate('rescission_fgts_balance');
  String get rescissionStartDate => translate('rescission_start_date');
  String get rescissionEndDate => translate('rescission_end_date');
  String get rescissionUnjustified => translate('rescission_unjustified');
  String get rescissionNoticePeriod => translate('rescission_notice_period');
  String get rescissionUnusedVacation => translate('rescission_unused_vacation');
  String get rescissionCalculate => translate('rescission_calculate');
  String get rescissionTotalReceiveGross => translate('rescission_total_receive_gross');
  String get rescissionDisclaimer => translate('rescission_disclaimer');
  String get rescissionBreakdownTitle => translate('rescission_breakdown_title');
  String get rescissionSalaryBalance => translate('rescission_salary_balance');
  String get rescissionProportional13th => translate('rescission_proportional_13th');
  String get rescissionProportionalVacation => translate('rescission_proportional_vacation');
  String get rescissionUnusedVacationPay => translate('rescission_unused_vacation_pay');
  String get rescissionVacationThird => translate('rescission_vacation_third');
  String get rescissionNoticePeriodIndemnified => translate('rescission_notice_period_indemnified');
  String get rescissionFgtsFine => translate('rescission_fgts_fine');
  // Toast / feedback
  String get netWorthSaved => translate('net_worth_saved');
  String get budgetSaved => translate('budget_saved');
  String get budgetGoalsSaved => translate('budget_goals_saved');
  String get expenseSaved => translate('expense_saved');
  String get invalidAmount => translate('invalid_amount');
  String get emailRequired => translate('email_required');
  String get recoveryEmailSent => translate('recovery_email_sent');
  String get verificationEmailResent => translate('verification_email_resent');
  String get errorSaving => translate('error_saving');
  String get settingsSaved => translate('settings_saved');
  String get exportSuccess => translate('export_success');
  String get salarySaved => translate('salary_saved');
  String get enterGrossSalary => translate('enter_gross_salary');
  String get couldNotLoadBudget => translate('could_not_load_budget');
  String get couldNotLoadNetWorth => translate('could_not_load_net_worth');
  String get couldNotLoadSalary => translate('could_not_load_salary');
  String get welcomeBack => translate('welcome_back');
  String get errorLoading => translate('error_loading');
  String get saveChanges => translate('save_changes');
  // Budget overflow
  String get budgetOverflowWarning => translate('budget_overflow_warning');
  String get rebalance => translate('rebalance');
  String allocatedOverLimit(String pct) => translate('allocated_over_limit').replaceFirst('%s', pct).replaceFirst('%%', '%');
  // Accounts & Patrimony
  String get bankAccounts => translate('bank_accounts');
  String get manageAccountsDesc => translate('manage_accounts_desc');
  String get patrimony => translate('patrimony');
  String get patrimonyDesc => translate('patrimony_desc');
  // Salary sheet
  String get salaryCltTitle => translate('salary_clt_title');
  String get grossMonthlySalary => translate('gross_monthly_salary');
  String get dependents => translate('dependents');
  String dependentsDeduction(String amount) => translate('dependents_deduction').replaceFirst('%s', amount);
  String get simplifiedDeduction => translate('simplified_deduction');
  String get simplifiedDeductionDesc => translate('simplified_deduction_desc');
  String get otherDeductions => translate('other_deductions');
  String get netSalaryLabel => translate('net_salary_label');
  String effectiveRateSuffix(String rate) => '$rate${translate('effective_rate_suffix').replaceFirst('%%', '%')}';
  String monthlyReductionApplied(String amount) => translate('monthly_reduction_applied').replaceFirst('%s', amount);
  String get fgtsEmployerNote => translate('fgts_employer_note');
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _AppLocalizationsDelegate._supported.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

// Private helper to keep the supported list in sync with the translation map.
abstract class _AppLocalizationsDelegate {
  static final _supported = AppLocalizations._t.keys.toSet();
}
