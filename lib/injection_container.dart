import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'core/audio_engine/iaudio_engine_service.dart';
import 'features/player_mixer/data/models/music_model.dart';
import 'features/player_mixer/data/repositories/isar_music_repository.dart';
import 'features/player_mixer/domain/repositories/imusic_repository.dart';
import 'features/player_mixer/presentation/stores/create_music_store.dart';

final sl = GetIt.instance; // Service Locator

Future<void> init() async {
  //! Features - Player Mixer
  // Store (receives both repository and audio engine via DI)
  sl.registerFactory(() => CreateMusicStore(sl(), sl()));

  // Repository
  sl.registerLazySingleton<IMusicRepository>(() => IsarMusicRepository(sl()));

  //! Core
  // Audio Engine — register as lazy singleton.
  // TODO: Replace with the real native implementation when available.
  sl.registerLazySingleton<IAudioEngineService>(() => _NoOpAudioEngine());

  //! External
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([MusicModelSchema], directory: dir.path);
  sl.registerSingleton<Isar>(isar);
}

/// Temporary no-op implementation of the audio engine.
/// Allows the app to compile and run while the native bridge is being developed.
class _NoOpAudioEngine implements IAudioEngineService {
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> seekTo(Duration timestamp) async {}
  @override
  Future<void> loadPreview(List tracks) async {}
  @override
  void playPreview() {}
  @override
  void pausePreview() {}
  @override
  void setTrackVolume(String trackId, double volume) {}
  @override
  void setTrackPan(String trackId, double pan) {}
  @override
  void setTrackMute(String trackId, bool isMuted) {}
  @override
  void setTrackSolo(String trackId, bool isSolo) {}
  @override
  void dispose() {}
}
