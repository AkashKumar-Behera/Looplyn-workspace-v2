import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class TasksBoardScreen extends StatefulWidget {
  const TasksBoardScreen({super.key});

  @override
  State<TasksBoardScreen> createState() => _TasksBoardScreenState();
}

class _TasksBoardScreenState extends State<TasksBoardScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  bool _isKanbanView = true;
  List<dynamic> _tasks = [];
  List<dynamic> _clients = [];
  List<dynamic> _staffList = [];
  String _selectedClientId = 'ALL';
  String _selectedPriority = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getTasks(
          clientId: _selectedClientId == 'ALL' ? null : _selectedClientId,
          priority: _selectedPriority == 'ALL' ? null : _selectedPriority,
        ),
        _api.getClients(),
        _api.getStaff(),
      ]);

      if (mounted) {
        setState(() {
          _tasks = results[0];
          _clients = results[1];
          _staffList = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTaskStatus(String id, String newStatus) async {
    try {
      await _api.updateTask(id, {'status': newStatus});
      _loadInitialData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update task status')),
      );
    }
  }

  Future<void> _deleteTask(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14141B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        title: const Text('Move to Trash?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('This task will be moved to trash and retained for 30 days.', style: TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.deleteTask(id);
        _loadInitialData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete task')),
        );
      }
    }
  }

  void _showCreateTaskModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String? selectedClient = _clients.isNotEmpty ? _clients[0]['id'] : null;
    String? selectedStaff = _staffList.isNotEmpty ? _staffList[0]['id'] : null;
    String priority = 'MEDIUM';
    String status = 'TODO';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF14141B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            title: const Row(
              children: [
                Icon(Icons.add_task_rounded, color: Color(0xFFDC2626), size: 22),
                SizedBox(width: 8),
                Text('Create Studio Task', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Task Title *', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Export 4K color-graded reels',
                        hintStyle: const TextStyle(color: Color(0xFF52525B)),
                        filled: true,
                        fillColor: const Color(0xFF0F0F13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Client Selector
                    const Text('Client', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F13),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedClient,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF181820),
                          items: _clients.map<DropdownMenuItem<String>>((cl) {
                            return DropdownMenuItem<String>(
                              value: cl['id'],
                              child: Text(cl['name'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) => setModalState(() => selectedClient = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Assignee & Priority
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Assignee', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F0F13),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedStaff,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF181820),
                                    items: _staffList.map<DropdownMenuItem<String>>((st) {
                                      return DropdownMenuItem<String>(
                                        value: st['id'],
                                        child: Text(st['name'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setModalState(() => selectedStaff = val),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Priority', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F0F13),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: priority,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF181820),
                                    items: ['LOW', 'MEDIUM', 'HIGH', 'URGENT'].map((p) {
                                      return DropdownMenuItem(
                                        value: p,
                                        child: Text(p, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setModalState(() => priority = val!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Description
                    const Text('Instructions / Notes', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Add deliverables details or drive references...',
                        hintStyle: const TextStyle(color: Color(0xFF52525B)),
                        filled: true,
                        fillColor: const Color(0xFF0F0F13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A)))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    await _api.createTask({
                      'title': titleController.text.trim(),
                      'description': descController.text.trim(),
                      'client_id': selectedClient,
                      'assigned_to': selectedStaff,
                      'priority': priority,
                      'status': status,
                      'due_date': selectedDate.toIso8601String(),
                    });
                    _loadInitialData();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create task')));
                  }
                },
                child: const Text('Create Task'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Filters Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tasks & Creative Pipeline', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('${_tasks.length} total tasks in studio queue', style: const TextStyle(fontSize: 13, color: Color(0xFF71717A))),
                ],
              ),
              Row(
                children: [
                  // View Switcher (Kanban / List)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F13),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.view_kanban_outlined, size: 18, color: _isKanbanView ? const Color(0xFFDC2626) : const Color(0xFF71717A)),
                          onPressed: () => setState(() => _isKanbanView = true),
                          tooltip: 'Kanban Board',
                        ),
                        IconButton(
                          icon: Icon(Icons.view_list_rounded, size: 18, color: !_isKanbanView ? const Color(0xFFDC2626) : const Color(0xFF71717A)),
                          onPressed: () => setState(() => _isKanbanView = false),
                          tooltip: 'List View',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('+ New Task', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    onPressed: _showCreateTaskModal,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filters Row
          Row(
            children: [
              // Client filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F13),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedClientId,
                    dropdownColor: const Color(0xFF181820),
                    items: [
                      const DropdownMenuItem(value: 'ALL', child: Text('All Clients', style: TextStyle(color: Colors.white, fontSize: 12))),
                      ..._clients.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name'], style: const TextStyle(color: Colors.white, fontSize: 12)))),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedClientId = val!);
                      _loadInitialData();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Priority filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F13),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPriority,
                    dropdownColor: const Color(0xFF181820),
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('All Priorities', style: TextStyle(color: Colors.white, fontSize: 12))),
                      DropdownMenuItem(value: 'HIGH', child: Text('High / Urgent', style: TextStyle(color: Colors.white, fontSize: 12))),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Medium', style: TextStyle(color: Colors.white, fontSize: 12))),
                      DropdownMenuItem(value: 'LOW', child: Text('Low', style: TextStyle(color: Colors.white, fontSize: 12))),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedPriority = val!);
                      _loadInitialData();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Tasks Board / List Content
          Expanded(
            child: _isKanbanView ? _buildKanbanBoard() : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanBoard() {
    const columns = [
      {'key': 'TODO', 'title': 'To Do', 'color': Color(0xFF6B7280)},
      {'key': 'IN_PROGRESS', 'title': 'In Progress', 'color': Color(0xFF3B82F6)},
      {'key': 'REVIEW', 'title': 'Review', 'color': Color(0xFFF59E0B)},
      {'key': 'DONE', 'title': 'Done', 'color': Color(0xFF10B981)},
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns.map((col) {
        final colTasks = _tasks.where((t) => (t['status'] ?? 'TODO').toString().toUpperCase() == col['key']).toList();

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0C10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: col['color'] as Color, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(col['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF181820), borderRadius: BorderRadius.circular(10)),
                      child: Text('${colTasks.length}', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Column Tasks List
                Expanded(
                  child: colTasks.isEmpty
                      ? Center(
                          child: Text('No tasks in ${col['title']}', style: const TextStyle(color: Color(0xFF52525B), fontSize: 12)),
                        )
                      : ListView.separated(
                          itemCount: colTasks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) => _buildTaskCard(colTasks[idx]),
                        ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final title = task['title'] ?? 'Untitled Task';
    final client = task['client_name'] ?? 'General';
    final assignee = task['assignee_name'] ?? 'Unassigned';
    final priority = (task['priority'] ?? 'MEDIUM').toString().toUpperCase();

    Color priorityColor = const Color(0xFF6B7280);
    if (priority == 'HIGH' || priority == 'URGENT') priorityColor = const Color(0xFFDC2626);
    if (priority == 'MEDIUM') priorityColor = const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14141B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(client.toString().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF71717A), letterSpacing: 0.5)),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, size: 16, color: Color(0xFF71717A)),
                color: const Color(0xFF1A1A24),
                onSelected: (val) {
                  if (val == 'DELETE') {
                    _deleteTask(task['id']);
                  } else {
                    _updateTaskStatus(task['id'], val);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'TODO', child: Text('Move to To Do', style: TextStyle(color: Colors.white, fontSize: 12))),
                  const PopupMenuItem(value: 'IN_PROGRESS', child: Text('Move to In Progress', style: TextStyle(color: Colors.white, fontSize: 12))),
                  const PopupMenuItem(value: 'REVIEW', child: Text('Move to Review', style: TextStyle(color: Colors.white, fontSize: 12))),
                  const PopupMenuItem(value: 'DONE', child: Text('Mark as Done', style: TextStyle(color: Colors.white, fontSize: 12))),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'DELETE', child: Text('Delete Task', style: TextStyle(color: Color(0xFFDC2626), fontSize: 12))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_circle_outlined, size: 14, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 4),
                  Text(assignee, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(priority, style: TextStyle(color: priorityColor, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      itemCount: _tasks.length,
      separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.04), height: 16),
      itemBuilder: (ctx, idx) {
        final task = _tasks[idx];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          tileColor: const Color(0xFF0F0F13),
          title: Text(task['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text('${task['client_name'] ?? 'General'} • Assigned to ${task['assignee_name'] ?? 'None'}', style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF181820), borderRadius: BorderRadius.circular(6)),
                child: Text(task['status'] ?? 'TODO', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF71717A)),
                onPressed: () => _deleteTask(task['id']),
              ),
            ],
          ),
        );
      },
    );
  }
}
