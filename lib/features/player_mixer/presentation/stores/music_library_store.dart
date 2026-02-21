import 'package:mobx/mobx.dart';
import '../../domain/entities/music.dart';
import '../../domain/repositories/imusic_repository.dart';
import '../enums/music_sort_type.dart';

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

  @observable
  String searchQuery = '';

  @observable
  MusicSortType sortBy = MusicSortType.dateDesc;

  @observable
  double minDurationFilter = 0.0;

  @observable
  double maxDurationFilter = 20.0; // Default max minutes (adjustable)

  // Use a large number for "no max limit" effectively, or control via UI range
  @computed
  List<Music> get filteredMusicList {
    var list = List<Music>.from(musicList);

    // 1. Filter by Search Query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      list = list.where((music) {
        final title = music.title.toLowerCase();
        final artist = music.artist.toLowerCase();
        return title.contains(query) || artist.contains(query);
      }).toList();
    }

    // 2. Filter by Duration
    // Using minDurationFilter / maxDurationFilter in minutes
    // Only filter if ranges are set to something restrictive?
    // User request: "slider range with 2 points ... to filter by duration"
    // We assume default range handles "all".
    list = list.where((music) {
      final duration = music.tracks.isNotEmpty
          ? music.tracks[0].duration
          : Duration.zero;
      final minutes = duration.inSeconds / 60.0;
      // If max filter is at its max visual value (e.g. 20), treat as infinite?
      // For now, strict range:
      return minutes >= minDurationFilter && minutes <= maxDurationFilter;
    }).toList();

    // 3. Sort
    switch (sortBy) {
      case MusicSortType.dateDesc:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case MusicSortType.dateAsc:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case MusicSortType.alphaAsc: // A-Z
        list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case MusicSortType.alphaDesc: // Z-A
        list.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case MusicSortType.durationDesc:
        list.sort((a, b) {
          final durA = a.tracks.isNotEmpty
              ? a.tracks[0].duration
              : Duration.zero;
          final durB = b.tracks.isNotEmpty
              ? b.tracks[0].duration
              : Duration.zero;
          return durB.compareTo(durA);
        });
        break;
      case MusicSortType.durationAsc:
        list.sort((a, b) {
          final durA = a.tracks.isNotEmpty
              ? a.tracks[0].duration
              : Duration.zero;
          final durB = b.tracks.isNotEmpty
              ? b.tracks[0].duration
              : Duration.zero;
          return durA.compareTo(durB);
        });
        break;
    }

    return list;
  }

  @action
  void setSearchQuery(String value) {
    searchQuery = value;
  }

  @action
  void setSortBy(MusicSortType value) {
    sortBy = value;
  }

  @action
  void setDurationRange(double min, double max) {
    minDurationFilter = min;
    maxDurationFilter = max;
  }

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
