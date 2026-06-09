import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/todo.dart';
import '../widgets/todo_card.dart';
import '../widgets/todo_form_sheet.dart';

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
  String _searchQuery = '';
  bool _searchActive = false;
  bool _loading = true;

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

  // ── Data ─────────────────────────────────────────────────────────────────────

  Future<void> _loadTodos() async {
    final todos = await _db.getAllTodos();
    if (mounted) setState(() { _todos = todos; _loading = false; });
  }

  List<Todo> get _filteredTodos {
    Iterable<Todo> result = _todos;

    // Apply status filter
    if (_filterStatus != null) {
      result = result.where((t) => t.status == _filterStatus);
    }

    // Apply search query — matches title or description, case-insensitive
    if (_searchQuery.isNotEmpty) {
      result = result.where((t) =>
          t.title.toLowerCase().contains(_searchQuery) ||
          t.description.toLowerCase().contains(_searchQuery));
    }

    return result.toList();
  }

  Future<void> _addTodo(String title, String description, TodoStatus status, DateTime? targetDate) async {
    final inserted = await _db.insertTodo(
      Todo(title: title, description: description, status: status, targetDate: targetDate),
    );
    setState(() => _todos.insert(0, inserted));
  }

  Future<void> _updateTodo(Todo original, String title, String description, TodoStatus status, DateTime? targetDate) async {
    final updated = original.copyWith(title: title, description: description, status: status, targetDate: targetDate);
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

  // ── Search ────────────────────────────────────────────────────────────────────

  void _activateSearch() {
    setState(() => _searchActive = true);
    // Delay focus so the widget is in the tree before requesting focus
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
  }

  void _deactivateSearch() {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() {
      _searchActive = false;
      _searchQuery = '';
    });
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
        onSave: (title, desc, status, targetDate) =>
            _updateTodo(todo, title, desc, status, targetDate),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTodos;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F4F0),
        elevation: 0,
        // Swap between title and search bar
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
          // Toggle search icon
          IconButton(
            icon: Icon(
              _searchActive ? Icons.search_off : Icons.search,
              color: const Color(0xFF1A1A1A),
            ),
            tooltip: _searchActive ? 'Close search' : 'Search',
            onPressed: _searchActive ? _deactivateSearch : _activateSearch,
          ),
          if (!_searchActive)
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _filterStatus == null,
                          onTap: () => setState(() => _filterStatus = null),
                        ),
                        const SizedBox(width: 6),
                        for (final s in TodoStatus.values) ...[
                          _FilterChip(
                            label: s.label,
                            selected: _filterStatus == s,
                            onTap: () => setState(() => _filterStatus = s),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
                ),

                // Search result count when query is active
                if (_searchActive && _searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Text(
                      filtered.isEmpty
                          ? 'No tasks match "$_searchQuery"'
                          : '${filtered.length} ${filtered.length == 1 ? 'result' : 'results'} for "$_searchQuery"',
                      style: TextStyle(
                        fontSize: 13,
                        color: filtered.isEmpty
                            ? Colors.grey.shade400
                            : const Color(0xFF888780),
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
                                _searchQuery.isNotEmpty
                                    ? Icons.search_off
                                    : Icons.check_box_outline_blank,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No tasks match your search'
                                    : 'No tasks here yet',
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFD3D1C7),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF888780),
          ),
        ),
      ),
    );
  }
}