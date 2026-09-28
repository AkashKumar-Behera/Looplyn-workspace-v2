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
  bool _isLoading = true;
  int _viewMode = 0; // 0 = Month Grid, 1 = Week / Kanban
  int _calendarTab = 0; // 0 = Content (Deadlines), 1 = Publishing (Live)
  String _selectedClient = 'All Clients';

  @override
  void initState() {
    super.initState();
    _loadContents();
  }

  Future<void> _loadContents() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getContents();
      if (mounted) {
        setState(() {
          _contents = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateContentDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPlatform = 'INSTAGRAM';
    String selectedFormat = 'REEL';
    String selectedPriority = 'Medium';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF111116),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: const Text('Create New Content Item', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Title', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g. Diwali Reel Promo',
                      filled: true,
                      fillColor: const Color(0xFF09090C),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Description', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Add context, brief or visual hooks...',
                      filled: true,
                      fillColor: const Color(0xFF09090C),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 14),

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
                              items: ['INSTAGRAM', 'YOUTUBE', 'LINKEDIN', 'TWITTER']
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
                              items: ['REEL', 'CAROUSEL', 'STATIC', 'VIDEO']
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
              onPressed: () async {
                if (titleController.text.trim().isNotEmpty) {
                  try {
                    await _api.createContent({
                      'title': titleController.text.trim(),
                      'description': descController.text.trim(),
                      'platform': selectedPlatform,
                      'format': selectedFormat,
                      'priority': selectedPriority,
                      'status': 'IDEA',
                      'scheduled_date': DateTime.now().toIso8601String().substring(0, 10),
                    });
                    if (context.mounted) Navigator.pop(ctx);
                    _loadContents();
                  } catch (_) {}
                }
              },
              child: const Text('Create Post'),
            ),
          ],
        ),
      ),
    );
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
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)))
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

          // Center: Client Filter Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF131318),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 8, color: Color(0xFFEF4444)),
                SizedBox(width: 8),
                Text('All Clients', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF71717A)),
              ],
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
                    onPressed: () {},
                  ),
                  const Text(
                    'SEPTEMBER 2026',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181820),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Today', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9CA3AF)),
                    onPressed: () {},
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
                onPressed: _showCreateContentDialog,
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

    // Mock calendar cards matching the reference screenshot
    final Map<int, List<Map<String, dynamic>>> sampleCards = {
      21: [
        {'client': 'DE..', 'title': "luxury isn't\na price tag", 'status': 'REVIEW', 'priority': 'MEDIUM', 'overdue': true},
        {'client': 'SH..', 'title': 'Craft 7 —\nSignature Dish...', 'status': 'TO DO', 'priority': 'MEDIUM', 'overdue': true},
      ],
      22: [
        {'client': 'SHREE PRASHADAM', 'title': 'Culture 2\n— Customer-...', 'status': 'DONE', 'priority': 'MEDIUM', 'overdue': false},
      ],
      24: [
        {'client': 'SIL..', 'title': 'Brand 3 — Stop-\nMotion Breakfas...', 'status': 'TO DO', 'priority': 'MEDIUM', 'overdue': true},
        {'client': 'DE..', 'title': 'OLD VS NEW', 'status': 'REVIEW', 'priority': 'MEDIUM', 'overdue': true},
        {'client': 'DE..', 'title': 'PIAGGIO\nCHALLANGE REE...', 'status': 'REVIEW', 'priority': 'MEDIUM', 'overdue': true},
      ],
      25: [
        {'client': 'SIL..', 'title': 'Culture 3\n— Kitchen...', 'status': 'IN PROGRESS', 'priority': 'MEDIUM', 'overdue': true},
        {'client': 'DE..', 'title': 'carousal', 'status': 'TO DO', 'priority': 'MEDIUM', 'overdue': true},
        {'client': 'SH..', 'title': 'Craft 5 —\nIngredient-Origi...', 'status': 'TO DO', 'priority': 'MEDIUM', 'overdue': true},
      ],
      26: [
        {'client': 'SH..', 'title': 'Brand 5\n— Reintroducing...', 'status': 'TO DO', 'priority': 'MEDIUM', 'overdue': true},
      ],
      27: [
        {'client': 'DE..', 'title': 'DJM TEAM\nCAROUSAL', 'status': 'TO DO', 'priority': 'MEDIUM', 'overdue': true},
      ],
      28: [],
      29: [],
      30: [
        {'client': 'DESIGN FUDGE S...', 'title': 'DESIGN FUDGE S...', 'status': 'TO DO', 'priority': 'LOW', 'overdue': false},
      ],
    };

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

          // Grid Matrix (Row 1: 21 to 27)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [21, 22, 23, 24, 25, 26, 27].map((date) {
              return Expanded(
                child: _buildCalendarCell(date, sampleCards[date] ?? []),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Grid Matrix (Row 2: 28 to 30)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [28, 29, 30, 1, 2, 3, 4].map((date) {
              return Expanded(
                child: _buildCalendarCell(date, sampleCards[date] ?? [], isNextMonth: date < 10),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCell(int date, List<Map<String, dynamic>> items, {bool isNextMonth = false}) {
    return Container(
      margin: const EdgeInsets.all(3),
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date Number
          Align(
            alignment: Alignment.topRight,
            child: Text(
              '$date',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isNextMonth ? const Color(0xFF3F3F46) : const Color(0xFF71717A),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Items inside date
          ...items.map((item) => _buildGridCard(item)),
        ],
      ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> item) {
    final title = item['title'] ?? '';
    final client = item['client'] ?? '';
    final status = item['status'] ?? 'TO DO';
    final priority = item['priority'] ?? 'MEDIUM';
    final isOverdue = item['overdue'] == true;

    Color statusColor;
    if (status == 'DONE' || status == 'PUBLISHED') {
      statusColor = const Color(0xFF10B981);
    } else if (status == 'REVIEW') {
      statusColor = const Color(0xFFF59E0B);
    } else if (status == 'IN PROGRESS') {
      statusColor = const Color(0xFF3B82F6);
    } else {
      statusColor = const Color(0xFF71717A);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF131317),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOverdue ? const Color(0xFF8B1E22).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
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
                        client,
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
                            return InkWell(
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => ClientReviewScreen(contentItem: item)),
                                );
                                _loadContents();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF14141A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                                    if (item['description'] != null && item['description'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(item['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF71717A), fontSize: 11)),
                                    ],
                                  ],
                                ),
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
