import 'dart:convert';
import 'dart:io';

import 'package:bagmitra/api/api_client.dart';
import 'package:bagmitra/features/bills/data/bill_read_api.dart';
import 'package:bagmitra/features/bills/domain/bill_reading.dart';
import 'package:bagmitra/features/photo_analysis/domain/photo_analysis.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../photo_analysis/photo_analysis_test.dart' show fakeJpeg, json;

/// One bill as the server answers `POST /v1/bills/read`.
String billJson({
  String? shop = 'कृषी सेवा केंद्र',
  String? date = '2026-10-10',
  String? no = '482',
  List<Map<String, Object?>>? items,
  num? total = 2150,
  bool unsure = false,
}) => jsonEncode({
  'shop_name': shop,
  'bill_date': date,
  'bill_no': no,
  'items':
      items ??
      [
        {
          'name': 'Imida 17.8 SL',
          'active_ingredient': 'imidacloprid',
          'quantity': 500,
          'unit': 'ml',
          'amount_rs': 650,
        },
        {
          'name': 'Ridomil Gold',
          'active_ingredient': null,
          'quantity': 1,
          'unit': 'kg',
          'amount_rs': 1500,
        },
      ],
  'total_rs': total,
  'unsure': unsure,
});

String billLimitJson(String kind, {String max = '5', String resets = ''}) =>
    jsonEncode({
      'error': {
        'code': 'bill_read_limit',
        'message': '$kind bill limit reached',
        'details': {'limit': kind, 'max': max, 'resets_at': resets},
      },
    });

/// The bill endpoint as a test wants it to answer; remembers every request.
class FakeBillServer {
  FakeBillServer(this.answer);

  Future<http.Response> Function(http.Request) answer;
  final requests = <http.Request>[];

  late final client = MockClient((r) {
    requests.add(r);
    return answer(r);
  });

  BillReadApi get api => HttpBillReadApi(
    createApi(
      baseUrl: Uri.parse('http://localhost:8000'),
      token: () => 't',
      httpClient: client,
    ),
  );
}

void main() {
  group('the bill API client', () {
    test('sends one multipart photo and reads the answer', () async {
      final server = FakeBillServer((_) async => json(billJson(), 200));
      final bill = await server.api.read(fakeJpeg);
      final r = server.requests.single;
      expect(r.method, 'POST');
      expect(r.url.path, '/v1/bills/read');
      expect(r.headers['authorization'], 'Bearer t');
      expect(r.headers['content-type'], startsWith('multipart/form-data'));
      expect(
        latin1.decode(r.bodyBytes),
        contains('name="photo"; filename="bill.jpg"'),
      );
      expect(bill.shopName, 'कृषी सेवा केंद्र');
      expect(bill.billDate, DateTime(2026, 10, 10));
      expect(bill.billNo, '482');
      expect(bill.totalRs, 2150);
      expect(bill.unsure, isFalse);
      expect(bill.items, hasLength(2));
      expect(bill.items.first.activeIngredient, 'imidacloprid');
      expect(bill.items.first.quantityText, '500 ml');
      expect(bill.items.last.activeIngredient, isNull);
    });

    test('nulls, blanks and nameless lines are read safely', () async {
      final server = FakeBillServer(
        (_) async => json(
          billJson(
            shop: '  ',
            date: null,
            no: null,
            total: null,
            unsure: true,
            items: [
              {'name': ' ', 'amount_rs': 10},
              {'name': 'Neem oil', 'quantity': 1.5, 'unit': null},
            ],
          ),
          200,
        ),
      );
      final bill = await server.api.read(fakeJpeg);
      expect(bill.shopName, isNull);
      expect(bill.billDate, isNull);
      expect(bill.unsure, isTrue);
      expect(bill.items.single.name, 'Neem oil');
      expect(bill.items.single.quantityText, '1.5');
      expect(bill.items.single.amountRs, isNull);
    });

    test('429 is the calm limit with its kind, count and reset', () async {
      final server = FakeBillServer(
        (_) async => json(
          billLimitJson('monthly', max: '50', resets: '2026-11-01T00:00:00Z'),
          429,
        ),
      );
      final e = await server.api
          .read(fakeJpeg)
          .then<Object?>((_) => null, onError: (Object e) => e);
      expect(e, isA<PhotoLimitException>());
      final limit = e! as PhotoLimitException;
      expect(limit.kind, PhotoLimitKind.monthly);
      expect(limit.max, 50);
      expect(limit.resetsAt, DateTime.utc(2026, 11));
    });

    for (final (status, problem) in [
      (503, PhotoProblem.unavailable),
      (502, PhotoProblem.failed),
      (413, PhotoProblem.refused),
      (415, PhotoProblem.refused),
      (401, PhotoProblem.signedOut),
    ]) {
      test('$status is ${problem.name}', () async {
        final server = FakeBillServer((_) async => json('{}', status));
        await expectLater(
          server.api.read(fakeJpeg),
          throwsA(
            isA<PhotoProblemException>().having(
              (e) => e.problem,
              'problem',
              problem,
            ),
          ),
        );
      });
    }

    test('no network is offline; a broken answer is failed', () async {
      final offline = FakeBillServer(
        (_) async => throw const SocketException('no route'),
      );
      await expectLater(
        offline.api.read(fakeJpeg),
        throwsA(
          isA<PhotoProblemException>().having(
            (e) => e.problem,
            'problem',
            PhotoProblem.offline,
          ),
        ),
      );
      final broken = FakeBillServer((_) async => json('[1]', 200));
      await expectLater(
        broken.api.read(fakeJpeg),
        throwsA(
          isA<PhotoProblemException>().having(
            (e) => e.problem,
            'problem',
            PhotoProblem.failed,
          ),
        ),
      );
    });
  });

  group('fill rules', () {
    final bill = BillReading.fromJson(
      jsonDecode(billJson()) as Map<String, dynamic>,
    );
    final first = DateTime(2024);
    final last = DateTime(2027);

    test(
      'spray: an empty form takes name, ingredient, dose, cost and date',
      () {
        final r = sprayFill(
          item: bill.items.first,
          bill: bill,
          current: const {},
          dateIsDefault: true,
          firstDate: first,
          lastDate: last,
        );
        expect(r.fill, {
          BillField.product: 'Imida 17.8 SL',
          BillField.active: 'imidacloprid',
          BillField.dose: '500 ml',
          BillField.cost: '650',
        });
        expect(r.date, DateTime(2026, 10, 10));
      },
    );

    test('spray: typed fields and a picked date are never overwritten', () {
      final r = sprayFill(
        item: bill.items.first,
        bill: bill,
        current: const {BillField.product: 'Confidor', BillField.cost: '700'},
        dateIsDefault: false,
        firstDate: first,
        lastDate: last,
      );
      expect(r.fill, {
        BillField.active: 'imidacloprid',
        BillField.dose: '500 ml',
      });
      expect(r.date, isNull);
    });

    test('spray: an ingredient that was not read is left alone', () {
      final r = sprayFill(
        item: bill.items.last,
        bill: bill,
        current: const {},
        dateIsDefault: true,
        firstDate: first,
        lastDate: last,
      );
      expect(r.fill.containsKey(BillField.active), isFalse);
      expect(r.fill[BillField.dose], '1 kg');
    });

    test('a bill date outside the date picker is not used', () {
      final old = BillReading.fromJson(
        jsonDecode(billJson(date: '2019-01-01')) as Map<String, dynamic>,
      );
      final r = sprayFill(
        item: old.items.first,
        bill: old,
        current: const {},
        dateIsDefault: true,
        firstDate: first,
        lastDate: last,
      );
      expect(r.date, isNull);
    });

    test('expense: the total, the date and the shop / bill number note', () {
      final r = expenseFill(
        item: null,
        bill: bill,
        billLabel: 'कृषी सेवा केंद्र बिल #482',
        current: const {},
        dateIsDefault: true,
        firstDate: first,
        lastDate: last,
      );
      expect(r.fill, {
        BillField.amount: '2150',
        BillField.note: 'कृषी सेवा केंद्र बिल #482',
      });
      expect(r.date, DateTime(2026, 10, 10));
    });

    test('expense: a picked line gives its amount and name; typed stays', () {
      final r = expenseFill(
        item: bill.items.last,
        bill: bill,
        billLabel: 'कृषी सेवा केंद्र बिल #482',
        current: const {BillField.note: 'माझी टीप'},
        dateIsDefault: true,
        firstDate: first,
        lastDate: last,
      );
      expect(r.fill, {BillField.amount: '1500'});
      final empty = expenseFill(
        item: bill.items.last,
        bill: bill,
        billLabel: null,
        current: const {BillField.amount: '99'},
        dateIsDefault: false,
        firstDate: first,
        lastDate: last,
      );
      expect(empty.fill, {BillField.note: 'Ridomil Gold'});
      expect(empty.date, isNull);
    });

    test('rupee and quantity text has no trailing zeros', () {
      expect(rupeesFieldText(1250), '1250');
      expect(rupeesFieldText(12.5), '12.5');
      expect(rupeesFieldText(12.05), '12.05');
    });
  });
}
