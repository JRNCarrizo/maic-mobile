abstract final class MaicModules {
  static const viewer = 'MAIC.Module.Viewer';
  static const videoRecorder = 'MAIC.Module.VideoRecorder';
}

abstract final class MaicActions {
  static const refreshDeviceInfo = 'videorecorder.refreshDeviceInfo';
  static const streamOpen = 'videorecorder.stream.open';
  static const streamOpenMany = 'videorecorder.stream.openMany';
  static const streamClose = 'videorecorder.stream.close';
  static const snapshotCapture = 'videorecorder.snapshot.capture';
  static const pulseRelay = 'videorecorder.pulseRelay';
  static const setRelayState = 'videorecorder.setRelayState';
  static const strobeToggle = 'videorecorder.channel.strobe.toggle';
  static const whiteLightToggle = 'videorecorder.channel.whiteLight.toggle';
  static const sirenToggle = 'videorecorder.channel.siren.toggle';
}

abstract final class MaicPaths {
  static const health = '/api/platform/system/health';
  static const capabilities = '/api/platform/system/capabilities';
  static const login = '/api/platform/auth/login';
  static const heartbeat = '/api/session/heartbeat';
  static const release = '/api/session/release';
  static const viewerUnits = '/api/platform/modules/${MaicModules.viewer}/units';
  static const unitActions = '/api/platform/unit-actions/execute';
  static const events = '/api/platform/events';
  static const alarms = '/api/platform/alarms';
  static const platformHub = '/hubs/platform';
  static const layoutList = '/api/platform/module-layouts/list';
  static const layoutSave = '/api/platform/module-layouts/save';
}

abstract final class MaicHeaders {
  static const session = 'X-MAIC-Session';
}

abstract final class MaicDefaults {
  static const apiPort = 5443;
  static const heartbeatInterval = Duration(seconds: 10);
  static const httpTimeout = Duration(seconds: 15);
  static const machineNamePrefix = 'MAIC-Mobile-';
  static const videoTargetMobile = 'mobile';
  static const layoutKindLast = 'viewer.last';
  static const layoutViewKeyLast = 'mobile.last';
  static const demoStreamUrl = 'asset:assets/demo/sample.mp4';
}
