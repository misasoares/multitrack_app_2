import 'package:mobx/mobx.dart';
import '../../domain/entities/music.dart';
import '../../domain/repositories/imusic_repository.dart';

part 'music_library_store.g.dart';

class MusicLibraryStore = MusicLibraryStoreBase with _$MusicLibraryStore;

abstract class MusicLibraryStoreBase with Store {
  final IMusicRepository _repository;

  MusicLibraryStoreBase(this._repository);

  @observable
  ObservableList<Music> musicList = ObservableList<Music>();

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  @action
  Future<void> loadAllMusic() async {
    try {
      isLoading = true;
      errorMessage = null;

      final result = await _repository.getAllMusic();
      musicList.clear();
      musicList.addAll(result);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> deleteMusic(String id) async {
    try {
      isLoading = true;
      errorMessage = null;
      await _repository.deleteMusic(id);
      await loadAllMusic();
    } catch (e) {
      errorMessage = 'Failed to delete music: $e';
    } finally {
      isLoading = false;
    }
  }
}
