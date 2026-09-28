import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/looplyn_logo.dart';
import '../../core/route_transitions.dart';
import '../auth/login_screen.dart';
import '../chat/chat_hub_screen.dart';
import '../clients/clients_staff_screen.dart';
import '../dashboard/studio_dashboard_screen.dart';
import '../emails/email_templates_screen.dart';
import '../studio/studio_calendar_screen.dart';
import '../trash/trash_screen.dart';

class AppShell extends StatefulWidget {
  final int initialTab;
  const AppShell({super.key, this.initialTab = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentTab;
  final _api = ApiClient();
  String _userName = 'Akash';
  String _userEmail = 'admin@looplyn.tech';
  String _userRole = 'admin';

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final res = await _api.getMe();
      if (res['success'] == true && res['user'] != null) {
        if (mounted) {
          setState(() {
            _userName = res['user']['name'] ?? 'Admin';
            _userEmail = res['user']['email'] ?? 'admin@looplyn.tech';
            _userRole = res['user']['role'] ?? 'admin';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _handleLogout() async {
    await _api.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      SmoothPageRoute(
        page: const LoginScreen(),
        direction: SlideDirection.fadeOnly,
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, $_userName';
    if (hour < 17) return 'Good afternoon, $_userName';
    return 'Good evening, $_userName';
  }

  String _getDateSubtitle() {
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'];
    return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]}';
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case 0:
        return StudioDashboardScreen(
          onNavigateToCalendar: () => setState(() => _currentTab = 1),
        );
      case 1:
        return const StudioCalendarScreen();
      case 2:
        return const ChatHubScreen();
      case 3:
        return _buildPlaceholderScreen('Tasks Board', 'Track and assign creative workflows, approvals, and deadlines.', Icons.check_circle_outline_rounded);
      case 4:
        return _buildPlaceholderScreen('Asset Library & Files', 'Organize video drafts, reels, PSDs, and brand collateral.', Icons.folder_outlined);
      case 5:
        return const ClientsStaffScreen();
      case 6:
        return const EmailTemplatesScreen();
      case 7:
        return const TrashScreen();
      case 8:
        return _buildPlaceholderScreen('Workspace Settings', 'Configure studio preferences, members, roles, and integrations.', Icons.settings_outlined);
      default:
        return const StudioDashboardScreen();
    }
  }

  Widget _buildPlaceholderScreen(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF181820),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(icon, size: 36, color: const Color(0xFFDC2626)),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF71717A)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      body: Row(
        children: [
          // 1. Sidebar Navigation (Left)
          _buildSidebar(),

          // 2. Main Workspace (Header + Dynamic Page Content)
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0E),
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                const LooplynLogo(size: 26),
                const SizedBox(width: 10),
                RichText(
                  text: const TextSpan(
                    text: 'Looplyn',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(
                        text: '▪',
                        style: TextStyle(color: Color(0xFFDC2626), fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quick Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF121217),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, size: 15, color: Color(0xFF71717A)),
                  SizedBox(width: 8),
                  Text('Search', style: TextStyle(color: Color(0xFF52525B), fontSize: 12)),
                  Spacer(),
                  Text('⌘K', style: TextStyle(color: Color(0xFF52525B), fontSize: 10, fontFamily: 'monospace')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _buildNavItem(0, 'Dashboard', Icons.dashboard_outlined),
                _buildNavItem(1, 'Content Calendar', Icons.calendar_month_outlined),
                _buildNavItem(2, 'Messages', Icons.chat_bubble_outline_rounded),
                _buildNavItem(3, 'Tasks', Icons.check_circle_outline_rounded),
                _buildNavItem(4, 'Files', Icons.folder_outlined),
                _buildNavItem(5, 'Client & Staff', Icons.group_outlined),
                _buildNavItem(6, 'Emails', Icons.mail_outline_rounded),
                _buildNavItem(7, 'Trash', Icons.delete_outline_rounded),
                _buildNavItem(8, 'Settings', Icons.settings_outlined),
              ],
            ),
          ),

          // Sidebar Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Column(
              children: [
                _buildFooterItem('Feedback & Bugs', Icons.bug_report_outlined, () {}),
                const SizedBox(height: 4),
                _buildFooterItem('Sign Out', Icons.logout_rounded, _handleLogout, isDanger: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = _currentTab == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _currentTab = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1C1315) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.35))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF71717A),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterItem(String label, IconData icon, VoidCallback onTap, {bool isDanger = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: isDanger ? const Color(0xFFEF4444) : const Color(0xFF71717A),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDanger ? const Color(0xFFEF4444) : const Color(0xFF71717A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0E),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dynamic Greeting
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _currentTab == 0 ? 'OVERVIEW FOR TODAY' : _getDateSubtitle(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF71717A),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          // Header Controls
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.wb_sunny_outlined, size: 17, color: Color(0xFF71717A)),
                onPressed: () {},
                tooltip: 'Theme toggle',
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 17, color: Color(0xFF71717A)),
                onPressed: () {},
                tooltip: 'Filter options',
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 18, color: Color(0xFF71717A)),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
              const SizedBox(width: 8),
              // User Avatar
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFFC0151C),
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'A',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
