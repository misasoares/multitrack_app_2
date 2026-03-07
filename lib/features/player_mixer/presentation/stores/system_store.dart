import 'dart:async';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:mobx/mobx.dart';
import 'package:isar/isar.dart';
import '../../data/models/midi_config_model.dart';

part 'system_store.g.dart';

class SystemStore = _SystemStoreBase with _$SystemStore;

abstract class _SystemStoreBase with Store {
  final MidiCommand _midiCommand = MidiCommand();
  final Isar _isar;
  StreamSubscription? _setupSubscription;
  StreamSubscription? _midiDataSubscription;

  @observable
  ObservableMap<int, String> midiDrumMap = ObservableMap<int, String>();

  @observable
  String? padInLearnMode;

  @observable
  ObservableList<MidiDevice> devices = ObservableList<MidiDevice>();

  @observable
  bool isScanning = false;

  @observable
  String? errorMessage;

  _SystemStoreBase(this._isar) {
    _setupSubscription = _midiCommand.onMidiSetupChanged?.listen((_) {
      _updateDevices();
    });

    _midiDataSubscription = _midiCommand.onMidiDataReceived?.listen(
      _handleMidiData,
    );

    loadMidiConfig();
  }

  @action
  void startLearning(String padId) {
    padInLearnMode = padId;
  }

  @action
  void _handleMidiData(MidiPacket packet) {
    // Note On status is 144-159 (0x90-0x9F) for channels 1-16
    // We check if it's a Note On (>=144 && <=159) and velocity > 0
    if (packet.data.length >= 3) {
      final status = packet.data[0];
      final isNoteOn = status >= 144 && status <= 159;
      final note = packet.data[1];
      final velocity = packet.data[2];

      if (isNoteOn && velocity > 0 && padInLearnMode != null) {
        midiDrumMap[note] = padInLearnMode!;
        padInLearnMode = null;
        saveMidiConfig();
      }
    }
  }

  @action
  Future<void> loadMidiConfig() async {
    final config = await _isar.midiConfigModels
        .where()
        .deviceIdEqualTo('default_config')
        .findFirst();
    if (config != null) {
      midiDrumMap.addAll(config.getMap());
    }
  }

  @action
  Future<void> saveMidiConfig() async {
    final config = MidiConfigModel()..deviceId = 'default_config';
    config.setMap(midiDrumMap);
    await _isar.writeTxn(() async {
      await _isar.midiConfigModels.put(config);
    });
  }

  @action
  Future<void> startScanning() async {
    isScanning = true;
    errorMessage = null;
    try {
      await _midiCommand.startScanningForBluetoothDevices();
      // Periodically update the list or wait for updates via stream
      _updateDevices();
    } catch (e) {
      errorMessage = "Erro ao escanear: $e";
    } finally {
      // Scanning usually stops automatically or we stop it after a timeout
      // For now, let's keep it simple as requested
      Future.delayed(const Duration(seconds: 10), () {
        isScanning = false;
      });
    }
  }

  @action
  Future<void> stopScanning() async {
    _midiCommand.stopScanningForBluetoothDevices();
    isScanning = false;
  }

  @action
  Future<void> _updateDevices() async {
    final devList = await _midiCommand.devices;
    if (devList != null) {
      devices.clear();
      devices.addAll(devList);
    }
  }

  @action
  Future<void> connectToDevice(MidiDevice device) async {
    try {
      await _midiCommand.connectToDevice(device);
      _updateDevices();
    } catch (e) {
      errorMessage = "Erro ao conectar: $e";
    }
  }

  @action
  Future<void> disconnectFromDevice(MidiDevice device) async {
    _midiCommand.disconnectDevice(device);
    _updateDevices();
  }

  void dispose() {
    _setupSubscription?.cancel();
    _midiDataSubscription?.cancel();
  }
}
