import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multitracks_df_pro/features/player_mixer/presentation/pages/stage_page.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup global error handling
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    debugPrint('StackTrace: ${details.stack}');
  };

  try {
    debugPrint('## STARTUP: Initializing DI...');
    // Initialize dependency injection
    await di.init();

    debugPrint('## STARTUP: Setting orientations...');
    // Allow all orientations (portrait and landscape)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    debugPrint('## STARTUP: Running App');
    runApp(const MultitracksDFProApp());
  } catch (e, stack) {
    debugPrint('## FATAL STARTUP ERROR: $e');
    debugPrint('## STACKTRACE: $stack');
  }
}

class MultitracksDFProApp extends StatelessWidget {
  const MultitracksDFProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multitracks DF Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Apply the strict dark theme
      home: const StagePage(),
    );
  }
}
