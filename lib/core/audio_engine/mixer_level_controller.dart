import 'dart:async';
import 'package:mobx/mobx.dart';
import 'iaudio_engine_service.dart';

/// Controller that polls real-time audio levels from the engine.
///
/// Designed to be active only when the Mixer UI is visible to save CPU.
class MixerLevelController {
  final IAudioEngineService _audioEngine;
  final List<String> trackIds;

  Timer? _timer;

  /// Observable map of trackId -> peak dB (-60.0 to 0.0)
  final ObservableMap<String, double> trackLevels =
      ObservableMap<String, double>();

  /// Observable master peak dB (-60.0 to 0.0)
  final ObservableList<double> _masterLevelContainer = ObservableList.of([
    -60.0,
  ]);
  double get masterLevel => _masterLevelContainer.first;

  MixerLevelController(this._audioEngine, this.trackIds) {
    for (final id in trackIds) {
      trackLevels[id] = -60.0;
    }
  }

  /// Starts polling at ~30 FPS (33ms interval)
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      _updateLevels();
    });
  }

  /// Stops polling and clears timer.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _updateLevels() {
    // We update the observables directly.
    // Since we're not inside a MobX action, we should wrap in runInAction
    // if we want strict mode, but for high-frequency polling,
    // direct modification of ObservableMap/List is often acceptable
    // if we want to avoid action overhead, or we can use runInAction.

    runInAction(() {
      for (final id in trackIds) {
        trackLevels[id] = _audioEngine.getTrackVolumeDb(id);
      }
      _masterLevelContainer[0] = _audioEngine.getMasterVolumeDb();
    });
  }

  /// Rigorously cancel resources.
  void dispose() {
    stop();
  }
}
