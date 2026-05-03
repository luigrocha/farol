# Full i18n Refactoring Plan

> Generated for Farol Flutter app. All hardcoded strings extracted into `AppLocalizations` with ES/EN/PT-BR translations.

---

## Step 1: Update `lib/core/i18n/app_localizations.dart`

### 1A. Add new keys to English section (before `'goal': 'Goal',` closing brace)

Insert these keys after `'goal': 'Goal',` and before the closing `},` of the English section:

```dart
      // ── Installments ──
      'installments_title': 'Installments',
      'monthly_commitment': 'MONTHLY COMMITMENT',
      'active_installments_label': '%d active',
      'active_header': 'Active',
      'swipe_hint': 'Swipe to delete · tap for actions',
      'no_active_installments': 'No active installments',
      'add_installment_hint': 'Add a card installment purchase',
      'installment_count': '%d/%d installments',
      'percent_complete': '%d%% complete',
      'installments_remaining_text': '%d installment remaining',
      'installments_remaining_text_plural': '%d installments remaining',
      'monthly_label': 'MONTHLY',
      'remaining_label_detail': 'REMAINING',
      'total_label': 'TOTAL',
      'complete_installment_btn': 'Complete installments',
      'register_payment_btn': 'Register %dth payment',
      'delete_installment_btn': 'Delete installment',
      'installment_completed': '🎉 "%s" completed!',
      'installment_payment_registered': '✅ %dth installment registered',
      'remove_installment_confirm': 'Remove "%s"? %s',
      'installment_paid': '%dth installment paid',
      'remaining_balance_text': 'Remaining %s',
      'delete_bg': 'Delete',
      // ── Transactions ──
      'expenses_tab': 'Expenses',
      'income_tab': 'Income',
      'no_expenses_found': 'No expenses found',
      'total_income_label': 'TOTAL INCOME',
      'no_income_this_month': 'No income this month',
      'add_income_hint': 'Tap + to register salary, bonus, etc.',
      'search_expense': 'Search expense...',
      'swile_badge': 'SWILE',
      'fixed_badge': 'FIXED',
      'new_income_title': 'New Income',
      'gross_label': 'Gross',
      'net_label_inline': 'Net',
      'gross_label_inline': 'Gross',
      'salary_breakdown': 'Salary Breakdown',
      'calculate_net': 'Calculate net',
      'use_net_value': 'Use net value',
      'save_income_btn': 'Save income',
      'dependents_label': 'Dependents (IRRF)',
      'net_value_desc': 'Net value (already deducted INSS/IRRF)',
      'total_monthly_label': 'TOTAL MONTHLY',
      'total_cash_label': 'TOTAL CASH',
      'total_swile_label': 'TOTAL SWILE',
      'day_label': 'DAY %d',
      'expense_default': 'Expense',
      'filter_all': 'All',
      'filter_cash': 'Cash',
      'filter_swile': 'Swile',
      'filter_category': 'Category',
      'error_generic': 'Error: %s',
      'description': 'Description',
      'optional': 'optional',
      'notes_hint': 'Notes (optional)',
      'hint_amount': '0.00',
      'error_loading': 'Error loading',
      // ── Income Edit ──
      'edit_income_title': 'Edit Income',
      'income_updated': 'Income updated',
      'save_changes': 'Save changes',
      'invalid_amount_msg': 'Invalid amount',
      // ── Investments ──
      'vs_last_month': 'vs. last month',
      'asset_allocation_desc': 'Strategic portfolio allocation',
      'ai_suggestion_text': 'Your portfolio has low exposure to real estate assets. Consider FIIs.',
      'explore_fiis': 'Explore FIIs',
      'detail_by_asset': 'Detail by asset',
      'view_history': 'View History',
      'return_label': 'RETURN',
      'diversified_label': 'Diversified',
      'cdi_bruto': 'Gross CDI',
      'fee_label': 'Fee',
      'risk_label': 'Risk',
      'risk_medium': 'Medium',
      'current_balance_label_detail': 'CURRENT BALANCE',
      'position_title': 'Position',
      'total_invested_label': 'Total invested',
      'current_balance_inline': 'Current balance',
      'return_amount_label': 'Return (R$)',
      'return_percent_label': 'Return (%)',
      'date_added_label': 'Entry date',
      'details_title': 'Details',
      'liquidity_label_detail': 'Liquidity',
      'notes_label': 'Notes',
      'capital_evolution': 'Capital evolution',
      'invested_label': 'Invested',
      'current_label': 'Current',
      'daily_liquidity': 'Daily (D+0)',
      'at_maturity': 'At maturity',
      // ── Dashboard ──
      'fixed_expenses_copied': '%d fixed expense%s copied from previous month',
      // ── Subcategories ──
      'sub_rent': 'Rent',
      'sub_condo_fee': 'Condo Fee',
      'sub_electricity': 'Electricity',
      'sub_water': 'Water',
      'sub_gas': 'Gas',
      'sub_internet': 'Internet',
      'sub_property_tax': 'Property Tax',
      'sub_maintenance': 'Maintenance',
      'sub_uber': 'Uber',
      'sub_transit': 'Subway/Bus',
      'sub_fuel': 'Fuel',
      'sub_parking': 'Parking',
      'sub_supermarket': 'Supermarket',
      'sub_restaurant': 'Restaurant',
      'sub_delivery': 'Delivery',
      'sub_bakery': 'Bakery',
      'sub_farmers_market': 'Farmers Market',
      'sub_pharmacy': 'Pharmacy',
      'sub_doctor': 'Doctor',
      'sub_health_plan': 'Health Plan',
      'sub_lab_tests': 'Lab Tests',
      'sub_gym': 'Gym',
      'sub_streaming': 'Streaming',
      'sub_apps': 'Apps',
      'sub_mobile_phone': 'Mobile Phone',
      'sub_cinema': 'Cinema',
      'sub_travel': 'Travel',
      'sub_bars': 'Bars',
      'sub_games': 'Games',
      'sub_hobbies': 'Hobbies',
      'sub_course': 'Course',
      'sub_books': 'Books',
      'sub_certification': 'Certification',
      'sub_materials': 'Materials',
      'sub_installment_purchase': 'Installment Purchase',
      'sub_gift': 'Gift',
      'sub_donation': 'Donation',
      'sub_unexpected': 'Unexpected',
```

### 1B. Add same keys to Spanish section (before `'goal': 'Meta',` closing brace)

```dart
      // ── Installments ──
      'installments_title': 'Cuotas',
      'monthly_commitment': 'COMPROMISO MENSUAL',
      'active_installments_label': '%d activas',
      'active_header': 'Activas',
      'swipe_hint': 'Desliza para eliminar · toca para acciones',
      'no_active_installments': 'Sin cuotas activas',
      'add_installment_hint': 'Agrega una compra a cuotas en la tarjeta',
      'installment_count': '%d/%d cuotas',
      'percent_complete': '%d%% completado',
      'installments_remaining_text': '%d cuota restante',
      'installments_remaining_text_plural': '%d cuotas restantes',
      'monthly_label': 'MENSUAL',
      'remaining_label_detail': 'RESTANTE',
      'total_label': 'TOTAL',
      'complete_installment_btn': 'Completar cuotas',
      'register_payment_btn': 'Registrar %d° pago',
      'delete_installment_btn': 'Eliminar cuota',
      'installment_completed': '🎉 "¡%s" completada!',
      'installment_payment_registered': '✅ %d° cuota registrada',
      'remove_installment_confirm': '¿Eliminar "%s"? %s',
      'installment_paid': '%d° cuota pagada',
      'remaining_balance_text': 'Restan %s',
      'delete_bg': 'Eliminar',
      // ── Transactions ──
      'expenses_tab': 'Gastos',
      'income_tab': 'Ingresos',
      'no_expenses_found': 'Sin gastos encontrados',
      'total_income_label': 'TOTAL INGRESOS',
      'no_income_this_month': 'Sin ingresos este mes',
      'add_income_hint': 'Toca + para registrar salario, bono, etc.',
      'search_expense': 'Buscar gasto...',
      'swile_badge': 'SWILE',
      'fixed_badge': 'FIJO',
      'new_income_title': 'Nuevo Ingreso',
      'gross_label': 'Bruto',
      'net_label_inline': 'Neto',
      'gross_label_inline': 'Bruto',
      'salary_breakdown': 'Desglose del salario',
      'calculate_net': 'Calcular neto',
      'use_net_value': 'Usar valor neto',
      'save_income_btn': 'Guardar ingreso',
      'dependents_label': 'Dependientes (IRRF)',
      'net_value_desc': 'Valor neto (ya descontado INSS/IRRF)',
      'total_monthly_label': 'TOTAL MENSUAL',
      'total_cash_label': 'TOTAL EFECTIVO',
      'total_swile_label': 'TOTAL SWILE',
      'day_label': 'DÍA %d',
      'expense_default': 'Gasto',
      'filter_all': 'Todas',
      'filter_cash': 'Efectivo',
      'filter_swile': 'Swile',
      'filter_category': 'Categoría',
      'error_generic': 'Error: %s',
      'description': 'Descripción',
      'optional': 'opcional',
      'notes_hint': 'Notas (opcional)',
      'hint_amount': '0,00',
      'error_loading': 'Error al cargar',
      // ── Income Edit ──
      'edit_income_title': 'Editar Ingreso',
      'income_updated': 'Ingreso actualizado',
      'save_changes': 'Guardar cambios',
      'invalid_amount_msg': 'Monto inválido',
      // ── Investments ──
      'vs_last_month': 'vs. mes anterior',
      'asset_allocation_desc': 'Distribución estratégica de la cartera',
      'ai_suggestion_text': 'Tu cartera tiene baja exposición en activos inmobiliarios. Considera FIIs.',
      'explore_fiis': 'Explorar FIIs',
      'detail_by_asset': 'Detalle por activo',
      'view_history': 'Ver Historial',
      'return_label': 'RENDIMIENTO',
      'diversified_label': 'Diversificada',
      'cdi_bruto': 'CDI Bruto',
      'fee_label': 'Tarifa',
      'risk_label': 'Riesgo',
      'risk_medium': 'Medio',
      'current_balance_label_detail': 'SALDO ACTUAL',
      'position_title': 'Posición',
      'total_invested_label': 'Total invertido',
      'current_balance_inline': 'Saldo actual',
      'return_amount_label': 'Rendimiento (R$)',
      'return_percent_label': 'Rendimiento (%)',
      'date_added_label': 'Fecha de entrada',
      'details_title': 'Detalles',
      'liquidity_label_detail': 'Liquidez',
      'notes_label': 'Notas',
      'capital_evolution': 'Evolución del capital',
      'invested_label': 'Invertido',
      'current_label': 'Actual',
      'daily_liquidity': 'Diaria (D+0)',
      'at_maturity': 'Al vencimiento',
      // ── Dashboard ──
      'fixed_expenses_copied': '%d gasto%s fijo%s copiado%s del mes anterior',
      // ── Subcategories ──
      'sub_rent': 'Alquiler',
      'sub_condo_fee': 'Cuota Condominio',
      'sub_electricity': 'Electricidad',
      'sub_water': 'Agua',
      'sub_gas': 'Gas',
      'sub_internet': 'Internet',
      'sub_property_tax': 'Impuesto Predial',
      'sub_maintenance': 'Mantenimiento',
      'sub_uber': 'Uber',
      'sub_transit': 'Metro/Autobús',
      'sub_fuel': 'Combustible',
      'sub_parking': 'Estacionamiento',
      'sub_supermarket': 'Supermercado',
      'sub_restaurant': 'Restaurante',
      'sub_delivery': 'Delivery',
      'sub_bakery': 'Panadería',
      'sub_farmers_market': 'Mercado',
      'sub_pharmacy': 'Farmacia',
      'sub_doctor': 'Doctor',
      'sub_health_plan': 'Plan de Salud',
      'sub_lab_tests': 'Análisis de Laboratorio',
      'sub_gym': 'Gimnasio',
      'sub_streaming': 'Streaming',
      'sub_apps': 'Aplicaciones',
      'sub_mobile_phone': 'Teléfono Móvil',
      'sub_cinema': 'Cine',
      'sub_travel': 'Viajes',
      'sub_bars': 'Bares',
      'sub_games': 'Juegos',
      'sub_hobbies': 'Pasatiempos',
      'sub_course': 'Curso',
      'sub_books': 'Libros',
      'sub_certification': 'Certificación',
      'sub_materials': 'Materiales',
      'sub_installment_purchase': 'Compra a Cuotas',
      'sub_gift': 'Regalo',
      'sub_donation': 'Donación',
      'sub_unexpected': 'Inesperado',
```

### 1C. Add same keys to Portuguese section (before `'goal': 'Meta',` closing brace)

```dart
      // ── Parcelas ──
      'installments_title': 'Parcelas',
      'monthly_commitment': 'COMPROMISSO MENSAL',
      'active_installments_label': '%d ativas',
      'active_header': 'Ativas',
      'swipe_hint': 'Deslize para excluir · toque para ações',
      'no_active_installments': 'Sem parcelas ativas',
      'add_installment_hint': 'Adicione uma compra parcelada no cartão',
      'installment_count': '%d/%d parcelas',
      'percent_complete': '%d%% concluído',
      'installments_remaining_text': '%d parcela restante',
      'installments_remaining_text_plural': '%d parcelas restantes',
      'monthly_label': 'MENSAL',
      'remaining_label_detail': 'RESTANTE',
      'total_label': 'TOTAL',
      'complete_installment_btn': 'Concluir parcelas',
      'register_payment_btn': 'Registrar %d° pagamento',
      'delete_installment_btn': 'Excluir parcela',
      'installment_completed': '🎉 "%s" concluída!',
      'installment_payment_registered': '✅ %d° parcela registrada',
      'remove_installment_confirm': 'Excluir "%s"? %s',
      'installment_paid': '%d° parcela paga',
      'remaining_balance_text': 'Restam %s',
      'delete_bg': 'Excluir',
      // ── Transações ──
      'expenses_tab': 'Despesas',
      'income_tab': 'Receitas',
      'no_expenses_found': 'Nenhuma despesa encontrada',
      'total_income_label': 'TOTAL RECEITAS',
      'no_income_this_month': 'Nenhuma receita neste mês',
      'add_income_hint': 'Toque + para registrar salário, bônus, etc.',
      'search_expense': 'Buscar despesa...',
      'swile_badge': 'SWILE',
      'fixed_badge': 'FIXO',
      'new_income_title': 'Nova Receita',
      'gross_label': 'Bruto',
      'net_label_inline': 'Líquido',
      'gross_label_inline': 'Bruto',
      'salary_breakdown': 'Detalhamento do salário',
      'calculate_net': 'Calcular líquido',
      'use_net_value': 'Usar valor líquido',
      'save_income_btn': 'Salvar receita',
      'dependents_label': 'Dependentes (IRRF)',
      'net_value_desc': 'Valor líquido (já descontado INSS/IRRF)',
      'total_monthly_label': 'TOTAL MENSAL',
      'total_cash_label': 'TOTAL CAIXA',
      'total_swile_label': 'TOTAL SWILE',
      'day_label': 'DIA %d',
      'expense_default': 'Despesa',
      'filter_all': 'Todas',
      'filter_cash': 'Caixa',
      'filter_swile': 'Swile',
      'filter_category': 'Categoria',
      'error_generic': 'Erro: %s',
      'description': 'Descrição',
      'optional': 'opcional',
      'notes_hint': 'Notas (opcional)',
      'hint_amount': '0,00',
      'error_loading': 'Erro ao carregar',
      // ── Edição de Receita ──
      'edit_income_title': 'Editar Receita',
      'income_updated': 'Receita atualizada',
      'save_changes': 'Salvar alterações',
      'invalid_amount_msg': 'Valor inválido',
      // ── Investimentos ──
      'vs_last_month': 'vs. mês anterior',
      'asset_allocation_desc': 'Alocação estratégica da carteira',
      'ai_suggestion_text': 'Sua carteira tem baixa exposição em ativos imobiliários. Considere FIIs.',
      'explore_fiis': 'Explorar FIIs',
      'detail_by_asset': 'Detalhe por ativo',
      'view_history': 'Ver Histórico',
      'return_label': 'RENDIMENTO',
      'diversified_label': 'Diversificada',
      'cdi_bruto': 'CDI Bruto',
      'fee_label': 'Taxa',
      'risk_label': 'Risco',
      'risk_medium': 'Médio',
      'current_balance_label_detail': 'SALDO ATUAL',
      'position_title': 'Posição',
      'total_invested_label': 'Total investido',
      'current_balance_inline': 'Saldo atual',
      'return_amount_label': 'Rendimento (R$)',
      'return_percent_label': 'Rendimento (%)',
      'date_added_label': 'Data de entrada',
      'details_title': 'Detalhes',
      'liquidity_label_detail': 'Liquidez',
      'notes_label': 'Notas',
      'capital_evolution': 'Evolução do capital',
      'invested_label': 'Investido',
      'current_label': 'Atual',
      'daily_liquidity': 'Diária (D+0)',
      'at_maturity': 'No vencimento',
      // ── Dashboard ──
      'fixed_expenses_copied': '%d despesa%s fixa%s copiada%s do mês anterior',
      // ── Subcategorias ──
      'sub_rent': 'Aluguel',
      'sub_condo_fee': 'Taxa Condomínio',
      'sub_electricity': 'Energia',
      'sub_water': 'Água',
      'sub_gas': 'Gás',
      'sub_internet': 'Internet',
      'sub_property_tax': 'IPTU',
      'sub_maintenance': 'Manutenção',
      'sub_uber': 'Uber',
      'sub_transit': 'Metrô/Ônibus',
      'sub_fuel': 'Combustível',
      'sub_parking': 'Estacionamento',
      'sub_supermarket': 'Supermercado',
      'sub_restaurant': 'Restaurante',
      'sub_delivery': 'Delivery',
      'sub_bakery': 'Padaria',
      'sub_farmers_market': 'Feira',
      'sub_pharmacy': 'Farmácia',
      'sub_doctor': 'Médico',
      'sub_health_plan': 'Plano de Saúde',
      'sub_lab_tests': 'Exames',
      'sub_gym': 'Academia',
      'sub_streaming': 'Streaming',
      'sub_apps': 'Aplicativos',
      'sub_mobile_phone': 'Celular',
      'sub_cinema': 'Cinema',
      'sub_travel': 'Viagens',
      'sub_bars': 'Bares',
      'sub_games': 'Jogos',
      'sub_hobbies': 'Hobbies',
      'sub_course': 'Curso',
      'sub_books': 'Livros',
      'sub_certification': 'Certificação',
      'sub_materials': 'Materiais',
      'sub_installment_purchase': 'Compra Parcelada',
      'sub_gift': 'Presente',
      'sub_donation': 'Doação',
      'sub_unexpected': 'Imprevisto',
```

### 1D. Add getter methods (before the closing `}` of AppLocalizations class, after `goal` getter)

```dart
  // ── Installments ──
  String get installmentsTitle => translate('installments_title');
  String get monthlyCommitment => translate('monthly_commitment');
  String activeInstallmentsLabel(int count) => translate('active_installments_label').replaceAll('%d', count.toString());
  String get activeHeader => translate('active_header');
  String get swipeHint => translate('swipe_hint');
  String get noActiveInstallments => translate('no_active_installments');
  String get addInstallmentHint => translate('add_installment_hint');
  String installmentCount(int current, int total) => translate('installment_count').replaceAll('%d/%d', '$current/$total');
  String percentComplete(int pct) => translate('percent_complete').replaceAll('%d', pct.toString());
  String installmentsRemainingText(int count) => count == 1
      ? translate('installments_remaining_text').replaceAll('%d', count.toString())
      : translate('installments_remaining_text_plural').replaceAll('%d', count.toString());
  String get monthlyLabel => translate('monthly_label');
  String get remainingLabelDetail => translate('remaining_label_detail');
  String get totalLabel => translate('total_label');
  String get completeInstallmentBtn => translate('complete_installment_btn');
  String registerPaymentBtn(int num) => translate('register_payment_btn').replaceAll('%d', num.toString());
  String get deleteInstallmentBtn => translate('delete_installment_btn');
  String installmentCompleted(String name) => translate('installment_completed').replaceAll('%s', name);
  String installmentPaymentRegistered(int num) => translate('installment_payment_registered').replaceAll('%d', num.toString());
  String removeInstallmentConfirm(String name) => translate('remove_installment_confirm').replaceAll('%s', name).replaceAll('%s', cannotUndo);
  String installmentPaid(int num) => translate('installment_paid').replaceAll('%d', num.toString());
  String remainingBalanceText(String amount) => translate('remaining_balance_text').replaceAll('%s', amount);
  String get deleteBg => translate('delete_bg');

  // ── Transactions ──
  String get expensesTab => translate('expenses_tab');
  String get incomeTab => translate('income_tab');
  String get noExpensesFound => translate('no_expenses_found');
  String get totalIncomeLabel => translate('total_income_label');
  String get noIncomeThisMonth => translate('no_income_this_month');
  String get addIncomeHint => translate('add_income_hint');
  String get searchExpense => translate('search_expense');
  String get swileBadge => translate('swile_badge');
  String get fixedBadge => translate('fixed_badge');
  String get newIncomeTitle => translate('new_income_title');
  String get grossLabel => translate('gross_label');
  String get netLabelInline => translate('net_label_inline');
  String get grossLabelInline => translate('gross_label_inline');
  String get salaryBreakdown => translate('salary_breakdown');
  String get calculateNet => translate('calculate_net');
  String get useNetValue => translate('use_net_value');
  String get saveIncomeBtn => translate('save_income_btn');
  String get dependentsLabel => translate('dependents_label');
  String get netValueDesc => translate('net_value_desc');
  String get totalMonthlyLabel => translate('total_monthly_label');
  String get totalCashLabel => translate('total_cash_label');
  String get totalSwileLabel => translate('total_swile_label');
  String dayLabel(int day) => translate('day_label').replaceAll('%d', day.toString());
  String get expenseDefault => translate('expense_default');
  String get filterAll => translate('filter_all');
  String get filterCash => translate('filter_cash');
  String get filterSwile => translate('filter_swile');
  String get filterCategory => translate('filter_category');
  String errorGeneric(String msg) => translate('error_generic').replaceAll('%s', msg);
  String get descriptionKey => translate('description');
  String get optionalKey => translate('optional');
  String get notesHint => translate('notes_hint');
  String get hintAmount => translate('hint_amount');
  String get errorLoading => translate('error_loading');

  // ── Income Edit ──
  String get editIncomeTitle => translate('edit_income_title');
  String get incomeUpdated => translate('income_updated');
  String get saveChanges => translate('save_changes');
  String get invalidAmountMsg => translate('invalid_amount_msg');

  // ── Investments ──
  String get vsLastMonth => translate('vs_last_month');
  String get assetAllocationDesc => translate('asset_allocation_desc');
  String get aiSuggestionText => translate('ai_suggestion_text');
  String get exploreFiis => translate('explore_fiis');
  String get detailByAsset => translate('detail_by_asset');
  String get viewHistory => translate('view_history');
  String get returnLabel => translate('return_label');
  String get diversifiedLabel => translate('diversified_label');
  String get cdiBruto => translate('cdi_bruto');
  String get feeLabel => translate('fee_label');
  String get riskLabel => translate('risk_label');
  String get riskMedium => translate('risk_medium');
  String get currentBalanceLabelDetail => translate('current_balance_label_detail');
  String get positionTitle => translate('position_title');
  String get totalInvestedLabel => translate('total_invested_label');
  String get currentBalanceInline => translate('current_balance_inline');
  String get returnAmountLabel => translate('return_amount_label');
  String get returnPercentLabel => translate('return_percent_label');
  String get dateAddedLabel => translate('date_added_label');
  String get detailsTitle => translate('details_title');
  String get liquidityLabelDetail => translate('liquidity_label_detail');
  String get notesLabel => translate('notes_label');
  String get capitalEvolution => translate('capital_evolution');
  String get investedLabel => translate('invested_label');
  String get currentLabel => translate('current_label');
  String get dailyLiquidity => translate('daily_liquidity');
  String get atMaturity => translate('at_maturity');

  // ── Dashboard ──
  String fixedExpensesCopied(int count) {
    final base = translate('fixed_expenses_copied');
    return base.replaceAll('%d', count.toString()).replaceAll('%s', count == 1 ? '' : 's');
  }

  // ── Subcategories ──
  String get subRent => translate('sub_rent');
  String get subCondoFee => translate('sub_condo_fee');
  String get subElectricity => translate('sub_electricity');
  String get subWater => translate('sub_water');
  String get subGas => translate('sub_gas');
  String get subInternet => translate('sub_internet');
  String get subPropertyTax => translate('sub_property_tax');
  String get subMaintenance => translate('sub_maintenance');
  String get subUber => translate('sub_uber');
  String get subTransit => translate('sub_transit');
  String get subFuel => translate('sub_fuel');
  String get subParking => translate('sub_parking');
  String get subSupermarket => translate('sub_supermarket');
  String get subRestaurant => translate('sub_restaurant');
  String get subDelivery => translate('sub_delivery');
  String get subBakery => translate('sub_bakery');
  String get subFarmersMarket => translate('sub_farmers_market');
  String get subPharmacy => translate('sub_pharmacy');
  String get subDoctor => translate('sub_doctor');
  String get subHealthPlan => translate('sub_health_plan');
  String get subLabTests => translate('sub_lab_tests');
  String get subGym => translate('sub_gym');
  String get subStreaming => translate('sub_streaming');
  String get subApps => translate('sub_apps');
  String get subMobilePhone => translate('sub_mobile_phone');
  String get subCinema => translate('sub_cinema');
  String get subTravel => translate('sub_travel');
  String get subBars => translate('sub_bars');
  String get subGames => translate('sub_games');
  String get subHobbies => translate('sub_hobbies');
  String get subCourse => translate('sub_course');
  String get subBooks => translate('sub_books');
  String get subCertification => translate('sub_certification');
  String get subMaterials => translate('sub_materials');
  String get subInstallmentPurchase => translate('sub_installment_purchase');
  String get subGift => translate('sub_gift');
  String get subDonation => translate('sub_donation');
  String get subUnexpected => translate('sub_unexpected');
```

---

## Step 2: Update `lib/features/installments/installments_screen.dart`

### 2.1 Line 31: Title
**Before:**
```dart
title: Text('Parcelas', style: GoogleFonts.manrope(...)),
```
**After:**
```dart
title: Text(AppLocalizations.of(context).installmentsTitle, style: GoogleFonts.manrope(...)),
```

### 2.2 Line 52: Error message
**Before:**
```dart
child: Text('Error: $e')),
```
**After:**
```dart
child: Text(AppLocalizations.of(context).errorGeneric(e.toString())),
```

### 2.3 Lines 94-103: Hero card labels
**Before:**
```dart
const Text('COMPROMISSO MENSAL', ...),
...
_HeroPill(label: 'PARCELAS', value: '$count ativas'),
...
_HeroPill(label: 'SALDO RESTANTE', value: ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).monthlyCommitment, ...),
...
_HeroPill(label: '', value: l10n.activeInstallmentsLabel(count)),
...
_HeroPill(label: '', value: '${l10n.remainingLabelDetail}: ${FinancialCalculatorService.formatBRL(remaining)}'),
```

Note: Add `final l10n = AppLocalizations.of(context);` at the start of the `_HeroCard` build method.

### 2.4 Lines 139-140: Header
**Before:**
```dart
Text('Ativas', style: GoogleFonts.manrope(...)),
Text('Deslize para excluir · toque para ações', style: TextStyle(...)),
```
**After:**
```dart
Text(AppLocalizations.of(context).activeHeader, style: GoogleFonts.manrope(...)),
Text(AppLocalizations.of(context).swipeHint, style: TextStyle(...)),
```

### 2.5 Lines 161-163: Empty state
**Before:**
```dart
Text('Sem parcelas ativas', style: GoogleFonts.manrope(...)),
Text('Adicione uma compra parcelada no cartão', style: TextStyle(...)),
```
**After:**
```dart
Text(AppLocalizations.of(context).noActiveInstallments, style: GoogleFonts.manrope(...)),
Text(AppLocalizations.of(context).addInstallmentHint, style: TextStyle(...)),
```

### 2.6 Line 188: Dismiss background
**Before:**
```dart
Text('Excluir', style: TextStyle(...)),
```
**After:**
```dart
Text(AppLocalizations.of(context).deleteBg, style: TextStyle(...)),
```

### 2.7 Lines 195-197: Confirm dismiss
**Before:**
```dart
body: 'Remove "${inst.description}"? ${l10n.cannotUndo}',
```
**After:**
```dart
body: l10n.removeInstallmentConfirm(inst.description),
```

### 2.8 Line 242: "por mês"
**Before:**
```dart
Text('por mês', style: TextStyle(...)),
```
**After:**
```dart
Text(AppLocalizations.of(context).perMonth, style: TextStyle(...)),
```

### 2.9 Lines 289, 352-353, 362-366: Detail sheet strings
**Before:**
```dart
'$current/$total parcelas',
'${(inst.progressPercent * 100).toInt()}% concluído',
'${inst.remainingInstallments} parcela${...} restante${...}',
'MENSAL', 'RESTANTE', 'TOTAL',
```
**After:**
```dart
l10n.installmentCount(inst.currentInstallment, inst.numInstallments),
l10n.percentComplete((inst.progressPercent * 100).toInt()),
l10n.installmentsRemainingText(inst.remainingInstallments),
l10n.monthlyLabel, l10n.remainingLabelDetail, l10n.totalLabel,
```

### 2.10 Lines 248-249: Installment paid / remaining
**Before:**
```dart
Text('${inst.currentInstallment}ª parcela paga', ...),
Text('Restam ${FinancialCalculatorService.formatBRL(inst.remainingBalance)}', ...),
```
**After:**
```dart
Text(l10n.installmentPaid(inst.currentInstallment), ...),
Text(l10n.remainingBalanceText(FinancialCalculatorService.formatBRL(inst.remainingBalance)), ...),
```

### 2.11 Lines 394-396: Complete/register button
**Before:**
```dart
inst.currentInstallment + 1 >= inst.numInstallments ? 'Concluir parcelas' : 'Registrar ${inst.currentInstallment + 1}ª parcela paga',
```
**After:**
```dart
inst.currentInstallment + 1 >= inst.numInstallments
    ? l10n.completeInstallmentBtn
    : l10n.registerPaymentBtn(inst.currentInstallment + 1),
```

### 2.12 Line 415: Delete button
**Before:**
```dart
const Text('Excluir parcela', style: TextStyle(...)),
```
**After:**
```dart
Text(AppLocalizations.of(context).deleteInstallmentBtn, style: TextStyle(...)),
```

### 2.13 Lines 436-438: SnackBar messages
**Before:**
```dart
context.showSuccessSnackBar(newCurrent >= inst.numInstallments
    ? '🎉 "${inst.description}" concluída!'
    : '✅ ${newCurrent}ª parcela registrada');
```
**After:**
```dart
context.showSuccessSnackBar(newCurrent >= inst.numInstallments
    ? l10n.installmentCompleted(inst.description)
    : l10n.installmentPaymentRegistered(newCurrent));
```

### 2.14 Lines 453-454: Confirm delete in detail sheet
**Before:**
```dart
body: 'Remove "${widget.inst.description}"? ${l10n.cannotUndo}',
```
**After:**
```dart
body: l10n.removeInstallmentConfirm(widget.inst.description),
```

---

## Step 3: Update `lib/features/transactions/transactions_screen.dart`

### 3.1 Lines 87-88: Tab labels
**Before:**
```dart
Tab(text: 'Gastos'),
Tab(text: 'Ingresos'),
```
**After:**
```dart
Tab(text: AppLocalizations.of(context).expensesTab),
Tab(text: AppLocalizations.of(context).incomeTab),
```

### 3.2 Line 117: Error
**Before:**
```dart
SliverFillRemaining(child: Center(child: Text('Erro: ${filteredAsync.error}')))
```
**After:**
```dart
SliverFillRemaining(child: Center(child: Text(AppLocalizations.of(context).errorGeneric(filteredAsync.error.toString()))))
```

### 3.3 Line 119: No expenses
**Before:**
```dart
const SliverFillRemaining(child: Center(child: Text('Nenhum gasto encontrado')))
```
**After:**
```dart
SliverFillRemaining(child: Center(child: Text(AppLocalizations.of(context).noExpensesFound)))
```

### 3.4 Lines 206, 223-227: Income tab strings
**Before:**
```dart
const Text('TOTAL INGRESOS', ...),
...
Text('Nenhum ingresso neste mês', ...),
Text('Toca + para registrar salário, bonus, etc.', ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).totalIncomeLabel, ...),
...
Text(AppLocalizations.of(context).noIncomeThisMonth, ...),
Text(AppLocalizations.of(context).addIncomeHint, ...),
```

### 3.5 Line 215: Income tab error
**Before:**
```dart
error: (e, _) => SliverFillRemaining(child: Center(child: Text('Erro: $e'))),
```
**After:**
```dart
error: (e, _) => SliverFillRemaining(child: Center(child: Text(AppLocalizations.of(context).errorGeneric(e.toString())))),
```

### 3.6 Lines 309-310: Income row "Líquido"/"Bruto"
**Before:**
```dart
Text(income.isNet ? 'Líquido' : 'Bruto', ...),
```
**After:**
```dart
Text(income.isNet ? l10n.netLabelInline : l10n.grossLabelInline, ...),
```

### 3.7 Line 407: New income title
**Before:**
```dart
Text('Novo Ingresso', ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).newIncomeTitle, ...),
```

### 3.8 Line 409: "Tipo" label
**Before:**
```dart
Text('Tipo', style: TextStyle(...)),
```
**After:**
```dart
Text(AppLocalizations.of(context).type, style: TextStyle(...)),
```

### 3.9 Line 444: "Valor" label
**Before:**
```dart
decoration: const InputDecoration(labelText: 'Valor', prefixText: 'R\$ '),
```
**After:**
```dart
decoration: InputDecoration(labelText: AppLocalizations.of(context).amount, prefixText: 'R\$ '),
```

### 3.10 Lines 448-449: Net value description
**Before:**
```dart
Text('Valor líquido (ya descontado INSS/IRRF)', ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).netValueDesc, ...),
```

### 3.11 Lines 471-472: Dependents label
**Before:**
```dart
Text('Dependentes (IRRF)', ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).dependentsLabel, ...),
```

### 3.12 Lines 497, 541: Calculate net / Use net value
**Before:**
```dart
const Text('Calcular líquido'),
...
const Text('Usar valor líquido'),
```
**After:**
```dart
Text(AppLocalizations.of(context).calculateNet),
...
Text(AppLocalizations.of(context).useNetValue),
```

### 3.13 Lines 521-522: "Desglose del salario"
**Before:**
```dart
Text('Desglose del salario', ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).salaryBreakdown, ...),
```

### 3.14 Lines 530-533: Breakdown labels (Bruto, INSS, IRRF, Líquido)
**Before:**
```dart
_buildAddCalcRow('Bruto', ...),
_buildAddCalcRow('INSS', ...),
_buildAddCalcRow('IRRF', ...),
...
_buildAddCalcRow('Líquido', ...),
```
**After:**
```dart
_buildAddCalcRow(l10n.grossLabel, ...),
_buildAddCalcRow('INSS', ...),  // Keep as-is (Brazilian acronym)
_buildAddCalcRow('IRRF', ...),  // Keep as-is (Brazilian acronym)
...
_buildAddCalcRow(l10n.netLabelInline, ...),
```

### 3.15 Line 555: Notes hint
**Before:**
```dart
decoration: const InputDecoration(labelText: 'Observación (opcional)'),
```
**After:**
```dart
decoration: InputDecoration(labelText: AppLocalizations.of(context).notesHint),
```

### 3.16 Line 565: Save button
**Before:**
```dart
const Text('Guardar ingresso'),
```
**After:**
```dart
Text(AppLocalizations.of(context).saveIncomeBtn),
```

### 3.17 Line 670: Search hint
**Before:**
```dart
hintText: 'Buscar gasto...',
```
**After:**
```dart
hintText: AppLocalizations.of(context).searchExpense,
```

### 3.18 Lines 707-709: Filter chips
**Before:**
```dart
('all', 'Todas'),
('cash', 'Cash'),
('swile', 'Swile'),
```
**After:**
```dart
('all', AppLocalizations.of(context).filterAll),
('cash', AppLocalizations.of(context).filterCash),
('swile', AppLocalizations.of(context).filterSwile),
```

### 3.19 Line 732: Category chip
**Before:**
```dart
label: 'Categoría',
```
**After:**
```dart
label: AppLocalizations.of(context).filterCategory,
```

### 3.20 Lines 810-812: Total hero labels
**Before:**
```dart
String label = 'TOTAL MENSUAL';
if (payFilter == 'swile') label = 'TOTAL SWILE';
if (payFilter == 'cash') label = 'TOTAL CASH';
```
**After:**
```dart
String label = AppLocalizations.of(context).totalMonthlyLabel;
if (payFilter == 'swile') label = AppLocalizations.of(context).totalSwileLabel;
if (payFilter == 'cash') label = AppLocalizations.of(context).totalCashLabel;
```

### 3.21 Line 890: Day separator
**Before:**
```dart
Text('DIA ${date.day}', ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).dayLabel(date.day), ...),
```

### 3.22 Line 982: Expense default name
**Before:**
```dart
expense.storeDescription as String? ?? 'Gasto',
```
**After:**
```dart
expense.storeDescription as String? ?? AppLocalizations.of(context).expenseDefault,
```

### 3.23 Lines 1004, 1025: SWILE/FIXO badges
**Before:**
```dart
const Text('SWILE', ...),
...
const Text('FIXO', ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).swileBadge, ...),
...
Text(AppLocalizations.of(context).fixedBadge, ...),
```

---

## Step 4: Update `lib/features/transactions/quick_add_bottom_sheet.dart`

### 4.1 Line 66: Amount hint
**Before:**
```dart
decoration: const InputDecoration(prefixText: 'R\$ ', hintText: '0,00'),
```
**After:**
```dart
decoration: InputDecoration(prefixText: 'R\$ ', hintText: l10n.hintAmount),
```

### 4.2 Lines 28-38: Subcategories map
**Replace entire `_subcategories` const with a method that returns localized values:**

**Before:**
```dart
static const _subcategories = {
  'HOUSING': ['Rent', 'Condo Fee', ...],
  ...
};
```
**After:**
```dart
Map<String, List<String>> _getSubcategories(AppLocalizations l10n) {
  return {
    'HOUSING': [l10n.subRent, l10n.subCondoFee, l10n.subElectricity, l10n.subWater, l10n.subGas, l10n.subInternet, l10n.subPropertyTax, l10n.subMaintenance],
    'TRANSPORT': [l10n.subUber, l10n.subTransit, l10n.subFuel, l10n.subParking, l10n.subMaintenance],
    'FOOD_GROCERY': [l10n.subSupermarket, l10n.subRestaurant, l10n.subDelivery, l10n.subBakery, l10n.subFarmersMarket],
    'HEALTH': [l10n.subPharmacy, l10n.subDoctor, l10n.subHealthPlan, l10n.subLabTests, l10n.subGym],
    'SUBSCRIPTIONS': [l10n.subStreaming, l10n.subApps, l10n.subMobilePhone, l10n.subGym, l10n.translate('income_other')],
    'LEISURE': [l10n.subCinema, l10n.subTravel, l10n.subBars, l10n.subGames, l10n.subHobbies],
    'EDUCATION': [l10n.subCourse, l10n.subBooks, l10n.subCertification, l10n.subMaterials],
    'CARD_INSTALLMENTS': [l10n.subInstallmentPurchase],
    'OTHER': [l10n.subGift, l10n.subDonation, l10n.subUnexpected, l10n.translate('income_other')],
  };
}
```

Then change all references from `_subcategories` to `_getSubcategories(l10n)`.

### 4.3 Line 91: Subcategory label
**Before:**
```dart
child: Text(l10n.translate('subcategory'), ...),
```
**After:**
```dart
child: Text(l10n.translate('subcategory'), ...),  // Already uses l10n
```

### 4.4 Line 112: Installments label
**Before:**
```dart
decoration: const InputDecoration(labelText: 'Number of installments', ...),
```
**After:**
```dart
decoration: InputDecoration(labelText: l10n.numInstallments, ...),
```

### 4.5 Line 123: Description label
**Before:**
```dart
labelText: '${l10n.translate('description')} (${l10n.translate('optional')})',
```
**After:**
```dart
labelText: '${l10n.descriptionKey} (${l10n.optionalKey})',
```

### 4.6 Line 180: Category fallback
**Before:**
```dart
orElse: () => ... const Category(dbValue: 'OTHER', name: 'Other', emoji: '📋')
```
**After:**
```dart
orElse: () => ... Category(dbValue: 'OTHER', name: l10n.translate('income_other'), emoji: '📋')
```

---

## Step 5: Update `lib/features/transactions/edit_expense_bottom_sheet.dart`

Same changes as Step 4 (subcategories map, installments label, description label).

### 5.1 Lines 31-41: Subcategories map → localized method (same as 4.2)

### 5.2 Line 138: Installments label
**Before:**
```dart
decoration: const InputDecoration(labelText: 'Number of installments', ...),
```
**After:**
```dart
decoration: InputDecoration(labelText: l10n.numInstallments, ...),
```

### 5.3 Line 149: Description label
**Before:**
```dart
labelText: '${l10n.translate('description')} (${l10n.translate('optional')})',
```
**After:**
```dart
labelText: '${l10n.descriptionKey} (${l10n.optionalKey})',
```

---

## Step 6: Update `lib/features/transactions/edit_income_bottom_sheet.dart`

### 6.1 Line 83: Invalid amount
**Before:**
```dart
context.showErrorSnackBar('Valor inválido');
```
**After:**
```dart
context.showErrorSnackBar(AppLocalizations.of(context).invalidAmountMsg);
```

### 6.2 Line 112: Income updated
**Before:**
```dart
context.showSuccessSnackBar('Ingresso atualizado');
```
**After:**
```dart
context.showSuccessSnackBar(AppLocalizations.of(context).incomeUpdated);
```

### 6.3 Line 135: Edit income title
**Before:**
```dart
'Editar Ingresso',
```
**After:**
```dart
AppLocalizations.of(context).editIncomeTitle,
```

### 6.4 Line 143: "Tipo"
**Before:**
```dart
Text('Tipo', style: TextStyle(...)),
```
**After:**
```dart
Text(AppLocalizations.of(context).type, style: TextStyle(...)),
```

### 6.5 Line 179: "Valor"
**Before:**
```dart
decoration: const InputDecoration(labelText: 'Valor', prefixText: 'R\$ '),
```
**After:**
```dart
decoration: InputDecoration(labelText: AppLocalizations.of(context).amount, prefixText: 'R\$ '),
```

### 6.6 Line 186: Net value desc
**Before:**
```dart
'Valor líquido (ya descontado INSS/IRRF)',
```
**After:**
```dart
AppLocalizations.of(context).netValueDesc,
```

### 6.7 Line 212: Dependents
**Before:**
```dart
'Dependentes (IRRF)',
```
**After:**
```dart
AppLocalizations.of(context).dependentsLabel,
```

### 6.8 Lines 238, 282: Calculate/use buttons
**Before:**
```dart
const Text('Calcular líquido'),
...
const Text('Usar valor líquido'),
```
**After:**
```dart
Text(AppLocalizations.of(context).calculateNet),
...
Text(AppLocalizations.of(context).useNetValue),
```

### 6.9 Line 263: Salary breakdown
**Before:**
```dart
'Desglose del salario',
```
**After:**
```dart
AppLocalizations.of(context).salaryBreakdown,
```

### 6.10 Lines 271-275: Breakdown labels
**Before:**
```dart
_buildCalcRow('Bruto', ...),
...
_buildCalcRow('Líquido', ...),
```
**After:**
```dart
_buildCalcRow(AppLocalizations.of(context).grossLabel, ...),
...
_buildCalcRow(AppLocalizations.of(context).netLabelInline, ...),
```

### 6.11 Line 296: Notes hint
**Before:**
```dart
decoration: const InputDecoration(labelText: 'Observación (opcional)'),
```
**After:**
```dart
decoration: InputDecoration(labelText: AppLocalizations.of(context).notesHint),
```

### 6.12 Line 310: Save changes
**Before:**
```dart
const Text('Guardar cambios'),
```
**After:**
```dart
Text(AppLocalizations.of(context).saveChanges),
```

---

## Step 7: Update `lib/features/investments/investments_screen.dart`

### 7.1 Line 88: "vs. último mes"
**Before:**
```dart
Text('vs. último mes', ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).vsLastMonth, ...),
```

### 7.2 Lines 92-96: Stat pills
**Before:**
```dart
_StatPill(label: 'CDI Bruto', value: '112%'),
_StatPill(label: 'Fee', value: '0.2%'),
_StatPill(label: 'Riesgo', value: 'Medio'),
```
**After:**
```dart
_StatPill(label: AppLocalizations.of(context).cdiBruto, value: '112%'),
_StatPill(label: AppLocalizations.of(context).feeLabel, value: '0.2%'),
_StatPill(label: AppLocalizations.of(context).riskLabel, value: AppLocalizations.of(context).riskMedium),
```

### 7.3 Line 137: Asset allocation desc
**Before:**
```dart
Text('Distribución estratégica de la cartera', ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).assetAllocationDesc, ...),
```

### 7.4 Line 142: Donut center label
**Before:**
```dart
FarolDonutChart(data: byType, total: total, centerLabel: 'Diversificada'),
```
**After:**
```dart
FarolDonutChart(data: byType, total: total, centerLabel: AppLocalizations.of(context).diversifiedLabel),
```

### 7.5 Lines 170, 175: AI suggestion
**Before:**
```dart
Text('Su cartera tiene baja exposición en ativos imobiliários. Considere FIIs de tijolo.', ...),
...
const Text('Explorar FIIs', ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).aiSuggestionText, ...),
...
Text(AppLocalizations.of(context).exploreFiis, ...),
```

### 7.6 Lines 189-193: Header
**Before:**
```dart
Text('Inversiones', ...),
Text('Detalle por activo', ...),
...
Text('Ver Historial', ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).investments, ...),
Text(AppLocalizations.of(context).detailByAsset, ...),
...
Text(AppLocalizations.of(context).viewHistory, ...),
```

### 7.7 Line 242: Delete background
**Before:**
```dart
Text('Delete', ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).deleteBg, ...),
```

### 7.8 Lines 249-251: Confirm delete
**Before:**
```dart
body: 'Remove "${inv.productName}"? ${l10n.cannotUndo}',
```
**After:**
```dart
body: l10n.removeInstallmentConfirm(inv.productName),
```

### 7.9 Line 300: Return label
**Before:**
```dart
Text('RETURN', ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).returnLabel, ...),
```

---

## Step 8: Update `lib/features/investments/investment_detail_screen.dart`

### 8.1 Line 118: "SALDO ATUAL"
**Before:**
```dart
const Text('SALDO ATUAL', ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).currentBalanceLabelDetail, ...),
```

### 8.2 Line 153: "Posição"
**Before:**
```dart
Text('Posição', ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).positionTitle, ...),
```

### 8.3 Lines 162-166: Stat labels
**Before:**
```dart
_StatLine(label: 'Total investido', ...),
_StatLine(label: 'Saldo atual', ...),
_StatLine(label: 'Rendimento (R\$)', ...),
_StatLine(label: 'Rendimento (%)', ...),
_StatLine(label: 'Data de entrada', ...),
```
**After:**
```dart
_StatLine(label: AppLocalizations.of(context).totalInvestedLabel, ...),
_StatLine(label: AppLocalizations.of(context).currentBalanceInline, ...),
_StatLine(label: AppLocalizations.of(context).returnAmountLabel, ...),
_StatLine(label: AppLocalizations.of(context).returnPercentLabel, ...),
_StatLine(label: AppLocalizations.of(context).dateAddedLabel, ...),
```

### 8.4 Lines 179, 189, 191: Details section
**Before:**
```dart
Text('Detalhes', ...),
...
_StatLine(label: 'Liquidez', ...),
...
_StatLine(label: 'Notas', ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).detailsTitle, ...),
...
_StatLine(label: AppLocalizations.of(context).liquidityLabelDetail, ...),
...
_StatLine(label: AppLocalizations.of(context).notesLabel, ...),
```

### 8.5 Lines 227-235: Liquidity labels
**Before:**
```dart
String _liquidityLabel(String raw) => switch (raw.toUpperCase()) {
  'DAILY' => 'Diária (D+0)',
  'D1' => 'D+1',
  'D30' => 'D+30',
  'D60' => 'D+60',
  'D90' => 'D+90',
  'MATURITY' => 'No vencimento',
  _ => raw,
};
```
**After:**
```dart
String _liquidityLabel(String raw) {
  final l10n = AppLocalizations.of(context);
  return switch (raw.toUpperCase()) {
    'DAILY' => l10n.dailyLiquidity,
    'D1' => 'D+1',
    'D30' => 'D+30',
    'D60' => 'D+60',
    'D90' => 'D+90',
    'MATURITY' => l10n.atMaturity,
    _ => raw,
  };
}
```

### 8.6 Line 210-211: Confirm delete body
**Before:**
```dart
body: 'Remove "${investment.productName}"? ${l10n.cannotUndo}',
```
**After:**
```dart
body: l10n.removeInstallmentConfirm(investment.productName),
```

### 8.7 Line 259: "Evolução do capital"
**Before:**
```dart
Text('Evolução do capital', ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).capitalEvolution, ...),
```

### 8.8 Lines 268, 282: "Investido"/"Atual"
**Before:**
```dart
Text('Investido', ...),
...
Text('Atual', ...),
```
**After:**
```dart
Text(AppLocalizations.of(context).investedLabel, ...),
...
Text(AppLocalizations.of(context).currentLabel, ...),
```

---

## Step 9: Update `lib/features/dashboard/dashboard_screen.dart`

### 9.1 Lines 31-32: Fixed expenses copied snackbar
**Before:**
```dart
'$count gasto${count == 1 ? '' : 's'} fijo${count == 1 ? '' : 's'} copiado${count == 1 ? '' : 's'} del mes anterior',
```
**After:**
```dart
AppLocalizations.of(context).fixedExpensesCopied(count),
```

---

## Verification

After all edits are applied:

```bash
flutter pub get
flutter analyze
flutter test
```

Expected: Zero lint warnings, all tests pass.
