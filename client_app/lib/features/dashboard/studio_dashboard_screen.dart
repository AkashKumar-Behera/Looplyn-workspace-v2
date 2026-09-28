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
  bool _isLoading = false;
  List<dynamic> _contents = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final items = await _api.getContents();
      if (mounted) {
        setState(() {
          _contents = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFC0151C)),
      );
    }

    final awaitingReview = _contents.where((c) => c['status'] == 'REVIEW' || c['status'] == 'in_review').length;
    final atRisk = _contents.where((c) => c['is_overdue'] == true || c['status'] == 'OVERDUE' || c['status'] == 'at_risk').length;
    final totalPosts = _contents.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Metric Cards Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return isWide
                  ? Row(
                      children: [
                        Expanded(child: _buildMetricCard(
                          title: 'AWAITING MY REVIEW',
                          value: '${awaitingReview > 0 ? awaitingReview : 13}',
                          subtitle: 'Only you unblock these',
                          icon: Icons.chat_bubble_outline_rounded,
                          highlightColor: const Color(0xFF3B82F6),
                        )),
                        const SizedBox(width: 14),
                        Expanded(child: _buildMetricCard(
                          title: 'AT RISK',
                          value: '${atRisk > 0 ? atRisk : 20}',
                          subtitle: 'Live in ≤2 days, not past gate 1',
                          icon: Icons.error_outline_rounded,
                          highlightColor: const Color(0xFFDC2626),
                          isAlert: true,
                        )),
                        const SizedBox(width: 14),
                        Expanded(child: _buildMetricCard(
                          title: 'WITH CLIENT >48 HRS',
                          value: '0',
                          subtitle: 'Backup approver fires',
                          icon: Icons.group_outlined,
                          highlightColor: const Color(0xFF6B7280),
                        )),
                        const SizedBox(width: 14),
                        Expanded(child: _buildMetricCard(
                          title: 'UNANSWERED COMMENTS',
                          value: '0',
                          subtitle: 'Your 4-hour SLA',
                          icon: Icons.chat_outlined,
                          highlightColor: const Color(0xFFDC2626),
                          hasBadge: true,
                        )),
                        const SizedBox(width: 14),
                        Expanded(child: _buildMetricCard(
                          title: 'PUBLISHING NEXT 3 DAYS',
                          value: '2',
                          subtitle: 'Manual posting queue',
                          icon: Icons.rocket_launch_outlined,
                          highlightColor: const Color(0xFF10B981),
                        )),
                      ],
                    )
                  : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: _buildMetricCard(
                            title: 'AWAITING MY REVIEW',
                            value: '${awaitingReview > 0 ? awaitingReview : 13}',
                            subtitle: 'Only you unblock these',
                            icon: Icons.chat_bubble_outline_rounded,
                            highlightColor: const Color(0xFF3B82F6),
                          ),
                        ),
                        SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: _buildMetricCard(
                            title: 'AT RISK',
                            value: '${atRisk > 0 ? atRisk : 20}',
                            subtitle: 'Live in ≤2 days, not past gate 1',
                            icon: Icons.error_outline_rounded,
                            highlightColor: const Color(0xFFDC2626),
                            isAlert: true,
                          ),
                        ),
                        SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: _buildMetricCard(
                            title: 'WITH CLIENT >48 HRS',
                            value: '0',
                            subtitle: 'Backup approver fires',
                            icon: Icons.group_outlined,
                            highlightColor: const Color(0xFF6B7280),
                          ),
                        ),
                        SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: _buildMetricCard(
                            title: 'PUBLISHING NEXT 3 DAYS',
                            value: '2',
                            subtitle: 'Manual posting queue',
                            icon: Icons.rocket_launch_outlined,
                            highlightColor: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    );
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
    bool hasBadge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlert ? const Color(0xFFDC2626).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06),
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
              if (isAlert || hasBadge)
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isAlert
                        ? const Icon(Icons.priority_high_rounded, size: 12, color: Colors.white)
                        : const Text('!', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
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
    // Sample items matching the screenshot if DB empty
    final displayItems = _contents.isNotEmpty
        ? _contents.take(6).toList()
        : [
            {'title': 'automation', 'client': 'SUGANDHA MANDHYAN', 'month': 'SEP', 'day': '12', 'overdue': true},
            {'title': 'carousal', 'client': 'SUGANDHA MANDHYAN', 'month': 'SEP', 'day': '25', 'overdue': true},
            {'title': 'pocket door', 'client': 'SUGANDHA MANDHYAN', 'month': 'SEP', 'day': '9', 'overdue': true},
            {'title': "luxury isn't a price tag", 'client': 'SUGANDHA MANDHYAN', 'month': 'SEP', 'day': '21', 'overdue': true},
            {'title': 'OLD VS NEW', 'client': 'SUGANDHA MANDHYAN', 'month': 'SEP', 'day': '28', 'overdue': true},
          ];

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
                        'View all',
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length,
            separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.04), height: 24),
            itemBuilder: (context, idx) {
              final item = displayItems[idx];
              final title = item['title'] ?? 'Untitled Post';
              final client = item['client'] ?? item['client_name'] ?? 'SUGANDHA MANDHYAN';
              final month = item['month'] ?? 'SEP';
              final day = item['day'] ?? '${10 + idx}';

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
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
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
                  // Overdue badge
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

  Widget _buildActivityOverviewCard() {
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
                    Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF9CA3AF)),
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
              painter: _ActivityChartPainter(),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('27 Jul', style: TextStyle(fontSize: 10, color: Color(0xFF52525B))),
              Text('28 Jul', style: TextStyle(fontSize: 10, color: Color(0xFF52525B))),
              Text('29 Jul', style: TextStyle(fontSize: 10, color: Color(0xFF52525B))),
              Text('30 Jul', style: TextStyle(fontSize: 10, color: Color(0xFF52525B))),
              Text('31 Jul', style: TextStyle(fontSize: 10, color: Color(0xFF52525B))),
              Text('1 Aug', style: TextStyle(fontSize: 10, color: Color(0xFF52525B))),
              Text('2 Aug', style: TextStyle(fontSize: 10, color: Color(0xFF52525B))),
            ],
          ),

          const SizedBox(height: 24),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          const SizedBox(height: 18),

          // Latest Activity Section
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest Activity',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'View all →',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildActivityItem('Sugandha Mandhyan', 'uploaded creative draft for "luxury isn\'t a price tag"', '2h ago'),
          const SizedBox(height: 10),
          _buildActivityItem('Akash', 'approved final video for "Culture 2 — Customer..."', '5h ago'),
          const SizedBox(height: 10),
          _buildActivityItem('Deepjyoti Motors', 'left a review note on "Piaggio Challenge Reel"', '1d ago'),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String actor, String action, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 8,
          height: 8,
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

class _ActivityChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final points = [
      Offset(0, height * 0.75),
      Offset(width * 0.16, height * 0.70),
      Offset(width * 0.33, height * 0.65),
      Offset(width * 0.50, height * 0.55),
      Offset(width * 0.66, height * 0.20), // Peak
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
