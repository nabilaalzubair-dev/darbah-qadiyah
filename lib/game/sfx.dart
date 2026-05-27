import 'package:flutter/services.dart';

/// Basic sound cues without external assets.
///
/// You can later replace these with real audio files by uploading them via
/// Dreamflow Assets panel and switching to an audio package.
class GameSfx {
  const GameSfx();

  Future<void> correct() async => SystemSound.play(SystemSoundType.click);
  Future<void> wrong() async => SystemSound.play(SystemSoundType.alert);
  Future<void> warning() async => SystemSound.play(SystemSoundType.alert);
  Future<void> tick() async => SystemSound.play(SystemSoundType.click);
  Future<void> win() async => SystemSound.play(SystemSoundType.alert);
}
