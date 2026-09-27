/// Puerto del reproductor. La implementación (VLC) vive en data/player.
/// No conoce MAIC: solo una URL y el ciclo de vida.
abstract interface class PlayerPort {
  Future<void> play(String streamUrl);
  Future<void> stop();
}
