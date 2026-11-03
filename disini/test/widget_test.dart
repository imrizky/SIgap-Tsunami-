import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_tsunami_flutter/models/api_record.dart';

void main() {
  test('parses the Laravel paginator response shape', () {
    final records = recordsFrom({
      'current_page': 1,
      'data': [
        {
          'id': 7,
          'title': 'Informasi kesiapsiagaan',
          'message': 'Kenali jalur evakuasi.',
          'severity': 'waspada',
          'type': 'informasi',
        },
      ],
    });

    expect(records, hasLength(1));
    expect(records.single.id, '7');
    expect(records.single.title, 'Informasi kesiapsiagaan');
    expect(records.single.description, 'Kenali jalur evakuasi.');
    expect(records.single.subtitle, 'WASPADA • informasi');
  });

  test('returns an empty list for an empty or unrecognized response', () {
    expect(recordsFrom({'data': []}), isEmpty);
    expect(recordsFrom({'message': 'Tidak tersedia'}), isEmpty);
  });
}
