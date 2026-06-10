import 'package:flutter/material.dart';
import '../models/todo.dart';

extension _TodoStatusColors on TodoStatus {
  Color get badgeColor {
    switch (this) {
      case TodoStatus.pending:
        return const Color(0xFFEF9F27);
      case TodoStatus.inProgress:
        return const Color(0xFF378ADD);
      case TodoStatus.done:
        return const Color(0xFF639922);
    }
  }

  Color get badgeBackground {
    switch (this) {
      case TodoStatus.pending:
        return const Color(0xFFFAEEDA);
      case TodoStatus.inProgress:
        return const Color(0xFFE6F1FB);
      case TodoStatus.done:
        return const Color(0xFFEAF3DE);
    }
  }
}

class TodoCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback onDelete;
  final VoidCallback onToggleDone;
  final ValueChanged<TodoStatus> onStatusChanged;
  final VoidCallback onEdit;
  final String searchQuery; // empty string when no search is active

  const TodoCard({
    super.key,
    required this.todo,
    required this.onDelete,
    required this.onToggleDone,
    required this.onStatusChanged,
    required this.onEdit,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final isDone = todo.status == TodoStatus.done;
    final isOverdue = todo.targetDate != null &&
        !isDone &&
        todo.targetDate!.isBefore(
          DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0),
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue ? const Color(0xFFF5C0C0) : const Color(0xFFE8E6DF),
          width: isOverdue ? 1.0 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Check circle
            GestureDetector(
              onTap: onToggleDone,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? const Color(0xFF1A1A1A) : Colors.transparent,
                  border: Border.all(
                    color: isDone ? const Color(0xFF1A1A1A) : const Color(0xFFB4B2A9),
                    width: 1.5,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Opacity(
                opacity: isDone ? 0.55 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description — with optional highlight
                    if (todo.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _HighlightText(
                        text: todo.description,
                        query: searchQuery,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888780),
                          height: 1.5,
                        ),
                      ),
                    ],

                    // Target date
                    if (todo.targetDate != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: isOverdue
                                ? const Color(0xFFA32D2D)
                                : const Color(0xFF888780),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(todo.targetDate!),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isOverdue
                                  ? const Color(0xFFA32D2D)
                                  : const Color(0xFF888780),
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDE8E8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Overdue',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFA32D2D),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: todo.status.badgeBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            todo.status.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: todo.status.badgeColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusDropdown(
                          current: todo.status,
                          onChanged: onStatusChanged,
                        ),
                        const Spacer(),
                        _IconBtn(icon: Icons.edit_outlined, onTap: onEdit),
                        const SizedBox(width: 4),
                        _IconBtn(
                          icon: Icons.delete_outline,
                          onTap: onDelete,
                          color: const Color(0xFFA32D2D),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Priority badge ────────────────────────────────────────────────────────────

class _PriorityBadge extends StatelessWidget {
  final TodoPriority priority;

  const _PriorityBadge({required this.priority});

  static Color _bg(TodoPriority p) {
    switch (p) {
      case TodoPriority.high:   return const Color(0xFFFDE8E8);
      case TodoPriority.medium: return const Color(0xFFFAEEDA);
      case TodoPriority.low:    return const Color(0xFFEAF3DE);
    }
  }

  static Color _fg(TodoPriority p) {
    switch (p) {
      case TodoPriority.high:   return const Color(0xFFA32D2D);
      case TodoPriority.medium: return const Color(0xFFEF9F27);
      case TodoPriority.low:    return const Color(0xFF639922);
    }
  }

  static IconData _icon(TodoPriority p) {
    switch (p) {
      case TodoPriority.high:   return Icons.keyboard_double_arrow_up_rounded;
      case TodoPriority.medium: return Icons.remove_rounded;
      case TodoPriority.low:    return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _bg(priority),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(priority), size: 12, color: _fg(priority)),
          const SizedBox(width: 3),
          Text(
            priority.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _fg(priority),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Highlight widget ───────────────────────────────────────────────────────────

/// Renders [text] with every occurrence of [query] highlighted in amber.
/// Falls back to a plain Text widget when [query] is empty.
class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: style);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final matchIndex = lowerText.indexOf(lowerQuery, start);
      if (matchIndex == -1) {
        // Append remaining text
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      // Text before the match
      if (matchIndex > start) {
        spans.add(TextSpan(text: text.substring(start, matchIndex)));
      }
      // The matched portion — highlighted
      spans.add(TextSpan(
        text: text.substring(matchIndex, matchIndex + query.length),
        style: const TextStyle(
          backgroundColor: Color(0xFFFFF0A0),
          color: Color(0xFF1A1A1A),
          fontWeight: FontWeight.w600,
        ),
      ));
      start = matchIndex + query.length;
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

class _StatusDropdown extends StatelessWidget {
  final TodoStatus current;
  final ValueChanged<TodoStatus> onChanged;

  const _StatusDropdown({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F0),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD3D1C7), width: 0.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TodoStatus>(
          value: current,
          isDense: true,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF888780),
            fontWeight: FontWeight.w500,
          ),
          icon: const Icon(Icons.expand_more, size: 14, color: Color(0xFF888780)),
          items: TodoStatus.values
              .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
              .toList(),
          onChanged: (s) {
            if (s != null) onChanged(s);
          },
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFF888780),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}