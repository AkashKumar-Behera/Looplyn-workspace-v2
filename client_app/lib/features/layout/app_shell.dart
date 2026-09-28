import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/looplyn_logo.dart';
import '../../core/route_transitions.dart';
import '../../core/theme.dart';
import '../auth/login_screen.dart';
import '../chat/chat_hub_screen.dart';
import '../clients/clients_staff_screen.dart';
import '../dashboard/studio_dashboard_screen.dart';
import '../emails/email_templates_screen.dart';
import '../files/files_storage_screen.dart';
import '../settings/workspace_settings_screen.dart';
import '../studio/studio_calendar_screen.dart';
import '../tasks/tasks_board_screen.dart';
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
  String _userEmail = 'akashkumar48874@gmail.com';
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
            _userName = res['user']['name'] ?? 'Akash';
            _userEmail = res['user']['email'] ?? 'akashkumar48874@gmail.com';
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
    if (hour >= 22 || hour < 5) return "It's quite late, $_userName";
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
        return const TasksBoardScreen();
      case 4:
        return const FilesStorageScreen();
      case 5:
        return const ClientsStaffScreen();
      case 6:
        return const EmailTemplatesScreen();
      case 7:
        return const TrashScreen();
      case 8:
        return const WorkspaceSettingsScreen();
      default:
        return const StudioDashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final isDark = ThemeController.instance.isDark;

        return Scaffold(
          backgroundColor: AppColors.bg(isDark),
          body: Row(
            children: [
              // 1. Sidebar Navigation (Left)
              _buildSidebar(isDark),

              // 2. Main Workspace (Header + Dynamic Page Content)
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(isDark),
                    Expanded(child: _buildBody()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar(bool isDark) {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: AppColors.sidebar(isDark),
        border: Border(right: BorderSide(color: AppColors.border(isDark))),
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
                  text: TextSpan(
                    text: 'Looplyn',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary(isDark),
                      letterSpacing: -0.5,
                    ),
                    children: const [
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
                color: isDark ? const Color(0xFF121217) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border(isDark)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 15, color: AppColors.textMuted(isDark)),
                  const SizedBox(width: 8),
                  Text('Search', style: TextStyle(color: AppColors.textMuted(isDark), fontSize: 12)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('⌘K', style: TextStyle(color: AppColors.textMuted(isDark), fontSize: 10, fontFamily: 'monospace')),
                  ),
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
                _buildNavItem(0, 'Dashboard', Icons.dashboard_outlined, isDark),
                _buildNavItem(1, 'Content Calendar', Icons.calendar_month_outlined, isDark),
                _buildNavItem(2, 'Messages', Icons.chat_bubble_outline_rounded, isDark),
                _buildNavItem(3, 'Tasks', Icons.check_circle_outline_rounded, isDark),
                _buildNavItem(4, 'Files', Icons.folder_outlined, isDark),
                _buildNavItem(5, 'Client & Staff', Icons.group_outlined, isDark),
                _buildNavItem(6, 'Emails', Icons.mail_outline_rounded, isDark),
                _buildNavItem(7, 'Trash', Icons.delete_outline_rounded, isDark),
                _buildNavItem(8, 'Settings', Icons.settings_outlined, isDark),
              ],
            ),
          ),

          // Storage widget matching legacy Screenshot 5
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101015) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border(isDark)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cloud_outlined, size: 14, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 6),
                          Text('Storage', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary(isDark))),
                        ],
                      ),
                      Text('2.1% used', style: TextStyle(fontSize: 10, color: AppColors.textMuted(isDark), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.021,
                      backgroundColor: Color(0xFF272730),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('407 files • 46.6 GB of 2TB', style: TextStyle(fontSize: 9, color: AppColors.textMuted(isDark))),
                ],
              ),
            ),
          ),

          // Sidebar Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border(isDark))),
            ),
            child: Column(
              children: [
                _buildFooterItem('Feedback & Bugs', Icons.bug_report_outlined, () {}, isDark),
                const SizedBox(height: 4),
                _buildFooterItem('Sign Out', Icons.logout_rounded, _handleLogout, isDark, isDanger: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, bool isDark) {
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
              color: isSelected
                  ? (isDark ? const Color(0xFF1C1315) : const Color(0xFFFEE2E2))
                  : Colors.transparent,
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
                  color: isSelected ? const Color(0xFFEF4444) : AppColors.textMuted(isDark),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFFDC2626))
                        : AppColors.textSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterItem(String label, IconData icon, VoidCallback onTap, bool isDark, {bool isDanger = false}) {
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
                color: isDanger ? const Color(0xFFEF4444) : AppColors.textMuted(isDark),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDanger ? const Color(0xFFEF4444) : AppColors.textMuted(isDark),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.sidebar(isDark),
        border: Border(bottom: BorderSide(color: AppColors.border(isDark))),
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
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(isDark),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _currentTab == 0 ? 'OVERVIEW FOR TODAY' : _getDateSubtitle(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted(isDark),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          // Header Controls
          Row(
            children: [
              // Theme Toggle Button (Sun / Moon)
              IconButton(
                icon: Icon(
                  isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                  size: 18,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                ),
                tooltip: isDark ? 'Switch to Light mode' : 'Switch to Dark Noir mode',
                onPressed: () => ThemeController.instance.toggleTheme(),
              ),
              const SizedBox(width: 4),

              // Filter Controls
              IconButton(
                icon: Icon(Icons.tune_rounded, size: 18, color: AppColors.textMuted(isDark)),
                tooltip: 'Filter options',
                onPressed: () {},
              ),
              const SizedBox(width: 4),

              // Notifications Bell
              IconButton(
                icon: Icon(Icons.notifications_none_rounded, size: 19, color: AppColors.textMuted(isDark)),
                tooltip: 'Notifications',
                onPressed: () {},
              ),
              const SizedBox(width: 12),

              // User Avatar
              Tooltip(
                message: '$_userName ($_userRole) • $_userEmail',
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC0151C),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'A',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
