import 'package:mobx/mobx.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/music.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/imusic_repository.dart';

part 'create_music_store.g.dart';

class CreateMusicStore = CreateMusicStoreBase with _$CreateMusicStore;

abstract class CreateMusicStoreBase with Store {
  final IMusicRepository _repository;
  final Uuid _uuid = const Uuid();

  CreateMusicStoreBase(this._repository);

  @observable
  String title = '';

  @observable
  String artist = '';

  @observable
  String bpm = ''; // Using String for text field binding, convert to int later

  @observable
  String key = '';

  @observable
  int timeSignatureNumerator = 4;

  @observable
  int timeSignatureDenominator = 4;

  @observable
  ObservableList<Track> tracks = ObservableList<Track>();

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  @action
  void setTitle(String value) {
    title = value;
  }

  @action
  void setArtist(String value) {
    artist = value;
  }

  @action
  void setBpm(String value) {
    bpm = value;
  }

  @action
  void setTimeSignatureNumerator(int value) {
    timeSignatureNumerator = value;
  }

  @action
  void setTimeSignatureDenominator(int value) {
    timeSignatureDenominator = value;
  }

  @action
  void setKey(String value) {
    key = value;
  }

  @action
  void addTrack(String name, String filePath, {bool isClick = false}) {
    final newTrack = Track(
      id: _uuid.v4(),
      name: name,
      filePath: filePath,
      volume: 1.0,
      isClick: isClick,
    );
    tracks.add(newTrack);
  }

  @action
  void removeTrack(String trackId) {
    tracks.removeWhere((t) => t.id == trackId);
  }

  @action
  Future<void> saveMusic() async {
    if (title.isEmpty) {
      errorMessage = "Title is required";
      return;
    }

    final bpmInt = int.tryParse(bpm) ?? 0;
    if (bpmInt <= 0) {
      errorMessage = "Valid BPM is required";
      return;
    }

    try {
      isLoading = true;
      errorMessage = null;

      final music = Music(
        id: _uuid.v4(),
        title: title,
        artist: artist,
        bpm: bpmInt,
        timeSignatureNumerator: timeSignatureNumerator,
        timeSignatureDenominator: timeSignatureDenominator,
        key: key,
        tracks: List.from(tracks),
      );

      await _repository.saveMusic(music);

      // Reset form on success
      title = '';
      artist = '';
      bpm = '';
      key = '';
      timeSignatureNumerator = 4;
      timeSignatureDenominator = 4;
      tracks.clear();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
    }
  }
}
