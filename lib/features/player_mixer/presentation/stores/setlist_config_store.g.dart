// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setlist_config_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SetlistConfigStore on SetlistConfigStoreBase, Store {
  Computed<Duration>? _$totalDurationComputed;

  @override
  Duration get totalDuration =>
      (_$totalDurationComputed ??= Computed<Duration>(() => super.totalDuration,
              name: 'SetlistConfigStoreBase.totalDuration'))
          .value;

  late final _$currentSetlistAtom =
      Atom(name: 'SetlistConfigStoreBase.currentSetlist', context: context);

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
      Atom(name: 'SetlistConfigStoreBase.playingItemId', context: context);

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
      Atom(name: 'SetlistConfigStoreBase.isPlaying', context: context);

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
      Atom(name: 'SetlistConfigStoreBase.isLoading', context: context);

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

  late final _$previewLoadingItemIdAtom = Atom(
      name: 'SetlistConfigStoreBase.previewLoadingItemId', context: context);

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

  late final _$saveDraftAsyncAction =
      AsyncAction('SetlistConfigStoreBase.saveDraft', context: context);

  @override
  Future<void> saveDraft() {
    return _$saveDraftAsyncAction.run(() => super.saveDraft());
  }

  late final _$seekAsyncAction =
      AsyncAction('SetlistConfigStoreBase.seek', context: context);

  @override
  Future<void> seek(Duration position) {
    return _$seekAsyncAction.run(() => super.seek(position));
  }

  late final _$togglePreviewAsyncAction =
      AsyncAction('SetlistConfigStoreBase.togglePreview', context: context);

  @override
  Future<void> togglePreview(String itemId) {
    return _$togglePreviewAsyncAction.run(() => super.togglePreview(itemId));
  }

  late final _$SetlistConfigStoreBaseActionController =
      ActionController(name: 'SetlistConfigStoreBase', context: context);

  @override
  void init(Setlist setlist) {
    final _$actionInfo = _$SetlistConfigStoreBaseActionController.startAction(
        name: 'SetlistConfigStoreBase.init');
    try {
      return super.init(setlist);
    } finally {
      _$SetlistConfigStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateItemVolume(String itemId, double volume) {
    final _$actionInfo = _$SetlistConfigStoreBaseActionController.startAction(
        name: 'SetlistConfigStoreBase.updateItemVolume');
    try {
      return super.updateItemVolume(itemId, volume);
    } finally {
      _$SetlistConfigStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateItemTempo(String itemId, double factor) {
    final _$actionInfo = _$SetlistConfigStoreBaseActionController.startAction(
        name: 'SetlistConfigStoreBase.updateItemTempo');
    try {
      return super.updateItemTempo(itemId, factor);
    } finally {
      _$SetlistConfigStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateItemTranspose(String itemId, int semitones) {
    final _$actionInfo = _$SetlistConfigStoreBaseActionController.startAction(
        name: 'SetlistConfigStoreBase.updateItemTranspose');
    try {
      return super.updateItemTranspose(itemId, semitones);
    } finally {
      _$SetlistConfigStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateTransposableTracks(String itemId, List<String> trackIds) {
    final _$actionInfo = _$SetlistConfigStoreBaseActionController.startAction(
        name: 'SetlistConfigStoreBase.updateTransposableTracks');
    try {
      return super.updateTransposableTracks(itemId, trackIds);
    } finally {
      _$SetlistConfigStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateItemMasterEq(String itemId, EqBandData updatedBand) {
    final _$actionInfo = _$SetlistConfigStoreBaseActionController.startAction(
        name: 'SetlistConfigStoreBase.updateItemMasterEq');
    try {
      return super.updateItemMasterEq(itemId, updatedBand);
    } finally {
      _$SetlistConfigStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
currentSetlist: ${currentSetlist},
playingItemId: ${playingItemId},
isPlaying: ${isPlaying},
isLoading: ${isLoading},
previewLoadingItemId: ${previewLoadingItemId},
totalDuration: ${totalDuration}
    ''';
  }
}
