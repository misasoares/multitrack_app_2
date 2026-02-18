// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_library_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$MusicLibraryStore on MusicLibraryStoreBase, Store {
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

  @override
  String toString() {
    return '''
musicList: ${musicList},
isLoading: ${isLoading},
errorMessage: ${errorMessage}
    ''';
  }
}
