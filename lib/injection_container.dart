import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'core/audio_engine/audio_dsp_service.dart';
import 'core/audio_engine/iaudio_engine_service.dart';
import 'core/audio_engine/native_audio_engine.dart';
import 'features/player_mixer/data/models/music_model.dart';
import 'features/player_mixer/data/models/setlist_model.dart';
import 'features/player_mixer/data/repositories/isar_music_repository.dart';
import 'features/player_mixer/domain/repositories/imusic_repository.dart';
import 'features/player_mixer/presentation/stores/create_music_store.dart';
import 'features/player_mixer/presentation/stores/create_setlist_store.dart';
import 'features/player_mixer/presentation/stores/music_library_store.dart';
import 'features/player_mixer/presentation/stores/setlist_library_store.dart';
import 'features/player_mixer/presentation/stores/setlist_config_store.dart';
import 'features/player_mixer/domain/services/setlist_export_service.dart';
import 'features/performance/presentation/stores/performance_list_store.dart';
import 'features/performance/presentation/stores/live_performance_store.dart';

final sl = GetIt.instance; // Service Locator

Future<void> init() async {
  //! Features - Player Mixer
  // Store (receives both repository and audio engine via DI)
  sl.registerFactory(() => CreateMusicStore(sl(), sl()));
  sl.registerFactory(() => MusicLibraryStore(sl()));
  sl.registerFactory(() => SetlistLibraryStore(sl()));
  sl.registerFactory(() => CreateSetlistStore(sl(), sl()));
  sl.registerFactory(() => SetlistConfigStore(sl(), sl(), sl()));
  sl.registerLazySingleton<SetlistExportService>(
    () => SetlistExportService(sl()),
  );
  sl.registerFactory(() => PerformanceListStore(sl()));
  sl.registerFactory(() => LivePerformanceStore(sl(), sl()));

  // Repository
  sl.registerLazySingleton<IMusicRepository>(() => IsarMusicRepository(sl()));

  //! Core
  // Audio Engine — singleton to avoid re-initialising the C++ Oboe engine.
  // registerFactory was causing engine_init(44100) to run on every resolve,
  // which killed active playback when the EQ dialog opened.
  sl.registerLazySingleton<IAudioEngineService>(() => NativeAudioEngine());

  // DSP Service — singleton façade sharing the same engine instance.
  sl.registerLazySingleton<AudioDspService>(() => AudioDspService(sl()));

  //! External
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([
    MusicModelSchema,
    SetlistModelSchema,
  ], directory: dir.path);
  sl.registerSingleton<Isar>(isar);
}
