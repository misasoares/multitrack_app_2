// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_library_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$MusicLibraryStore on MusicLibraryStoreBase, Store {
  Computed<List<Music>>? _$filteredMusicListComputed;

  @override
  List<Music> get filteredMusicList => (_$filteredMusicListComputed ??=
          Computed<List<Music>>(() => super.filteredMusicList,
              name: 'MusicLibraryStoreBase.filteredMusicList'))
      .value;

  late final _$musicListAtom =
      Atom(name: 'MusicLibraryStoreBase.musicList', context: context);

  @override
  ObservableList<Music> get musicList {
    _$musicListAtom.reportRead();
    return super.musicList;
  }

  @override
  set musicList(ObservableList<Music> value) {
    _$musicListAtom.reportWrite(value, super.musicList, () {
      super.musicList = value;
    });
  }

  late final _$isLoadingAtom =
      Atom(name: 'MusicLibraryStoreBase.isLoading', context: context);

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$errorMessageAtom =
      Atom(name: 'MusicLibraryStoreBase.errorMessage', context: context);

  @override
  String? get errorMessage {
    _$errorMessageAtom.reportRead();
    return super.errorMessage;
  }

  @override
  set errorMessage(String? value) {
    _$errorMessageAtom.reportWrite(value, super.errorMessage, () {
      super.errorMessage = value;
    });
  }

  late final _$searchQueryAtom =
      Atom(name: 'MusicLibraryStoreBase.searchQuery', context: context);

  @override
  String get searchQuery {
    _$searchQueryAtom.reportRead();
    return super.searchQuery;
  }

  @override
  set searchQuery(String value) {
    _$searchQueryAtom.reportWrite(value, super.searchQuery, () {
      super.searchQuery = value;
    });
  }

  late final _$sortByAtom =
      Atom(name: 'MusicLibraryStoreBase.sortBy', context: context);

  @override
  MusicSortType get sortBy {
    _$sortByAtom.reportRead();
    return super.sortBy;
  }

  @override
  set sortBy(MusicSortType value) {
    _$sortByAtom.reportWrite(value, super.sortBy, () {
      super.sortBy = value;
    });
  }

  late final _$minDurationFilterAtom =
      Atom(name: 'MusicLibraryStoreBase.minDurationFilter', context: context);

  @override
  double get minDurationFilter {
    _$minDurationFilterAtom.reportRead();
    return super.minDurationFilter;
  }

  @override
  set minDurationFilter(double value) {
    _$minDurationFilterAtom.reportWrite(value, super.minDurationFilter, () {
      super.minDurationFilter = value;
    });
  }

  late final _$maxDurationFilterAtom =
      Atom(name: 'MusicLibraryStoreBase.maxDurationFilter', context: context);

  @override
  double get maxDurationFilter {
    _$maxDurationFilterAtom.reportRead();
    return super.maxDurationFilter;
  }

  @override
  set maxDurationFilter(double value) {
    _$maxDurationFilterAtom.reportWrite(value, super.maxDurationFilter, () {
      super.maxDurationFilter = value;
    });
  }

  late final _$loadAllMusicAsyncAction =
      AsyncAction('MusicLibraryStoreBase.loadAllMusic', context: context);

  @override
  Future<void> loadAllMusic() {
    return _$loadAllMusicAsyncAction.run(() => super.loadAllMusic());
  }

  late final _$deleteMusicAsyncAction =
      AsyncAction('MusicLibraryStoreBase.deleteMusic', context: context);

  @override
  Future<void> deleteMusic(String id) {
    return _$deleteMusicAsyncAction.run(() => super.deleteMusic(id));
  }

  late final _$MusicLibraryStoreBaseActionController =
      ActionController(name: 'MusicLibraryStoreBase', context: context);

  @override
  void setSearchQuery(String value) {
    final _$actionInfo = _$MusicLibraryStoreBaseActionController.startAction(
        name: 'MusicLibraryStoreBase.setSearchQuery');
    try {
      return super.setSearchQuery(value);
    } finally {
      _$MusicLibraryStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSortBy(MusicSortType value) {
    final _$actionInfo = _$MusicLibraryStoreBaseActionController.startAction(
        name: 'MusicLibraryStoreBase.setSortBy');
    try {
      return super.setSortBy(value);
    } finally {
      _$MusicLibraryStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDurationRange(double min, double max) {
    final _$actionInfo = _$MusicLibraryStoreBaseActionController.startAction(
        name: 'MusicLibraryStoreBase.setDurationRange');
    try {
      return super.setDurationRange(min, max);
    } finally {
      _$MusicLibraryStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
musicList: ${musicList},
isLoading: ${isLoading},
errorMessage: ${errorMessage},
searchQuery: ${searchQuery},
sortBy: ${sortBy},
minDurationFilter: ${minDurationFilter},
maxDurationFilter: ${maxDurationFilter},
filteredMusicList: ${filteredMusicList}
    ''';
  }
}
