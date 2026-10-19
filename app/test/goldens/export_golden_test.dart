@Tags(['golden'])
library;

import 'package:bagmitra/features/export/domain/accounts_csv.dart';
import 'package:bagmitra/features/export/presentation/report_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const labels = ExportLabels(
  title: 'हिशोब',
  date: 'तारीख',
  type: 'प्रकार',
  details: 'तपशील',
  amount: 'रक्कम (₹)',
  expenses: 'खर्च',
  income: 'उत्पन्न',
  profit: 'नफा',
  dues: 'खरेदीदारांकडून येणे',
  typeExpense: 'खर्च',
  typeSale: 'विक्री',
  typeSpray: 'फवारणी',
  typeInput: 'खत / निविष्ठा',
  typeLabour: 'मजुरी',
  kg: 'किलो',
);

void main() {
  testWidgets('report_page_mr', (tester) async {
    await initializeDateFormatting('mr');
    tester.view
      ..physicalSize = reportPageSize
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ReportPage(
        title: 'बाग १ · हिशोब',
        lang: 'mr',
        labels: labels,
        pageLabel: '१ / १',
        summary: const [
          ('खर्च', 4000000),
          ('उत्पन्न', 7950000),
          ('नफा', 3950000),
          ('खरेदीदारांकडून येणे', 2950000),
        ],
        lines: [
          (
            date: DateTime(2026, 10, 10),
            type: 'खत / निविष्ठा',
            details: 'युरिया · खत',
            paise: -133000,
          ),
          (
            date: DateTime(2026, 11, 5),
            type: 'मजुरी',
            details: 'सुनीता · निंदणी',
            paise: -40000,
          ),
          (
            date: DateTime(2027, 1, 20),
            type: 'विक्री',
            details: 'कळमेश्वर व्यापारी · २५०० किलो',
            paise: 7950000,
          ),
        ],
      ),
    );
    await expectLater(
      find.byType(ReportPage),
      matchesGoldenFile('report_page_mr.png'),
    );
  });
}
