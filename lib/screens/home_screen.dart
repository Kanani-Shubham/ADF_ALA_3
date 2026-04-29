import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/note_model.dart';
import '../providers/note_provider.dart';
import '../services/pin_service.dart';
import '../utils/theme.dart';
import '../widgets/note_card.dart';
import '../widgets/search_bar.dart';
import 'add_edit_note_screen.dart';
import 'lock_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _fabController;
  int _tabIndex = 0;
  bool _fabOpen = false;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _openNote(NoteModel note) async {
    final provider = context.read<NoteProvider>();
    if (provider.isSelecting) {
      provider.toggleSelection(note.id);
      return;
    }

    if (note.isLocked) {
      final unlocked = await Navigator.of(context).push<bool>(
        _premiumRoute(const LockScreen(mode: LockMode.unlockNote), fullscreenDialog: true),
      );
      if (unlocked != true || !mounted) return;
    }

    Navigator.of(context).push(_premiumRoute(AddEditNoteScreen(note: note)));
  }

  void _createNote({String? seed}) {
    _closeFab();
    Navigator.of(context).push(_premiumRoute(AddEditNoteScreen(initialContent: seed)));
  }

  void _toggleFab() {
    setState(() => _fabOpen = !_fabOpen);
    _fabOpen ? _fabController.forward() : _fabController.reverse();
  }

  void _closeFab() {
    if (!_fabOpen) return;
    setState(() => _fabOpen = false);
    _fabController.reverse();
  }

  PageRoute<T> _premiumRoute<T>(Widget page, {bool fullscreenDialog = false}) {
    return PageRouteBuilder<T>(
      fullscreenDialog: fullscreenDialog,
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleAppLock(NoteProvider provider) async {
    if (!provider.appLockEnabled) {
      final hasPin = await PinService.hasPin();
      if (!mounted) return;
      if (!hasPin) {
        final created = await Navigator.of(context).push<bool>(
          _premiumRoute(const LockScreen(mode: LockMode.createPin), fullscreenDialog: true),
        );
        if (created != true) return;
      }
      await provider.setAppLockEnabled(true);
    } else {
      await provider.setAppLockEnabled(false);
    }
  }

  Future<void> _exportNotes(NoteProvider provider) async {
    final json = provider.exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    _showTextDialog(title: 'Backup copied', text: json, readOnly: true);
  }

  Future<void> _importNotes(NoteProvider provider) async {
    final controller = TextEditingController();
    final imported = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore backup'),
        content: TextField(
          controller: controller,
          minLines: 8,
          maxLines: 12,
          decoration: const InputDecoration(hintText: 'Paste exported JSON here'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final count = await provider.importJson(controller.text);
                if (context.mounted) Navigator.of(context).pop(count);
              } catch (_) {
                if (context.mounted) Navigator.of(context).pop(-1);
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || imported == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(imported < 0 ? 'Invalid backup JSON.' : 'Restored $imported notes.')),
    );
  }

  void _showTextDialog({
    required String title,
    required String text,
    required bool readOnly,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: TextEditingController(text: text),
            readOnly: readOnly,
            minLines: 8,
            maxLines: 12,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteProvider>(
      builder: (context, provider, child) {
        final notes = provider.filteredNotes;
        final body = _tabIndex == 2
            ? _SettingsView(
                provider: provider,
                onToggleAppLock: () => _toggleAppLock(provider),
                onExport: () => _exportNotes(provider),
                onImport: () => _importNotes(provider),
              )
            : _NotesView(
                notes: notes,
                provider: provider,
                favoritesTab: _tabIndex == 1,
                onOpen: _openNote,
              );

        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(provider.isSelecting ? '${provider.selectedIds.length} selected' : 'Secure Notes Pro'),
            leading: provider.isSelecting
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: provider.clearSelection,
                  )
                : null,
            actions: [
              if (provider.isSelecting)
                IconButton(
                  tooltip: 'Delete selected',
                  icon: const Icon(Icons.delete_rounded),
                  onPressed: provider.deleteSelected,
                )
              else ...[
                IconButton(
                  tooltip: 'Theme',
                  icon: Icon(provider.darkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                  onPressed: provider.toggleDarkMode,
                ),
                PopupMenuButton<SortMode>(
                  tooltip: 'Sort',
                  icon: const Icon(Icons.sort_rounded),
                  onSelected: provider.setSortMode,
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: SortMode.updated, child: Text('Latest updated')),
                    PopupMenuItem(value: SortMode.created, child: Text('Newest created')),
                    PopupMenuItem(value: SortMode.title, child: Text('Title A-Z')),
                  ],
                ),
              ],
            ],
          ),
          body: _PremiumBackground(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              child: body,
            ),
          ),
          floatingActionButton: _tabIndex == 2
              ? null
              : _ExpandingFab(
                  controller: _fabController,
                  open: _fabOpen,
                  onToggle: _toggleFab,
                  onAdd: () => _createNote(),
                  onVoice: () => _createNote(seed: 'Voice note idea: '),
                  onQuick: () => _createNote(seed: 'Quick thought: '),
                ),
          bottomNavigationBar: _GlassBottomNav(
            index: _tabIndex,
            onChanged: (index) {
              _closeFab();
              setState(() => _tabIndex = index);
              provider.setFavoritesOnly(index == 1);
            },
          ),
        );
      },
    );
  }
}

class _NotesView extends StatelessWidget {
  const _NotesView({
    required this.notes,
    required this.provider,
    required this.favoritesTab,
    required this.onOpen,
  });

  final List<NoteModel> notes;
  final NoteProvider provider;
  final bool favoritesTab;
  final ValueChanged<NoteModel> onOpen;

  @override
  Widget build(BuildContext context) {
    final total = provider.notes.length;
    final favorites = provider.notes.where((note) => note.isFavorite).length;
    final locked = provider.notes.where((note) => note.isLocked).length;
    return CustomScrollView(
      key: ValueKey('notes-$favoritesTab'),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GreetingHeader(favoritesTab: favoritesTab),
                const SizedBox(height: 18),
                NotesSearchBar(value: provider.query, onChanged: provider.setQuery),
                const SizedBox(height: 16),
                _CategoryRail(provider: provider),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _StatCard(icon: Icons.sticky_note_2_rounded, label: 'Notes', value: '$total')),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(icon: Icons.favorite_rounded, label: 'Favorites', value: '$favorites')),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(icon: Icons.lock_rounded, label: 'Locked', value: '$locked')),
                  ],
                ),
                if (provider.notes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _ActivityTimeline(notes: provider.notes),
                ],
              ],
            ),
          ),
        ),
        if (notes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(favoritesTab: favoritesTab),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 116),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.crossAxisExtent > 700 ? 3 : 2;
                return SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.76,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 260 + (index * 45).clamp(0, 420)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 18 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Dismissible(
                        key: ValueKey(note.id),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            provider.toggleFavorite(note);
                            return false;
                          }
                          return true;
                        },
                        onDismissed: (_) => provider.deleteNote(note.id),
                        background: _SwipeAction(
                          alignment: Alignment.centerLeft,
                          icon: Icons.favorite_rounded,
                          label: 'Favorite',
                          color: const Color(0xFFFF5A8A),
                        ),
                        secondaryBackground: _SwipeAction(
                          alignment: Alignment.centerRight,
                          icon: Icons.delete_rounded,
                          label: 'Delete',
                          color: const Color(0xFFFF5E57),
                        ),
                        child: NoteCard(
                          note: note,
                          gradient: AppTheme.noteGradients[note.colorIndex % AppTheme.noteGradients.length],
                          selected: provider.selectedIds.contains(note.id),
                          onTap: () => onOpen(note),
                          onLongPress: () => provider.toggleSelection(note.id),
                          onFavorite: () => provider.toggleFavorite(note),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.favoritesTab});

  final bool favoritesTab;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                favoritesTab ? 'Favorite Notes' : '$greeting, Shubham',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                favoritesTab ? 'Your most loved thoughts live here' : 'Capture your thoughts beautifully',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        _GlassIcon(icon: Icons.auto_awesome_rounded),
      ],
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({required this.provider});

  final NoteProvider provider;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: provider.categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = provider.categories[index];
          final selected = provider.category == category;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(colors: [Color(0xFF6554F2), Color(0xFF9D7CFF)])
                  : null,
              color: selected ? null : Colors.white.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withValues(alpha: 0.56)),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6554F2).withValues(alpha: 0.28),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ]
                  : null,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: () => provider.setCategory(category),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                child: Text(
                  category,
                  style: TextStyle(
                    color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ActivityTimeline extends StatelessWidget {
  const _ActivityTimeline({required this.notes});

  final List<NoteModel> notes;

  @override
  Widget build(BuildContext context) {
    final recent = notes.toList()
      ..sort((a, b) => b.dateUpdated.compareTo(a.dateUpdated));
    final visible = recent.take(3).toList();
    return _GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded, size: 18),
              const SizedBox(width: 8),
              Text(
                'Recent activity',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final note in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    height: 9,
                    width: 9,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Color(0xFF6554F2), Color(0xFF8BE7FF)]),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({
    required this.provider,
    required this.onToggleAppLock,
    required this.onExport,
    required this.onImport,
  });

  final NoteProvider provider;
  final VoidCallback onToggleAppLock;
  final VoidCallback onExport;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('settings'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 116),
      children: [
        Text(
          'Control Center',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Security, appearance, and backups in one polished space',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 22),
        _SettingsSection(
          title: 'Security',
          children: [
            _SettingTile(
              icon: Icons.lock_rounded,
              title: 'App lock',
              subtitle: provider.appLockEnabled ? 'PIN required on startup' : 'Startup opens directly',
              trailing: Switch.adaptive(
                value: provider.appLockEnabled,
                onChanged: (_) => onToggleAppLock(),
              ),
            ),
          ],
        ),
        _SettingsSection(
          title: 'Appearance',
          children: [
            _SettingTile(
              icon: Icons.dark_mode_rounded,
              title: 'Premium dark mode',
              subtitle: provider.darkMode ? 'Deep glow theme enabled' : 'Soft pastel theme enabled',
              trailing: Switch.adaptive(
                value: provider.darkMode,
                onChanged: (_) => provider.toggleDarkMode(),
              ),
            ),
          ],
        ),
        _SettingsSection(
          title: 'Backup',
          children: [
            _SettingTile(
              icon: Icons.ios_share_rounded,
              title: 'Export backup',
              subtitle: '${provider.notes.length} notes as JSON',
              onTap: onExport,
            ),
            _SettingTile(
              icon: Icons.restore_rounded,
              title: 'Restore backup',
              subtitle: 'Import notes from exported JSON',
              onTap: onImport,
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassPanel(
        padding: EdgeInsets.zero,
        child: ListTile(
          onTap: onTap,
          minVerticalPadding: 18,
          leading: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6554F2), Color(0xFF8BE7FF)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6554F2).withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(subtitle),
          trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.favoritesTab});

  final bool favoritesTab;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: _GlassPanel(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GlassIcon(
                icon: favoritesTab ? Icons.favorite_border_rounded : Icons.note_add_rounded,
                size: 76,
              ),
              const SizedBox(height: 18),
              Text(
                favoritesTab ? 'No favorites yet' : 'Your first note awaits',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                favoritesTab
                    ? 'Tap the heart on an unlocked note to keep it close.'
                    : 'Create a polished, private note with the plus button.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandingFab extends StatelessWidget {
  const _ExpandingFab({
    required this.controller,
    required this.open,
    required this.onToggle,
    required this.onAdd,
    required this.onVoice,
    required this.onQuick,
  });

  final AnimationController controller;
  final bool open;
  final VoidCallback onToggle;
  final VoidCallback onAdd;
  final VoidCallback onVoice;
  final VoidCallback onQuick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 226,
      width: 178,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          _FabOption(animation: controller, index: 3, icon: Icons.bolt_rounded, label: 'Quick', onTap: onQuick),
          _FabOption(animation: controller, index: 2, icon: Icons.mic_rounded, label: 'Voice', onTap: onVoice),
          _FabOption(animation: controller, index: 1, icon: Icons.edit_rounded, label: 'Add Note', onTap: onAdd),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF171717), Color(0xFF6554F2)]),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6554F2).withValues(alpha: 0.42),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: FloatingActionButton(
              elevation: 0,
              backgroundColor: Colors.transparent,
              onPressed: onToggle,
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 240),
                turns: open ? 0.125 : 0,
                child: Icon(open ? Icons.close_rounded : Icons.add_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FabOption extends StatelessWidget {
  const _FabOption({
    required this.animation,
    required this.index,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Animation<double> animation;
  final int index;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = Curves.easeOutBack.transform(animation.value);
        return Positioned(
          right: 0,
          bottom: 66.0 * index * value,
          child: Opacity(
            opacity: animation.value,
            child: Transform.scale(scale: value.clamp(0.0, 1.0), child: child),
          ),
        );
      },
      child: _GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassBottomNav extends StatelessWidget {
  const _GlassBottomNav({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: _GlassPanel(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            _NavItem(icon: Icons.grid_view_rounded, label: 'Notes', selected: index == 0, onTap: () => onChanged(0)),
            _NavItem(icon: Icons.favorite_rounded, label: 'Love', selected: index == 1, onTap: () => onChanged(1)),
            _NavItem(icon: Icons.tune_rounded, label: 'Control', selected: index == 2, onTap: () => onChanged(2)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(colors: [Color(0xFF6554F2), Color(0xFF8BE7FF)])
                : null,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: selected ? Colors.white : null),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: Text(
                          label,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumBackground extends StatefulWidget {
  const _PremiumBackground({required this.child});

  final Widget child;

  @override
  State<_PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<_PremiumBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF080B16), Color(0xFF10172A), Color(0xFF17102A)]
                  : const [Color(0xFFF9F6FF), Color(0xFFEAF8FF), Color(0xFFFFF1F6)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 70 + math.sin(_controller.value * math.pi * 2) * 16,
                right: -40,
                child: _Glow(size: 190, color: const Color(0xFF8BE7FF)),
              ),
              Positioned(
                top: 260,
                left: -52 + math.cos(_controller.value * math.pi * 2) * 12,
                child: _Glow(size: 210, color: const Color(0xFFC7A5FF)),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _ParticlePainter(progress: _controller.value, dark: isDark),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.26), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({required this.progress, required this.dark});

  final double progress;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = (dark ? Colors.white : const Color(0xFF6554F2)).withValues(alpha: dark ? 0.08 : 0.06);
    for (var i = 0; i < 24; i++) {
      final x = (i * 67.0 + math.sin(progress * math.pi * 2 + i) * 12) % size.width;
      final y = (i * 103.0 + progress * 36) % size.height;
      canvas.drawCircle(Offset(x, y), 1.3 + (i % 3) * 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => oldDelegate.progress != progress;
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.64)),
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

class _GlassIcon extends StatelessWidget {
  const _GlassIcon({
    required this.icon,
    this.size = 52,
  });

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFECE7FF)]),
        borderRadius: BorderRadius.circular(size / 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6554F2).withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF6554F2)),
    );
  }
}

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({
    required this.alignment,
    required this.icon,
    required this.label,
    required this.color,
  });

  final Alignment alignment;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
