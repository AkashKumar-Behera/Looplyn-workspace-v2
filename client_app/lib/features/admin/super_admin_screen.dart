import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/api_client.dart';
import '../../core/looplyn_logo.dart';
import '../../core/route_transitions.dart';
import '../auth/login_screen.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  final _api = ApiClient();
  List<dynamic> _admins = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  Future<void> _fetchAdmins() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _api.getAdmins();
      setState(() {
        _admins = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load admin accounts';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await _api.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      SmoothPageRoute(
        page: const LoginScreen(),
        direction: SlideDirection.leftToRight,
      ),
    );
  }

  void _showCreateAdminDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String? dialogError;
    bool isSubmitting = false;

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
            title: const Row(
              children: [
                Icon(LucideIcons.userPlus, size: 20, color: Color(0xFFDC2626)),
                SizedBox(width: 10),
                Text('Create Admin Account', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dialogError != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C0B0E),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0x66DC2626)),
                      ),
                      child: Text(dialogError!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const Text('Full Name', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g. John Doe',
                      hintStyle: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF09090C),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Email Address', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'admin@looplyn.tech',
                      hintStyle: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF09090C),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Password (Min 6 chars)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF09090C),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final pass = passCtrl.text.trim();

                        if (name.isEmpty || email.isEmpty || pass.length < 6) {
                          setDialogState(() => dialogError = 'Please fill all fields (password min 6 chars)');
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });

                        try {
                          final res = await _api.createAdmin(name, email, pass);
                          if (res['success'] == true) {
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            _fetchAdmins();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text('Admin $name created successfully!'), backgroundColor: const Color(0xFF059669)),
                            );
                          } else {
                            setDialogState(() {
                              dialogError = res['error'] ?? 'Failed to create admin';
                              isSubmitting = false;
                            });
                          }
                        } catch (err) {
                          setDialogState(() {
                            dialogError = 'Error creating admin';
                            isSubmitting = false;
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Admin'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog(String adminId, String adminName) {
    final passCtrl = TextEditingController();
    String? dialogError;
    bool isSubmitting = false;

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
            title: Text('Change Password for $adminName', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dialogError != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C0B0E),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0x66DC2626)),
                      ),
                      child: Text(dialogError!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const Text('New Password (Min 6 chars)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      filled: true,
                      fillColor: const Color(0xFF09090C),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final newPass = passCtrl.text.trim();
                        if (newPass.length < 6) {
                          setDialogState(() => dialogError = 'Password must be at least 6 characters');
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });

                        try {
                          final res = await _api.updateAdmin(adminId, password: newPass);
                          if (res['success'] == true) {
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text('Password updated for $adminName'), backgroundColor: const Color(0xFF059669)),
                            );
                          } else {
                            setDialogState(() {
                              dialogError = res['error'] ?? 'Failed to update password';
                              isSubmitting = false;
                            });
                          }
                        } catch (err) {
                          setDialogState(() {
                            dialogError = 'Error updating password';
                            isSubmitting = false;
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Password'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleAdminStatus(String adminId, String currentStatus, String adminName) async {
    final nextStatus = currentStatus == 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';
    try {
      final res = await _api.updateAdmin(adminId, status: nextStatus);
      if (res['success'] == true) {
        _fetchAdmins();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$adminName is now $nextStatus'),
            backgroundColor: nextStatus == 'ACTIVE' ? const Color(0xFF059669) : const Color(0xFFD97706),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status'), backgroundColor: Color(0xFFEF4444)),
      );
    }
  }

  void _confirmDeleteAdmin(String adminId, String adminName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111116),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text('Delete $adminName?', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to delete this Admin account? This action cannot be undone.',
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final res = await _api.deleteAdmin(adminId);
                if (res['success'] == true) {
                  _fetchAdmins();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Admin $adminName deleted successfully'), backgroundColor: const Color(0xFF059669)),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete admin'), backgroundColor: Color(0xFFEF4444)),
                );
              }
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAdmins = _admins.where((a) {
      final name = (a['name'] ?? '').toString().toLowerCase();
      final email = (a['email'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    final activeCount = _admins.where((a) => a['status'] == 'ACTIVE').length;
    final suspendedCount = _admins.where((a) => a['status'] == 'SUSPENDED').length;

    return Scaffold(
      backgroundColor: const Color(0xFF09090C),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0E0E14),
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: Row(
                children: [
                  const LooplynLogo(size: 26),
                  const SizedBox(width: 10),
                  RichText(
                    text: const TextSpan(
                      text: 'Looplyn',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                      children: [
                        TextSpan(text: '▪', style: TextStyle(color: Color(0xFFDC2626), fontSize: 18)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      'SUPER ADMIN',
                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'admin@looplyn.tech',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(LucideIcons.logOut, size: 18, color: Color(0xFFEF4444)),
                    tooltip: 'Sign out',
                    onPressed: _handleLogout,
                  ),
                ],
              ),
            ),

            // Body Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Title Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin Accounts Management',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Create, suspend, update passwords, and control workspace administrator access.',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC0151C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _showCreateAdminDialog,
                              icon: const Icon(LucideIcons.userPlus, size: 16),
                              label: const Text('Add Admin', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Stats Metric Cards
                        Row(
                          children: [
                            _buildStatCard('Total Admins', '${_admins.length}', LucideIcons.users, const Color(0xFF3B82F6)),
                            const SizedBox(width: 16),
                            _buildStatCard('Active Admins', '$activeCount', LucideIcons.userCheck, const Color(0xFF10B981)),
                            const SizedBox(width: 16),
                            _buildStatCard('Suspended', '$suspendedCount', LucideIcons.userX, const Color(0xFFF59E0B)),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Search Box
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111116),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              icon: Icon(LucideIcons.search, size: 16, color: Color(0xFF71717A)),
                              hintText: 'Search admin by name or email...',
                              hintStyle: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Admins List Table Container
                        if (_isLoading) ...[
                          const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFFDC2626)))),
                        ] else if (_errorMessage != null) ...[
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFEF4444))),
                            ),
                          ),
                        ] else if (filteredAdmins.isEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111116),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Column(
                              children: [
                                const Icon(LucideIcons.users, size: 36, color: Color(0xFF4B5563)),
                                const SizedBox(height: 12),
                                const Text('No Admin Accounts Found', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                const Text('Click "Add Admin" above to register your first workspace administrator.', style: TextStyle(color: Color(0xFF71717A), fontSize: 13)),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                                  onPressed: _showCreateAdminDialog,
                                  icon: const Icon(LucideIcons.userPlus, size: 15),
                                  label: const Text('Create Admin'),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF111116),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredAdmins.length,
                              separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                              itemBuilder: (ctx, idx) {
                                final admin = filteredAdmins[idx];
                                final id = admin['id'] ?? '';
                                final name = admin['name'] ?? 'Admin';
                                final email = admin['email'] ?? '';
                                final status = admin['status'] ?? 'ACTIVE';
                                final isActive = status == 'ACTIVE';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  child: Row(
                                    children: [
                                      // Avatar Circle
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.18),
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : 'A',
                                          style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700, fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // Name & Email
                                      Expanded(
                                        flex: 4,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 2),
                                            Text(email, style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                                          ],
                                        ),
                                      ),

                                      // Status Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isActive ? const Color(0x1A10B981) : const Color(0x1AF59E0B),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isActive ? const Color(0x4D10B981) : const Color(0x4DF59E0B),
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: isActive ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 24),

                                      // Actions
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(LucideIcons.keyRound, size: 16, color: Color(0xFF9CA3AF)),
                                            tooltip: 'Change Password',
                                            onPressed: () => _showChangePasswordDialog(id, name),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              isActive ? LucideIcons.pauseCircle : LucideIcons.playCircle,
                                              size: 16,
                                              color: isActive ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                            ),
                                            tooltip: isActive ? 'Suspend Account' : 'Reactivate Account',
                                            onPressed: () => _toggleAdminStatus(id, status, name),
                                          ),
                                          IconButton(
                                            icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFEF4444)),
                                            tooltip: 'Delete Admin',
                                            onPressed: () => _confirmDeleteAdmin(id, name),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111116),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF71717A))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
