import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/note_model.dart';

class NoteCard extends StatefulWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.gradient,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onFavorite,
  });

  final NoteModel note;
  final List<Color> gradient;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onFavorite;

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final textColor = const Color(0xFF111827);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? 0.965 : 1,
        curve: Curves.easeOutBack,
        duration: const Duration(milliseconds: 180),
        child: Hero(
          tag: 'note-${note.id}',
          child: Material(
            color: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.gradient,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: widget.selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.56),
                  width: widget.selected ? 2.2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.last.withValues(alpha: widget.selected ? 0.62 : 0.34),
                    blurRadius: widget.selected ? 34 : 24,
                    spreadRadius: widget.selected ? 2 : 0,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.48),
                    blurRadius: 18,
                    offset: const Offset(-8, -8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _NoisePainter(color: Colors.white.withValues(alpha: 0.13)),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.34),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                note.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.76),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _RoundIcon(
                            icon: note.isLocked
                                ? Icons.lock_rounded
                                : note.isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                            active: note.isLocked || note.isFavorite,
                            onTap: note.isLocked ? null : widget.onFavorite,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        note.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 19,
                          height: 1.08,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            note.isLocked ? 'Private thought\nTap to unlock' : note.content,
                            key: ValueKey(note.isLocked),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.68),
                              height: 1.36,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            _moodIcon(note.colorIndex),
                            color: textColor.withValues(alpha: 0.62),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              DateFormat('MMM d, h:mm a').format(note.dateUpdated),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.62),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _moodIcon(int index) {
    const icons = [
      Icons.water_drop_rounded,
      Icons.favorite_rounded,
      Icons.eco_rounded,
      Icons.wb_sunny_rounded,
      Icons.auto_awesome_rounded,
      Icons.nightlight_round,
    ];
    return icons[index % icons.length];
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.active,
    this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF111827).withValues(alpha: 0.86)
              : Colors.white.withValues(alpha: 0.34),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? Colors.white : const Color(0xFF111827),
        ),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  const _NoisePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var i = 0; i < 70; i++) {
      final x = ((i * 41) % size.width.toInt()).toDouble();
      final y = ((i * 29) % size.height.toInt()).toDouble();
      canvas.drawCircle(Offset(x, y), i.isEven ? 0.7 : 0.45, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) => false;
}
