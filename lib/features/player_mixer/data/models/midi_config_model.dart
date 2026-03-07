import 'package:isar/isar.dart';

part 'midi_config_model.g.dart';

@collection
class MidiConfigModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String deviceId = 'default_config'; // We'll use a single config for now

  // Isar doesn't support Map<int, String> directly, so we store it as a JSON-like string
  // or use two separate lists. For simplicity with Isar, let's use two lists.
  List<int> midiNotes = [];
  List<String> padIds = [];

  MidiConfigModel();

  void setMap(Map<int, String> map) {
    midiNotes = map.keys.toList();
    padIds = map.values.toList();
  }

  Map<int, String> getMap() {
    final Map<int, String> result = {};
    for (int i = 0; i < midiNotes.length; i++) {
      if (i < padIds.length) {
        result[midiNotes[i]] = padIds[i];
      }
    }
    return result;
  }
}
