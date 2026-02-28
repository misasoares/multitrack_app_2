import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multitracks_df_pro/features/player_mixer/presentation/pages/music_library_page.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await di.init();

  // Allow all orientations (portrait and landscape)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MultitracksDFProApp());
}

class MultitracksDFProApp extends StatelessWidget {
  const MultitracksDFProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multitracks DF Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Apply the strict dark theme
      home: const MusicLibraryPage(),
    );
  }
}
