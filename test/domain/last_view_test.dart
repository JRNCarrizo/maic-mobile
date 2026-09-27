import 'package:flutter_test/flutter_test.dart';
import 'package:maic_mobile/domain/layouts/last_view.dart';

void main() {
  test('serializa y versiona layoutJson', () {
    const view = LastView(unitId: '11111111-2222-3333-4444-555555555555');
    final parsed = LastView.tryParse(view.toJsonString());
    expect(parsed?.unitId, view.unitId);
    expect(parsed?.version, 1);
  });

  test('ignora json inválido', () {
    expect(LastView.tryParse('{'), isNull);
    expect(LastView.tryParse('{"v":1}'), isNull);
  });
}
