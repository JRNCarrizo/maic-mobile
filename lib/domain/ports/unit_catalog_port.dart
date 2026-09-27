import '../../core/endpoint/server_endpoint.dart';
import '../units/unit.dart';
import '../units/video_channel.dart';

abstract interface class UnitCatalogPort {
  Future<List<MaicUnit>> listViewerUnits(ServerEndpoint endpoint);

  Future<List<VideoChannel>> refreshChannels({
    required ServerEndpoint endpoint,
    required String unitId,
    bool defaultCameraChannel = false,
  });
}
