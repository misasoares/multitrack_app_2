// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_performance_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$LivePerformanceStore on LivePerformanceStoreBase, Store {
  late final _$currentSetlistAtom =
      Atom(name: 'LivePerformanceStoreBase.currentSetlist', context: context);

  @override
  Setlist? get currentSetlist {
    _$currentSetlistAtom.reportRead();
    return super.currentSetlist;
  }

  @override
  set currentSetlist(Setlist? value) {
    _$currentSetlistAtom.reportWrite(value, super.currentSetlist, () {
      super.currentSetlist = value;
    });
  }

  late final _$activeSongIndexAtom =
      Atom(name: 'LivePerformanceStoreBase.activeSongIndex', context: context);

  @override
  int get activeSongIndex {
    _$activeSongIndexAtom.reportRead();
    return super.activeSongIndex;
  }

  @override
  set activeSongIndex(int value) {
    _$activeSongIndexAtom.reportWrite(value, super.activeSongIndex, () {
      super.activeSongIndex = value;
    });
  }

  late final _$isPlayingAtom =
      Atom(name: 'LivePerformanceStoreBase.isPlaying', context: context);

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

  late final _$currentPositionAtom =
      Atom(name: 'LivePerformanceStoreBase.currentPosition', context: context);

  @override
  Duration get currentPosition {
    _$currentPositionAtom.reportRead();
    return super.currentPosition;
  }

  @override
  set currentPosition(Duration value) {
    _$currentPositionAtom.reportWrite(value, super.currentPosition, () {
      super.currentPosition = value;
    });
  }

  late final _$isLoadingSongAtom =
      Atom(name: 'LivePerformanceStoreBase.isLoadingSong', context: context);

  @override
  bool get isLoadingSong {
    _$isLoadingSongAtom.reportRead();
    return super.isLoadingSong;
  }

  @override
  set isLoadingSong(bool value) {
    _$isLoadingSongAtom.reportWrite(value, super.isLoadingSong, () {
      super.isLoadingSong = value;
    });
  }

  late final _$loadSetlistAsyncAction =
      AsyncAction('LivePerformanceStoreBase.loadSetlist', context: context);

  @override
  Future<void> loadSetlist(Setlist setlist) {
    return _$loadSetlistAsyncAction.run(() => super.loadSetlist(setlist));
  }

  late final _$LivePerformanceStoreBaseActionController =
      ActionController(name: 'LivePerformanceStoreBase', context: context);

  @override
  void togglePlay() {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.togglePlay');
    try {
      return super.togglePlay();
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void nextSong() {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.nextSong');
    try {
      return super.nextSong();
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void prevSong() {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.prevSong');
    try {
      return super.prevSong();
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void goToSong(int index) {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.goToSong');
    try {
      return super.goToSong(index);
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setTrackVolume(String trackId, double volume) {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.setTrackVolume');
    try {
      return super.setTrackVolume(trackId, volume);
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setTrackMute(String trackId, bool isMuted) {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.setTrackMute');
    try {
      return super.setTrackMute(trackId, isMuted);
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setTrackSolo(String trackId, bool isSolo) {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.setTrackSolo');
    try {
      return super.setTrackSolo(trackId, isSolo);
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
currentSetlist: ${currentSetlist},
activeSongIndex: ${activeSongIndex},
isPlaying: ${isPlaying},
currentPosition: ${currentPosition},
isLoadingSong: ${isLoadingSong}
    ''';
  }
}
