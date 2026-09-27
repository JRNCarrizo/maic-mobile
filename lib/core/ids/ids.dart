import 'package:uuid/uuid.dart';

import '../constants/maic_constants.dart';

abstract final class Ids {
  static const _uuid = Uuid();

  static String correlationId() => _uuid.v4().replaceAll('-', '');

  static String newInstallationId() =>
      _uuid.v4().replaceAll('-', '').substring(0, 12).toUpperCase();

  static String machineName(String installationId) =>
      '${MaicDefaults.machineNamePrefix}$installationId';
}
