import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      'no_net_worth': 'No net worth data',
      'score_desc': 'Score from 0 to 10',
      'months': ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'],
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
      'onboarding_subtitle': 'Your money on the right track. Financial planning that guides every decision with clarity.',
      'onboarding_f1': 'Bank-grade security and integrated Pix',
      'onboarding_f2': 'AI that understands your salary and benefits',
      'onboarding_f3': 'Support in your language, 24/7',
      'onboarding_button': 'Create my Farol account',
      'onboarding_login': 'Already a client · Log in',
      'pay_debit': 'Debit',
      'pay_pix': 'PIX',
      'pay_credit': 'Credit',
      'pay_credit_inst': 'Credit (Installments)',
      'pay_swile_meal': 'Swile Meal',
      'pay_swile_food': 'Swile Food',
    },
    'es': {
      'app_name': 'Farol',
      'dashboard': 'Panel',
      'transactions': 'Transacciones',
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
      'no_net_worth': 'Sin datos de patrimonio',
      'score_desc': 'Puntaje de 0 a 10',
      'months': ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'],
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
      'onboarding_subtitle': 'Tu dinero en el rumbo correcto. Planificación financiera que guía cada decisión con claridad.',
      'onboarding_f1': 'Seguridad bancaria y Pix integrado',
      'onboarding_f2': 'IA que entiende tu salario y beneficios',
      'onboarding_f3': 'Soporte en tu idioma, 24/7',
      'onboarding_button': 'Crear mi cuenta Farol',
      'onboarding_login': 'Ya soy cliente · Iniciar sesión',
      'pay_debit': 'Débito',
      'pay_pix': 'PIX',
      'pay_credit': 'Crédito',
      'pay_credit_inst': 'Crédito (Cuotas)',
      'pay_swile_meal': 'Vale Comida',
      'pay_swile_food': 'Vale Alimento',
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
      'no_net_worth': 'Sem dados de patrimônio',
      'score_desc': 'Pontuação de 0 a 10',
      'months': ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'],
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
      'onboarding_subtitle': 'Seu dinheiro no rumo certo. Planejamento financeiro que guia cada decisão com clareza.',
      'onboarding_f1': 'Segurança bancária e Pix integrado',
      'onboarding_f2': 'IA que entende seu salário CLT e FGTS',
      'onboarding_f3': 'Suporte em português, 24/7',
      'onboarding_button': 'Criar minha conta Farol',
      'onboarding_login': 'Já sou cliente · Entrar',
      'pay_debit': 'Débito',
      'pay_pix': 'PIX',
      'pay_credit': 'Crédito à Vista',
      'pay_credit_inst': 'Crédito Parcelado',
      'pay_swile_meal': 'Swile Refeição',
      'pay_swile_food': 'Swile Alimentação',
    },
  };

  String translate(String key) {
    final value = _localizedValues[locale.languageCode]?[key];
    if (value is String) return value;
    return key;
  }

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
  List<String> get months => (_localizedValues[locale.languageCode]?['months'] as List<String>?) ?? 
      ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  String get healthHealthy => translate('health_healthy');
  String get healthWarning => translate('health_warning');
  String get healthCritical => translate('health_critical');
  String get healthExcellentDesc => translate('health_excellent');
  String get healthGoodDesc => translate('health_good');
  String get healthFairDesc => translate('health_fair');
  String get healthWarningDesc => translate('health_warning_desc');
  String get healthCriticalDesc => translate('health_critical_desc');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
