import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies
  await di.init();

  // Enforce Landscape Orientation
  await SystemChrome.setPreferredOrientations([
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
      home: const Scaffold(
        body: Center(child: Text('Multitracks DF Pro - Init')),
      ),
    );
  }
}
