// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stage_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$StageStore on StageStoreBase, Store {
  Computed<bool>? _$isRehearsalModeComputed;

  @override
  bool get isRehearsalMode =>
      (_$isRehearsalModeComputed ??= Computed<bool>(() => super.isRehearsalMode,
              name: 'StageStoreBase.isRehearsalMode'))
          .value;
  Computed<bool>? _$isPerformanceModeComputed;

  @override
  bool get isPerformanceMode => (_$isPerformanceModeComputed ??= Computed<bool>(
          () => super.isPerformanceMode,
          name: 'StageStoreBase.isPerformanceMode'))
      .value;

  late final _$modeAtom = Atom(name: 'StageStoreBase.mode', context: context);

  @override
  AppMode get mode {
    _$modeAtom.reportRead();
    return super.mode;
  }

  @override
  set mode(AppMode value) {
    _$modeAtom.reportWrite(value, super.mode, () {
      super.mode = value;
    });
  }

  late final _$currentSetlistAtom =
      Atom(name: 'StageStoreBase.currentSetlist', context: context);

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

  late final _$playingItemIdAtom =
      Atom(name: 'StageStoreBase.playingItemId', context: context);

  @override
  String? get playingItemId {
    _$playingItemIdAtom.reportRead();
    return super.playingItemId;
  }

  @override
  set playingItemId(String? value) {
    _$playingItemIdAtom.reportWrite(value, super.playingItemId, () {
      super.playingItemId = value;
    });
  }

  late final _$isPlayingAtom =
      Atom(name: 'StageStoreBase.isPlaying', context: context);

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

  late final _$isLoadingAtom =
      Atom(name: 'StageStoreBase.isLoading', context: context);

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

  late final _$isRenderingAtom =
      Atom(name: 'StageStoreBase.isRendering', context: context);

  @override
  bool get isRendering {
    _$isRenderingAtom.reportRead();
    return super.isRendering;
  }

  @override
  set isRendering(bool value) {
    _$isRenderingAtom.reportWrite(value, super.isRendering, () {
      super.isRendering = value;
    });
  }

  late final _$renderProgressAtom =
      Atom(name: 'StageStoreBase.renderProgress', context: context);

  @override
  double get renderProgress {
    _$renderProgressAtom.reportRead();
    return super.renderProgress;
  }

  @override
  set renderProgress(double value) {
    _$renderProgressAtom.reportWrite(value, super.renderProgress, () {
      super.renderProgress = value;
    });
  }

  late final _$renderMessageAtom =
      Atom(name: 'StageStoreBase.renderMessage', context: context);

  @override
  String get renderMessage {
    _$renderMessageAtom.reportRead();
    return super.renderMessage;
  }

  @override
  set renderMessage(String value) {
    _$renderMessageAtom.reportWrite(value, super.renderMessage, () {
      super.renderMessage = value;
    });
  }

  late final _$trackPeaksAtom =
      Atom(name: 'StageStoreBase.trackPeaks', context: context);

  @override
  Map<String, double> get trackPeaks {
    _$trackPeaksAtom.reportRead();
    return super.trackPeaks;
  }

  @override
  set trackPeaks(Map<String, double> value) {
    _$trackPeaksAtom.reportWrite(value, super.trackPeaks, () {
      super.trackPeaks = value;
    });
  }

  late final _$importTracksForNewMusicAsyncAction =
      AsyncAction('StageStoreBase.importTracksForNewMusic', context: context);

  @override
  Future<void> importTracksForNewMusic(
      {required String title, required List<String> filePaths}) {
    return _$importTracksForNewMusicAsyncAction.run(() =>
        super.importTracksForNewMusic(title: title, filePaths: filePaths));
  }

  late final _$togglePreviewAsyncAction =
      AsyncAction('StageStoreBase.togglePreview', context: context);

  @override
  Future<void> togglePreview(String itemId) {
    return _$togglePreviewAsyncAction.run(() => super.togglePreview(itemId));
  }

  late final _$renderSetlistAsyncAction =
      AsyncAction('StageStoreBase.renderSetlist', context: context);

  @override
  Future<void> renderSetlist() {
    return _$renderSetlistAsyncAction.run(() => super.renderSetlist());
  }

  late final _$StageStoreBaseActionController =
      ActionController(name: 'StageStoreBase', context: context);

  @override
  void setMode(AppMode newMode) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.setMode');
    try {
      return super.setMode(newMode);
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void init(Setlist setlist) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.init');
    try {
      return super.init(setlist);
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateTrackVolume(String itemId, String trackId, double volume) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.updateTrackVolume');
    try {
      return super.updateTrackVolume(itemId, trackId, volume);
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateTrackMute(String itemId, String trackId, bool muted) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.updateTrackMute');
    try {
      return super.updateTrackMute(itemId, trackId, muted);
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateTrackPan(String itemId, String trackId, double pan) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.updateTrackPan');
    try {
      return super.updateTrackPan(itemId, trackId, pan);
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateTrackEq(String itemId, String trackId, EqBandData updatedBand) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.updateTrackEq');
    try {
      return super.updateTrackEq(itemId, trackId, updatedBand);
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateItemTempo(String itemId, double tempo) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.updateItemTempo');
    try {
      return super.updateItemTempo(itemId, tempo);
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateItemTranspose(String itemId, int semitones) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.updateItemTranspose');
    try {
      return super.updateItemTranspose(itemId, semitones);
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
mode: ${mode},
currentSetlist: ${currentSetlist},
playingItemId: ${playingItemId},
isPlaying: ${isPlaying},
isLoading: ${isLoading},
isRendering: ${isRendering},
renderProgress: ${renderProgress},
renderMessage: ${renderMessage},
trackPeaks: ${trackPeaks},
isRehearsalMode: ${isRehearsalMode},
isPerformanceMode: ${isPerformanceMode}
    ''';
  }
}
