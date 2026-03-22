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
  Computed<Duration>? _$totalDurationComputed;

  @override
  Duration get totalDuration =>
      (_$totalDurationComputed ??= Computed<Duration>(() => super.totalDuration,
              name: 'StageStoreBase.totalDuration'))
          .value;
  Computed<Stream<Duration>>? _$previewPositionComputed;

  @override
  Stream<Duration> get previewPosition => (_$previewPositionComputed ??=
          Computed<Stream<Duration>>(() => super.previewPosition,
              name: 'StageStoreBase.previewPosition'))
      .value;
  Computed<SetlistItem?>? _$currentItemComputed;

  @override
  SetlistItem? get currentItem =>
      (_$currentItemComputed ??= Computed<SetlistItem?>(() => super.currentItem,
              name: 'StageStoreBase.currentItem'))
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

  late final _$previewLoadingItemIdAtom =
      Atom(name: 'StageStoreBase.previewLoadingItemId', context: context);

  @override
  String? get previewLoadingItemId {
    _$previewLoadingItemIdAtom.reportRead();
    return super.previewLoadingItemId;
  }

  @override
  set previewLoadingItemId(String? value) {
    _$previewLoadingItemIdAtom.reportWrite(value, super.previewLoadingItemId,
        () {
      super.previewLoadingItemId = value;
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

  late final _$currentPositionAtom =
      Atom(name: 'StageStoreBase.currentPosition', context: context);

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

  late final _$isScrubbingAtom =
      Atom(name: 'StageStoreBase.isScrubbing', context: context);

  @override
  bool get isScrubbing {
    _$isScrubbingAtom.reportRead();
    return super.isScrubbing;
  }

  @override
  set isScrubbing(bool value) {
    _$isScrubbingAtom.reportWrite(value, super.isScrubbing, () {
      super.isScrubbing = value;
    });
  }

  late final _$masterVolumeAtom =
      Atom(name: 'StageStoreBase.masterVolume', context: context);

  @override
  double get masterVolume {
    _$masterVolumeAtom.reportRead();
    return super.masterVolume;
  }

  @override
  set masterVolume(double value) {
    _$masterVolumeAtom.reportWrite(value, super.masterVolume, () {
      super.masterVolume = value;
    });
  }

  late final _$metronomeBpmAtom =
      Atom(name: 'StageStoreBase.metronomeBpm', context: context);

  @override
  double get metronomeBpm {
    _$metronomeBpmAtom.reportRead();
    return super.metronomeBpm;
  }

  @override
  set metronomeBpm(double value) {
    _$metronomeBpmAtom.reportWrite(value, super.metronomeBpm, () {
      super.metronomeBpm = value;
    });
  }

  late final _$metronomeVolumeAtom =
      Atom(name: 'StageStoreBase.metronomeVolume', context: context);

  @override
  double get metronomeVolume {
    _$metronomeVolumeAtom.reportRead();
    return super.metronomeVolume;
  }

  @override
  set metronomeVolume(double value) {
    _$metronomeVolumeAtom.reportWrite(value, super.metronomeVolume, () {
      super.metronomeVolume = value;
    });
  }

  late final _$metronomePanAtom =
      Atom(name: 'StageStoreBase.metronomePan', context: context);

  @override
  double get metronomePan {
    _$metronomePanAtom.reportRead();
    return super.metronomePan;
  }

  @override
  set metronomePan(double value) {
    _$metronomePanAtom.reportWrite(value, super.metronomePan, () {
      super.metronomePan = value;
    });
  }

  late final _$isMetronomePlayingAtom =
      Atom(name: 'StageStoreBase.isMetronomePlaying', context: context);

  @override
  bool get isMetronomePlaying {
    _$isMetronomePlayingAtom.reportRead();
    return super.isMetronomePlaying;
  }

  @override
  set isMetronomePlaying(bool value) {
    _$isMetronomePlayingAtom.reportWrite(value, super.isMetronomePlaying, () {
      super.isMetronomePlaying = value;
    });
  }

  late final _$isMixerVisibleAtom =
      Atom(name: 'StageStoreBase.isMixerVisible', context: context);

  @override
  bool get isMixerVisible {
    _$isMixerVisibleAtom.reportRead();
    return super.isMixerVisible;
  }

  @override
  set isMixerVisible(bool value) {
    _$isMixerVisibleAtom.reportWrite(value, super.isMixerVisible, () {
      super.isMixerVisible = value;
    });
  }

  late final _$isMetronomeVisibleAtom =
      Atom(name: 'StageStoreBase.isMetronomeVisible', context: context);

  @override
  bool get isMetronomeVisible {
    _$isMetronomeVisibleAtom.reportRead();
    return super.isMetronomeVisible;
  }

  @override
  set isMetronomeVisible(bool value) {
    _$isMetronomeVisibleAtom.reportWrite(value, super.isMetronomeVisible, () {
      super.isMetronomeVisible = value;
    });
  }

  late final _$isDrumRackVisibleAtom =
      Atom(name: 'StageStoreBase.isDrumRackVisible', context: context);

  @override
  bool get isDrumRackVisible {
    _$isDrumRackVisibleAtom.reportRead();
    return super.isDrumRackVisible;
  }

  @override
  set isDrumRackVisible(bool value) {
    _$isDrumRackVisibleAtom.reportWrite(value, super.isDrumRackVisible, () {
      super.isDrumRackVisible = value;
    });
  }

  late final _$midiDrumMapAtom =
      Atom(name: 'StageStoreBase.midiDrumMap', context: context);

  @override
  ObservableMap<int, String> get midiDrumMap {
    _$midiDrumMapAtom.reportRead();
    return super.midiDrumMap;
  }

  @override
  set midiDrumMap(ObservableMap<int, String> value) {
    _$midiDrumMapAtom.reportWrite(value, super.midiDrumMap, () {
      super.midiDrumMap = value;
    });
  }

  late final _$activeSongIndexAtom =
      Atom(name: 'StageStoreBase.activeSongIndex', context: context);

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

  late final _$importTracksForNewMusicAsyncAction =
      AsyncAction('StageStoreBase.importTracksForNewMusic', context: context);

  @override
  Future<void> importTracksForNewMusic(
      {required String title, required List<String> filePaths}) {
    return _$importTracksForNewMusicAsyncAction.run(() =>
        super.importTracksForNewMusic(title: title, filePaths: filePaths));
  }

  late final _$_initMidiAsyncAction =
      AsyncAction('StageStoreBase._initMidi', context: context);

  @override
  Future<void> _initMidi() {
    return _$_initMidiAsyncAction.run(() => super._initMidi());
  }

  late final _$loadMidiConfigAsyncAction =
      AsyncAction('StageStoreBase.loadMidiConfig', context: context);

  @override
  Future<void> loadMidiConfig() {
    return _$loadMidiConfigAsyncAction.run(() => super.loadMidiConfig());
  }

  late final _$seekToPositionAsyncAction =
      AsyncAction('StageStoreBase.seekToPosition', context: context);

  @override
  Future<void> seekToPosition(Duration position) {
    return _$seekToPositionAsyncAction
        .run(() => super.seekToPosition(position));
  }

  late final _$togglePreviewAsyncAction =
      AsyncAction('StageStoreBase.togglePreview', context: context);

  @override
  Future<void> togglePreview(String itemId) {
    return _$togglePreviewAsyncAction.run(() => super.togglePreview(itemId));
  }

  late final _$nextSongAsyncAction =
      AsyncAction('StageStoreBase.nextSong', context: context);

  @override
  Future<void> nextSong() {
    return _$nextSongAsyncAction.run(() => super.nextSong());
  }

  late final _$previousSongAsyncAction =
      AsyncAction('StageStoreBase.previousSong', context: context);

  @override
  Future<void> previousSong() {
    return _$previousSongAsyncAction.run(() => super.previousSong());
  }

  late final _$goToSongAsyncAction =
      AsyncAction('StageStoreBase.goToSong', context: context);

  @override
  Future<void> goToSong(int index) {
    return _$goToSongAsyncAction.run(() => super.goToSong(index));
  }

  late final _$saveDraftAsyncAction =
      AsyncAction('StageStoreBase.saveDraft', context: context);

  @override
  Future<void> saveDraft() {
    return _$saveDraftAsyncAction.run(() => super.saveDraft());
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
  void updateTrackSolo(String itemId, String trackId, bool isSolo) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.updateTrackSolo');
    try {
      return super.updateTrackSolo(itemId, trackId, isSolo);
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
  void updateItemMasterEq(String itemId, EqBandData band) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.updateItemMasterEq');
    try {
      return super.updateItemMasterEq(itemId, band);
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateItemVolume(String itemId, double volume) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.updateItemVolume');
    try {
      return super.updateItemVolume(itemId, volume);
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
  void setMasterVolume(double volume) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.setMasterVolume');
    try {
      return super.setMasterVolume(volume);
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setMetronomeBpm(double bpm) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.setMetronomeBpm');
    try {
      return super.setMetronomeBpm(bpm);
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setMetronomeVolume(double volume) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.setMetronomeVolume');
    try {
      return super.setMetronomeVolume(volume);
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setMetronomePan(double pan) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.setMetronomePan');
    try {
      return super.setMetronomePan(pan);
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setMetronomePlaying(bool playing) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.setMetronomePlaying');
    try {
      return super.setMetronomePlaying(playing);
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void tapTempo() {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.tapTempo');
    try {
      return super.tapTempo();
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleMixerVisible() {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.toggleMixerVisible');
    try {
      return super.toggleMixerVisible();
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleMetronomeVisible() {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.toggleMetronomeVisible');
    try {
      return super.toggleMetronomeVisible();
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleDrumRackVisible() {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.toggleDrumRackVisible');
    try {
      return super.toggleDrumRackVisible();
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void startScrubbing() {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.startScrubbing');
    try {
      return super.startScrubbing();
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateScrubPosition(Duration position) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.updateScrubPosition');
    try {
      return super.updateScrubPosition(position);
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void endScrubbing() {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.endScrubbing');
    try {
      return super.endScrubbing();
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void seek(Duration position) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.seek');
    try {
      return super.seek(position);
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleTrackTranspose(String itemId, String trackId, bool apply) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.toggleTrackTranspose');
    try {
      return super.toggleTrackTranspose(itemId, trackId, apply);
    } finally {
      _$StageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleTrackOctave(String itemId, String trackId) {
    final _$actionInfo = _$StageStoreBaseActionController.startAction(
        name: 'StageStoreBase.toggleTrackOctave');
    try {
      return super.toggleTrackOctave(itemId, trackId);
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
previewLoadingItemId: ${previewLoadingItemId},
renderProgress: ${renderProgress},
renderMessage: ${renderMessage},
trackPeaks: ${trackPeaks},
currentPosition: ${currentPosition},
isScrubbing: ${isScrubbing},
masterVolume: ${masterVolume},
metronomeBpm: ${metronomeBpm},
metronomeVolume: ${metronomeVolume},
metronomePan: ${metronomePan},
isMetronomePlaying: ${isMetronomePlaying},
isMixerVisible: ${isMixerVisible},
isMetronomeVisible: ${isMetronomeVisible},
isDrumRackVisible: ${isDrumRackVisible},
midiDrumMap: ${midiDrumMap},
activeSongIndex: ${activeSongIndex},
isRehearsalMode: ${isRehearsalMode},
isPerformanceMode: ${isPerformanceMode},
totalDuration: ${totalDuration},
previewPosition: ${previewPosition},
currentItem: ${currentItem}
    ''';
  }
}
