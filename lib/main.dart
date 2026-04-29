import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/note_provider.dart';
import 'screens/splash_lock_screen.dart';
import 'services/hive_service.dart';
import 'utils/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const SecureNotesApp());
}

class SecureNotesApp extends StatelessWidget {
  const SecureNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NoteProvider()..load(),
      child: Consumer<NoteProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'Secure Notes Pro',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: provider.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashLockScreen(),
          );
        },
      ),
    );
  }
}
