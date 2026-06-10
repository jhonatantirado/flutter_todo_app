import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/todo.dart';
import '../widgets/todo_card.dart';
import '../widgets/todo_form_sheet.dart';

// ── Sort options ───────────────────────────────────────────────────────────────

enum SortField { createdAt, targetDate, title, priority }
enum SortDirection { asc, desc }

class SortOption {
  final SortField field;
  final SortDirection direction;

  const SortOption(this.field, this.direction);

  String get label {
    final dir = direction == SortDirection.asc ? '↑' : '↓';
    switch (field) {
      case SortField.createdAt:
        return 'Date created $dir';
      case SortField.targetDate:
        return 'Target date $dir';
      case SortField.title:
        return 'Title $dir';
      case SortField.priority:
        return 'Priority $dir';
    }
  }

  // Default: newest first
  static const defaultOption = SortOption(SortField.createdAt, SortDirection.desc);
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final _db = DatabaseHelper.instance;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  List<Todo> _todos = [];
  TodoStatus? _filterStatus;
  bool _filterOverdue = false;
  String _searchQuery = '';
  bool _searchActive = false;
  bool _loading = true;
  SortOption _sortOption = SortOption.defaultOption;

  @override
  void initState() {
    super.initState();
    _loadTodos();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────────

  Future<void> _loadTodos() async {
    final todos = await _db.getAllTodos();
    if (mounted) setState(() { _todos = todos; _loading = false; });
  }

  static bool _isOverdue(Todo t) {
    if (t.targetDate == null || t.status == TodoStatus.done) return false;
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    return t.targetDate!.isBefore(todayMidnight);
  }

  int get _overdueCount => _todos.where(_isOverdue).length;

  List<Todo> get _filteredTodos {
    Iterable<Todo> result = _todos;

    if (_filterOverdue) {
      result = result.where(_isOverdue);
    } else if (_filterStatus != null) {
      result = result.where((t) => t.status == _filterStatus);
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((t) =>
          t.title.toLowerCase().contains(_searchQuery) ||
          t.description.toLowerCase().contains(_searchQuery));
    }

    final list = result.toList();
    _applySort(list);
    return list;
  }

  void _applySort(List<Todo> list) {
    final asc = _sortOption.direction == SortDirection.asc;
    list.sort((a, b) {
      int cmp;
      switch (_sortOption.field) {
        case SortField.createdAt:
          cmp = a.createdAt.compareTo(b.createdAt);
        case SortField.title:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case SortField.targetDate:
          // Nulls always go to the end regardless of direction
          if (a.targetDate == null && b.targetDate == null) return 0;
          if (a.targetDate == null) return 1;
          if (b.targetDate == null) return -1;
          cmp = a.targetDate!.compareTo(b.targetDate!);
        case SortField.priority:
          cmp = a.priority.weight.compareTo(b.priority.weight);
      }
      return asc ? cmp : -cmp;
    });
  }

  Future<void> _addTodo(String title, String description, TodoStatus status, TodoPriority priority, DateTime? targetDate) async {
    final inserted = await _db.insertTodo(
      Todo(title: title, description: description, status: status, priority: priority, targetDate: targetDate),
    );
    setState(() => _todos.insert(0, inserted));
  }

  Future<void> _updateTodo(Todo original, String title, String description, TodoStatus status, TodoPriority priority, DateTime? targetDate) async {
    final updated = original.copyWith(title: title, description: description, status: status, priority: priority, targetDate: targetDate);
    await _db.updateTodo(updated);
    setState(() {
      final idx = _todos.indexWhere((t) => t.id == original.id);
      if (idx != -1) _todos[idx] = updated;
    });
  }

  Future<void> _toggleDone(Todo todo) async {
    final updated = todo.copyWith(
      status: todo.status == TodoStatus.done ? TodoStatus.pending : TodoStatus.done,
    );
    await _db.updateTodo(updated);
    setState(() {
      final idx = _todos.indexWhere((t) => t.id == todo.id);
      if (idx != -1) _todos[idx] = updated;
    });
  }

  Future<void> _changeStatus(Todo todo, TodoStatus status) async {
    final updated = todo.copyWith(status: status);
    await _db.updateTodo(updated);
    setState(() {
      final idx = _todos.indexWhere((t) => t.id == todo.id);
      if (idx != -1) _todos[idx] = updated;
    });
  }

  Future<void> _deleteTodo(Todo todo) async {
    await _db.deleteTodo(todo.id!);
    setState(() => _todos.removeWhere((t) => t.id == todo.id));
  }

  // ── Bulk actions ──────────────────────────────────────────────────────────────

  int get _doneCount => _todos.where((t) => t.status == TodoStatus.done).length;

  Future<void> _clearCompleted() async {
    final completed = _todos.where((t) => t.status == TodoStatus.done).toList();
    if (completed.isEmpty) return;

    // Show confirmation dialog before deleting
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear completed tasks?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
        ),
        content: Text(
          '${completed.length} completed ${completed.length == 1 ? 'task' : 'tasks'} will be permanently deleted.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF888780), height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFD3D1C7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    foregroundColor: const Color(0xFF888780),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFA32D2D),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Delete from DB in parallel, then remove from in-memory list
    await Future.wait(completed.map((t) => _db.deleteTodo(t.id!)));
    setState(() => _todos.removeWhere((t) => t.status == TodoStatus.done));

    // Show undo snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${completed.length} completed ${completed.length == 1 ? 'task' : 'tasks'} deleted',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: const Color(0xFF1A1A1A),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────────

  void _activateSearch() {
    setState(() => _searchActive = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
  }

  void _deactivateSearch() {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() { _searchActive = false; _searchQuery = ''; });
  }

  // ── Sort sheet ────────────────────────────────────────────────────────────────

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SortSheet(
        current: _sortOption,
        onChanged: (opt) => setState(() => _sortOption = opt),
      ),
    );
  }

  // ── Sheets ────────────────────────────────────────────────────────────────────

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TodoFormSheet(onSave: _addTodo),
    );
  }

  void _openEditSheet(Todo todo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TodoFormSheet(
        todo: todo,
        onSave: (title, desc, status, priority, targetDate) =>
            _updateTodo(todo, title, desc, status, priority, targetDate),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  bool get _isSortActive => _sortOption != SortOption.defaultOption;
  bool get _isFilterActive => _filterStatus != null || _filterOverdue;

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTodos;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F4F0),
        elevation: 0,
        title: _searchActive
            ? TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                autofocus: true,
                style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
                decoration: InputDecoration(
                  hintText: 'Search tasks…',
                  hintStyle: const TextStyle(color: Color(0xFFB4B2A9)),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF888780), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(Icons.close, color: Color(0xFF888780), size: 18),
                        )
                      : null,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Tasks',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                  ),
                  Text(
                    '${_todos.length} ${_todos.length == 1 ? 'task' : 'tasks'}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF888780)),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_searchActive ? Icons.search_off : Icons.search, color: const Color(0xFF1A1A1A)),
            tooltip: _searchActive ? 'Close search' : 'Search',
            onPressed: _searchActive ? _deactivateSearch : _activateSearch,
          ),
          if (!_searchActive) ...[
            // Sort button — badge dot when a non-default sort is active
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.sort, color: Color(0xFF1A1A1A)),
                  tooltip: 'Sort',
                  onPressed: _openSortSheet,
                ),
                if (_isSortActive)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF378ADD),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            // Clear completed — only shown when there are done tasks
            if (_doneCount > 0)
              IconButton(
                icon: const Icon(Icons.playlist_remove_rounded, color: Color(0xFF1A1A1A)),
                tooltip: 'Clear completed ($_doneCount)',
                onPressed: _clearCompleted,
              ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: _openAddSheet,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New task'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary count bar
                _SummaryBar(todos: _todos, isOverdue: _isOverdue),

                // Filter chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: !_isFilterActive,
                          onTap: () => setState(() {
                            _filterStatus = null;
                            _filterOverdue = false;
                          }),
                        ),
                        const SizedBox(width: 6),
                        for (final s in TodoStatus.values) ...[
                          _FilterChip(
                            label: s.label,
                            selected: _filterStatus == s && !_filterOverdue,
                            onTap: () => setState(() {
                              _filterStatus = s;
                              _filterOverdue = false;
                            }),
                          ),
                          const SizedBox(width: 6),
                        ],
                        // Overdue chip — only shown when there are overdue tasks
                        if (_overdueCount > 0)
                          _FilterChip(
                            label: 'Overdue ($_overdueCount)',
                            selected: _filterOverdue,
                            isWarning: true,
                            onTap: () => setState(() {
                              _filterOverdue = !_filterOverdue;
                              if (_filterOverdue) _filterStatus = null;
                            }),
                          ),
                      ],
                    ),
                  ),
                ),

                // Active sort indicator
                if (_isSortActive)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.sort, size: 13, color: Color(0xFF378ADD)),
                        const SizedBox(width: 4),
                        Text(
                          'Sorted by: ${_sortOption.label}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF378ADD), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => _sortOption = SortOption.defaultOption),
                          child: const Icon(Icons.close, size: 13, color: Color(0xFF378ADD)),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Search result count
                if (_searchActive && _searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Text(
                      filtered.isEmpty
                          ? 'No tasks match "$_searchQuery"'
                          : '${filtered.length} ${filtered.length == 1 ? 'result' : 'results'} for "$_searchQuery"',
                      style: TextStyle(
                        fontSize: 13,
                        color: filtered.isEmpty ? Colors.grey.shade400 : const Color(0xFF888780),
                      ),
                    ),
                  ),

                // Task list
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isNotEmpty ? Icons.search_off : Icons.check_box_outline_blank,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty ? 'No tasks match your search' : 'No tasks here yet',
                                style: TextStyle(fontSize: 15, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final todo = filtered[index];
                            return TodoCard(
                              todo: todo,
                              onDelete: () => _deleteTodo(todo),
                              onStatusChanged: (s) => _changeStatus(todo, s),
                              onToggleDone: () => _toggleDone(todo),
                              onEdit: () => _openEditSheet(todo),
                              searchQuery: _searchQuery,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// ── Sort bottom sheet ──────────────────────────────────────────────────────────

class _SortSheet extends StatefulWidget {
  final SortOption current;
  final ValueChanged<SortOption> onChanged;

  const _SortSheet({required this.current, required this.onChanged});

  @override
  State<_SortSheet> createState() => _SortSheetState();
}

class _SortSheetState extends State<_SortSheet> {
  late SortField _field;
  late SortDirection _direction;

  @override
  void initState() {
    super.initState();
    _field = widget.current.field;
    _direction = widget.current.direction;
  }

  void _apply() {
    widget.onChanged(SortOption(_field, _direction));
    Navigator.pop(context);
  }

  void _reset() {
    widget.onChanged(SortOption.defaultOption);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Sort by',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Color(0xFF888780)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Field options
          _SectionLabel('Field'),
          const SizedBox(height: 8),
          _OptionRow(
            label: 'Date created',
            icon: Icons.access_time_outlined,
            selected: _field == SortField.createdAt,
            onTap: () => setState(() => _field = SortField.createdAt),
          ),
          const SizedBox(height: 8),
          _OptionRow(
            label: 'Target date',
            icon: Icons.calendar_today_outlined,
            selected: _field == SortField.targetDate,
            onTap: () => setState(() => _field = SortField.targetDate),
          ),
          const SizedBox(height: 8),
          _OptionRow(
            label: 'Title',
            icon: Icons.sort_by_alpha_outlined,
            selected: _field == SortField.title,
            onTap: () => setState(() => _field = SortField.title),
          ),
          const SizedBox(height: 8),
          _OptionRow(
            label: 'Priority',
            icon: Icons.flag_outlined,
            selected: _field == SortField.priority,
            onTap: () => setState(() => _field = SortField.priority),
          ),
          const SizedBox(height: 20),

          // Direction options
          _SectionLabel('Direction'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DirectionButton(
                  label: _field == SortField.title ? 'A → Z' : _field == SortField.priority ? 'Low → High' : 'Oldest first',
                  icon: Icons.arrow_upward,
                  selected: _direction == SortDirection.asc,
                  onTap: () => setState(() => _direction = SortDirection.asc),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DirectionButton(
                  label: _field == SortField.title ? 'Z → A' : _field == SortField.priority ? 'High → Low' : 'Newest first',
                  icon: Icons.arrow_downward,
                  selected: _direction == SortDirection.desc,
                  onTap: () => setState(() => _direction = SortDirection.desc),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFD3D1C7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    foregroundColor: const Color(0xFF888780),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionRow({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F0EC) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFD3D1C7),
            width: selected ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: selected ? const Color(0xFF1A1A1A) : const Color(0xFF888780)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? const Color(0xFF1A1A1A) : const Color(0xFF444240),
              ),
            ),
            const Spacer(),
            if (selected) const Icon(Icons.check, size: 16, color: Color(0xFF1A1A1A)),
          ],
        ),
      ),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DirectionButton({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFD3D1C7),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : const Color(0xFF888780)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF888780),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isWarning;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isWarning ? const Color(0xFFA32D2D) : const Color(0xFF1A1A1A);
    final Color inactiveBorder = isWarning ? const Color(0xFFF5C0C0) : const Color(0xFFD3D1C7);
    final Color inactiveText = isWarning ? const Color(0xFFA32D2D) : const Color(0xFF888780);
    final Color inactiveBg = isWarning ? const Color(0xFFFDE8E8) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor : inactiveBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : inactiveBorder,
            width: selected ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isWarning) ...[
              Icon(
                Icons.warning_amber_rounded,
                size: 12,
                color: selected ? Colors.white : inactiveText,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : inactiveText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Summary bar ────────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final List<Todo> todos;
  final bool Function(Todo) isOverdue;

  const _SummaryBar({required this.todos, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) return const SizedBox.shrink();

    final done = todos.where((t) => t.status == TodoStatus.done).length;
    final inProgress = todos.where((t) => t.status == TodoStatus.inProgress).length;
    final pending = todos.where((t) => t.status == TodoStatus.pending).length;
    final overdue = todos.where(isOverdue).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E6DF), width: 0.5),
      ),
      child: Row(
        children: [
          _SummaryCell(count: pending, label: 'Pending', color: const Color(0xFFEF9F27)),
          _Divider(),
          _SummaryCell(count: inProgress, label: 'In Progress', color: const Color(0xFF378ADD)),
          _Divider(),
          _SummaryCell(count: done, label: 'Done', color: const Color(0xFF639922)),
          if (overdue > 0) ...[
            _Divider(),
            _SummaryCell(count: overdue, label: 'Overdue', color: const Color(0xFFA32D2D)),
          ],
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _SummaryCell({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF888780),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 36,
      color: const Color(0xFFE8E6DF),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

Widget _SectionLabel(String text) {
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