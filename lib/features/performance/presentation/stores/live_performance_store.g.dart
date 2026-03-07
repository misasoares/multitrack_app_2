// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_performance_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$LivePerformanceStore on LivePerformanceStoreBase, Store {
  late final _$midiDrumMapAtom =
      Atom(name: 'LivePerformanceStoreBase.midiDrumMap', context: context);

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

  late final _$isScrubbingAtom =
      Atom(name: 'LivePerformanceStoreBase.isScrubbing', context: context);

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

  late final _$trackPeaksAtom =
      Atom(name: 'LivePerformanceStoreBase.trackPeaks', context: context);

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

  late final _$isMixerVisibleAtom =
      Atom(name: 'LivePerformanceStoreBase.isMixerVisible', context: context);

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

  late final _$isMetronomeVisibleAtom = Atom(
      name: 'LivePerformanceStoreBase.isMetronomeVisible', context: context);

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

  late final _$isDrumRackVisibleAtom = Atom(
      name: 'LivePerformanceStoreBase.isDrumRackVisible', context: context);

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

  late final _$masterVolumeAtom =
      Atom(name: 'LivePerformanceStoreBase.masterVolume', context: context);

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
      Atom(name: 'LivePerformanceStoreBase.metronomeBpm', context: context);

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
      Atom(name: 'LivePerformanceStoreBase.metronomeVolume', context: context);

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
      Atom(name: 'LivePerformanceStoreBase.metronomePan', context: context);

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

  late final _$isMetronomePlayingAtom = Atom(
      name: 'LivePerformanceStoreBase.isMetronomePlaying', context: context);

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

  late final _$loadSetlistAsyncAction =
      AsyncAction('LivePerformanceStoreBase.loadSetlist', context: context);

  @override
  Future<void> loadSetlist(Setlist setlist) {
    return _$loadSetlistAsyncAction.run(() => super.loadSetlist(setlist));
  }

  late final _$_initMidiAsyncAction =
      AsyncAction('LivePerformanceStoreBase._initMidi', context: context);

  @override
  Future<void> _initMidi() {
    return _$_initMidiAsyncAction.run(() => super._initMidi());
  }

  late final _$loadMidiConfigAsyncAction =
      AsyncAction('LivePerformanceStoreBase.loadMidiConfig', context: context);

  @override
  Future<void> loadMidiConfig() {
    return _$loadMidiConfigAsyncAction.run(() => super.loadMidiConfig());
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
  void seekToPosition(Duration position) {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.seekToPosition');
    try {
      return super.seekToPosition(position);
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void startScrubbing() {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.startScrubbing');
    try {
      return super.startScrubbing();
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateScrubPosition(Duration position) {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.updateScrubPosition');
    try {
      return super.updateScrubPosition(position);
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void endScrubbing() {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.endScrubbing');
    try {
      return super.endScrubbing();
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
  void toggleMixerVisible() {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.toggleMixerVisible');
    try {
      return super.toggleMixerVisible();
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleMetronomeVisible() {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.toggleMetronomeVisible');
    try {
      return super.toggleMetronomeVisible();
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleDrumRackVisible() {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.toggleDrumRackVisible');
    try {
      return super.toggleDrumRackVisible();
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setMasterVolume(double volume) {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.setMasterVolume');
    try {
      return super.setMasterVolume(volume);
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setMetronomeBpm(double bpm) {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.setMetronomeBpm');
    try {
      return super.setMetronomeBpm(bpm);
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setMetronomeVolume(double volume) {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.setMetronomeVolume');
    try {
      return super.setMetronomeVolume(volume);
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setMetronomePan(double pan) {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.setMetronomePan');
    try {
      return super.setMetronomePan(pan);
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setMetronomePlaying(bool playing) {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.setMetronomePlaying');
    try {
      return super.setMetronomePlaying(playing);
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void tapTempo() {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.tapTempo');
    try {
      return super.tapTempo();
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void dispose() {
    final _$actionInfo = _$LivePerformanceStoreBaseActionController.startAction(
        name: 'LivePerformanceStoreBase.dispose');
    try {
      return super.dispose();
    } finally {
      _$LivePerformanceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
midiDrumMap: ${midiDrumMap},
currentSetlist: ${currentSetlist},
activeSongIndex: ${activeSongIndex},
isPlaying: ${isPlaying},
currentPosition: ${currentPosition},
isLoadingSong: ${isLoadingSong},
isScrubbing: ${isScrubbing},
trackPeaks: ${trackPeaks},
isMixerVisible: ${isMixerVisible},
isMetronomeVisible: ${isMetronomeVisible},
isDrumRackVisible: ${isDrumRackVisible},
masterVolume: ${masterVolume},
metronomeBpm: ${metronomeBpm},
metronomeVolume: ${metronomeVolume},
metronomePan: ${metronomePan},
isMetronomePlaying: ${isMetronomePlaying}
    ''';
  }
}
