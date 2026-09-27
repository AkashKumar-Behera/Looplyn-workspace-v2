import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../client/client_review_screen.dart';
import '../chat/chat_hub_screen.dart';

class StudioCalendarScreen extends StatefulWidget {
  const StudioCalendarScreen({super.key});

  @override
  State<StudioCalendarScreen> createState() => _StudioCalendarScreenState();
}

class _StudioCalendarScreenState extends State<StudioCalendarScreen> {
  final ApiClient _api = ApiClient();
  List<dynamic> _contents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContents();
  }

  Future<void> _loadContents() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getContents();
      setState(() {
        _contents = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateContentStatus(String id, String newStatus) async {
    try {
      await _api.updateContent(id, {'status': newStatus});
      _loadContents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status')),
      );
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
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.surfaceLight)),
          title: const Text('Create New Content Item', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Title', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(controller: titleController, decoration: const InputDecoration(hintText: 'e.g. Diwali Reel Promo')),
                  const SizedBox(height: 14),

                  const Text('Description', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(controller: descController, maxLines: 2, decoration: const InputDecoration(hintText: 'Add context, brief or visual hooks...')),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Platform', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedPlatform,
                              dropdownColor: AppTheme.surface,
                              items: ['INSTAGRAM', 'YOUTUBE', 'LINKEDIN', 'TWITTER'].map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (val) => setDialogState(() => selectedPlatform = val!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Format', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedFormat,
                              dropdownColor: AppTheme.surface,
                              items: ['REEL', 'CAROUSEL', 'STATIC', 'VIDEO'].map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (val) => setDialogState(() => selectedFormat = val!),
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
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                await _api.createContent({
                  'title': titleController.text.trim(),
                  'description': descController.text.trim(),
                  'platform': selectedPlatform,
                  'format': selectedFormat,
                  'priority': selectedPriority,
                  'status': 'IDEA',
                });
                if (mounted) {
                  Navigator.of(ctx).pop();
                  _loadContents();
                }
              },
              child: const Text('Create Content'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Row(
          children: [
            const Icon(LucideIcons.calendar, size: 20, color: AppTheme.accent),
            const SizedBox(width: 10),
            const Text('Studio & Calendar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.messageSquare, size: 18, color: Colors.white),
            tooltip: 'Open Chat Hub',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatHubScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18, color: AppTheme.textSecondary),
            onPressed: _loadContents,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(LucideIcons.plus, size: 16, color: Colors.black),
              label: const Text('New Post'),
              onPressed: _showCreateContentDialog,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _buildKanbanBoard(),
    );
  }

  Widget _buildKanbanBoard() {
    final columns = [
      {'status': 'IDEA', 'label': '💡 Ideas', 'color': AppTheme.textSecondary},
      {'status': 'IN_PROGRESS', 'label': '⚙️ In Progress', 'color': AppTheme.info},
      {'status': 'IN_REVIEW', 'label': '👀 In Review', 'color': AppTheme.warning},
      {'status': 'APPROVED', 'label': '✅ Approved', 'color': AppTheme.success},
      {'status': 'PUBLISHED', 'label': '🚀 Published', 'color': AppTheme.accent},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: columns.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, idx) {
          final col = columns[idx];
          final colStatus = col['status'] as String;
          final items = _contents.where((c) => (c['status'] ?? 'IDEA').toString().toUpperCase() == colStatus).toList();

          return Container(
            width: 300,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Column Header
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        col['label'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${items.length}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.surfaceLight),

                // Column Items List
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('No posts here', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, itemIdx) {
                            final item = items[itemIdx];
                            return _buildContentCard(item);
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

  Widget _buildContentCard(dynamic item) {
    final platform = (item['platform'] ?? 'INSTAGRAM').toString().toUpperCase();
    final format = (item['format'] ?? 'REEL').toString().toUpperCase();

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ClientReviewScreen(contentItem: item)),
        );
        _loadContents();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.surfaceLight),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(platform, style: const TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(format, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            item['title'] ?? 'Untitled',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
          ),
          if (item['description'] != null && item['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item['description'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),

          // Action Row (Move Status / Staff Avatar)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.user, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(item['staff_name'] ?? 'Unassigned', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreHorizontal, size: 16, color: AppTheme.textSecondary),
                color: AppTheme.surface,
                onSelected: (newStatus) => _updateContentStatus(item['id'], newStatus),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'IDEA', child: Text('Move to 💡 Ideas')),
                  const PopupMenuItem(value: 'IN_PROGRESS', child: Text('Move to ⚙️ In Progress')),
                  const PopupMenuItem(value: 'IN_REVIEW', child: Text('Move to 👀 In Review')),
                  const PopupMenuItem(value: 'APPROVED', child: Text('Move to ✅ Approved')),
                  const PopupMenuItem(value: 'PUBLISHED', child: Text('Move to 🚀 Published')),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
