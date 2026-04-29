import 'package:flutter/material.dart';

import '../services/pin_service.dart';
import 'home_screen.dart';
import 'lock_screen.dart';

class SplashLockScreen extends StatefulWidget {
  const SplashLockScreen({super.key});

  @override
  State<SplashLockScreen> createState() => _SplashLockScreenState();
}

class _SplashLockScreenState extends State<SplashLockScreen> {
  @override
  void initState() {
    super.initState();
    _decideStartScreen();
  }

  Future<void> _decideStartScreen() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final locked = await PinService.hasPin() && await PinService.isAppLockEnabled();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: locked
              ? const LockScreen(mode: LockMode.unlockApp)
              : const HomeScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 86,
              width: 86,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const Icon(Icons.lock_rounded, size: 42),
            ),
            const SizedBox(height: 22),
            Text(
              'Secure Notes Pro',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            const SizedBox(
              width: 120,
              child: LinearProgressIndicator(minHeight: 4),
            ),
          ],
        ),
      ),
    );
  }
}
