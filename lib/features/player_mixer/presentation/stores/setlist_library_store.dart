import 'package:mobx/mobx.dart';
import '../../domain/entities/setlist.dart';
import '../../domain/repositories/imusic_repository.dart';

part 'setlist_library_store.g.dart';

class SetlistLibraryStore = SetlistLibraryStoreBase with _$SetlistLibraryStore;

abstract class SetlistLibraryStoreBase with Store {
  final IMusicRepository _repository;

  SetlistLibraryStoreBase(this._repository);

  @observable
  ObservableList<Setlist> setlists = ObservableList<Setlist>();

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  @action
  Future<void> loadAllSetlists() async {
    try {
      isLoading = true;
      errorMessage = null;
      final result = await _repository.getAllSetlists();
      setlists.clear();
      setlists.addAll(result);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> deleteSetlist(String id) async {
    try {
      isLoading = true;
      errorMessage = null;
      await _repository.deleteSetlist(id);
      await loadAllSetlists();
    } catch (e) {
      errorMessage = 'Failed to delete setlist: $e';
    } finally {
      isLoading = false;
    }
  }
}
