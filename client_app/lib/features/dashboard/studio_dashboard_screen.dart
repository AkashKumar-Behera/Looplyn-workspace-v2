import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class StudioDashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToCalendar;
  const StudioDashboardScreen({super.key, this.onNavigateToCalendar});

  @override
  State<StudioDashboardScreen> createState() => _StudioDashboardScreenState();
}

class _StudioDashboardScreenState extends State<StudioDashboardScreen> {
  final _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _contents = [];
  List<dynamic> _activities = [];
  List<dynamic> _activityStats = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getContents(),
        _api.getActivities(),
        _api.getActivityStats(),
      ]);

      if (mounted) {
        setState(() {
          _contents = results[0];
          _activities = results[1];
          _activityStats = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatRelativeTime(String? dateStr) {
    if (dateStr == null) return 'recently';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return 'recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFC0151C)),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final in3Days = today.add(const Duration(days: 3));

    // Calculate real dynamic metric values
    final awaitingReview = _contents.where((c) {
      final status = (c['status'] ?? '').toString().toUpperCase();
      return status == 'REVIEW' || status == 'IN_REVIEW';
    }).length;

    final atRisk = _contents.where((c) {
      final status = (c['status'] ?? '').toString().toUpperCase();
      if (status == 'PUBLISHED' || status == 'APPROVED') return false;
      if (c['scheduled_date'] == null) return false;
      try {
        final sched = DateTime.parse(c['scheduled_date']).toLocal();
        final schedDay = DateTime(sched.year, sched.month, sched.day);
        return schedDay.isBefore(today) || schedDay.isBefore(today.add(const Duration(days: 2)));
      } catch (_) {
        return false;
      }
    }).length;

    final withClientOver48h = _contents.where((c) {
      final status = (c['status'] ?? '').toString().toUpperCase();
      if (status != 'REVIEW' && status != 'IN_REVIEW') return false;
      try {
        final created = DateTime.parse(c['created_at']);
        return now.difference(created).inHours >= 48;
      } catch (_) {
        return false;
      }
    }).length;

    final publishingNext3Days = _contents.where((c) {
      if (c['scheduled_date'] == null) return false;
      try {
        final sched = DateTime.parse(c['scheduled_date']).toLocal();
        final schedDay = DateTime(sched.year, sched.month, sched.day);
        return !schedDay.isBefore(today) && !schedDay.isAfter(in3Days);
      } catch (_) {
        return false;
      }
    }).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Metric Cards Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final cards = [
                _buildMetricCard(
                  title: 'AWAITING MY REVIEW',
                  value: '$awaitingReview',
                  subtitle: 'Only you unblock these',
                  icon: Icons.chat_bubble_outline_rounded,
                  highlightColor: const Color(0xFF3B82F6),
                ),
                _buildMetricCard(
                  title: 'AT RISK',
                  value: '$atRisk',
                  subtitle: 'Live in ≤2 days, not published',
                  icon: Icons.error_outline_rounded,
                  highlightColor: const Color(0xFFDC2626),
                  isAlert: atRisk > 0,
                ),
                _buildMetricCard(
                  title: 'WITH CLIENT >48 HRS',
                  value: '$withClientOver48h',
                  subtitle: 'Pending approval overdue',
                  icon: Icons.group_outlined,
                  highlightColor: const Color(0xFF6B7280),
                ),
                _buildMetricCard(
                  title: 'TOTAL POSTS IN PIPELINE',
                  value: '${_contents.length}',
                  subtitle: 'Active studio items',
                  icon: Icons.view_kanban_outlined,
                  highlightColor: const Color(0xFF8B5CF6),
                ),
                _buildMetricCard(
                  title: 'PUBLISHING NEXT 3 DAYS',
                  value: '$publishingNext3Days',
                  subtitle: 'Scheduled queue',
                  icon: Icons.rocket_launch_outlined,
                  highlightColor: const Color(0xFF10B981),
                ),
              ];

              if (isWide) {
                return Row(
                  children: cards.map((c) => Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: c,
                  ))).toList(),
                );
              } else {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: cards.map((c) => SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: c,
                  )).toList(),
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // 2. Bottom Split Section: Deadlines & Activity
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 960;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildContentDeadlinesCard()),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: _buildActivityOverviewCard()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildContentDeadlinesCard(),
                    const SizedBox(height: 20),
                    _buildActivityOverviewCard(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color highlightColor,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlert ? const Color(0xFFDC2626).withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.06),
        ),
        gradient: isAlert
            ? const RadialGradient(
                center: Alignment.topRight,
                radius: 1.2,
                colors: [
                  Color(0x22DC2626),
                  Color(0xFF0F0F13),
                ],
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF71717A),
                  letterSpacing: 0.5,
                ),
              ),
              if (isAlert)
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.priority_high_rounded, size: 12, color: Colors.white),
                  ),
                )
              else
                Icon(icon, size: 16, color: const Color(0xFF52525B)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isAlert ? const Color(0xFFDC2626) : Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF71717A),
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContentDeadlinesCard() {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final displayItems = _contents.take(6).toList();

    return Container(
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
              const Row(
                children: [
                  Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF9CA3AF)),
                  SizedBox(width: 8),
                  Text(
                    'Content Deadlines',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onNavigateToCalendar,
                  child: const Row(
                    children: [
                      Text(
                        'View calendar',
                        style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF9CA3AF)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (displayItems.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.event_available_outlined, size: 36, color: Color(0xFF52525B)),
                  SizedBox(height: 10),
                  Text('No scheduled deadlines right now', style: TextStyle(color: Color(0xFF71717A), fontSize: 13)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayItems.length,
              separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.04), height: 24),
              itemBuilder: (context, idx) {
                final item = displayItems[idx];
                final title = item['title'] ?? 'Untitled Post';
                final client = item['client_name'] ?? item['client'] ?? 'STUDIO CLIENT';
                final status = (item['status'] ?? '').toString().toUpperCase();

                String monthStr = 'SEP';
                String dayStr = '${idx + 1}';
                bool isOverdue = false;

                if (item['scheduled_date'] != null) {
                  try {
                    final dt = DateTime.parse(item['scheduled_date']).toLocal();
                    monthStr = months[dt.month - 1];
                    dayStr = '${dt.day}';
                    final schedDay = DateTime(dt.year, dt.month, dt.day);
                    if (schedDay.isBefore(today) && status != 'PUBLISHED') {
                      isOverdue = true;
                    }
                  } catch (_) {}
                }

                return Row(
                  children: [
                    // Date box
                    Container(
                      width: 44,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isOverdue ? const Color(0x1ADB2727) : const Color(0xFF18181E),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isOverdue ? const Color(0x33DC2626) : Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            monthStr,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF9CA3AF),
                            ),
                          ),
                          Text(
                            dayStr,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title & Client
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            client.toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF71717A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status / Overdue badge
                    if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0x22DC2626),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0x66DC2626)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 6, color: Color(0xFFEF4444)),
                            SizedBox(width: 4),
                            Text(
                              'OVERDUE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEF4444),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF181820),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Text(
                          status.replaceAll('_', ' '),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9CA3AF),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityOverviewCard() {
    final stats = _activityStats.isNotEmpty
        ? _activityStats
        : List.generate(7, (i) => {'label': 'Day ${i + 1}', 'count': 0});

    return Container(
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
              const Text(
                'Activity Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181E),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Row(
                  children: [
                    Text('Last 7 days', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    SizedBox(width: 4),
                    Icon(Icons.insights_rounded, size: 14, color: Color(0xFFDC2626)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Glowing Activity Spline Graph
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _DynamicActivityChartPainter(
                dataCounts: stats.map<double>((s) => ((s['count'] ?? 0) as num).toDouble()).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stats.map<Widget>((s) {
              return Text(
                s['label'] ?? '',
                style: const TextStyle(fontSize: 10, color: Color(0xFF52525B)),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          const SizedBox(height: 18),

          // Latest Activity Section
          const Text(
            'Latest Activity Feed',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          if (_activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No recent activity recorded yet.', style: TextStyle(fontSize: 12, color: Color(0xFF71717A))),
            )
          else
            ..._activities.take(4).map((act) {
              final user = act['user_name'] ?? 'Team Member';
              final action = act['action'] ?? 'performed action';
              final target = act['entity_title'] ?? '';
              final timeStr = _formatRelativeTime(act['created_at']);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildActivityItem(user, '$action ${target.isNotEmpty ? '"$target"' : ''}', timeStr),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String actor, String action, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFFC0151C),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: '$actor ',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
              children: [
                TextSpan(
                  text: action,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF52525B))),
      ],
    );
  }
}

class _DynamicActivityChartPainter extends CustomPainter {
  final List<double> dataCounts;
  _DynamicActivityChartPainter({required this.dataCounts});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    if (dataCounts.isEmpty) return;

    final maxVal = dataCounts.fold(1.0, (prev, curr) => curr > prev ? curr : prev);
    final count = dataCounts.length;
    final stepX = count > 1 ? width / (count - 1) : width;

    final points = <Offset>[];
    for (int i = 0; i < count; i++) {
      final x = i * stepX;
      final normalized = dataCounts[i] / (maxVal > 0 ? maxVal : 1.0);
      final y = height * 0.85 - (normalized * (height * 0.65));
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFDC2626).withValues(alpha: 0.35),
        const Color(0xFFDC2626).withValues(alpha: 0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);

    // Peak dot highlight
    int peakIndex = 0;
    double maxCount = -1;
    for (int i = 0; i < dataCounts.length; i++) {
      if (dataCounts[i] > maxCount) {
        maxCount = dataCounts[i];
        peakIndex = i;
      }
    }

    final peakPoint = points[peakIndex];
    final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final dotRingPaint = Paint()..color = const Color(0xFFEF4444)..strokeWidth = 2..style = PaintingStyle.stroke;

    canvas.drawCircle(peakPoint, 5, dotPaint);
    canvas.drawCircle(peakPoint, 5, dotRingPaint);
  }

  @override
  bool shouldRepaint(covariant _DynamicActivityChartPainter oldDelegate) {
    return oldDelegate.dataCounts != dataCounts;
  }
}
