// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_setlist_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$CreateSetlistStore on CreateSetlistStoreBase, Store {
  Computed<Duration>? _$totalDurationComputed;

  @override
  Duration get totalDuration =>
      (_$totalDurationComputed ??= Computed<Duration>(() => super.totalDuration,
              name: 'CreateSetlistStoreBase.totalDuration'))
          .value;

  late final _$selectedItemsAtom =
      Atom(name: 'CreateSetlistStoreBase.selectedItems', context: context);

  @override
  ObservableList<SetlistItem> get selectedItems {
    _$selectedItemsAtom.reportRead();
    return super.selectedItems;
  }

  @override
  set selectedItems(ObservableList<SetlistItem> value) {
    _$selectedItemsAtom.reportWrite(value, super.selectedItems, () {
      super.selectedItems = value;
    });
  }

  late final _$nameAtom =
      Atom(name: 'CreateSetlistStoreBase.name', context: context);

  @override
  String get name {
    _$nameAtom.reportRead();
    return super.name;
  }

  @override
  set name(String value) {
    _$nameAtom.reportWrite(value, super.name, () {
      super.name = value;
    });
  }

  late final _$descriptionAtom =
      Atom(name: 'CreateSetlistStoreBase.description', context: context);

  @override
  String get description {
    _$descriptionAtom.reportRead();
    return super.description;
  }

  @override
  set description(String value) {
    _$descriptionAtom.reportWrite(value, super.description, () {
      super.description = value;
    });
  }

  late final _$isLoadingAtom =
      Atom(name: 'CreateSetlistStoreBase.isLoading', context: context);

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
      Atom(name: 'CreateSetlistStoreBase.errorMessage', context: context);

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

  late final _$isPlayingAtom =
      Atom(name: 'CreateSetlistStoreBase.isPlaying', context: context);

  @override
  bool get isPlaying {
    _$isPlayingAtom.reportRead();
    return super.isPlaying;
  }

  @override
  set isPlaying(bool value) {
    _$isPlayingAtom.reportWrite(value, super.isPlaying, () {
      super.isPlaying = value;
    });
  }

  late final _$currentItemIndexAtom =
      Atom(name: 'CreateSetlistStoreBase.currentItemIndex', context: context);

  @override
  int get currentItemIndex {
    _$currentItemIndexAtom.reportRead();
    return super.currentItemIndex;
  }

  @override
  set currentItemIndex(int value) {
    _$currentItemIndexAtom.reportWrite(value, super.currentItemIndex, () {
      super.currentItemIndex = value;
    });
  }

  late final _$currentItemPositionAtom = Atom(
      name: 'CreateSetlistStoreBase.currentItemPosition', context: context);

  @override
  Duration get currentItemPosition {
    _$currentItemPositionAtom.reportRead();
    return super.currentItemPosition;
  }

  @override
  set currentItemPosition(Duration value) {
    _$currentItemPositionAtom.reportWrite(value, super.currentItemPosition, () {
      super.currentItemPosition = value;
    });
  }

  late final _$saveSuccessAtom =
      Atom(name: 'CreateSetlistStoreBase.saveSuccess', context: context);

  @override
  bool get saveSuccess {
    _$saveSuccessAtom.reportRead();
    return super.saveSuccess;
  }

  @override
  set saveSuccess(bool value) {
    _$saveSuccessAtom.reportWrite(value, super.saveSuccess, () {
      super.saveSuccess = value;
    });
  }

  late final _$savedSetlistAtom =
      Atom(name: 'CreateSetlistStoreBase.savedSetlist', context: context);

  @override
  Setlist? get savedSetlist {
    _$savedSetlistAtom.reportRead();
    return super.savedSetlist;
  }

  @override
  set savedSetlist(Setlist? value) {
    _$savedSetlistAtom.reportWrite(value, super.savedSetlist, () {
      super.savedSetlist = value;
    });
  }

  late final _$saveSetlistAsyncAction =
      AsyncAction('CreateSetlistStoreBase.saveSetlist', context: context);

  @override
  Future<void> saveSetlist() {
    return _$saveSetlistAsyncAction.run(() => super.saveSetlist());
  }

  late final _$playAsyncAction =
      AsyncAction('CreateSetlistStoreBase.play', context: context);

  @override
  Future<void> play() {
    return _$playAsyncAction.run(() => super.play());
  }

  late final _$pauseAsyncAction =
      AsyncAction('CreateSetlistStoreBase.pause', context: context);

  @override
  Future<void> pause() {
    return _$pauseAsyncAction.run(() => super.pause());
  }

  late final _$stopAsyncAction =
      AsyncAction('CreateSetlistStoreBase.stop', context: context);

  @override
  Future<void> stop() {
    return _$stopAsyncAction.run(() => super.stop());
  }

  late final _$skipToNextAsyncAction =
      AsyncAction('CreateSetlistStoreBase.skipToNext', context: context);

  @override
  Future<void> skipToNext() {
    return _$skipToNextAsyncAction.run(() => super.skipToNext());
  }

  late final _$skipToPreviousAsyncAction =
      AsyncAction('CreateSetlistStoreBase.skipToPrevious', context: context);

  @override
  Future<void> skipToPrevious() {
    return _$skipToPreviousAsyncAction.run(() => super.skipToPrevious());
  }

  late final _$CreateSetlistStoreBaseActionController =
      ActionController(name: 'CreateSetlistStoreBase', context: context);

  @override
  void setName(String value) {
    final _$actionInfo = _$CreateSetlistStoreBaseActionController.startAction(
        name: 'CreateSetlistStoreBase.setName');
    try {
      return super.setName(value);
    } finally {
      _$CreateSetlistStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDescription(String value) {
    final _$actionInfo = _$CreateSetlistStoreBaseActionController.startAction(
        name: 'CreateSetlistStoreBase.setDescription');
    try {
      return super.setDescription(value);
    } finally {
      _$CreateSetlistStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addMusic(Music music) {
    final _$actionInfo = _$CreateSetlistStoreBaseActionController.startAction(
        name: 'CreateSetlistStoreBase.addMusic');
    try {
      return super.addMusic(music);
    } finally {
      _$CreateSetlistStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeMusic(int index) {
    final _$actionInfo = _$CreateSetlistStoreBaseActionController.startAction(
        name: 'CreateSetlistStoreBase.removeMusic');
    try {
      return super.removeMusic(index);
    } finally {
      _$CreateSetlistStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void reorderMusic(int oldIndex, int newIndex) {
    final _$actionInfo = _$CreateSetlistStoreBaseActionController.startAction(
        name: 'CreateSetlistStoreBase.reorderMusic');
    try {
      return super.reorderMusic(oldIndex, newIndex);
    } finally {
      _$CreateSetlistStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
selectedItems: ${selectedItems},
name: ${name},
description: ${description},
isLoading: ${isLoading},
errorMessage: ${errorMessage},
isPlaying: ${isPlaying},
currentItemIndex: ${currentItemIndex},
currentItemPosition: ${currentItemPosition},
saveSuccess: ${saveSuccess},
savedSetlist: ${savedSetlist},
totalDuration: ${totalDuration}
    ''';
  }
}
