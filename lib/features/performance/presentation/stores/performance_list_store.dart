import 'package:mobx/mobx.dart';
import 'package:multitracks_df_pro/features/player_mixer/domain/entities/setlist.dart';
import 'package:multitracks_df_pro/features/player_mixer/domain/repositories/imusic_repository.dart';

part 'performance_list_store.g.dart';

class PerformanceListStore = PerformanceListStoreBase with _$PerformanceListStore;

abstract class PerformanceListStoreBase with Store {
  final IMusicRepository _musicRepository;

  PerformanceListStoreBase(this._musicRepository);

  @observable
  ObservableList<Setlist> setlists = ObservableList<Setlist>();

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  @action
  Future<void> loadSetlists() async {
    try {
      isLoading = true;
      errorMessage = null;
      final result = await _musicRepository.getAllSetlists();
      setlists.clear();
      setlists.addAll(result);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
    }
  }

  /// Um setlist é 'Rendered' (pronto para o palco) quando todas as tracks
  /// dos itens alterados possuem caminho válido em track.liveFilePath.
  /// Provisório: retorna true apenas se [SetlistStatus.ready]; quando
  /// existir liveFilePath no modelo, avaliar por item/track.
  bool isSetlistRendered(Setlist setlist) {
    return setlist.status == SetlistStatus.ready;
  }
}
