import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;

class AudioGarbageCollector {
  /// Scans the `audioDirPath` and deletes any file that is not part of `validPaths`.
  /// Runs inside `Isolate.run` to prevent blocking the UI thread.
  static Future<void> collect(
    String audioDirPath,
    List<String> validPaths,
  ) async {
    await Isolate.run(() {
      final dir = Directory(audioDirPath);
      if (!dir.existsSync()) return;

      final validSet = validPaths.map((path) => p.normalize(path)).toSet();

      final entities = dir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          // Assume only audio files are collected (e.g. .wav or .mp3)
          if (ext == '.wav' ||
              ext == '.mp3' ||
              ext == '.m4a' ||
              ext == '.aac') {
            final normalizedPath = p.normalize(entity.path);
            if (!validSet.contains(normalizedPath)) {
              try {
                entity.deleteSync();
                print(
                  'AudioGarbageCollector: Deleted orphaned file -> \${entity.path}',
                );
              } catch (e) {
                print(
                  'AudioGarbageCollector: Failed to delete \${entity.path} -> \$e',
                );
              }
            }
          }
        }
      }
    });
  }
}
