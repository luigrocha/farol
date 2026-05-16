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
      'swile_label': 'Swile',
      'period_budget': 'Period Budget',
      'copy_from_previous': 'Copy from previous period',
      'no_budgets_period': 'No budgets for this period',
      'budgets_hint': 'Add budget goals in Settings to see defaults here',
      'budget_pct_used': '%s% used',
      'budget_pct_over_limit': '%s% over limit',
      'budget_pct_remaining': '%s% remaining',
      'budget_free_up': 'Adjusting this would exceed your 100%% budget limit. Free up %s% first.',
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
      // Health Screen
      'health_screen_title': 'Financial Health',
      'health_sub_scores': 'Breakdown',
      'health_savings_rate_label': 'Savings Rate',
      'health_housing_vs_salary': 'Housing / Salary',
      'health_monthly_balance': 'Monthly Balance',
      'health_emergency_fund_label': 'Emergency Fund',
      'health_installments_vs_salary': 'Installments / Salary',
      'health_history': 'History',
      'health_no_history_yet': 'No history yet',
      'health_error': 'Error: %s',
      'health_emergency_months': '%s months',
      'health_history_subtitle': 'Savings %s%%  ·  Balance %s',
      // Notifications Screen
      'notifications_title': 'Notifications',
      'notifications_subtitle': 'Real-time budget alerts',
      'notifications_all_good': 'All under control',
      'notifications_no_category_over': 'No category exceeds 75% of the budget',
      'notifications_tips': 'Tips',
      'notifications_tip_title': 'Tip of the month',
      'notifications_tip_body': 'Reviewing your budgets by category helps you identify patterns and make better financial decisions.',
      'notifications_level_exceeded': 'Limit exceeded',
      'notifications_level_critical': 'Critical alert',
      'notifications_level_warning': 'Warning',
      'alert_exceeded_body': 'You exceeded the limit of %s in %s. Spent: %s.',
      'alert_critical_body': 'You have used %s of the %s budget (%s of %s).',
      'alert_warning_body': 'You have used %s of the %s budget. Remaining: %s.',
      // Investments Screen
      // Dashboard widgets
      'burn_rate_title': 'Spending velocity',
      'burn_pace_comfortable': 'On track',
      'burn_pace_on_track': 'Watch spending',
      'burn_pace_overspending': 'Over budget',
      'burn_daily_rate_label': 'R\$/day',
      'burn_projection_label': 'Projection at close',
      'burn_days_remaining': 'Days remaining',
      'burn_pace_vs_budget': 'Pace vs budget',
      'liquidity_critical_title': 'Critical liquidity risk',
      'liquidity_high_title': 'Tight week',
      'liquidity_medium_title': 'Watch your commitments',
      'liquidity_days_to_zero': 'Balance expected to zero in %s days',
      'liquidity_obligations_this_week': '%s in %s commitment%s this week',
      'liquidity_check_upcoming': 'Check your upcoming commitments',
      'liquidity_sheet_title': 'This week\'s commitments',
      'liquidity_no_commitments': 'No commitments in the next 7 days.',
      'liquidity_total': 'Total',
      'period_balance_title': 'PERIOD BALANCE',
      'period_projection_closing': 'Projection at close: %s',
      'period_incomes': 'Income',
      'period_expenses': 'Expenses',
      'recurring_card_title': 'Recurring',
      'recurring_pending': 'Pending',
      'recurring_total_expected': 'Total expected',
      'recurring_active_rules': 'Active rules',
      // Recurring screen
      'recurring_screen_title': 'Recurring',
      'recurring_total_monthly': 'Total monthly in recurring',
      'recurring_active_count_one': '%s active recurring',
      'recurring_active_count_other': '%s active recurring rules',
      'recurring_filter_active': 'Active',
      'recurring_filter_paused': 'Paused',
      'recurring_filter_cancelled': 'Cancelled',
      'recurring_status_active': 'Active',
      'recurring_status_paused': 'Paused',
      'recurring_status_cancelled': 'Cancelled',
      'recurring_upcoming_occurrences': 'Upcoming occurrences',
      'recurring_no_pending': 'No pending occurrences',
      'recurring_error': 'Error: %s',
      'recurring_empty_active': 'No active recurring.\nTap + to add one.',
      'recurring_empty_paused': 'No paused recurring rules.',
      'recurring_empty_cancelled': 'No cancelled recurring rules.',
      'recurring_action_edit': 'Edit',
      'recurring_action_pause': 'Pause',
      'recurring_action_resume': 'Resume',
      'recurring_action_cancel': 'Cancel',
      'recurring_cancel_dialog_title': 'Cancel recurring?',
      'recurring_cancel_dialog_body': 'Future occurrences will be removed.',
      'recurring_cancel_dialog_no': 'No',
      'recurring_paused_snack': 'Recurring paused',
      'recurring_resumed_snack': 'Recurring resumed',
      'recurring_cancelled_snack': 'Recurring cancelled',
      // Add/Edit recurring sheet
      'recurring_add_title': 'New recurring',
      'recurring_edit_title': 'Edit recurring',
      'recurring_field_name': 'Name',
      'recurring_field_name_hint': 'E.g.: Netflix, Rent...',
      'recurring_field_amount': 'Amount (R\$)',
      'recurring_field_frequency': 'Frequency',
      'recurring_field_day_of_month': 'Day of month',
      'recurring_field_category': 'Category',
      'recurring_field_category_hint': 'Select',
      'recurring_field_start': 'Start date',
      'recurring_btn_save': 'Save',
      'recurring_btn_create': 'Create recurring',
      'recurring_updated_snack': 'Recurring updated',
      'recurring_created_snack': 'Recurring created',
      // Suggestions screen
      'recurring_suggestions_title': 'Recurring suggestions',
      'recurring_suggestions_subtitle': 'I found patterns in your spending history.\nConfirm the ones that are recurring.',
      'recurring_suggestions_empty': 'No recurring pattern found\nin your history.',
      'recurring_confidence_pct': '%s%% confidence',
      'recurring_btn_ignore': 'Ignore',
      'recurring_btn_confirm': 'Confirm',
      'recurring_confirmed_snack': 'Recurring "%s" created',
      'recurring_occurrences_count': '%s occurrences',
      // investments_vs_last_month
      'investments_vs_last_month': 'vs. last month',
      'investments_strategic_distribution': 'Strategic portfolio distribution',
      'investments_low_exposure': 'Your portfolio has low exposure to real estate assets. Consider brick FIIs.',
      'investments_explore_fiis': 'Explore FIIs',
      'investments_header': 'Investments',
      'investments_detail_by_asset': 'Detail by asset',
      'investments_view_history': 'View History',
      'investments_diversified': 'Diversified',
      // Transactions Screen
      'no_income_this_month': 'No income this month',
      'no_income_hint': 'Tap + to record salary, bonus, etc.',
      'net_value_description': 'Net value (INSS/IRRF already deducted)',
      // Insights
      'insights_label': 'Insights',
      'insights_see_all': 'See all (%s)',
      'insights_subtitle': 'Analyses based on your real data.',
      'insights_group_critical': 'Critical alerts',
      'insights_group_warning': 'Attention',
      'insights_group_info': 'Opportunities',
      'insights_group_achievement': 'Achievements',
      'insights_most_ignored': 'Most ignored types',
      'insights_empty': 'No insights right now.\nKeep recording your expenses!',
      // Insight rule strings
      'insight_overdraft_title': '⚠️ You may close in the red',
      'insight_overdraft_body': 'At the current pace, the period closes at %s. You still have %s in bills to pay.',
      'insight_overdraft_action': 'See projection →',
      'insight_liquidity_critical_title': '🚨 Critical: payments due this week',
      'insight_liquidity_warning_title': '📅 Payments due this week',
      'insight_liquidity_body': 'Your current balance is %s. Check that it covers all due payments before spending.',
      'insight_liquidity_action': 'See commitments →',
      'insight_spike_title': '📈 %s above usual pace',
      'insight_spike_body': 'You spent %s this month — %s%% more than your average of %s. There\'s still time to adjust.',
      'insight_spike_action': 'See %s →',
      'insight_duplicate_title': 'Possible duplicate charge',
      'insight_duplicate_body': '%sx "%s" for R\$ %s in %s day(s).',
      'insight_duplicate_action': 'Check',
      'insight_subscription_title': 'Subscriptions growing',
      'insight_subscription_body': 'Your subscription spending increased R\$ %s over the last 3 months.',
      'insight_subscription_action': 'See subscriptions',
      'insight_savings_title': 'Savings possible in %s',
      'insight_savings_body': '%s is %s over budget. Adjusting could free up that amount per period.',
      'insight_savings_action': 'Adjust budget',
      'insight_invest_title': 'You will have %s left over',
      'insight_invest_body': 'At the current pace, you will have %s free at the end of the period. How about setting some aside?',
      'insight_invest_action': 'See options',
      'insight_streak_title': '%s periods within budget! 🎉',
      'insight_streak_body': 'You have been keeping your finances in check for %s consecutive periods. Keep it up!',
      'insight_debt_title': 'Installments decreasing!',
      'insight_debt_body': 'Your active installments dropped R\$ %s compared to the previous period.',
      'insight_unusual_title': 'New high-value purchase',
      'insight_unusual_body': '"%s" for R\$ %s — first time it appears in your history.',
      'insight_unusual_action': 'See expense',
      // Recurring frequency labels
      'freq_weekly': 'Weekly',
      'freq_biweekly': 'Biweekly',
      'freq_monthly': 'Monthly',
      'freq_quarterly': 'Quarterly',
      'freq_semiannual': 'Semiannual',
      'freq_yearly': 'Yearly',
      // Account types
      'account_type_checking': 'Checking Account',
      'account_type_savings': 'Savings Account',
      'account_type_investment': 'Investment Account',
      'account_type_fgts': 'FGTS',
      // Accounts screen
      'accounts_transfer_tooltip': 'Transfer between accounts',
      'accounts_transfer_need_two': 'Add at least 2 accounts to transfer',
      'accounts_section_bank': 'Bank Accounts',
      'accounts_empty_title': 'No accounts registered',
      'accounts_empty_hint': 'Add your accounts to track\nyour net worth in real time.',
      'accounts_delete_title': 'Delete account?',
      'accounts_delete_body': 'The account "%s" will be removed.',
      'accounts_action_update_balance': 'Update balance',
      'accounts_add_title': 'New Account',
      'accounts_field_name': 'Account name',
      'accounts_field_name_hint': 'e.g. Checking Account',
      'accounts_field_institution': 'Institution',
      'accounts_field_type': 'Account type',
      'accounts_field_initial_balance': 'Initial balance',
      'accounts_update_balance_title': 'Update Balance',
      'accounts_field_current_balance': 'Current balance',
      'accounts_transfer_title': 'Internal Transfer',
      'accounts_transfer_subtitle': 'Does not appear in income/expenses',
      'accounts_transfer_from': 'From',
      'accounts_transfer_to': 'To',
      'accounts_field_description_optional': 'Description (optional)',
      'accounts_btn_transfer': 'Transfer',
      'accounts_transfer_success': 'Transfer registered',
      // Analytics screen
      'analytics_subtitle': 'Your data, analyzed over time.',
      'analytics_avg_per_month': 'AVG/MONTH',
      'analytics_top_category': 'TOP CAT.',
      'analytics_monthly_trend': 'Monthly Trend',
      'analytics_spending_legend': 'Spending',
      'analytics_category_distribution': 'Category Distribution',
      'analytics_monthly_comparison': 'Monthly Comparison',
      // Cashflow chart
      'cashflow_title': 'Cash Flow (90 days)',
      'cashflow_negative_warning': 'Projected balance goes negative at some point',
      'cashflow_legend_real': 'Actual',
      'cashflow_legend_projection': 'Projection',
      'cashflow_legend_commitment': 'Commitment',
      'cashflow_min_balance_label': 'Projected minimum balance: ',
      // Installments screen
      'installments_monthly_commitment': 'MONTHLY COMMITMENT',
      'installments_active_plans': 'ACTIVE PLANS',
      'installments_filter_active': 'Active',
      'installments_filter_completed': 'Completed',
      'installments_filter_all': 'All',
      'installments_per_installment': 'per installment',
      'installments_per_installment_label': 'PER INSTALL.',
      'installments_paid_of': '%s of %s paid',
      'installments_remaining_amount': 'Remaining %s',
      'installments_pct_complete': '%s%% complete',
      'installments_remaining_payments_one': '%s installment left',
      'installments_remaining_payments_other': '%s installments left',
      'installments_btn_complete': 'Complete installments',
      'installments_btn_register_nth': 'Register %s installment paid  •  %s',
      'installments_btn_skip_nth': 'Skip %s installment',
      'installments_btn_delete_plan': 'Delete plan',
      'installments_plan_title': 'Installment plan',
      'installments_delete_confirm': 'Remove "%s"? All installments will be deleted.',
      'installments_completed_snack': '🎉 "%s" completed!',
      'installments_registered_snack': '✅ %s installment registered',
      'installments_skipped_snack': '⏭ %s installment skipped',
      'installments_empty_completed': 'No completed plans yet',
      'installments_empty_active': 'No active installment plans',
      'installments_empty_hint': 'Tap + to add an installment purchase',
      'installments_skipped_label': 'skipped',
      // Add installment sheet
      'installments_add_title': 'New installment purchase',
      'installments_field_description': 'Description *',
      'installments_field_description_hint': 'iPhone 15, Sofa, Laptop...',
      'installments_field_store': 'Store (optional)',
      'installments_field_total': 'Total purchase amount',
      'installments_field_num': 'Number of installments: %s',
      'installments_field_category': 'Category (optional)',
      'installments_no_category': 'No category',
      'installments_field_purchase_date': 'Purchase date',
      'installments_field_first_due': '1st due date',
      'installments_btn_create': 'CREATE INSTALLMENT PLAN',
      'installments_validation_desc': 'Please enter a description',
      'installments_validation_amount': 'Please enter the total purchase amount',
      'installments_created_snack': '✅ Installment plan created',
      'installments_preview': 'Preview',
      'installments_preview_last': 'Last',
      'installments_preview_ends': 'Ends on',
      'installments_preview_rounding_note': '* Last installment adjusted for rounding',
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
      'confirm_password': 'Confirm password',
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
      // Workspace invite
      'invite_share_text': "You're invited to '{name}' on Farol! Join: {link}",
      'invite_share_email_subject': 'Join {name} on Farol',
      'invite_accepting': 'Joining workspace...',
      'invite_success_joined': 'You joined {name}!',
      'invite_error_expired': 'This invite has expired. Ask for a new one.',
      'invite_error_used': 'This invite was already used.',
      'invite_error_member': "You're already a member of this workspace.",
      'invite_error_not_found': 'Invite not found or invalid link.',
      'invite_go_workspace': 'Go to workspace',
      'invite_login_to_accept': 'Log in to accept invite',
      // Onboarding carousel slides
      'onboarding_s1_eyebrow': 'FINANCIAL CLARITY',
      'onboarding_s1_title': 'Know exactly where your money goes',
      'onboarding_s1_f1': 'Smart envelopes per category with real periods',
      'onboarding_s1_f2': 'Visual cashflow — balance at a glance',
      'onboarding_s1_f3': 'Installments and recurring tracked automatically',
      'onboarding_s2_eyebrow': 'PREDICTIVE ENGINE',
      'onboarding_s2_title': 'Know before you run out',
      'onboarding_s2_f1': 'Burn rate — how fast you spend vs. budget',
      'onboarding_s2_f2': '90-day cashflow forecast with obligations',
      'onboarding_s2_f3': 'Smart alerts before your balance drops',
      'onboarding_s3_eyebrow': 'YOUR FINANCIAL OS',
      'onboarding_s3_title': 'Your complete financial system',
      'onboarding_s3_f1': 'Shared workspaces — finances with your family',
      'onboarding_s3_f2': 'Financial health score (0–10) with context',
      'onboarding_s3_f3': 'Built for CLT workers — salary, FGTS, Swile',
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
      'personal_data': 'Personal Data',
      'professional_profile': 'Professional Profile',
      'security': 'Security',
      'job_title': 'Job Title',
      'company': 'Company',
      'monthly_income': 'Monthly Income',
      'phone': 'Phone',
      'cpf_label': 'CPF',
      'verified': 'Verified',
      'change_password': 'Change Password',
      'manage_2fa': 'Manage 2FA',
      'delete_account': 'Delete Account',
      'delete_account_confirm_title': 'Delete account?',
      'delete_account_confirm_body': 'This action is irreversible. All your data will be permanently removed.',
      'delete_account_confirm': 'Yes, delete',
      'change_photo': 'Change Photo',
      'take_photo': 'Take a Selfie',
      'choose_from_gallery': 'Choose from Gallery',
      'uploading_photo': 'Uploading photo...',
      'upload_photo_error': 'Failed to update photo. Try again.',
      'photo': 'Photo',
      'initials': 'Initials',
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
      'swile_label': 'Swile',
      'period_budget': 'Presupuesto de Período',
      'copy_from_previous': 'Copiar del período anterior',
      'no_budgets_period': 'Sin presupuestos para este período',
      'budgets_hint': 'Agrega metas en Ajustes para ver los valores aquí',
      'budget_pct_used': '%s% utilizado',
      'budget_pct_over_limit': '%s% sobre el límite',
      'budget_pct_remaining': '%s% restante',
      'budget_free_up': 'Esto excedería tu límite del 100%%. Libera %s% primero.',
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
      // Health Screen
      'health_screen_title': 'Salud Financiera',
      'health_sub_scores': 'Desglose',
      'health_savings_rate_label': 'Tasa de ahorro',
      'health_housing_vs_salary': 'Vivienda / salario',
      'health_monthly_balance': 'Balance mensual',
      'health_emergency_fund_label': 'Fondo de emergencia',
      'health_installments_vs_salary': 'Parcelas / salario',
      'health_history': 'Historial',
      'health_no_history_yet': 'Sin historial aún',
      'health_error': 'Error: %s',
      'health_emergency_months': '%s meses',
      'health_history_subtitle': 'Ahorro %s%%  ·  Balance %s',
      // Notifications Screen
      'notifications_title': 'Notificaciones',
      'notifications_subtitle': 'Alertas de presupuesto en tiempo real',
      'notifications_all_good': 'Todo bajo control',
      'notifications_no_category_over': 'Ninguna categoría supera el 75% del presupuesto',
      'notifications_tips': 'Tips',
      'notifications_tip_title': 'Consejo del mes',
      'notifications_tip_body': 'Revisar tus presupuestos por categoría te ayuda a identificar patrones y tomar mejores decisiones financieras.',
      'notifications_level_exceeded': 'Límite superado',
      'notifications_level_critical': 'Alerta crítica',
      'notifications_level_warning': 'Aviso',
      'alert_exceeded_body': 'Superaste el límite de %s en %s. Gastado: %s.',
      'alert_critical_body': 'Llevas el %s del presupuesto de %s (%s de %s).',
      'alert_warning_body': 'Ya usaste el %s del presupuesto de %s. Quedan %s.',
      // Investments Screen
      // Dashboard widgets
      'burn_rate_title': 'Velocidad de gasto',
      'burn_pace_comfortable': 'Al ritmo correcto',
      'burn_pace_on_track': 'Atención al ritmo',
      'burn_pace_overspending': 'Ritmo sobre presupuesto',
      'burn_daily_rate_label': 'R\$/día',
      'burn_projection_label': 'Proyección al cierre',
      'burn_days_remaining': 'Días restantes',
      'burn_pace_vs_budget': 'Ritmo vs presupuesto',
      'liquidity_critical_title': 'Riesgo crítico de liquidez',
      'liquidity_high_title': 'Semana ajustada',
      'liquidity_medium_title': 'Atención a los compromisos',
      'liquidity_days_to_zero': 'Saldo previsto para cero en %s días',
      'liquidity_obligations_this_week': '%s en %s compromiso%s esta semana',
      'liquidity_check_upcoming': 'Revisa tus compromisos próximos',
      'liquidity_sheet_title': 'Compromisos de esta semana',
      'liquidity_no_commitments': 'Ningún compromiso en los próximos 7 días.',
      'liquidity_total': 'Total',
      'period_balance_title': 'BALANCE DEL PERÍODO',
      'period_projection_closing': 'Proyección al cierre: %s',
      'period_incomes': 'Ingresos',
      'period_expenses': 'Gastos',
      'recurring_card_title': 'Recurrentes',
      'recurring_pending': 'Pendientes',
      'recurring_total_expected': 'Total previsto',
      'recurring_active_rules': 'Reglas activas',
      // Recurring screen
      'recurring_screen_title': 'Recurrentes',
      'recurring_total_monthly': 'Total mensual en recurrentes',
      'recurring_active_count_one': '%s recurrente activo',
      'recurring_active_count_other': '%s recurrentes activos',
      'recurring_filter_active': 'Activos',
      'recurring_filter_paused': 'Pausados',
      'recurring_filter_cancelled': 'Cancelados',
      'recurring_status_active': 'Activo',
      'recurring_status_paused': 'Pausado',
      'recurring_status_cancelled': 'Cancelado',
      'recurring_upcoming_occurrences': 'Próximas ocurrencias',
      'recurring_no_pending': 'Sin ocurrencias pendientes',
      'recurring_error': 'Error: %s',
      'recurring_empty_active': 'Ningún recurrente activo.\nToca + para agregar uno.',
      'recurring_empty_paused': 'Ningún recurrente pausado.',
      'recurring_empty_cancelled': 'Ningún recurrente cancelado.',
      'recurring_action_edit': 'Editar',
      'recurring_action_pause': 'Pausar',
      'recurring_action_resume': 'Reanudar',
      'recurring_action_cancel': 'Cancelar',
      'recurring_cancel_dialog_title': '¿Cancelar recurrente?',
      'recurring_cancel_dialog_body': 'Las ocurrencias futuras serán eliminadas.',
      'recurring_cancel_dialog_no': 'No',
      'recurring_paused_snack': 'Recurrente pausado',
      'recurring_resumed_snack': 'Recurrente reanudado',
      'recurring_cancelled_snack': 'Recurrente cancelado',
      // Add/Edit recurring sheet
      'recurring_add_title': 'Nuevo recurrente',
      'recurring_edit_title': 'Editar recurrente',
      'recurring_field_name': 'Nombre',
      'recurring_field_name_hint': 'Ej.: Netflix, Alquiler...',
      'recurring_field_amount': 'Monto (R\$)',
      'recurring_field_frequency': 'Frecuencia',
      'recurring_field_day_of_month': 'Día del mes',
      'recurring_field_category': 'Categoría',
      'recurring_field_category_hint': 'Seleccionar',
      'recurring_field_start': 'Fecha de inicio',
      'recurring_btn_save': 'Guardar',
      'recurring_btn_create': 'Crear recurrente',
      'recurring_updated_snack': 'Recurrente actualizado',
      'recurring_created_snack': 'Recurrente creado',
      // Suggestions screen
      'recurring_suggestions_title': 'Sugerencias de recurrentes',
      'recurring_suggestions_subtitle': 'Encontré patrones en tu historial de gastos.\nConfirma los que son recurrentes.',
      'recurring_suggestions_empty': 'Ningún patrón recurrente encontrado\nen tu historial.',
      'recurring_confidence_pct': '%s%% confianza',
      'recurring_btn_ignore': 'Ignorar',
      'recurring_btn_confirm': 'Confirmar',
      'recurring_confirmed_snack': 'Recurrente "%s" creado',
      'recurring_occurrences_count': '%s ocurrencias',
      // investments_vs_last_month
      'investments_vs_last_month': 'vs. último mes',
      'investments_strategic_distribution': 'Distribución estratégica de la cartera',
      'investments_low_exposure': 'Su cartera tiene baja exposición en activos inmobiliarios. Considere FIIs de tijolo.',
      'investments_explore_fiis': 'Explorar FIIs',
      'investments_header': 'Inversiones',
      'investments_detail_by_asset': 'Detalle por activo',
      'investments_view_history': 'Ver Historial',
      'investments_diversified': 'Diversificada',
      // Transactions Screen
      'no_income_this_month': 'Ningún ingreso este mes',
      'no_income_hint': 'Toca + para registrar salario, bonus, etc.',
      'net_value_description': 'Valor neto (INSS/IRRF ya descontado)',
      // Insights
      'insights_label': 'Insights',
      'insights_see_all': 'Ver todos (%s)',
      'insights_subtitle': 'Análisis basados en tus datos reales.',
      'insights_group_critical': 'Alertas críticas',
      'insights_group_warning': 'Atención',
      'insights_group_info': 'Oportunidades',
      'insights_group_achievement': 'Logros',
      'insights_most_ignored': 'Tipos más ignorados',
      'insights_empty': 'Ningún insight por ahora.\n¡Sigue registrando tus gastos!',
      // Insight rule strings
      'insight_overdraft_title': '⚠️ Puedes cerrar el período en rojo',
      'insight_overdraft_body': 'Al ritmo actual, el período cierra en %s. Aún tienes %s en cuentas por pagar.',
      'insight_overdraft_action': 'Ver proyección →',
      'insight_liquidity_critical_title': '🚨 Crítico: pagos vencen esta semana',
      'insight_liquidity_warning_title': '📅 Pagos vencen esta semana',
      'insight_liquidity_body': 'Tu saldo actual es %s. Verifica que cubra todos los vencimientos antes de gastar.',
      'insight_liquidity_action': 'Ver compromisos →',
      'insight_spike_title': '📈 %s por encima del ritmo habitual',
      'insight_spike_body': 'Gastaste %s este mes — %s%% más que tu promedio de %s. Aún hay tiempo para ajustar.',
      'insight_spike_action': 'Ver %s →',
      'insight_duplicate_title': 'Posible cobro duplicado',
      'insight_duplicate_body': '%sx "%s" por R\$ %s en %s día(s).',
      'insight_duplicate_action': 'Verificar',
      'insight_subscription_title': 'Suscripciones creciendo',
      'insight_subscription_body': 'Tu gasto en suscripciones aumentó R\$ %s en los últimos 3 meses.',
      'insight_subscription_action': 'Ver suscripciones',
      'insight_savings_title': 'Ahorro posible en %s',
      'insight_savings_body': '%s está %s por encima del presupuesto. Ajustar podría liberar esa cantidad por período.',
      'insight_savings_action': 'Ajustar presupuesto',
      'insight_invest_title': 'Te sobrarán %s',
      'insight_invest_body': 'Al ritmo actual, tendrás %s libres al final del período. ¿Qué tal destinar una parte?',
      'insight_invest_action': 'Ver opciones',
      'insight_streak_title': '¡%s períodos dentro del presupuesto! 🎉',
      'insight_streak_body': 'Llevas %s períodos consecutivos manteniendo tus finanzas bajo control. ¡Sigue así!',
      'insight_debt_title': '¡Cuotas reduciendo!',
      'insight_debt_body': 'Tus cuotas activas bajaron R\$ %s respecto al período anterior.',
      'insight_unusual_title': 'Nueva compra de alto valor',
      'insight_unusual_body': '"%s" por R\$ %s — primera vez que aparece en tu historial.',
      'insight_unusual_action': 'Ver gasto',
      // Recurring frequency labels
      'freq_weekly': 'Semanal',
      'freq_biweekly': 'Quincenal',
      'freq_monthly': 'Mensual',
      'freq_quarterly': 'Trimestral',
      'freq_semiannual': 'Semestral',
      'freq_yearly': 'Anual',
      // Account types
      'account_type_checking': 'Cuenta Corriente',
      'account_type_savings': 'Cuenta de Ahorros',
      'account_type_investment': 'Cuenta Inversión',
      'account_type_fgts': 'FGTS',
      // Accounts screen
      'accounts_transfer_tooltip': 'Transferencia entre cuentas',
      'accounts_transfer_need_two': 'Agrega al menos 2 cuentas para transferir',
      'accounts_section_bank': 'Cuentas Bancarias',
      'accounts_empty_title': 'Ninguna cuenta registrada',
      'accounts_empty_hint': 'Agrega tus cuentas para seguir\ntu patrimonio en tiempo real.',
      'accounts_delete_title': '¿Eliminar cuenta?',
      'accounts_delete_body': 'La cuenta "%s" será eliminada.',
      'accounts_action_update_balance': 'Actualizar saldo',
      'accounts_add_title': 'Nueva Cuenta',
      'accounts_field_name': 'Nombre de la cuenta',
      'accounts_field_name_hint': 'ej: Cuenta Corriente',
      'accounts_field_institution': 'Institución',
      'accounts_field_type': 'Tipo de cuenta',
      'accounts_field_initial_balance': 'Saldo inicial',
      'accounts_update_balance_title': 'Actualizar Saldo',
      'accounts_field_current_balance': 'Saldo actual',
      'accounts_transfer_title': 'Transferencia Interna',
      'accounts_transfer_subtitle': 'No aparece en ingresos/gastos',
      'accounts_transfer_from': 'De',
      'accounts_transfer_to': 'Para',
      'accounts_field_description_optional': 'Descripción (opcional)',
      'accounts_btn_transfer': 'Transferir',
      'accounts_transfer_success': 'Transferencia registrada',
      // Analytics screen
      'analytics_subtitle': 'Tus datos, analizados a lo largo del tiempo.',
      'analytics_avg_per_month': 'PROM/MES',
      'analytics_top_category': 'TOP CAT.',
      'analytics_monthly_trend': 'Tendencia Mensual',
      'analytics_spending_legend': 'Gasto',
      'analytics_category_distribution': 'Distribución por Categoría',
      'analytics_monthly_comparison': 'Comparativo Mensual',
      // Cashflow chart
      'cashflow_title': 'Flujo de Caja (90 días)',
      'cashflow_negative_warning': 'El saldo proyectado se vuelve negativo en algún punto',
      'cashflow_legend_real': 'Real',
      'cashflow_legend_projection': 'Proyección',
      'cashflow_legend_commitment': 'Compromiso',
      'cashflow_min_balance_label': 'Saldo mínimo proyectado: ',
      // Installments screen
      'installments_monthly_commitment': 'COMPROMISO MENSUAL',
      'installments_active_plans': 'PLANES ACTIVOS',
      'installments_filter_active': 'Activos',
      'installments_filter_completed': 'Completados',
      'installments_filter_all': 'Todos',
      'installments_per_installment': 'por cuota',
      'installments_per_installment_label': 'POR CUOTA',
      'installments_paid_of': '%s de %s pagadas',
      'installments_remaining_amount': 'Restan %s',
      'installments_pct_complete': '%s%% completado',
      'installments_remaining_payments_one': '%s cuota restante',
      'installments_remaining_payments_other': '%s cuotas restantes',
      'installments_btn_complete': 'Completar cuotas',
      'installments_btn_register_nth': 'Registrar %s cuota pagada  •  %s',
      'installments_btn_skip_nth': 'Saltar %s cuota',
      'installments_btn_delete_plan': 'Eliminar plan',
      'installments_plan_title': 'Plan de cuotas',
      'installments_delete_confirm': '¿Eliminar "%s"? Todas las cuotas serán borradas.',
      'installments_completed_snack': '🎉 "%s" ¡completado!',
      'installments_registered_snack': '✅ %s cuota registrada',
      'installments_skipped_snack': '⏭ %s cuota saltada',
      'installments_empty_completed': 'Ningún plan completado aún',
      'installments_empty_active': 'Sin planes de cuotas activos',
      'installments_empty_hint': 'Toca + para añadir una compra en cuotas',
      'installments_skipped_label': 'saltada',
      // Add installment sheet
      'installments_add_title': 'Nueva compra en cuotas',
      'installments_field_description': 'Descripción *',
      'installments_field_description_hint': 'iPhone 15, Sofá, Laptop...',
      'installments_field_store': 'Tienda (opcional)',
      'installments_field_total': 'Valor total de la compra',
      'installments_field_num': 'Número de cuotas: %s',
      'installments_field_category': 'Categoría (opcional)',
      'installments_no_category': 'Sin categoría',
      'installments_field_purchase_date': 'Fecha de compra',
      'installments_field_first_due': '1º vencimiento',
      'installments_btn_create': 'CREAR PLAN DE CUOTAS',
      'installments_validation_desc': 'Ingresa la descripción',
      'installments_validation_amount': 'Ingresa el valor total de la compra',
      'installments_created_snack': '✅ Plan de cuotas creado',
      'installments_preview': 'Vista previa',
      'installments_preview_last': 'Última',
      'installments_preview_ends': 'Termina en',
      'installments_preview_rounding_note': '* Última cuota ajustada por redondeo',
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
      'confirm_password': 'Confirmar contraseña',
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
      // Workspace invite
      'invite_share_text': "Te invito a '{name}' en Farol. Únete: {link}",
      'invite_share_email_subject': 'Únete a {name} en Farol',
      'invite_accepting': 'Uniéndose al workspace...',
      'invite_success_joined': '¡Te uniste a {name}!',
      'invite_error_expired': 'Esta invitación expiró. Pide una nueva.',
      'invite_error_used': 'Esta invitación ya fue usada.',
      'invite_error_member': 'Ya eres miembro de este workspace.',
      'invite_error_not_found': 'Invitación no encontrada o enlace inválido.',
      'invite_go_workspace': 'Ir al workspace',
      'invite_login_to_accept': 'Iniciar sesión para aceptar',
      // Onboarding carousel slides
      'onboarding_s1_eyebrow': 'CLARIDAD FINANCIERA',
      'onboarding_s1_title': 'Sabe exactamente adónde va tu dinero',
      'onboarding_s1_f1': 'Sobres inteligentes por categoría con períodos reales',
      'onboarding_s1_f2': 'Cashflow visual — saldo de un vistazo',
      'onboarding_s1_f3': 'Cuotas y recurrentes seguidos automáticamente',
      'onboarding_s2_eyebrow': 'MOTOR PREDICTIVO',
      'onboarding_s2_title': 'Anticípate antes de quedarte sin saldo',
      'onboarding_s2_f1': 'Burn rate — qué tan rápido gastas vs. presupuesto',
      'onboarding_s2_f2': 'Forecast de 90 días con cuotas y recurrentes',
      'onboarding_s2_f3': 'Alertas inteligentes antes de que el saldo caiga',
      'onboarding_s3_eyebrow': 'TU SISTEMA FINANCIERO',
      'onboarding_s3_title': 'Todo tu ecosistema financiero en un lugar',
      'onboarding_s3_f1': 'Workspaces compartidos con tu familia',
      'onboarding_s3_f2': 'Salud financiera (0–10) con contexto real',
      'onboarding_s3_f3': 'Hecho para CLT — salario, FGTS, beneficios',
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
      'personal_data': 'Datos Personales',
      'professional_profile': 'Perfil Profesional',
      'security': 'Seguridad',
      'job_title': 'Cargo',
      'company': 'Empresa',
      'monthly_income': 'Ingreso Mensual',
      'phone': 'Teléfono',
      'cpf_label': 'CPF',
      'verified': 'Verificado',
      'change_password': 'Cambiar Contraseña',
      'manage_2fa': 'Gestionar 2FA',
      'delete_account': 'Eliminar cuenta',
      'delete_account_confirm_title': '¿Eliminar cuenta?',
      'delete_account_confirm_body': 'Esta acción es irreversible. Todos tus datos serán eliminados permanentemente.',
      'delete_account_confirm': 'Sí, eliminar',
      'change_photo': 'Cambiar Foto',
      'take_photo': 'Tomar Selfie',
      'choose_from_gallery': 'Elegir de la Galería',
      'uploading_photo': 'Subiendo foto...',
      'upload_photo_error': 'Error al actualizar la foto. Inténtalo de nuevo.',
      'photo': 'Foto',
      'initials': 'Iniciales',
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
      // Health Screen
      'health_screen_title': 'Saúde Financeira',
      'health_sub_scores': 'Detalhamento',
      'health_savings_rate_label': 'Taxa de poupança',
      'health_housing_vs_salary': 'Moradia / salário',
      'health_monthly_balance': 'Saldo mensal',
      'health_emergency_fund_label': 'Fundo de emergência',
      'health_installments_vs_salary': 'Parcelas / salário',
      'health_history': 'Histórico',
      'health_no_history_yet': 'Sem histórico ainda',
      'health_error': 'Erro: %s',
      'health_emergency_months': '%s meses',
      'health_history_subtitle': 'Poupança %s%%  ·  Saldo %s',
      // Notifications Screen
      'notifications_title': 'Notificações',
      'notifications_subtitle': 'Alertas de orçamento em tempo real',
      'notifications_all_good': 'Tudo sob controle',
      'notifications_no_category_over': 'Nenhuma categoria supera 75% do orçamento',
      'notifications_tips': 'Dicas',
      'notifications_tip_title': 'Dica do mês',
      'notifications_tip_body': 'Revisar seus orçamentos por categoria ajuda a identificar padrões e tomar melhores decisões financeiras.',
      'notifications_level_exceeded': 'Limite ultrapassado',
      'notifications_level_critical': 'Alerta crítico',
      'notifications_level_warning': 'Aviso',
      'alert_exceeded_body': 'Você ultrapassou o limite de %s em %s. Gasto: %s.',
      'alert_critical_body': 'Você usou %s do orçamento de %s (%s de %s).',
      'alert_warning_body': 'Você usou %s do orçamento de %s. Restam %s.',
      // Investments Screen
      // Dashboard widgets
      'burn_rate_title': 'Velocidade de gasto',
      'burn_pace_comfortable': 'No ritmo certo',
      'burn_pace_on_track': 'Atenção ao ritmo',
      'burn_pace_overspending': 'Ritmo acima do orçamento',
      'burn_daily_rate_label': 'R\$/dia',
      'burn_projection_label': 'Projeção ao fechamento',
      'burn_days_remaining': 'Dias restantes',
      'burn_pace_vs_budget': 'Ritmo vs orçamento',
      'liquidity_critical_title': 'Risco crítico de liquidez',
      'liquidity_high_title': 'Semana apertada',
      'liquidity_medium_title': 'Atenção aos compromissos',
      'liquidity_days_to_zero': 'Saldo previsto para zerar em %s dias',
      'liquidity_obligations_this_week': '%s em %s compromisso%s esta semana',
      'liquidity_check_upcoming': 'Verifique seus compromissos próximos',
      'liquidity_sheet_title': 'Compromissos desta semana',
      'liquidity_no_commitments': 'Nenhum compromisso nos próximos 7 dias.',
      'liquidity_total': 'Total',
      'period_balance_title': 'SALDO DO PERÍODO',
      'period_projection_closing': 'Projeção ao fechamento: %s',
      'period_incomes': 'Receitas',
      'period_expenses': 'Despesas',
      'recurring_card_title': 'Recorrentes',
      'recurring_pending': 'Pendentes',
      'recurring_total_expected': 'Total previsto',
      'recurring_active_rules': 'Regras ativas',
      // Recurring screen
      'recurring_screen_title': 'Recorrentes',
      'recurring_total_monthly': 'Total mensal em recorrentes',
      'recurring_active_count_one': '%s recorrente ativo',
      'recurring_active_count_other': '%s recorrentes ativos',
      'recurring_filter_active': 'Ativos',
      'recurring_filter_paused': 'Pausados',
      'recurring_filter_cancelled': 'Cancelados',
      'recurring_status_active': 'Ativo',
      'recurring_status_paused': 'Pausado',
      'recurring_status_cancelled': 'Cancelado',
      'recurring_upcoming_occurrences': 'Próximas ocorrências',
      'recurring_no_pending': 'Sem ocorrências pendentes',
      'recurring_error': 'Erro: %s',
      'recurring_empty_active': 'Nenhum recorrente ativo.\nToque em + para adicionar.',
      'recurring_empty_paused': 'Nenhum recorrente pausado.',
      'recurring_empty_cancelled': 'Nenhum recorrente cancelado.',
      'recurring_action_edit': 'Editar',
      'recurring_action_pause': 'Pausar',
      'recurring_action_resume': 'Retomar',
      'recurring_action_cancel': 'Cancelar',
      'recurring_cancel_dialog_title': 'Cancelar recorrente?',
      'recurring_cancel_dialog_body': 'As ocorrências futuras serão removidas.',
      'recurring_cancel_dialog_no': 'Não',
      'recurring_paused_snack': 'Recorrente pausado',
      'recurring_resumed_snack': 'Recorrente retomado',
      'recurring_cancelled_snack': 'Recorrente cancelado',
      // Add/Edit recurring sheet
      'recurring_add_title': 'Novo recorrente',
      'recurring_edit_title': 'Editar recorrente',
      'recurring_field_name': 'Nome',
      'recurring_field_name_hint': 'Ex: Netflix, Aluguel...',
      'recurring_field_amount': 'Valor (R\$)',
      'recurring_field_frequency': 'Frequência',
      'recurring_field_day_of_month': 'Dia do mês',
      'recurring_field_category': 'Categoria',
      'recurring_field_category_hint': 'Selecione',
      'recurring_field_start': 'Início',
      'recurring_btn_save': 'Salvar',
      'recurring_btn_create': 'Criar recorrente',
      'recurring_updated_snack': 'Recorrente atualizado',
      'recurring_created_snack': 'Recorrente criado',
      // Suggestions screen
      'recurring_suggestions_title': 'Sugestões de recorrentes',
      'recurring_suggestions_subtitle': 'Identifiquei padrões no seu histórico de gastos.\nConfirme os que forem recorrentes.',
      'recurring_suggestions_empty': 'Nenhum padrão recorrente encontrado\nno seu histórico.',
      'recurring_confidence_pct': '%s%% confiança',
      'recurring_btn_ignore': 'Ignorar',
      'recurring_btn_confirm': 'Confirmar',
      'recurring_confirmed_snack': 'Recorrente "%s" criado',
      'recurring_occurrences_count': '%s ocorrências',
      // investments_vs_last_month
      'investments_vs_last_month': 'vs. mês passado',
      'investments_strategic_distribution': 'Distribuição estratégica da carteira',
      'investments_low_exposure': 'Sua carteira tem baixa exposição em ativos imobiliários. Considere FIIs de tijolo.',
      'investments_explore_fiis': 'Explorar FIIs',
      'investments_header': 'Investimentos',
      'investments_detail_by_asset': 'Detalhe por ativo',
      'investments_view_history': 'Ver Histórico',
      'investments_diversified': 'Diversificada',
      // Transactions Screen
      'no_income_this_month': 'Nenhum ingresso neste mês',
      'no_income_hint': 'Toca + para registrar salário, bônus, etc.',
      'net_value_description': 'Valor líquido (INSS/IRRF já descontado)',
      // Insights
      'insights_label': 'Insights',
      'insights_see_all': 'Ver todos (%s)',
      'insights_subtitle': 'Análises baseadas nos seus dados reais.',
      'insights_group_critical': 'Alertas críticos',
      'insights_group_warning': 'Atenção',
      'insights_group_info': 'Oportunidades',
      'insights_group_achievement': 'Conquistas',
      'insights_most_ignored': 'Tipos mais ignorados',
      'insights_empty': 'Nenhum insight no momento.\nContinue registrando seus gastos!',
      // Insight rule strings
      'insight_overdraft_title': '⚠️ Você pode fechar no vermelho',
      'insight_overdraft_body': 'No ritmo atual, o período fecha em %s. Ainda tem %s em contas a pagar.',
      'insight_overdraft_action': 'Ver projeção →',
      'insight_liquidity_critical_title': '🚨 Crítico: pagamentos vencem esta semana',
      'insight_liquidity_warning_title': '📅 Pagamentos vencem esta semana',
      'insight_liquidity_body': 'Seu saldo atual é %s. Verifique se cobre todos os vencimentos antes de gastar.',
      'insight_liquidity_action': 'Ver compromissos →',
      'insight_spike_title': '📈 %s acima do ritmo habitual',
      'insight_spike_body': 'Você gastou %s este mês — %s%% a mais que sua média de %s. Ainda dá tempo de ajustar.',
      'insight_spike_action': 'Ver %s →',
      'insight_duplicate_title': 'Possível cobrança duplicada',
      'insight_duplicate_body': '%sx "%s" por R\$ %s em %s dia(s).',
      'insight_duplicate_action': 'Verificar',
      'insight_subscription_title': 'Assinaturas crescendo',
      'insight_subscription_body': 'Seus gastos com assinaturas aumentaram R\$ %s nos últimos 3 meses.',
      'insight_subscription_action': 'Ver assinaturas',
      'insight_savings_title': 'Economia possível em %s',
      'insight_savings_body': '%s está %s acima do orçamento. Ajustar pode liberar essa quantia por período.',
      'insight_savings_action': 'Ajustar orçamento',
      'insight_invest_title': 'Você vai sobrar %s',
      'insight_invest_body': 'Com base no ritmo atual, você terá %s livres no final do período. Que tal destinar uma parte?',
      'insight_invest_action': 'Ver opções',
      'insight_streak_title': '%s períodos dentro do orçamento! 🎉',
      'insight_streak_body': 'Você está mantendo suas finanças sob controle por %s períodos consecutivos. Continue assim!',
      'insight_debt_title': 'Parcelas reduzindo!',
      'insight_debt_body': 'Suas parcelas ativas caíram R\$ %s em relação ao período anterior.',
      'insight_unusual_title': 'Nova compra de alto valor',
      'insight_unusual_body': '"%s" por R\$ %s — primeira vez que aparece no seu histórico.',
      'insight_unusual_action': 'Ver gasto',
      // Recurring frequency labels
      'freq_weekly': 'Semanal',
      'freq_biweekly': 'Quinzenal',
      'freq_monthly': 'Mensal',
      'freq_quarterly': 'Trimestral',
      'freq_semiannual': 'Semestral',
      'freq_yearly': 'Anual',
      // Account types
      'account_type_checking': 'Conta Corrente',
      'account_type_savings': 'Poupança',
      'account_type_investment': 'Conta Investimento',
      'account_type_fgts': 'FGTS',
      // Accounts screen
      'accounts_transfer_tooltip': 'Transferência entre contas',
      'accounts_transfer_need_two': 'Adicione ao menos 2 contas para transferir',
      'accounts_section_bank': 'Contas Bancárias',
      'accounts_empty_title': 'Nenhuma conta cadastrada',
      'accounts_empty_hint': 'Adicione suas contas para acompanhar\nseu patrimônio em tempo real.',
      'accounts_delete_title': 'Excluir conta?',
      'accounts_delete_body': 'A conta "%s" será removida.',
      'accounts_action_update_balance': 'Atualizar saldo',
      'accounts_add_title': 'Nova Conta',
      'accounts_field_name': 'Nome da conta',
      'accounts_field_name_hint': 'ex: Conta Corrente',
      'accounts_field_institution': 'Instituição',
      'accounts_field_type': 'Tipo de conta',
      'accounts_field_initial_balance': 'Saldo inicial',
      'accounts_update_balance_title': 'Atualizar Saldo',
      'accounts_field_current_balance': 'Saldo atual',
      'accounts_transfer_title': 'Transferência Interna',
      'accounts_transfer_subtitle': 'Não aparece em receitas/despesas',
      'accounts_transfer_from': 'De',
      'accounts_transfer_to': 'Para',
      'accounts_field_description_optional': 'Descrição (opcional)',
      'accounts_btn_transfer': 'Transferir',
      'accounts_transfer_success': 'Transferência registrada',
      // Analytics screen
      'analytics_subtitle': 'Seus dados, analisados ao longo do tempo.',
      'analytics_avg_per_month': 'MÉDIA/MÊS',
      'analytics_top_category': 'TOP CAT.',
      'analytics_monthly_trend': 'Tendência Mensal',
      'analytics_spending_legend': 'Gasto',
      'analytics_category_distribution': 'Distribuição por Categoria',
      'analytics_monthly_comparison': 'Comparativo Mensal',
      // Cashflow chart
      'cashflow_title': 'Fluxo de Caixa (90 dias)',
      'cashflow_negative_warning': 'Saldo previsto negativo em algum ponto',
      'cashflow_legend_real': 'Real',
      'cashflow_legend_projection': 'Projeção',
      'cashflow_legend_commitment': 'Compromisso',
      'cashflow_min_balance_label': 'Saldo mínimo projetado: ',
      // Installments screen
      'installments_monthly_commitment': 'COMPROMISSO MENSAL',
      'installments_active_plans': 'PLANOS ATIVOS',
      'installments_filter_active': 'Ativos',
      'installments_filter_completed': 'Concluídos',
      'installments_filter_all': 'Todos',
      'installments_per_installment': 'por parcela',
      'installments_per_installment_label': 'POR PARCELA',
      'installments_paid_of': '%s de %s pagas',
      'installments_remaining_amount': 'Restam %s',
      'installments_pct_complete': '%s%% concluído',
      'installments_remaining_payments_one': '%s parcela restante',
      'installments_remaining_payments_other': '%s parcelas restantes',
      'installments_btn_complete': 'Concluir parcelas',
      'installments_btn_register_nth': 'Registrar %sª parcela paga  •  %s',
      'installments_btn_skip_nth': 'Pular %sª parcela',
      'installments_btn_delete_plan': 'Excluir plano',
      'installments_plan_title': 'Plano de parcelas',
      'installments_delete_confirm': 'Remover "%s"? Todas as parcelas serão excluídas.',
      'installments_completed_snack': '🎉 "%s" concluída!',
      'installments_registered_snack': '✅ %sª parcela registrada',
      'installments_skipped_snack': '⏭ %sª parcela pulada',
      'installments_empty_completed': 'Nenhum plano concluído ainda',
      'installments_empty_active': 'Sem planos de parcelas ativos',
      'installments_empty_hint': 'Toque em + para adicionar uma compra parcelada',
      'installments_skipped_label': 'pulada',
      // Add installment sheet
      'installments_add_title': 'Nova compra parcelada',
      'installments_field_description': 'Descrição *',
      'installments_field_description_hint': 'iPhone 15, Sofá, Notebook...',
      'installments_field_store': 'Loja (opcional)',
      'installments_field_total': 'Valor total da compra',
      'installments_field_num': 'Número de parcelas: %s',
      'installments_field_category': 'Categoria (opcional)',
      'installments_no_category': 'Sem categoria',
      'installments_field_purchase_date': 'Data da compra',
      'installments_field_first_due': '1º vencimento',
      'installments_btn_create': 'CRIAR PLANO DE PARCELAS',
      'installments_validation_desc': 'Informe a descrição',
      'installments_validation_amount': 'Informe o valor total da compra',
      'installments_created_snack': '✅ Plano de parcelas criado',
      'installments_preview': 'Prévia',
      'installments_preview_last': 'Última',
      'installments_preview_ends': 'Termina em',
      'installments_preview_rounding_note': '* Última parcela ajustada por arredondamento',
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
      'confirm_password': 'Confirmar senha',
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
      // Workspace invite
      'invite_share_text': "Te convido para '{name}' no Farol! Acesse: {link}",
      'invite_share_email_subject': 'Junte-se a {name} no Farol',
      'invite_accepting': 'Entrando no workspace...',
      'invite_success_joined': 'Você entrou em {name}!',
      'invite_error_expired': 'Este convite expirou. Peça um novo.',
      'invite_error_used': 'Este convite já foi usado.',
      'invite_error_member': 'Você já é membro deste workspace.',
      'invite_error_not_found': 'Convite não encontrado ou link inválido.',
      'invite_go_workspace': 'Ir para o workspace',
      'invite_login_to_accept': 'Entrar para aceitar o convite',
      // Onboarding carousel slides
      'onboarding_s1_eyebrow': 'CLAREZA FINANCEIRA',
      'onboarding_s1_title': 'Saiba exatamente para onde vai seu dinheiro',
      'onboarding_s1_f1': 'Envelopes inteligentes por categoria com períodos reais',
      'onboarding_s1_f2': 'Cashflow visual — saldo de um olhar',
      'onboarding_s1_f3': 'Parcelas e recorrentes rastreados automaticamente',
      'onboarding_s2_eyebrow': 'MOTOR PREDITIVO',
      'onboarding_s2_title': 'Antecipe-se antes de ficar sem saldo',
      'onboarding_s2_f1': 'Burn rate — o quão rápido você gasta vs. orçamento',
      'onboarding_s2_f2': 'Forecast de 90 dias com parcelas e recorrentes',
      'onboarding_s2_f3': 'Alertas inteligentes antes do saldo cair',
      'onboarding_s3_eyebrow': 'SEU SISTEMA FINANCEIRO',
      'onboarding_s3_title': 'Todo seu ecossistema financeiro em um lugar',
      'onboarding_s3_f1': 'Workspaces compartilhados com sua família',
      'onboarding_s3_f2': 'Saúde financeira (0–10) com contexto real',
      'onboarding_s3_f3': 'Feito para CLT — salário, FGTS, Swile',
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
      'personal_data': 'Dados Pessoais',
      'professional_profile': 'Perfil Profissional',
      'security': 'Segurança',
      'job_title': 'Cargo',
      'company': 'Empresa',
      'monthly_income': 'Renda Mensal',
      'phone': 'Telefone',
      'cpf_label': 'CPF',
      'verified': 'Verificado',
      'change_password': 'Alterar Senha',
      'manage_2fa': 'Gerenciar 2FA',
      'delete_account': 'Excluir conta',
      'delete_account_confirm_title': 'Excluir conta?',
      'delete_account_confirm_body': 'Esta ação é irreversível. Todos os seus dados serão permanentemente removidos.',
      'delete_account_confirm': 'Sim, excluir',
      'change_photo': 'Alterar Foto',
      'take_photo': 'Tirar Selfie',
      'choose_from_gallery': 'Escolher da Galeria',
      'uploading_photo': 'Enviando foto...',
      'upload_photo_error': 'Falha ao atualizar a foto. Tente novamente.',
      'photo': 'Foto',
      'initials': 'Iniciais',
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
  // Health Screen
  String get healthScreenTitle => translate('health_screen_title');
  String get healthSubScores => translate('health_sub_scores');
  String get healthSavingsRateLabel => translate('health_savings_rate_label');
  String get healthHousingVsSalary => translate('health_housing_vs_salary');
  String get healthMonthlyBalance => translate('health_monthly_balance');
  String get healthEmergencyFundLabel => translate('health_emergency_fund_label');
  String get healthInstallmentsVsSalary => translate('health_installments_vs_salary');
  String get healthHistory => translate('health_history');
  String get healthNoHistoryYet => translate('health_no_history_yet');
  String healthError(String e) => translate('health_error').replaceFirst('%s', e);
  String healthEmergencyMonths(String months) => translate('health_emergency_months').replaceFirst('%s', months);
  String healthHistorySubtitle(String savings, String balance) =>
      translate('health_history_subtitle').replaceFirst('%s', savings).replaceFirst('%s', balance);
  // Notifications Screen
  String get notificationsTitle => translate('notifications_title');
  String get notificationsSubtitle => translate('notifications_subtitle');
  String get notificationsAllGood => translate('notifications_all_good');
  String get notificationsNoCategoryOver => translate('notifications_no_category_over');
  String get notificationsTips => translate('notifications_tips');
  String get notificationsTipTitle => translate('notifications_tip_title');
  String get notificationsTipBody => translate('notifications_tip_body');
  String get notificationsLevelExceeded => translate('notifications_level_exceeded');
  String get notificationsLevelCritical => translate('notifications_level_critical');
  String get notificationsLevelWarning => translate('notifications_level_warning');
  String alertExceededBody(String limit, String category, String spent) =>
      translate('alert_exceeded_body').replaceFirst('%s', limit).replaceFirst('%s', category).replaceFirst('%s', spent);
  String alertCriticalBody(String pct, String category, String spent, String limit) =>
      translate('alert_critical_body').replaceFirst('%s', pct).replaceFirst('%s', category).replaceFirst('%s', spent).replaceFirst('%s', limit);
  String alertWarningBody(String pct, String category, String remaining) =>
      translate('alert_warning_body').replaceFirst('%s', pct).replaceFirst('%s', category).replaceFirst('%s', remaining);
  // Investments Screen
  String get investmentsVsLastMonth => translate('investments_vs_last_month');
  String get investmentsStrategicDistribution => translate('investments_strategic_distribution');
  String get investmentsLowExposure => translate('investments_low_exposure');
  String get investmentsExploreFiis => translate('investments_explore_fiis');
  String get investmentsHeader => translate('investments_header');
  String get investmentsDetailByAsset => translate('investments_detail_by_asset');
  String get investmentsViewHistory => translate('investments_view_history');
  String get investmentsDiversified => translate('investments_diversified');
  // Dashboard widgets
  String get burnRateTitle => translate('burn_rate_title');
  String get burnPaceComfortable => translate('burn_pace_comfortable');
  String get burnPaceOnTrack => translate('burn_pace_on_track');
  String get burnPaceOverspending => translate('burn_pace_overspending');
  String get burnDailyRateLabel => translate('burn_daily_rate_label');
  String get burnProjectionLabel => translate('burn_projection_label');
  String get burnDaysRemaining => translate('burn_days_remaining');
  String get burnPaceVsBudget => translate('burn_pace_vs_budget');
  String get liquidityCriticalTitle => translate('liquidity_critical_title');
  String get liquidityHighTitle => translate('liquidity_high_title');
  String get liquidityMediumTitle => translate('liquidity_medium_title');
  String liquidityDaysToZero(String days) => translate('liquidity_days_to_zero').replaceFirst('%s', days);
  String liquidityObligationsThisWeek(String amount, int count) {
    final plural = count == 1 ? '' : 's';
    return translate('liquidity_obligations_this_week')
        .replaceFirst('%s', amount)
        .replaceFirst('%s', '$count')
        .replaceFirst('%s', plural);
  }
  String get liquidityCheckUpcoming => translate('liquidity_check_upcoming');
  String get liquiditySheetTitle => translate('liquidity_sheet_title');
  String get liquidityNoCommitments => translate('liquidity_no_commitments');
  String get liquidityTotal => translate('liquidity_total');
  String get periodBalanceTitle => translate('period_balance_title');
  String periodProjectionClosing(String amount) => translate('period_projection_closing').replaceFirst('%s', amount);
  String get periodIncomes => translate('period_incomes');
  String get periodExpenses => translate('period_expenses');
  String get recurringCardTitle => translate('recurring_card_title');
  String get recurringPending => translate('recurring_pending');
  String get recurringTotalExpected => translate('recurring_total_expected');
  String get recurringActiveRules => translate('recurring_active_rules');
  // Recurring screen
  String get recurringScreenTitle => translate('recurring_screen_title');
  String get recurringTotalMonthly => translate('recurring_total_monthly');
  String recurringActiveCount(int n) => n == 1
      ? translate('recurring_active_count_one').replaceFirst('%s', '$n')
      : translate('recurring_active_count_other').replaceFirst('%s', '$n');
  String get recurringFilterActive => translate('recurring_filter_active');
  String get recurringFilterPaused => translate('recurring_filter_paused');
  String get recurringFilterCancelled => translate('recurring_filter_cancelled');
  String get recurringStatusActive => translate('recurring_status_active');
  String get recurringStatusPaused => translate('recurring_status_paused');
  String get recurringStatusCancelled => translate('recurring_status_cancelled');
  String get recurringUpcomingOccurrences => translate('recurring_upcoming_occurrences');
  String get recurringNoPending => translate('recurring_no_pending');
  String recurringError(String e) => translate('recurring_error').replaceFirst('%s', e);
  String get recurringEmptyActive => translate('recurring_empty_active');
  String get recurringEmptyPaused => translate('recurring_empty_paused');
  String get recurringEmptyCancelled => translate('recurring_empty_cancelled');
  String get recurringActionEdit => translate('recurring_action_edit');
  String get recurringActionPause => translate('recurring_action_pause');
  String get recurringActionResume => translate('recurring_action_resume');
  String get recurringActionCancel => translate('recurring_action_cancel');
  String get recurringCancelDialogTitle => translate('recurring_cancel_dialog_title');
  String get recurringCancelDialogBody => translate('recurring_cancel_dialog_body');
  String get recurringCancelDialogNo => translate('recurring_cancel_dialog_no');
  String get recurringPausedSnack => translate('recurring_paused_snack');
  String get recurringResumedSnack => translate('recurring_resumed_snack');
  String get recurringCancelledSnack => translate('recurring_cancelled_snack');
  // Add/Edit recurring sheet
  String get recurringAddTitle => translate('recurring_add_title');
  String get recurringEditTitle => translate('recurring_edit_title');
  String get recurringFieldName => translate('recurring_field_name');
  String get recurringFieldNameHint => translate('recurring_field_name_hint');
  String get recurringFieldAmount => translate('recurring_field_amount');
  String get recurringFieldFrequency => translate('recurring_field_frequency');
  String get recurringFieldDayOfMonth => translate('recurring_field_day_of_month');
  String get recurringFieldCategory => translate('recurring_field_category');
  String get recurringFieldCategoryHint => translate('recurring_field_category_hint');
  String get recurringFieldStart => translate('recurring_field_start');
  String get recurringBtnSave => translate('recurring_btn_save');
  String get recurringBtnCreate => translate('recurring_btn_create');
  String get recurringUpdatedSnack => translate('recurring_updated_snack');
  String get recurringCreatedSnack => translate('recurring_created_snack');
  // Suggestions screen
  String get recurringSuggestionsTitle => translate('recurring_suggestions_title');
  String get recurringSuggestionsSubtitle => translate('recurring_suggestions_subtitle');
  String get recurringSuggestionsEmpty => translate('recurring_suggestions_empty');
  String recurringConfidencePct(int pct) => translate('recurring_confidence_pct').replaceFirst('%s', '$pct');
  String get recurringBtnIgnore => translate('recurring_btn_ignore');
  String get recurringBtnConfirm => translate('recurring_btn_confirm');
  String recurringConfirmedSnack(String name) => translate('recurring_confirmed_snack').replaceFirst('%s', name);
  String recurringOccurrencesCount(int n) => translate('recurring_occurrences_count').replaceFirst('%s', '$n');
  // Insights
  String get insightsLabel => translate('insights_label');
  String insightsSeeAll(int n) => translate('insights_see_all').replaceFirst('%s', '$n');
  String get insightsSubtitle => translate('insights_subtitle');
  String get insightsGroupCritical => translate('insights_group_critical');
  String get insightsGroupWarning => translate('insights_group_warning');
  String get insightsGroupInfo => translate('insights_group_info');
  String get insightsGroupAchievement => translate('insights_group_achievement');
  String get insightsMostIgnored => translate('insights_most_ignored');
  String get insightsEmpty => translate('insights_empty');
  // Insight rule strings
  String get insightOverdraftTitle => translate('insight_overdraft_title');
  String insightOverdraftBody(String closing, String obligations) =>
      translate('insight_overdraft_body').replaceFirst('%s', closing).replaceFirst('%s', obligations);
  String get insightOverdraftAction => translate('insight_overdraft_action');
  String get insightLiquidityCriticalTitle => translate('insight_liquidity_critical_title');
  String get insightLiquidityWarningTitle => translate('insight_liquidity_warning_title');
  String insightLiquidityBody(String balance, String obligations) =>
      translate('insight_liquidity_body').replaceFirst('%s', balance).replaceFirst('%s', obligations);
  String get insightLiquidityAction => translate('insight_liquidity_action');
  String insightSpikeTitle(String category) => translate('insight_spike_title').replaceFirst('%s', category);
  // Template: "You spent %s this month — %s%% more than your average of %s."
  // Order: current, pct, average
  String insightSpikeBody(String current, String average, String pct) =>
      translate('insight_spike_body').replaceFirst('%s', current).replaceFirst('%s', pct).replaceFirst('%s', average);
  String insightSpikeAction(String category) => translate('insight_spike_action').replaceFirst('%s', category);
  String get insightDuplicateTitle => translate('insight_duplicate_title');
  String insightDuplicateBody(String count, String desc, String amount, String days) =>
      translate('insight_duplicate_body').replaceFirst('%s', count).replaceFirst('%s', desc).replaceFirst('%s', amount).replaceFirst('%s', days);
  String get insightDuplicateAction => translate('insight_duplicate_action');
  String get insightSubscriptionTitle => translate('insight_subscription_title');
  String insightSubscriptionBody(String growth) => translate('insight_subscription_body').replaceFirst('%s', growth);
  String get insightSubscriptionAction => translate('insight_subscription_action');
  String insightSavingsTitle(String category) => translate('insight_savings_title').replaceFirst('%s', category);
  String insightSavingsBody(String category, String overspent) =>
      translate('insight_savings_body').replaceFirst('%s', category).replaceFirst('%s', overspent);
  String get insightSavingsAction => translate('insight_savings_action');
  String insightInvestTitle(String amount) => translate('insight_invest_title').replaceFirst('%s', amount);
  String insightInvestBody(String amount) => translate('insight_invest_body').replaceFirst('%s', amount);
  String get insightInvestAction => translate('insight_invest_action');
  String insightStreakTitle(int n) => translate('insight_streak_title').replaceFirst('%s', '$n');
  String insightStreakBody(int n) => translate('insight_streak_body').replaceFirst('%s', '$n');
  String get insightDebtTitle => translate('insight_debt_title');
  String insightDebtBody(String reduction) => translate('insight_debt_body').replaceFirst('%s', reduction);
  String get insightUnusualTitle => translate('insight_unusual_title');
  String insightUnusualBody(String desc, String amount) =>
      translate('insight_unusual_body').replaceFirst('%s', desc).replaceFirst('%s', amount);
  String get insightUnusualAction => translate('insight_unusual_action');
  // Recurring frequency labels
  String get freqWeekly => translate('freq_weekly');
  String get freqBiweekly => translate('freq_biweekly');
  String get freqMonthly => translate('freq_monthly');
  String get freqQuarterly => translate('freq_quarterly');
  String get freqSemiannual => translate('freq_semiannual');
  String get freqYearly => translate('freq_yearly');
  // Account types
  String get accountTypeChecking => translate('account_type_checking');
  String get accountTypeSavings => translate('account_type_savings');
  String get accountTypeInvestment => translate('account_type_investment');
  String get accountTypeFgts => translate('account_type_fgts');
  // Accounts screen
  String get accountsTransferTooltip => translate('accounts_transfer_tooltip');
  String get accountsTransferNeedTwo => translate('accounts_transfer_need_two');
  String get accountsSectionBank => translate('accounts_section_bank');
  String get accountsEmptyTitle => translate('accounts_empty_title');
  String get accountsEmptyHint => translate('accounts_empty_hint');
  String get accountsDeleteTitle => translate('accounts_delete_title');
  String accountsDeleteBody(String name) => translate('accounts_delete_body').replaceFirst('%s', name);
  String get accountsActionUpdateBalance => translate('accounts_action_update_balance');
  String get accountsAddTitle => translate('accounts_add_title');
  String get accountsFieldName => translate('accounts_field_name');
  String get accountsFieldNameHint => translate('accounts_field_name_hint');
  String get accountsFieldInstitution => translate('accounts_field_institution');
  String get accountsFieldType => translate('accounts_field_type');
  String get accountsFieldInitialBalance => translate('accounts_field_initial_balance');
  String get accountsUpdateBalanceTitle => translate('accounts_update_balance_title');
  String get accountsFieldCurrentBalance => translate('accounts_field_current_balance');
  String get accountsTransferTitle => translate('accounts_transfer_title');
  String get accountsTransferSubtitle => translate('accounts_transfer_subtitle');
  String get accountsTransferFrom => translate('accounts_transfer_from');
  String get accountsTransferTo => translate('accounts_transfer_to');
  String get accountsFieldDescriptionOptional => translate('accounts_field_description_optional');
  String get accountsBtnTransfer => translate('accounts_btn_transfer');
  String get accountsTransferSuccess => translate('accounts_transfer_success');
  // Analytics screen
  String get analyticsSubtitle => translate('analytics_subtitle');
  String get analyticsAvgPerMonth => translate('analytics_avg_per_month');
  String get analyticsTopCategory => translate('analytics_top_category');
  String get analyticsMonthlyTrend => translate('analytics_monthly_trend');
  String get analyticsSpendingLegend => translate('analytics_spending_legend');
  String get analyticsCategoryDistribution => translate('analytics_category_distribution');
  String get analyticsMonthlyComparison => translate('analytics_monthly_comparison');
  // Cashflow chart
  String get cashflowTitle => translate('cashflow_title');
  String get cashflowNegativeWarning => translate('cashflow_negative_warning');
  String get cashflowLegendReal => translate('cashflow_legend_real');
  String get cashflowLegendProjection => translate('cashflow_legend_projection');
  String get cashflowLegendCommitment => translate('cashflow_legend_commitment');
  String get cashflowMinBalanceLabel => translate('cashflow_min_balance_label');
  // Installments screen
  String get installmentsMonthlyCommitment => translate('installments_monthly_commitment');
  String get installmentsActivePlans => translate('installments_active_plans');
  String get installmentsFilterActive => translate('installments_filter_active');
  String get installmentsFilterCompleted => translate('installments_filter_completed');
  String get installmentsFilterAll => translate('installments_filter_all');
  String get installmentsPerInstallment => translate('installments_per_installment');
  String get installmentsPerInstallmentLabel => translate('installments_per_installment_label');
  String installmentsPaidOf(int paid, int total) =>
      translate('installments_paid_of').replaceFirst('%s', '$paid').replaceFirst('%s', '$total');
  String installmentsRemainingAmount(String amount) =>
      translate('installments_remaining_amount').replaceFirst('%s', amount);
  String installmentsPctComplete(int pct) =>
      translate('installments_pct_complete').replaceFirst('%s', '$pct');
  String installmentsRemainingPayments(int n) => n == 1
      ? translate('installments_remaining_payments_one').replaceFirst('%s', '$n')
      : translate('installments_remaining_payments_other').replaceFirst('%s', '$n');
  String get installmentsBtnComplete => translate('installments_btn_complete');
  String installmentsBtnRegisterNth(String nth, String amount) =>
      translate('installments_btn_register_nth').replaceFirst('%s', nth).replaceFirst('%s', amount);
  String installmentsBtnSkipNth(String nth) =>
      translate('installments_btn_skip_nth').replaceFirst('%s', nth);
  String get installmentsBtnDeletePlan => translate('installments_btn_delete_plan');
  String get installmentsPlanTitle => translate('installments_plan_title');
  String installmentsDeleteConfirm(String name) =>
      translate('installments_delete_confirm').replaceFirst('%s', name);
  String installmentsCompletedSnack(String name) =>
      translate('installments_completed_snack').replaceFirst('%s', name);
  String installmentsRegisteredSnack(String nth) =>
      translate('installments_registered_snack').replaceFirst('%s', nth);
  String installmentsSkippedSnack(String nth) =>
      translate('installments_skipped_snack').replaceFirst('%s', nth);
  String get installmentsEmptyCompleted => translate('installments_empty_completed');
  String get installmentsEmptyActive => translate('installments_empty_active');
  String get installmentsEmptyHint => translate('installments_empty_hint');
  String get installmentsSkippedLabel => translate('installments_skipped_label');
  // Add installment sheet
  String get installmentsAddTitle => translate('installments_add_title');
  String get installmentsFieldDescription => translate('installments_field_description');
  String get installmentsFieldDescriptionHint => translate('installments_field_description_hint');
  String get installmentsFieldStore => translate('installments_field_store');
  String get installmentsFieldTotal => translate('installments_field_total');
  String installmentsFieldNum(int n) =>
      translate('installments_field_num').replaceFirst('%s', '$n');
  String get installmentsFieldCategory => translate('installments_field_category');
  String get installmentsNoCategory => translate('installments_no_category');
  String get installmentsFieldPurchaseDate => translate('installments_field_purchase_date');
  String get installmentsFieldFirstDue => translate('installments_field_first_due');
  String get installmentsBtnCreate => translate('installments_btn_create');
  String get installmentsValidationDesc => translate('installments_validation_desc');
  String get installmentsValidationAmount => translate('installments_validation_amount');
  String get installmentsCreatedSnack => translate('installments_created_snack');
  String get installmentsPreview => translate('installments_preview');
  String get installmentsPreviewLast => translate('installments_preview_last');
  String get installmentsPreviewEnds => translate('installments_preview_ends');
  String get installmentsPreviewRoundingNote => translate('installments_preview_rounding_note');
  // Transactions Screen
  String get noIncomeThisMonth => translate('no_income_this_month');
  String get noIncomeHint => translate('no_income_hint');
  String get netValueDescription => translate('net_value_description');
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
  // Workspace invite
  String inviteShareText(String name, String link) =>
      translate('invite_share_text').replaceAll('{name}', name).replaceAll('{link}', link);
  String inviteShareEmailSubject(String name) =>
      translate('invite_share_email_subject').replaceAll('{name}', name);
  String get inviteAccepting => translate('invite_accepting');
  String inviteSuccessJoined(String name) =>
      translate('invite_success_joined').replaceAll('{name}', name);
  String get inviteErrorExpired => translate('invite_error_expired');
  String get inviteErrorUsed => translate('invite_error_used');
  String get inviteErrorMember => translate('invite_error_member');
  String get inviteErrorNotFound => translate('invite_error_not_found');
  String get inviteGoWorkspace => translate('invite_go_workspace');
  String get inviteLoginToAccept => translate('invite_login_to_accept');
  // Onboarding carousel slides
  String get onboardingS1Eyebrow => translate('onboarding_s1_eyebrow');
  String get onboardingS1Title => translate('onboarding_s1_title');
  String get onboardingS1F1 => translate('onboarding_s1_f1');
  String get onboardingS1F2 => translate('onboarding_s1_f2');
  String get onboardingS1F3 => translate('onboarding_s1_f3');
  String get onboardingS2Eyebrow => translate('onboarding_s2_eyebrow');
  String get onboardingS2Title => translate('onboarding_s2_title');
  String get onboardingS2F1 => translate('onboarding_s2_f1');
  String get onboardingS2F2 => translate('onboarding_s2_f2');
  String get onboardingS2F3 => translate('onboarding_s2_f3');
  String get onboardingS3Eyebrow => translate('onboarding_s3_eyebrow');
  String get onboardingS3Title => translate('onboarding_s3_title');
  String get onboardingS3F1 => translate('onboarding_s3_f1');
  String get onboardingS3F2 => translate('onboarding_s3_f2');
  String get onboardingS3F3 => translate('onboarding_s3_f3');
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
  String get personalData => translate('personal_data');
  String get professionalProfile => translate('professional_profile');
  String get security => translate('security');
  String get jobTitle => translate('job_title');
  String get company => translate('company');
  String get monthlyIncome => translate('monthly_income');
  String get phone => translate('phone');
  String get cpfLabel => translate('cpf_label');
  String get verified => translate('verified');
  String get changePassword => translate('change_password');
  String get manage2fa => translate('manage_2fa');
  String get deleteAccount => translate('delete_account');
  String get deleteAccountConfirmTitle => translate('delete_account_confirm_title');
  String get deleteAccountConfirmBody => translate('delete_account_confirm_body');
  String get deleteAccountConfirm => translate('delete_account_confirm');
  String get changePhoto => translate('change_photo');
  String get takePhoto => translate('take_photo');
  String get chooseFromGallery => translate('choose_from_gallery');
  String get uploadingPhoto => translate('uploading_photo');
  String get uploadPhotoError => translate('upload_photo_error');
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
