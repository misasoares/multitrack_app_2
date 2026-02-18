import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'core/audio_engine/iaudio_engine_service.dart';
import 'core/audio_engine/native_audio_engine.dart';
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
  // Audio Engine — native C++ implementation with Oboe output.
  // Provides low-latency playback with gain smoothing + constant-power panning.
  sl.registerFactory<IAudioEngineService>(() => NativeAudioEngine());

  //! External
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([MusicModelSchema], directory: dir.path);
  sl.registerSingleton<Isar>(isar);
}
