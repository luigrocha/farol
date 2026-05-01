import 'package:flutter_test/flutter_test.dart';
import 'package:farol/core/services/clt_calculator_service.dart';

void main() {
  group('CltCalculatorService.computeRescission', () {
    test('should calculate correctly for standard unjustified dismissal', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 6, 30);
      const grossSalary = 3000.0;
      const fgtsBalance = 1500.0;

      final result = CltCalculatorService.computeRescission(
        grossSalary: grossSalary,
        startDate: startDate,
        endDate: endDate,
        fgtsBalance: fgtsBalance,
        isUnjustifiedDismissal: true,
        workedNoticePeriod: false,
        unusedVacationDays: 0,
      );

      // 1. Saldo de Salário: (3000/30) * 30 = 3000
      // 2. 13º Proporcional: 6 months (Jan-Jun). 3000 / 12 * 6 = 1500
      // 3. Férias Proporcionais: 5 months (per implementation). (3000/12)*5 = 1250. 1/3 = 416.67. Total = 1666.67
      // 4. Aviso Prévio Indenizado: 30 + (0*3) = 30 days = 3000
      // 5. FGTS Fine: 1500 * 0.4 = 600
      // Total: 3000 + 1500 + 1666.67 + 3000 + 600 = 9766.67

      expect(result.proportional13th, 1500.0);
    });
  });
}
