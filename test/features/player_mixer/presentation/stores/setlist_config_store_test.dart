import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:multitracks_df_pro/core/audio_engine/iaudio_engine_service.dart';
import 'package:multitracks_df_pro/features/player_mixer/domain/entities/music.dart';
import 'package:multitracks_df_pro/features/player_mixer/domain/entities/setlist.dart';
import 'package:multitracks_df_pro/features/player_mixer/domain/entities/setlist_item.dart';
import 'package:multitracks_df_pro/features/player_mixer/domain/entities/track.dart';
import 'package:multitracks_df_pro/features/player_mixer/domain/repositories/imusic_repository.dart';
import 'package:multitracks_df_pro/features/player_mixer/presentation/stores/setlist_config_store.dart';

import 'setlist_config_store_test.mocks.dart';

@GenerateMocks([IAudioEngineService, IMusicRepository])
void main() {
  late SetlistConfigStore store;
  late MockIAudioEngineService mockAudioEngine;
  late MockIMusicRepository mockMusicRepository;

  setUp(() {
    mockAudioEngine = MockIAudioEngineService();
    mockMusicRepository = MockIMusicRepository();
    store = SetlistConfigStore(mockAudioEngine, mockMusicRepository);
  });

  group('SetlistConfigStore', () {
    final track = Track(
      id: 't1',
      name: 'Vocals',
      filePath: 'url',
      duration: const Duration(seconds: 10),
    );
    final music = Music(
      id: 'm1',
      title: 'Song',
      artist: 'Artist',
      bpm: 120,
      timeSignatureNumerator: 4,
      timeSignatureDenominator: 4,
      tracks: [track],
    );
    final item = SetlistItem(
      id: 'i1',
      originalMusic: music,
      transposableTrackIds: ['t1'],
    );
    final setlist = Setlist(
      id: 's1',
      name: 'Setlist',
      description: 'Desc',
      items: [item],
      status: SetlistStatus.draft,
    );

    test('updateItemVolume updates the item in the setlist', () {
      store.init(setlist);
      store.updateItemVolume('i1', 0.8);

      expect(store.currentSetlist!.items.first.volume, 0.8);
    });

    test(
      'updateItemTempo updates the item and calls engine if playing',
      () async {
        store.init(setlist);
        store.playingItemId = 'i1';

        store.updateItemTempo('i1', 1.1);

        expect(store.currentSetlist!.items.first.tempoFactor, 1.1);
        verify(mockAudioEngine.setTrackTempo('t1', 1.1)).called(1);
      },
    );

    test(
      'updateItemTranspose updates the item and calls engine if playing',
      () async {
        store.init(setlist);
        store.playingItemId = 'i1';

        store.updateItemTranspose('i1', 2);

        expect(store.currentSetlist!.items.first.transposeSemitones, 2);
        verify(mockAudioEngine.setTrackPitch('t1', 2)).called(1);
      },
    );

    test('togglePreview loads and plays preview', () async {
      store.init(setlist);

      await store.togglePreview('i1');

      expect(store.playingItemId, 'i1');
      expect(store.isPlaying, true);
      verify(mockAudioEngine.loadPreview([track])).called(1);
      verify(mockAudioEngine.playPreview()).called(1);
    });
  });
}
