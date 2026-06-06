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

  const TodoCard({
    super.key,
    required this.todo,
    required this.onDelete,
    required this.onToggleDone,
    required this.onStatusChanged,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = todo.status == TodoStatus.done;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E6DF), width: 0.5),
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
                  color: isDone
                      ? const Color(0xFF1A1A1A)
                      : Colors.transparent,
                  border: Border.all(
                    color: isDone
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFB4B2A9),
                    width: 1.5,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check,
                        size: 13, color: Colors.white)
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
                    Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1A1A),
                        decoration:
                            isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (todo.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        todo.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888780),
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
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

                        // Status dropdown
                        _StatusDropdown(
                          current: todo.status,
                          onChanged: onStatusChanged,
                        ),

                        const Spacer(),

                        _IconBtn(
                            icon: Icons.edit_outlined, onTap: onEdit),
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

class _StatusDropdown extends StatelessWidget {
  final TodoStatus current;
  final ValueChanged<TodoStatus> onChanged;

  const _StatusDropdown(
      {required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F0),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: const Color(0xFFD3D1C7), width: 0.5),
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
          icon: const Icon(Icons.expand_more,
              size: 14, color: Color(0xFF888780)),
          items: TodoStatus.values
              .map((s) =>
                  DropdownMenuItem(value: s, child: Text(s.label)))
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
