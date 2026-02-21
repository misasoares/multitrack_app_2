// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_music_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$CreateMusicStore on CreateMusicStoreBase, Store {
  Computed<Duration>? _$totalDurationComputed;

  @override
  Duration get totalDuration =>
      (_$totalDurationComputed ??= Computed<Duration>(() => super.totalDuration,
              name: 'CreateMusicStoreBase.totalDuration'))
          .value;
  Computed<List<double>>? _$unifiedWaveformComputed;

  @override
  List<double> get unifiedWaveform => (_$unifiedWaveformComputed ??=
          Computed<List<double>>(() => super.unifiedWaveform,
              name: 'CreateMusicStoreBase.unifiedWaveform'))
      .value;

  late final _$titleAtom =
      Atom(name: 'CreateMusicStoreBase.title', context: context);

  @override
  String get title {
    _$titleAtom.reportRead();
    return super.title;
  }

  @override
  set title(String value) {
    _$titleAtom.reportWrite(value, super.title, () {
      super.title = value;
    });
  }

  late final _$artistAtom =
      Atom(name: 'CreateMusicStoreBase.artist', context: context);

  @override
  String get artist {
    _$artistAtom.reportRead();
    return super.artist;
  }

  @override
  set artist(String value) {
    _$artistAtom.reportWrite(value, super.artist, () {
      super.artist = value;
    });
  }

  late final _$bpmAtom =
      Atom(name: 'CreateMusicStoreBase.bpm', context: context);

  @override
  String get bpm {
    _$bpmAtom.reportRead();
    return super.bpm;
  }

  @override
  set bpm(String value) {
    _$bpmAtom.reportWrite(value, super.bpm, () {
      super.bpm = value;
    });
  }

  late final _$manualBpmAtom =
      Atom(name: 'CreateMusicStoreBase.manualBpm', context: context);

  @override
  int get manualBpm {
    _$manualBpmAtom.reportRead();
    return super.manualBpm;
  }

  @override
  set manualBpm(int value) {
    _$manualBpmAtom.reportWrite(value, super.manualBpm, () {
      super.manualBpm = value;
    });
  }

  late final _$keyAtom =
      Atom(name: 'CreateMusicStoreBase.key', context: context);

  @override
  String get key {
    _$keyAtom.reportRead();
    return super.key;
  }

  @override
  set key(String value) {
    _$keyAtom.reportWrite(value, super.key, () {
      super.key = value;
    });
  }

  late final _$timeSignatureNumeratorAtom = Atom(
      name: 'CreateMusicStoreBase.timeSignatureNumerator', context: context);

  @override
  int get timeSignatureNumerator {
    _$timeSignatureNumeratorAtom.reportRead();
    return super.timeSignatureNumerator;
  }

  @override
  set timeSignatureNumerator(int value) {
    _$timeSignatureNumeratorAtom
        .reportWrite(value, super.timeSignatureNumerator, () {
      super.timeSignatureNumerator = value;
    });
  }

  late final _$timeSignatureDenominatorAtom = Atom(
      name: 'CreateMusicStoreBase.timeSignatureDenominator', context: context);

  @override
  int get timeSignatureDenominator {
    _$timeSignatureDenominatorAtom.reportRead();
    return super.timeSignatureDenominator;
  }

  @override
  set timeSignatureDenominator(int value) {
    _$timeSignatureDenominatorAtom
        .reportWrite(value, super.timeSignatureDenominator, () {
      super.timeSignatureDenominator = value;
    });
  }

  late final _$originalCreatedAtAtom =
      Atom(name: 'CreateMusicStoreBase.originalCreatedAt', context: context);

  @override
  DateTime? get originalCreatedAt {
    _$originalCreatedAtAtom.reportRead();
    return super.originalCreatedAt;
  }

  @override
  set originalCreatedAt(DateTime? value) {
    _$originalCreatedAtAtom.reportWrite(value, super.originalCreatedAt, () {
      super.originalCreatedAt = value;
    });
  }

  late final _$tracksAtom =
      Atom(name: 'CreateMusicStoreBase.tracks', context: context);

  @override
  ObservableList<Track> get tracks {
    _$tracksAtom.reportRead();
    return super.tracks;
  }

  @override
  set tracks(ObservableList<Track> value) {
    _$tracksAtom.reportWrite(value, super.tracks, () {
      super.tracks = value;
    });
  }

  late final _$isLoadingAtom =
      Atom(name: 'CreateMusicStoreBase.isLoading', context: context);

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

  late final _$isPlayingAtom =
      Atom(name: 'CreateMusicStoreBase.isPlaying', context: context);

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

  late final _$errorMessageAtom =
      Atom(name: 'CreateMusicStoreBase.errorMessage', context: context);

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

  late final _$isProcessingAudioAtom =
      Atom(name: 'CreateMusicStoreBase.isProcessingAudio', context: context);

  @override
  bool get isProcessingAudio {
    _$isProcessingAudioAtom.reportRead();
    return super.isProcessingAudio;
  }

  @override
  set isProcessingAudio(bool value) {
    _$isProcessingAudioAtom.reportWrite(value, super.isProcessingAudio, () {
      super.isProcessingAudio = value;
    });
  }

  late final _$waveformDataAtom =
      Atom(name: 'CreateMusicStoreBase.waveformData', context: context);

  @override
  ObservableMap<String, List<double>> get waveformData {
    _$waveformDataAtom.reportRead();
    return super.waveformData;
  }

  @override
  set waveformData(ObservableMap<String, List<double>> value) {
    _$waveformDataAtom.reportWrite(value, super.waveformData, () {
      super.waveformData = value;
    });
  }

  late final _$saveSuccessAtom =
      Atom(name: 'CreateMusicStoreBase.saveSuccess', context: context);

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

  late final _$currentPositionAtom =
      Atom(name: 'CreateMusicStoreBase.currentPosition', context: context);

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

  late final _$editingMusicIdAtom =
      Atom(name: 'CreateMusicStoreBase.editingMusicId', context: context);

  @override
  String? get editingMusicId {
    _$editingMusicIdAtom.reportRead();
    return super.editingMusicId;
  }

  @override
  set editingMusicId(String? value) {
    _$editingMusicIdAtom.reportWrite(value, super.editingMusicId, () {
      super.editingMusicId = value;
    });
  }

  late final _$importTracksAsyncAction =
      AsyncAction('CreateMusicStoreBase.importTracks', context: context);

  @override
  Future<void> importTracks(List<({String name, String path})> files) {
    return _$importTracksAsyncAction.run(() => super.importTracks(files));
  }

  late final _$addTrackAsyncAction =
      AsyncAction('CreateMusicStoreBase.addTrack', context: context);

  @override
  Future<void> addTrack(String name, String filePath, {bool isClick = false}) {
    return _$addTrackAsyncAction
        .run(() => super.addTrack(name, filePath, isClick: isClick));
  }

  late final _$removeTrackAsyncAction =
      AsyncAction('CreateMusicStoreBase.removeTrack', context: context);

  @override
  Future<void> removeTrack(String trackId) {
    return _$removeTrackAsyncAction.run(() => super.removeTrack(trackId));
  }

  late final _$playPreviewAsyncAction =
      AsyncAction('CreateMusicStoreBase.playPreview', context: context);

  @override
  Future<void> playPreview() {
    return _$playPreviewAsyncAction.run(() => super.playPreview());
  }

  late final _$seekToAsyncAction =
      AsyncAction('CreateMusicStoreBase.seekTo', context: context);

  @override
  Future<void> seekTo(Duration position) {
    return _$seekToAsyncAction.run(() => super.seekTo(position));
  }

  late final _$loadMusicAsyncAction =
      AsyncAction('CreateMusicStoreBase.loadMusic', context: context);

  @override
  Future<void> loadMusic(Music music) {
    return _$loadMusicAsyncAction.run(() => super.loadMusic(music));
  }

  late final _$saveMusicConfigAsyncAction =
      AsyncAction('CreateMusicStoreBase.saveMusicConfig', context: context);

  @override
  Future<void> saveMusicConfig() {
    return _$saveMusicConfigAsyncAction.run(() => super.saveMusicConfig());
  }

  late final _$CreateMusicStoreBaseActionController =
      ActionController(name: 'CreateMusicStoreBase', context: context);

  @override
  void setTitle(String value) {
    final _$actionInfo = _$CreateMusicStoreBaseActionController.startAction(
        name: 'CreateMusicStoreBase.setTitle');
    try {
      return super.setTitle(value);
    } finally {
      _$CreateMusicStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setArtist(String value) {
    final _$actionInfo = _$CreateMusicStoreBaseActionController.startAction(
        name: 'CreateMusicStoreBase.setArtist');
    try {
      return super.setArtist(value);
    } finally {
      _$CreateMusicStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setBpm(String value) {
    final _$actionInfo = _$CreateMusicStoreBaseActionController.startAction(
        name: 'CreateMusicStoreBase.setBpm');
    try {
      return super.setBpm(value);
    } finally {
      _$CreateMusicStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setManualBpm(int value) {
    final _$actionInfo = _$CreateMusicStoreBaseActionController.startAction(
        name: 'CreateMusicStoreBase.setManualBpm');
    try {
      return super.setManualBpm(value);
    } finally {
      _$CreateMusicStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setKey(String value) {
    final _$actionInfo = _$CreateMusicStoreBaseActionController.startAction(
        name: 'CreateMusicStoreBase.setKey');
    try {
      return super.setKey(value);
    } finally {
      _$CreateMusicStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setTimeSignatureNumerator(int value) {
    final _$actionInfo = _$CreateMusicStoreBaseActionController.startAction(
        name: 'CreateMusicStoreBase.setTimeSignatureNumerator');
    try {
      return super.setTimeSignatureNumerator(value);
    } finally {
      _$CreateMusicStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setTimeSignatureDenominator(int value) {
    final _$actionInfo = _$CreateMusicStoreBaseActionController.startAction(
        name: 'CreateMusicStoreBase.setTimeSignatureDenominator');
    try {
      return super.setTimeSignatureDenominator(value);
    } finally {
      _$CreateMusicStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateVolume(String trackId, double newVolume) {
    final _$actionInfo = _$CreateMusicStoreBaseActionController.startAction(
        name: 'CreateMusicStoreBase.updateVolume');
    try {
      return super.updateVolume(trackId, newVolume);
    } finally {
      _$CreateMusicStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updatePan(String trackId, double newPan) {
    final _$actionInfo = _$CreateMusicStoreBaseActionController.startAction(
        name: 'CreateMusicStoreBase.updatePan');
    try {
      return super.updatePan(trackId, newPan);
    } finally {
      _$CreateMusicStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleMute(String trackId) {
    final _$actionInfo = _$CreateMusicStoreBaseActionController.startAction(
        name: 'CreateMusicStoreBase.toggleMute');
    try {
      return super.toggleMute(trackId);
    } finally {
      _$CreateMusicStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleSolo(String trackId) {
    final _$actionInfo = _$CreateMusicStoreBaseActionController.startAction(
        name: 'CreateMusicStoreBase.toggleSolo');
    try {
      return super.toggleSolo(trackId);
    } finally {
      _$CreateMusicStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateTrackEq(String trackId, EqBandData band) {
    final _$actionInfo = _$CreateMusicStoreBaseActionController.startAction(
        name: 'CreateMusicStoreBase.updateTrackEq');
    try {
      return super.updateTrackEq(trackId, band);
    } finally {
      _$CreateMusicStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void reorderTracks(int oldIndex, int newIndex) {
    final _$actionInfo = _$CreateMusicStoreBaseActionController.startAction(
        name: 'CreateMusicStoreBase.reorderTracks');
    try {
      return super.reorderTracks(oldIndex, newIndex);
    } finally {
      _$CreateMusicStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void pausePreview() {
    final _$actionInfo = _$CreateMusicStoreBaseActionController.startAction(
        name: 'CreateMusicStoreBase.pausePreview');
    try {
      return super.pausePreview();
    } finally {
      _$CreateMusicStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
title: ${title},
artist: ${artist},
bpm: ${bpm},
manualBpm: ${manualBpm},
key: ${key},
timeSignatureNumerator: ${timeSignatureNumerator},
timeSignatureDenominator: ${timeSignatureDenominator},
originalCreatedAt: ${originalCreatedAt},
tracks: ${tracks},
isLoading: ${isLoading},
isPlaying: ${isPlaying},
errorMessage: ${errorMessage},
isProcessingAudio: ${isProcessingAudio},
waveformData: ${waveformData},
saveSuccess: ${saveSuccess},
currentPosition: ${currentPosition},
editingMusicId: ${editingMusicId},
totalDuration: ${totalDuration},
unifiedWaveform: ${unifiedWaveform}
    ''';
  }
}
