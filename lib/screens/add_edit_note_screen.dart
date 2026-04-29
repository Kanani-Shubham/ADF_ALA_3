import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note_model.dart';
import '../providers/note_provider.dart';
import '../services/pin_service.dart';
import '../utils/theme.dart';
import 'lock_screen.dart';

class AddEditNoteScreen extends StatefulWidget {
  const AddEditNoteScreen({
    super.key,
    this.note,
    this.initialContent,
  });

  final NoteModel? note;
  final String? initialContent;

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> with SingleTickerProviderStateMixin {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _categoryController;
  late final AnimationController _toolbarController;
  late bool _locked;
  late int _colorIndex;

  bool get _editing => widget.note != null;

  static const List<String> _quickCategories = [
    'Personal',
    'Work',
    'Ideas',
    'Study',
    'Dreams',
    'Plans',
  ];

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? widget.initialContent ?? '');
    _categoryController = TextEditingController(text: note?.category ?? 'Personal');
    _locked = note?.isLocked ?? false;
    _colorIndex = note?.colorIndex ?? 0;
    _toolbarController = AnimationController(vsync: this, duration: const Duration(milliseconds: 460))..forward();
  }

  Future<void> _toggleLocked(bool value) async {
    if (!value) {
      setState(() => _locked = false);
      return;
    }
    final hasPin = await PinService.hasPin();
    if (!mounted) return;
    if (!hasPin) {
      final created = await Navigator.of(context).push<bool>(
        PageRouteBuilder(
          fullscreenDialog: true,
          pageBuilder: (context, animation, secondaryAnimation) => const LockScreen(mode: LockMode.createPin),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
      if (created != true) return;
    }
    setState(() => _locked = true);
  }

  Future<void> _save() async {
    final provider = context.read<NoteProvider>();
    if (_editing) {
      await provider.updateNote(
        widget.note!.copyWith(
          title: _titleController.text,
          content: _contentController.text,
          isLocked: _locked,
          category: _categoryController.text,
          colorIndex: _colorIndex,
        ),
      );
    } else {
      await provider.addNote(
        title: _titleController.text,
        content: _contentController.text,
        isLocked: _locked,
        category: _categoryController.text,
        colorIndex: _colorIndex,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    _toolbarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = AppTheme.noteGradients[_colorIndex % AppTheme.noteGradients.length];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Hero(
        tag: _editing ? 'note-${widget.note!.id}' : 'new-note',
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF090B16), Color(0xFF111827), Color(0xFF1B1430)]
                    : [gradient.first.withValues(alpha: 0.72), const Color(0xFFFFFFFF), gradient.last.withValues(alpha: 0.50)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _EditorToolbar(
                    animation: _toolbarController,
                    editing: _editing,
                    locked: _locked,
                    onBack: () => Navigator.of(context).pop(),
                    onSave: _save,
                    onLock: () => _toggleLocked(!_locked),
                  ),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      children: [
                        _GlassEditorPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _titleController,
                                textCapitalization: TextCapitalization.sentences,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0,
                                    ),
                                decoration: const InputDecoration(
                                  hintText: 'Untitled masterpiece',
                                  border: InputBorder.none,
                                  filled: false,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _contentController,
                                minLines: 13,
                                maxLines: 22,
                                textCapitalization: TextCapitalization.sentences,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      height: 1.58,
                                      fontWeight: FontWeight.w500,
                                    ),
                                decoration: InputDecoration(
                                  hintText: widget.initialContent == null
                                      ? 'Start writing something magical...'
                                      : 'Shape this thought into something useful...',
                                  border: InputBorder.none,
                                  filled: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _GlassEditorPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel(icon: Icons.sell_rounded, label: 'Category'),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (final category in _quickCategories)
                                    _CategoryChip(
                                      label: category,
                                      selected: _categoryController.text == category,
                                      onTap: () => setState(() => _categoryController.text = category),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _categoryController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  hintText: 'Custom category',
                                  prefixIcon: Icon(Icons.edit_note_rounded),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _GlassEditorPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel(icon: Icons.palette_rounded, label: 'Mood color'),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  for (var i = 0; i < AppTheme.noteGradients.length; i++)
                                    _MoodColorButton(
                                      colors: AppTheme.noteGradients[i],
                                      selected: _colorIndex == i,
                                      onTap: () => setState(() => _colorIndex = i),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.animation,
    required this.editing,
    required this.locked,
    required this.onBack,
    required this.onSave,
    required this.onLock,
  });

  final Animation<double> animation;
  final bool editing;
  final bool locked;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = Curves.easeOutCubic.transform(animation.value);
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, -14 * (1 - value)), child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
              ),
              child: Row(
                children: [
                  IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)),
                  Expanded(
                    child: Text(
                      editing ? 'Refine note' : 'New note',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    tooltip: locked ? 'Unlock note' : 'Lock note',
                    onPressed: onLock,
                    icon: Icon(locked ? Icons.lock_rounded : Icons.lock_open_rounded),
                  ),
                  FilledButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassEditorPanel extends StatelessWidget {
  const _GlassEditorPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.09 : 0.66)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.07),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? const LinearGradient(colors: [Color(0xFF6554F2), Color(0xFF9D7CFF)]) : null,
          color: selected ? null : Theme.of(context).colorScheme.surface.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : null,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MoodColorButton extends StatelessWidget {
  const _MoodColorButton({
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final List<Color> colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: selected ? 1.12 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Theme.of(context).colorScheme.onSurface : Colors.white,
              width: selected ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: selected ? 0.42 : 0.22),
                blurRadius: selected ? 22 : 12,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: selected ? const Icon(Icons.check_rounded, color: Colors.white) : null,
        ),
      ),
    );
  }
}
