import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _trashItems = [];

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    setState(() => _isLoading = true);
    try {
      final items = await _api.getTrashItems();
      if (mounted) {
        setState(() {
          _trashItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreItem(String type, String id) async {
    try {
      await _api.restoreTrashItem(type, id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Color(0xFF10B981), content: Text('Item restored successfully! ✅')),
      );
      _loadTrash();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to restore item')));
    }
  }

  Future<void> _permanentlyDeleteItem(String type, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14141B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        title: const Text('Permanently Delete?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('This action is irreversible. The item will be erased forever.', style: TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.permanentlyDeleteTrashItem(type, id);
        _loadTrash();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete item')));
      }
    }
  }

  Future<void> _emptyAllTrash() async {
    if (_trashItems.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14141B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        title: const Text('Empty All Trash?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('All items in the trash bin will be permanently erased.', style: TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.emptyTrash();
        _loadTrash();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to empty trash')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            '30-DAY RETENTION SYSTEM',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF71717A),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trash & Recoverable Storage',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              if (_trashItems.isNotEmpty)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F1F28),
                    foregroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                  label: const Text('Empty All Trash', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: _emptyAllTrash,
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Trash Container
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F13),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DELETED ITEMS IN RECOVERY POOL',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.4),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Deleted posts, tasks, and asset files remain recoverable here for 30 days before auto-purge.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF181820), borderRadius: BorderRadius.circular(6)),
                      child: Text('${_trashItems.length} items', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_trashItems.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    alignment: Alignment.center,
                    child: const Column(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 44, color: Color(0xFF52525B)),
                        SizedBox(height: 12),
                        Text('Trash is completely clean', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('No deleted items in the 30-day retention pool.', style: TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _trashItems.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.04), height: 24),
                    itemBuilder: (context, idx) {
                      final item = _trashItems[idx];
                      final name = item['name'] ?? item['title'] ?? 'Deleted Item';
                      final type = (item['type'] ?? 'content').toString().toLowerCase();
                      final client = item['client_name'] ?? 'STUDIO MASTER';
                      final daysRemaining = item['days_remaining'] ?? 30;

                      return Row(
                        children: [
                          // Type indicator
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0x1ADB2727),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0x33DC2626)),
                            ),
                            child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                          ),
                          const SizedBox(width: 14),

                          // Name & Client info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Text(
                                      client.toString().toUpperCase(),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF71717A), letterSpacing: 0.5),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(color: const Color(0xFF181820), borderRadius: BorderRadius.circular(4)),
                                      child: Text(
                                        type.toUpperCase(),
                                        style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Retention countdown badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF181820), borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              '$daysRemaining days left',
                              style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Action Buttons
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            icon: const Icon(Icons.restore_rounded, size: 14, color: Color(0xFF10B981)),
                            label: const Text('Restore', style: TextStyle(fontSize: 11)),
                            onPressed: () => _restoreItem(type, item['id']),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF71717A)),
                            tooltip: 'Permanently Erase',
                            onPressed: () => _permanentlyDeleteItem(type, item['id']),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
