// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SystemStore on _SystemStoreBase, Store {
  late final _$midiDrumMapAtom =
      Atom(name: '_SystemStoreBase.midiDrumMap', context: context);

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

  late final _$padInLearnModeAtom =
      Atom(name: '_SystemStoreBase.padInLearnMode', context: context);

  @override
  String? get padInLearnMode {
    _$padInLearnModeAtom.reportRead();
    return super.padInLearnMode;
  }

  @override
  set padInLearnMode(String? value) {
    _$padInLearnModeAtom.reportWrite(value, super.padInLearnMode, () {
      super.padInLearnMode = value;
    });
  }

  late final _$devicesAtom =
      Atom(name: '_SystemStoreBase.devices', context: context);

  @override
  ObservableList<MidiDevice> get devices {
    _$devicesAtom.reportRead();
    return super.devices;
  }

  @override
  set devices(ObservableList<MidiDevice> value) {
    _$devicesAtom.reportWrite(value, super.devices, () {
      super.devices = value;
    });
  }

  late final _$isScanningAtom =
      Atom(name: '_SystemStoreBase.isScanning', context: context);

  @override
  bool get isScanning {
    _$isScanningAtom.reportRead();
    return super.isScanning;
  }

  @override
  set isScanning(bool value) {
    _$isScanningAtom.reportWrite(value, super.isScanning, () {
      super.isScanning = value;
    });
  }

  late final _$errorMessageAtom =
      Atom(name: '_SystemStoreBase.errorMessage', context: context);

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

  late final _$loadMidiConfigAsyncAction =
      AsyncAction('_SystemStoreBase.loadMidiConfig', context: context);

  @override
  Future<void> loadMidiConfig() {
    return _$loadMidiConfigAsyncAction.run(() => super.loadMidiConfig());
  }

  late final _$saveMidiConfigAsyncAction =
      AsyncAction('_SystemStoreBase.saveMidiConfig', context: context);

  @override
  Future<void> saveMidiConfig() {
    return _$saveMidiConfigAsyncAction.run(() => super.saveMidiConfig());
  }

  late final _$startScanningAsyncAction =
      AsyncAction('_SystemStoreBase.startScanning', context: context);

  @override
  Future<void> startScanning() {
    return _$startScanningAsyncAction.run(() => super.startScanning());
  }

  late final _$stopScanningAsyncAction =
      AsyncAction('_SystemStoreBase.stopScanning', context: context);

  @override
  Future<void> stopScanning() {
    return _$stopScanningAsyncAction.run(() => super.stopScanning());
  }

  late final _$_updateDevicesAsyncAction =
      AsyncAction('_SystemStoreBase._updateDevices', context: context);

  @override
  Future<void> _updateDevices() {
    return _$_updateDevicesAsyncAction.run(() => super._updateDevices());
  }

  late final _$connectToDeviceAsyncAction =
      AsyncAction('_SystemStoreBase.connectToDevice', context: context);

  @override
  Future<void> connectToDevice(MidiDevice device) {
    return _$connectToDeviceAsyncAction
        .run(() => super.connectToDevice(device));
  }

  late final _$disconnectFromDeviceAsyncAction =
      AsyncAction('_SystemStoreBase.disconnectFromDevice', context: context);

  @override
  Future<void> disconnectFromDevice(MidiDevice device) {
    return _$disconnectFromDeviceAsyncAction
        .run(() => super.disconnectFromDevice(device));
  }

  late final _$_SystemStoreBaseActionController =
      ActionController(name: '_SystemStoreBase', context: context);

  @override
  void startLearning(String padId) {
    final _$actionInfo = _$_SystemStoreBaseActionController.startAction(
        name: '_SystemStoreBase.startLearning');
    try {
      return super.startLearning(padId);
    } finally {
      _$_SystemStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleMidiData(MidiPacket packet) {
    final _$actionInfo = _$_SystemStoreBaseActionController.startAction(
        name: '_SystemStoreBase._handleMidiData');
    try {
      return super._handleMidiData(packet);
    } finally {
      _$_SystemStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
midiDrumMap: ${midiDrumMap},
padInLearnMode: ${padInLearnMode},
devices: ${devices},
isScanning: ${isScanning},
errorMessage: ${errorMessage}
    ''';
  }
}
