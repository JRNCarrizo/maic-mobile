import 'package:flutter_test/flutter_test.dart';
import 'package:maic_mobile/data/units/channel_inventory_parser.dart';

void main() {
  test('usa requestChannel y no el índice N+1', () {
    final channels = ChannelInventoryParser.parse(const {
      'videoChannels': '2',
      'inventory.channel.0.requestChannel': '1',
      'inventory.channel.0.name': 'Entrada',
      'inventory.channel.1.requestChannel': '2',
      'inventory.channel.1.name': 'Depósito',
    });

    expect(channels, hasLength(2));
    expect(channels[0].requestChannel, 1);
    expect(channels[0].name, 'Entrada');
    expect(channels[1].requestChannel, 2);
    expect(channels[1].name, 'Depósito');
  });

  test('ignora filas sin requestChannel', () {
    final channels = ChannelInventoryParser.parse(const {
      'inventory.channel.0.name': 'Huérfano',
      'inventory.channel.1.requestChannel': '4',
      'inventory.channel.1.name': 'Fondo',
    });

    expect(channels, hasLength(1));
    expect(channels.single.requestChannel, 4);
  });

  test('cámara sin inventario usa canal 1', () {
    final channels = ChannelInventoryParser.parse(
      const {},
      defaultCameraChannel: true,
    );
    expect(channels.single.requestChannel, 1);
  });
}
