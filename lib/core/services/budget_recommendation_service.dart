import 'dart:convert';
import 'package:http/http.dart' as http;

class BudgetContext {
  final double netSalary;
  final Map<String, double> expensesByCategory;
  final Map<String, double> currentGoals;
  final double swileBalance;
  final double healthScore;

  const BudgetContext({
    required this.netSalary,
    required this.expensesByCategory,
    required this.currentGoals,
    required this.swileBalance,
    required this.healthScore,
  });
}

class CategoryRecommendation {
  final String category;
  final double percentage;
  final String reasoning;

  const CategoryRecommendation({
    required this.category,
    required this.percentage,
    required this.reasoning,
  });

  factory CategoryRecommendation.fromJson(Map<String, dynamic> json) =>
      CategoryRecommendation(
        category: json['category'] as String,
        percentage: (json['percentage'] as num).toDouble(),
        reasoning: json['reasoning'] as String? ?? '',
      );
}

class BudgetRecommendation {
  final List<CategoryRecommendation> recommendations;
  final String summary;

  const BudgetRecommendation({
    required this.recommendations,
    required this.summary,
  });

  Map<String, double> get percentageMap =>
      {for (final r in recommendations) r.category: r.percentage};
}

class BudgetRecommendationService {
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-6';
  static const _apiKey =
      String.fromEnvironment('CLAUDE_API_KEY', defaultValue: '');

  Future<BudgetRecommendation> generateRecommendations(
      BudgetContext ctx) async {
    if (_apiKey.isEmpty) throw Exception('CLAUDE_API_KEY not configured');

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 1024,
        'system':
            'You are a personal finance advisor for Brazilian CLT workers. '
                'Recommend monthly budget percentages that sum to exactly 100% for the cash budget. '
                'Exclude food/grocery if Swile balance covers it. '
                'Follow 50/30/20 adapted for Brazil: needs ≤50%, wants ≤30%, savings ≥20%. '
                'Return JSON only: {"recommendations": [{"category": string, "percentage": number, "reasoning": string}], "summary": string}',
        'messages': [
          {'role': 'user', 'content': _buildUserMessage(ctx)},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (body['content'] as List).first as Map<String, dynamic>;
    final text = content['text'] as String;

    // Strip markdown code fences if present
    final jsonStr =
        text.replaceAll(RegExp(r'```(?:json)?\s*|\s*```'), '').trim();
    final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

    return BudgetRecommendation(
      recommendations: (parsed['recommendations'] as List)
          .map((e) =>
              CategoryRecommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: parsed['summary'] as String? ?? '',
    );
  }

  String _buildUserMessage(BudgetContext ctx) {
    final buf = StringBuffer();
    buf.writeln(
        'Net monthly salary: R\$ ${ctx.netSalary.toStringAsFixed(2)}');
    buf.writeln(
        'Swile voucher balance: R\$ ${ctx.swileBalance.toStringAsFixed(2)}');
    buf.writeln(
        'Financial health score: ${ctx.healthScore.toStringAsFixed(1)}/10');
    buf.writeln('\n3-month average monthly expenses by category (BRL):');
    for (final e in ctx.expensesByCategory.entries) {
      buf.writeln('  ${e.key}: R\$ ${e.value.toStringAsFixed(2)}');
    }
    buf.writeln('\nCurrent budget allocations (%):');
    for (final g in ctx.currentGoals.entries) {
      buf.writeln('  ${g.key}: ${g.value.toStringAsFixed(1)}%');
    }
    buf.writeln(
        '\nPlease recommend optimal percentage allocations for all listed categories.');
    return buf.toString();
  }
}
