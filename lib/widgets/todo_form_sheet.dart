import 'package:flutter/material.dart';
import '../models/todo.dart';

class TodoFormSheet extends StatefulWidget {
  final Todo? todo;
  final void Function(
    String title,
    String description,
    TodoStatus status,
    TodoPriority priority,
    DateTime? targetDate,
  ) onSave;

  const TodoFormSheet({super.key, this.todo, required this.onSave});

  @override
  State<TodoFormSheet> createState() => _TodoFormSheetState();
}

class _TodoFormSheetState extends State<TodoFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late TodoStatus _status;
  late TodoPriority _priority;
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    _titleCtrl   = TextEditingController(text: widget.todo?.title ?? '');
    _descCtrl    = TextEditingController(text: widget.todo?.description ?? '');
    _status      = widget.todo?.status   ?? TodoStatus.pending;
    _priority    = widget.todo?.priority ?? TodoPriority.medium;
    _targetDate  = widget.todo?.targetDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1A1A1A),
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  void _clearDate() => setState(() => _targetDate = null);

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    widget.onSave(title, _descCtrl.text.trim(), _status, _priority, _targetDate);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.todo != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  isEdit ? 'Edit task' : 'New task',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Color(0xFF888780)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _FieldLabel('Title'),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              autofocus: !isEdit,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration('What needs to be done?'),
            ),
            const SizedBox(height: 16),

            _FieldLabel('Description'),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration('Add details (optional)...'),
            ),
            const SizedBox(height: 16),

            // Status + Priority side by side
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Status'),
                      const SizedBox(height: 6),
                      _DropdownField<TodoStatus>(
                        value: _status,
                        items: TodoStatus.values,
                        labelOf: (s) => s.label,
                        onChanged: (s) { if (s != null) setState(() => _status = s); },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Priority'),
                      const SizedBox(height: 6),
                      _PriorityDropdown(
                        value: _priority,
                        onChanged: (p) { if (p != null) setState(() => _priority = p); },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _FieldLabel('Target Date'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFD3D1C7), width: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: Color(0xFF888780)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _targetDate != null
                            ? _formatDate(_targetDate!)
                            : 'Select a date (optional)',
                        style: TextStyle(
                          fontSize: 14,
                          color: _targetDate != null
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFFB4B2A9),
                        ),
                      ),
                    ),
                    if (_targetDate != null)
                      GestureDetector(
                        onTap: _clearDate,
                        child: const Icon(Icons.close,
                            size: 16, color: Color(0xFF888780)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
                ),
                child: Text(isEdit ? 'Save changes' : 'Add task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB4B2A9), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD3D1C7), width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD3D1C7), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1A1A1A), width: 1.0),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}

// ── Generic dropdown field ────────────────────────────────────────────────────

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD3D1C7), width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(labelOf(i))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Priority dropdown with colour indicators ──────────────────────────────────

class _PriorityDropdown extends StatelessWidget {
  final TodoPriority value;
  final ValueChanged<TodoPriority?> onChanged;

  const _PriorityDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD3D1C7), width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TodoPriority>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
          items: TodoPriority.values.map((p) {
            return DropdownMenuItem(
              value: p,
              child: Row(
                children: [
                  _PriorityDot(priority: p),
                  const SizedBox(width: 8),
                  Text(p.label),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Shared priority dot ───────────────────────────────────────────────────────

class _PriorityDot extends StatelessWidget {
  final TodoPriority priority;
  final double size;

  const _PriorityDot({required this.priority, this.size = 8});

  static Color colorOf(TodoPriority p) {
    switch (p) {
      case TodoPriority.high:   return const Color(0xFFA32D2D);
      case TodoPriority.medium: return const Color(0xFFEF9F27);
      case TodoPriority.low:    return const Color(0xFF639922);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorOf(priority),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

Widget _FieldLabel(String text) {
  return Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Color(0xFF888780),
      letterSpacing: 0.6,
    ),
  );
}