import 'package:flutter/material.dart';
import '../models/todo.dart';

class TodoFormSheet extends StatefulWidget {
  final Todo? todo;
  final void Function(String title, String description, TodoStatus status)
      onSave;

  const TodoFormSheet({super.key, this.todo, required this.onSave});

  @override
  State<TodoFormSheet> createState() => _TodoFormSheetState();
}

class _TodoFormSheetState extends State<TodoFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late TodoStatus _status;

  @override
  void initState() {
    super.initState();
    _titleCtrl =
        TextEditingController(text: widget.todo?.title ?? '');
    _descCtrl =
        TextEditingController(text: widget.todo?.description ?? '');
    _status = widget.todo?.status ?? TodoStatus.pending;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    widget.onSave(title, _descCtrl.text.trim(), _status);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.todo != null;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
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
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      color: Color(0xFF888780)),
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
              decoration:
                  _inputDecoration('What needs to be done?'),
            ),
            const SizedBox(height: 16),

            _FieldLabel('Description'),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  _inputDecoration('Add details (optional)...'),
            ),
            const SizedBox(height: 16),

            _FieldLabel('Status'),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                    color: const Color(0xFFD3D1C7), width: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TodoStatus>(
                  value: _status,
                  isExpanded: true,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                  items: TodoStatus.values
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (s) {
                    if (s != null) setState(() => _status = s);
                  },
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child:
                    Text(isEdit ? 'Save changes' : 'Add task'),
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
      hintStyle: const TextStyle(
          color: Color(0xFFB4B2A9), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
            color: Color(0xFFD3D1C7), width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
            color: Color(0xFFD3D1C7), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
            color: Color(0xFF1A1A1A), width: 1.0),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
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
