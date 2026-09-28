import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../client/client_review_screen.dart';

class StudioCalendarScreen extends StatefulWidget {
  const StudioCalendarScreen({super.key});

  @override
  State<StudioCalendarScreen> createState() => _StudioCalendarScreenState();
}

class _StudioCalendarScreenState extends State<StudioCalendarScreen> {
  final ApiClient _api = ApiClient();
  List<dynamic> _contents = [];
  List<dynamic> _clients = [];
  List<dynamic> _staffList = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _viewMode = 0; // 0 = Month Grid, 1 = Week / Kanban
  int _calendarTab = 0; // 0 = Content (Deadlines), 1 = Publishing (Live)
  String? _selectedClientId; // null = All Clients
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contentsFuture = _api.getContents(clientId: _selectedClientId);
      final clientsFuture = _api.getClients();
      final staffFuture = _api.getStaff();

      final results = await Future.wait([contentsFuture, clientsFuture, staffFuture]);

      if (mounted) {
        setState(() {
          _contents = results[0];
          _clients = results[1];
          _staffList = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load calendar data from server';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateContentStatus(String id, String newStatus) async {
    try {
      await _api.updateContent(id, {'status': newStatus});
      _loadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated status to $newStatus'), backgroundColor: const Color(0xFF059669)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status'), backgroundColor: Color(0xFFDC2626)),
        );
      }
    }
  }

  void _showCreatePostModal({DateTime? prefilledDate}) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedClientId = _selectedClientId ?? (_clients.isNotEmpty ? _clients.first['id']?.toString() : null);
    String? selectedStaffId = _staffList.isNotEmpty ? _staffList.first['id']?.toString() : null;
    String selectedPlatform = 'INSTAGRAM';
    String selectedFormat = 'REEL';
    String selectedPriority = 'Medium';
    DateTime selectedDate = prefilledDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF111116),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            title: const Text('Create New Content Post', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Post Title *', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Diwali Reel Promo or Dish Reveal',
                        filled: true,
                        fillColor: const Color(0xFF09090C),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Client & Staff Selectors Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Client Brand *', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: selectedClientId,
                                dropdownColor: const Color(0xFF181820),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                items: _clients.map((cl) {
                                  return DropdownMenuItem<String>(
                                    value: cl['id']?.toString(),
                                    child: Text(cl['name'] ?? 'Client', overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) => setDialogState(() => selectedClientId = val),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF09090C),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                              const Text('Assigned Designer', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: selectedStaffId,
                                dropdownColor: const Color(0xFF181820),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                items: _staffList.map((st) {
                                  return DropdownMenuItem<String>(
                                    value: st['id']?.toString(),
                                    child: Text(st['name'] ?? 'Staff', overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) => setDialogState(() => selectedStaffId = val),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF09090C),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Platform & Format Selectors
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Platform', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: selectedPlatform,
                                dropdownColor: const Color(0xFF181820),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                items: ['INSTAGRAM', 'YOUTUBE', 'LINKEDIN', 'TWITTER', 'FACEBOOK']
                                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                    .toList(),
                                onChanged: (val) => setDialogState(() => selectedPlatform = val!),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF09090C),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                              const Text('Format', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: selectedFormat,
                                dropdownColor: const Color(0xFF181820),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                items: ['REEL', 'CAROUSEL', 'STATIC', 'VIDEO', 'STORY']
                                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                                    .toList(),
                                onChanged: (val) => setDialogState(() => selectedFormat = val!),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF09090C),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Scheduled Date Picker Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Scheduled Date *', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setDialogState(() => selectedDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF09090C),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                      ),
                                      const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF9CA3AF)),
                                    ],
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
                              const Text('Priority', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: selectedPriority,
                                dropdownColor: const Color(0xFF181820),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                items: ['Low', 'Medium', 'High', 'Urgent']
                                    .map((pr) => DropdownMenuItem(value: pr, child: Text(pr)))
                                    .toList(),
                                onChanged: (val) => setDialogState(() => selectedPriority = val!),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF09090C),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    const Text('Description / Visual Hook', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Add creative context, hooks, or notes for the client...',
                        filled: true,
                        fillColor: const Color(0xFF09090C),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0151C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) return;
                  try {
                    final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                    await _api.createContent({
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'client_id': selectedClientId,
                      'assigned_staff_id': selectedStaffId,
                      'platform': selectedPlatform,
                      'format': selectedFormat,
                      'priority': selectedPriority,
                      'status': 'IDEA',
                      'scheduled_date': dateStr,
                    });
                    if (context.mounted) Navigator.pop(ctx);
                    _loadAllData();
                  } catch (_) {}
                },
                child: const Text('Publish to Calendar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    });
  }

  String _getMonthTitle() {
    const months = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'];
    return '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Calendar Controls Bar
        _buildCalendarControls(),

        // Calendar Content Area
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFC0151C)))
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFEF4444))))
                  : _viewMode == 0
                      ? _buildMonthGrid()
                      : _buildKanbanView(),
        ),
      ],
    );
  }

  Widget _buildCalendarControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF09090D),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Toggle: Content (Deadlines) | Publishing (Live)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF131318),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                _buildSegmentBtn('Content (Deadlines)', 0),
                _buildSegmentBtn('Publishing (Live)', 1),
              ],
            ),
          ),

          // Center: Real Client Filter Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF131318),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedClientId,
                dropdownColor: const Color(0xFF181820),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF71717A)),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 7, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text('All Clients'),
                      ],
                    ),
                  ),
                  ..._clients.map((cl) {
                    return DropdownMenuItem<String?>(
                      value: cl['id']?.toString(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle, size: 7, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Text(cl['name'] ?? 'Client'),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() => _selectedClientId = val);
                  _loadAllData();
                },
              ),
            ),
          ),

          // Right Controls: View Switcher, Date Navigator, New Post
          Row(
            children: [
              // Month | Week
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF131318),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    _buildViewBtn('Month', 0),
                    _buildViewBtn('Week', 1),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Date Navigator
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 18, color: Color(0xFF9CA3AF)),
                    onPressed: () => _navigateMonth(-1),
                  ),
                  Text(
                    _getMonthTitle(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.6),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      setState(() => _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181820),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Today', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9CA3AF)),
                    onPressed: () => _navigateMonth(1),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // + New Post Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0151C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showCreatePostModal(),
                icon: const Icon(Icons.add, size: 15),
                label: const Text('New Post', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentBtn(String title, int idx) {
    final isSelected = _calendarTab == idx;
    return GestureDetector(
      onTap: () => setState(() => _calendarTab = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F1F28) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : const Color(0xFF71717A),
          ),
        ),
      ),
    );
  }

  Widget _buildViewBtn(String title, int idx) {
    final isSelected = _viewMode == idx;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F1F28) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : const Color(0xFF71717A),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthGrid() {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final totalDaysInMonth = DateTime(year, month + 1, 0).day;
    final firstDayWeekday = DateTime(year, month, 1).weekday; // 1 = Monday, 7 = Sunday

    // Group real contents by day of current month
    final Map<int, List<dynamic>> dayContents = {};
    for (int d = 1; d <= totalDaysInMonth; d++) {
      dayContents[d] = [];
    }

    for (final item in _contents) {
      final schedStr = item['scheduled_date']?.toString();
      if (schedStr != null && schedStr.length >= 10) {
        try {
          final postDate = DateTime.parse(schedStr.substring(0, 10));
          if (postDate.year == year && postDate.month == month) {
            dayContents[postDate.day]?.add(item);
          }
        } catch (_) {}
      }
    }

    // Build weeks matrix
    final List<List<int?>> weeks = [];
    List<int?> currentWeek = List.filled(7, null);
    int currentWeekdayIndex = firstDayWeekday - 1; // 0 = MON

    for (int day = 1; day <= totalDaysInMonth; day++) {
      currentWeek[currentWeekdayIndex] = day;
      if (currentWeekdayIndex == 6 || day == totalDaysInMonth) {
        weeks.add(List.from(currentWeek));
        currentWeek = List.filled(7, null);
        currentWeekdayIndex = 0;
      } else {
        currentWeekdayIndex++;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        children: [
          // Day Header Row
          Row(
            children: days
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF71717A), letterSpacing: 0.5),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),

          // Weeks Rows
          ...weeks.map((week) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: week.map((dayNum) {
                  return Expanded(
                    child: dayNum != null
                        ? _buildCalendarCell(dayNum, dayContents[dayNum] ?? [])
                        : Container(
                            margin: const EdgeInsets.all(3),
                            constraints: const BoxConstraints(minHeight: 140),
                            decoration: BoxDecoration(
                              color: const Color(0xFF07070A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCalendarCell(int date, List<dynamic> items) {
    return Container(
      margin: const EdgeInsets.all(3),
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date Number + Quick Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  final targetDate = DateTime(_currentMonth.year, _currentMonth.month, date);
                  _showCreatePostModal(prefilledDate: targetDate);
                },
                child: const Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF3F3F46)),
              ),
              Text(
                '$date',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF71717A)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Real Items inside date cell
          ...items.map((item) => _buildGridCard(item)),
        ],
      ),
    );
  }

  Widget _buildGridCard(dynamic item) {
    final title = item['title']?.toString() ?? 'Untitled';
    final client = item['client_name']?.toString() ?? 'Client';
    final status = (item['status'] ?? 'IDEA').toString().toUpperCase();
    final priority = (item['priority'] ?? 'MEDIUM').toString().toUpperCase();

    // Check overdue
    bool isOverdue = false;
    final schedStr = item['scheduled_date']?.toString();
    if (schedStr != null && schedStr.length >= 10) {
      try {
        final postDate = DateTime.parse(schedStr.substring(0, 10));
        final today = DateTime.now();
        final todayDateOnly = DateTime(today.year, today.month, today.day);
        if (postDate.isBefore(todayDateOnly) && status != 'PUBLISHED') {
          isOverdue = true;
        }
      } catch (_) {}
    }

    Color statusColor;
    if (status == 'APPROVED' || status == 'PUBLISHED') {
      statusColor = const Color(0xFF10B981);
    } else if (status == 'IN_REVIEW' || status == 'REVIEW') {
      statusColor = const Color(0xFFF59E0B);
    } else if (status == 'IN_PROGRESS') {
      statusColor = const Color(0xFF3B82F6);
    } else {
      statusColor = const Color(0xFF71717A);
    }

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ClientReviewScreen(contentItem: item)),
        );
        _loadAllData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF131317),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOverdue ? const Color(0xFF8B1E22).withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Pill & Overdue Warning
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, size: 5, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          client.toUpperCase(),
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFFD1D5DB)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C0E10),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: const Color(0x66DC2626)),
                    ),
                    child: const Row(
                      children: [
                        Text('OVERDUE', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                        SizedBox(width: 2),
                        Icon(Icons.warning_amber_rounded, size: 8, color: Color(0xFFEF4444)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Title
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Status & Priority Pills
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x1AF59E0B),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    priority,
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFFFBBF24)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanView() {
    final columns = [
      {'label': '💡 Ideas', 'status': 'IDEA'},
      {'label': '⚙️ In Progress', 'status': 'IN_PROGRESS'},
      {'label': '👀 In Review', 'status': 'IN_REVIEW'},
      {'label': '✅ Approved', 'status': 'APPROVED'},
      {'label': '🚀 Published', 'status': 'PUBLISHED'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: columns.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, idx) {
          final col = columns[idx];
          final colStatus = col['status'] as String;
          final items = _contents.where((c) => (c['status'] ?? 'IDEA').toString().toUpperCase() == colStatus).toList();

          return Container(
            width: 280,
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(col['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF181820), borderRadius: BorderRadius.circular(10)),
                        child: Text('${items.length}', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('No posts here', style: TextStyle(color: Color(0xFF52525B), fontSize: 12)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, itemIdx) {
                            final item = items[itemIdx];
                            final title = item['title'] ?? 'Untitled';
                            final client = item['client_name'] ?? 'Client';

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14141A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(client.toString().toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF))),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_horiz_rounded, size: 16, color: Color(0xFF71717A)),
                                        color: const Color(0xFF181820),
                                        onSelected: (newStatus) => _updateContentStatus(item['id'], newStatus),
                                        itemBuilder: (ctx) => [
                                          const PopupMenuItem(value: 'IDEA', child: Text('Move to 💡 Ideas', style: TextStyle(color: Colors.white, fontSize: 12))),
                                          const PopupMenuItem(value: 'IN_PROGRESS', child: Text('Move to ⚙️ In Progress', style: TextStyle(color: Colors.white, fontSize: 12))),
                                          const PopupMenuItem(value: 'IN_REVIEW', child: Text('Move to 👀 In Review', style: TextStyle(color: Colors.white, fontSize: 12))),
                                          const PopupMenuItem(value: 'APPROVED', child: Text('Move to ✅ Approved', style: TextStyle(color: Colors.white, fontSize: 12))),
                                          const PopupMenuItem(value: 'PUBLISHED', child: Text('Move to 🚀 Published', style: TextStyle(color: Colors.white, fontSize: 12))),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
