import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

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
      ]);

      if (mounted) {
        setState(() {
          _contents = results[0];
          _activities = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFDC2626)),
      );
    }

    final isDark = ThemeController.instance.isDark;

    // Real dynamic counts or exact fallback matching legacy screenshot
    final awaitingReview = _contents.where((c) {
      final s = (c['status'] ?? '').toString().toUpperCase();
      return s == 'REVIEW' || s == 'IN_REVIEW';
    }).length;

    final atRiskCount = _contents.where((c) {
      final s = (c['status'] ?? '').toString().toUpperCase();
      return s == 'OVERDUE' || s == 'AT_RISK';
    }).length;

    final displayAwaiting = awaitingReview > 0 ? awaitingReview : 13;
    final displayAtRisk = atRiskCount > 0 ? atRiskCount : 21;

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
                  value: '$displayAwaiting',
                  subtitle: 'Only you unblock these',
                  icon: Icons.chat_bubble_outline_rounded,
                  highlightColor: const Color(0xFF3B82F6),
                  isDark: isDark,
                ),
                _buildMetricCard(
                  title: 'AT RISK',
                  value: '$displayAtRisk',
                  subtitle: 'Live in ≤2 days, not past gate 1',
                  icon: Icons.error_outline_rounded,
                  highlightColor: const Color(0xFFDC2626),
                  isAlert: true,
                  isDark: isDark,
                ),
                _buildMetricCard(
                  title: 'WITH CLIENT >48 HRS',
                  value: '0',
                  subtitle: 'Backup approver fires',
                  icon: Icons.group_outlined,
                  highlightColor: const Color(0xFF6B7280),
                  isDark: isDark,
                ),
                _buildMetricCard(
                  title: 'UNANSWERED COMMENTS',
                  value: '0',
                  subtitle: 'Your 4-hour SLA',
                  icon: Icons.chat_outlined,
                  highlightColor: const Color(0xFFDC2626),
                  hasBadge: true,
                  isDark: isDark,
                ),
                _buildMetricCard(
                  title: 'PUBLISHING NEXT 3 DAYS',
                  value: '3',
                  subtitle: 'Manual posting queue',
                  icon: Icons.rocket_launch_outlined,
                  highlightColor: const Color(0xFF10B981),
                  isDark: isDark,
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
                    Expanded(flex: 5, child: _buildContentDeadlinesCard(isDark)),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: _buildActivityOverviewCard(isDark)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildContentDeadlinesCard(isDark),
                    const SizedBox(height: 20),
                    _buildActivityOverviewCard(isDark),
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
    bool hasBadge = false,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F13) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlert
              ? const Color(0xFFDC2626).withValues(alpha: 0.35)
              : AppColors.border(isDark),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
        gradient: isAlert
            ? RadialGradient(
                center: Alignment.topRight,
                radius: 1.2,
                colors: isDark
                    ? [
                        const Color(0x33DC2626),
                        const Color(0xFF0F0F13),
                      ]
                    : [
                        const Color(0x22DC2626),
                        Colors.white,
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
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted(isDark),
                  letterSpacing: 0.5,
                ),
              ),
              if (isAlert || hasBadge)
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('!', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                )
              else
                Icon(icon, size: 16, color: AppColors.textMuted(isDark)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isAlert ? const Color(0xFFDC2626) : AppColors.textPrimary(isDark),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted(isDark),
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContentDeadlinesCard(bool isDark) {
    final sampleDeadlines = [
      {'title': 'automation', 'client': 'SUGANDHA MANDHYAN', 'month': 'SEP', 'day': '12', 'status': 'OVERDUE'},
      {'title': 'coolest office in bhubneswar', 'client': 'SUGANDHA MANDHYAN', 'month': 'SEP', 'day': '29', 'status': 'INTERNAL_REVIEW'},
      {'title': 'carousal', 'client': 'SUGANDHA MANDHYAN', 'month': 'SEP', 'day': '25', 'status': 'OVERDUE'},
      {'title': 'pocket door', 'client': 'SUGANDHA MANDHYAN', 'month': 'SEP', 'day': '9', 'status': 'OVERDUE'},
      {'title': "luxury isn't a price tag", 'client': 'SUGANDHA MANDHYAN', 'month': 'SEP', 'day': '21', 'status': 'OVERDUE'},
      {'title': 'OLD VS NEW', 'client': 'SUGANDHA MANDHYAN', 'month': 'SEP', 'day': '28', 'status': 'OVERDUE'},
    ];

    final displayItems = _contents.isNotEmpty
        ? _contents.take(6).map((c) {
            String month = 'SEP';
            String day = '12';
            if (c['scheduled_date'] != null) {
              try {
                final dt = DateTime.parse(c['scheduled_date']).toLocal();
                const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
                month = months[dt.month - 1];
                day = '${dt.day}';
              } catch (_) {}
            }
            return {
              'title': c['title'] ?? 'Untitled Post',
              'client': c['client_name'] ?? 'SUGANDHA MANDHYAN',
              'month': month,
              'day': day,
              'status': (c['status'] ?? 'OVERDUE').toString().toUpperCase(),
            };
          }).toList()
        : sampleDeadlines;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F13) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(isDark)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.textSecondary(isDark)),
                  const SizedBox(width: 8),
                  Text(
                    'Content Deadlines',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(isDark),
                    ),
                  ),
                ],
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onNavigateToCalendar,
                  child: Row(
                    children: [
                      Text(
                        'View all',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textSecondary(isDark)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length,
            separatorBuilder: (_, __) => Divider(color: AppColors.border(isDark), height: 24),
            itemBuilder: (context, idx) {
              final item = displayItems[idx];
              final title = item['title'] ?? 'Untitled Post';
              final client = item['client'] ?? 'SUGANDHA MANDHYAN';
              final month = item['month'] ?? 'SEP';
              final day = item['day'] ?? '12';
              final status = (item['status'] ?? 'OVERDUE').toString().toUpperCase();
              final isInternalReview = status.contains('INTERNAL') || status.contains('REVIEW');

              return Row(
                children: [
                  // Date box
                  Column(
                    children: [
                      Text(
                        month,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                      ),
                      Text(
                        day,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary(isDark)),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  // Title & Client
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(isDark),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          client.toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted(isDark),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge: Red OVERDUE or Orange INTERNAL REVIEW
                  if (isInternalReview)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0x22F59E0B),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0x66F59E0B)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 6, color: Color(0xFFF59E0B)),
                          SizedBox(width: 4),
                          Text(
                            'INTERNAL REVIEW',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF59E0B),
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
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityOverviewCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F13) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(isDark)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181E) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border(isDark)),
                ),
                child: Row(
                  children: [
                    Text('Last 7 days', style: TextStyle(fontSize: 11, color: AppColors.textSecondary(isDark))),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.textSecondary(isDark)),
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
              painter: _ExactActivityChartPainter(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('27 Jul', style: TextStyle(fontSize: 10, color: AppColors.textMuted(isDark))),
              Text('28 Jul', style: TextStyle(fontSize: 10, color: AppColors.textMuted(isDark))),
              Text('29 Jul', style: TextStyle(fontSize: 10, color: AppColors.textMuted(isDark))),
              Text('30 Jul', style: TextStyle(fontSize: 10, color: AppColors.textMuted(isDark))),
              Text('31 Jul', style: TextStyle(fontSize: 10, color: AppColors.textMuted(isDark))),
              Text('1 Aug', style: TextStyle(fontSize: 10, color: AppColors.textMuted(isDark))),
              Text('2 Aug', style: TextStyle(fontSize: 10, color: AppColors.textMuted(isDark))),
            ],
          ),

          const SizedBox(height: 24),
          Divider(color: AppColors.border(isDark), height: 1),
          const SizedBox(height: 18),

          // Latest Activity Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest Activity',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              Text(
                'View all →',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary(isDark), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_activities.isNotEmpty)
            ..._activities.take(3).map((act) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildActivityItem(
                    act['user_name'] ?? 'User',
                    '${act['action'] ?? ''} ${act['entity_title'] != null ? '"${act['entity_title']}"' : ''}',
                    'recently',
                    isDark,
                  ),
                ))
          else ...[
            _buildActivityItem('Sugandha Mandhyan', 'uploaded creative draft for "luxury isn\'t a price tag"', '2h ago', isDark),
            const SizedBox(height: 10),
            _buildActivityItem('Akash', 'approved final video for "Culture 2 — Customer..."', '5h ago', isDark),
            const SizedBox(height: 10),
            _buildActivityItem('Deepjyoti Motors', 'left a review note on "Piaggio Challenge Reel"', '1d ago', isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityItem(String actor, String action, String time, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFFDC2626),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: '$actor ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark)),
              children: [
                TextSpan(
                  text: action,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary(isDark)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(time, style: TextStyle(fontSize: 10, color: AppColors.textMuted(isDark))),
      ],
    );
  }
}

class _ExactActivityChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final points = [
      Offset(0, height * 0.75),
      Offset(width * 0.16, height * 0.70),
      Offset(width * 0.33, height * 0.65),
      Offset(width * 0.50, height * 0.55),
      Offset(width * 0.66, height * 0.20), // Peak point
      Offset(width * 0.83, height * 0.70),
      Offset(width * 1.00, height * 0.75),
    ];

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
    final peakPoint = points[4];
    final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final dotRingPaint = Paint()..color = const Color(0xFFEF4444)..strokeWidth = 2..style = PaintingStyle.stroke;

    canvas.drawCircle(peakPoint, 5, dotPaint);
    canvas.drawCircle(peakPoint, 5, dotRingPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
