// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_music_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$CreateMusicStore on CreateMusicStoreBase, Store {
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

  late final _$saveMusicAsyncAction =
      AsyncAction('CreateMusicStoreBase.saveMusic', context: context);

  @override
  Future<void> saveMusic() {
    return _$saveMusicAsyncAction.run(() => super.saveMusic());
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
  void addTrack(String name, String filePath, {bool isClick = false}) {
    final _$actionInfo = _$CreateMusicStoreBaseActionController.startAction(
        name: 'CreateMusicStoreBase.addTrack');
    try {
      return super.addTrack(name, filePath, isClick: isClick);
    } finally {
      _$CreateMusicStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeTrack(String trackId) {
    final _$actionInfo = _$CreateMusicStoreBaseActionController.startAction(
        name: 'CreateMusicStoreBase.removeTrack');
    try {
      return super.removeTrack(trackId);
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
key: ${key},
timeSignatureNumerator: ${timeSignatureNumerator},
timeSignatureDenominator: ${timeSignatureDenominator},
tracks: ${tracks},
isLoading: ${isLoading},
errorMessage: ${errorMessage}
    ''';
  }
}
