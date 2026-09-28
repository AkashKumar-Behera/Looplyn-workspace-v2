import 'package:flutter/material.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final List<Map<String, dynamic>> _trashItems = [
    {
      'title': 'Craft 6 — Kitchen-in-Motion',
      'client': 'Karan Khandelwal',
      'deletedAt': 'Deleted: 9/23/2026, 4:14:46 PM',
      'source': 'MCP Server',
    },
    {
      'title': 'Brand 2 — Beat-Synced Dish Reveal',
      'client': 'Karan Khandelwal',
      'deletedAt': 'Deleted: 9/23/2026, 4:14:00 PM',
      'source': 'MCP Server',
    },
    {
      'title': '3. The ₹170 Breakdown — What You Actually Get',
      'client': 'Karan Khandelwal',
      'deletedAt': 'Deleted: 9/23/2026, 3:18:47 PM',
      'source': 'MCP Server',
    },
    {
      'title': 'Shree Prashadam DIARIES',
      'client': 'Karan Khandelwal',
      'deletedAt': 'Deleted: 9/23/2026, 3:18:07 PM',
      'source': 'MCP Server',
    },
    {
      'title': 'Craft 2 — Filter Coffee Pour',
      'client': 'Karan Khandelwal',
      'deletedAt': 'Deleted: 9/23/2026, 3:16:40 PM',
      'source': 'MCP Server',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            '30-DAY RETENTION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF71717A),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Trash & Deleted Items',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
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
                          'DELETED CONTENT ITEMS',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.4),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Items deleted via MCP Server or UI remain recoverable here for 30 days.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181E),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Text(
                        '${_trashItems.length} Items in Trash',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_trashItems.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('Trash is currently empty', style: TextStyle(color: Color(0xFF71717A))),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _trashItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final item = _trashItems[idx];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131318),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item['title'] ?? '',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1F1F26),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item['client'] ?? '',
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item['deletedAt']}  •  Source: ${item['source']}  •  Retention: 30 days',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
                                  ),
                                ],
                              ),
                            ),
                            // Restore Button
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                setState(() => _trashItems.removeAt(idx));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Restored content item to Calendar!'), backgroundColor: Color(0xFF059669)),
                                );
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 14),
                              label: const Text('Restore to Calendar', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 10),
                            // Delete Permanently Button
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(color: Color(0x66DC2626)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                setState(() => _trashItems.removeAt(idx));
                              },
                              icon: const Icon(Icons.delete_outline_rounded, size: 14),
                              label: const Text('Delete Permanently', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
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
