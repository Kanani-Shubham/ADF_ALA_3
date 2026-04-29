import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/pin_service.dart';
import 'home_screen.dart';

enum LockMode { unlockApp, unlockNote, createPin }

class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.mode,
    this.onUnlocked,
  });

  final LockMode mode;
  final VoidCallback? onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _shakeController;
  late final AnimationController _glowController;
  String? _error;
  bool _busy = false;

  String get _title {
    switch (widget.mode) {
      case LockMode.createPin:
        return 'Create secure PIN';
      case LockMode.unlockNote:
        return 'Private note';
      case LockMode.unlockApp:
        return 'Welcome back';
    }
  }

  int get _pinLength => 4;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 430));
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  Future<void> _submit() async {
    final pin = _pinController.text.trim();
    if (pin.length < _pinLength) {
      _fail('Enter $_pinLength digits.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    if (widget.mode == LockMode.createPin) {
      await PinService.savePin(pin);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }

    final ok = await PinService.verifyPin(pin);
    if (!mounted) return;
    if (!ok) {
      _fail('Incorrect PIN. Try again.');
      return;
    }

    if (widget.mode == LockMode.unlockApp) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      widget.onUnlocked?.call();
      Navigator.of(context).pop(true);
    }
  }

  void _fail(String message) {
    HapticFeedback.mediumImpact();
    _pinController.clear();
    setState(() {
      _busy = false;
      _error = message;
    });
    _shakeController
      ..reset()
      ..forward();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050713),
      body: AnimatedBuilder(
        animation: Listenable.merge([_shakeController, _glowController]),
        builder: (context, child) {
          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF050713), Color(0xFF10172A), Color(0xFF1B1230)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 120 + math.sin(_glowController.value * math.pi) * 24,
                  left: MediaQuery.sizeOf(context).width / 2 - 150,
                  child: Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF7C9CFF).withValues(alpha: 0.32),
                          const Color(0xFF7C9CFF).withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                child!,
              ],
            ),
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (widget.mode != LockMode.unlockApp)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      color: Colors.white,
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                const Spacer(),
                Container(
                  height: 92,
                  width: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF8BE7FF), Color(0xFF6554F2)]),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6554F2).withValues(alpha: 0.42),
                        blurRadius: 40,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.mode == LockMode.createPin ? Icons.password_rounded : Icons.fingerprint_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  _title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.mode == LockMode.createPin
                      ? 'Set a PIN for app lock and private notes.'
                      : 'Enter your PIN to continue securely.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 34),
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    final value = math.sin(_shakeController.value * math.pi * 6) * 12 * (1 - _shakeController.value);
                    return Transform.translate(offset: Offset(value, 0), child: child);
                  },
                  child: _PinBoxes(
                    controller: _pinController,
                    focusNode: _focusNode,
                    length: _pinLength,
                    onComplete: _submit,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _error == null
                      ? const SizedBox(height: 38)
                      : Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(
                            _error!,
                            key: ValueKey(_error),
                            style: const TextStyle(color: Color(0xFFFFB4C4), fontWeight: FontWeight.w800),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6554F2), Color(0xFF8BE7FF)]),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6554F2).withValues(alpha: 0.36),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: _busy ? null : _submit,
                      icon: _busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.lock_open_rounded),
                      label: Text(widget.mode == LockMode.createPin ? 'Save PIN' : 'Unlock'),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Icon(Icons.fingerprint_rounded, color: Colors.white.withValues(alpha: 0.30), size: 44),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinBoxes extends StatefulWidget {
  const _PinBoxes({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.onComplete,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final VoidCallback onComplete;

  @override
  State<_PinBoxes> createState() => _PinBoxesState();
}

class _PinBoxesState extends State<_PinBoxes> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
    if (widget.controller.text.length == widget.length) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text;
    return GestureDetector(
      onTap: widget.focusNode.requestFocus,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 1,
            width: 1,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: widget.length,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(counterText: '', border: InputBorder.none),
              style: const TextStyle(color: Colors.transparent),
              cursorColor: Colors.transparent,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                _PinBox(filled: i < value.length, active: i == value.length),
                if (i != widget.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PinBox extends StatelessWidget {
  const _PinBox({
    required this.filled,
    required this.active,
  });

  final bool filled;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      height: 62,
      width: 56,
      decoration: BoxDecoration(
        color: filled
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: active || filled
              ? const Color(0xFF8BE7FF)
              : Colors.white.withValues(alpha: 0.16),
          width: active ? 2 : 1,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: const Color(0xFF8BE7FF).withValues(alpha: 0.22),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Center(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: filled ? 1 : 0.4,
          child: Container(
            height: 13,
            width: 13,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
