import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class WorkspaceSettingsScreen extends StatefulWidget {
  const WorkspaceSettingsScreen({super.key});

  @override
  State<WorkspaceSettingsScreen> createState() => _WorkspaceSettingsScreenState();
}

class _WorkspaceSettingsScreenState extends State<WorkspaceSettingsScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  int _activeTab = 0; // 0 = Profile, 1 = Team & Roles, 2 = Security, 3 = Studio Config

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _customRoleController = TextEditingController();
  String _userEmail = '';
  String _userRole = 'admin';

  // Password controllers
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  List<dynamic> _teamMembers = [];

  @override
  void initState() {
    super.initState();
    _loadSettingsData();
  }

  Future<void> _loadSettingsData() async {
    setState(() => _isLoading = true);
    try {
      final profileRes = await _api.getSettingsProfile();
      if (profileRes['success'] == true && profileRes['user'] != null) {
        final u = profileRes['user'];
        _nameController.text = u['name'] ?? '';
        _phoneController.text = u['phone'] ?? '';
        _customRoleController.text = u['custom_role'] ?? '';
        _userEmail = u['email'] ?? '';
        _userRole = u['role'] ?? 'admin';
      }

      final team = await _api.getSettingsTeam();

      if (mounted) {
        setState(() {
          _teamMembers = team;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    try {
      final res = await _api.updateSettingsProfile({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'custom_role': _customRoleController.text.trim(),
      });
      if (res['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Color(0xFF10B981), content: Text('Profile updated successfully! ✅')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
    }
  }

  Future<void> _changePassword() async {
    final curr = _currentPassController.text.trim();
    final newP = _newPassController.text.trim();
    final conf = _confirmPassController.text.trim();

    if (newP.isEmpty || newP.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New password must be at least 6 characters')));
      return;
    }
    if (newP != conf) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match')));
      return;
    }

    try {
      final res = await _api.changeSettingsPassword(curr, newP);
      if (res['success'] == true && mounted) {
        _currentPassController.clear();
        _newPassController.clear();
        _confirmPassController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Color(0xFF10B981), content: Text('Password changed successfully! ✅')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to change password. Check current password.')));
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
          const Text('WORKSPACE CONFIGURATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF71717A), letterSpacing: 0.6)),
          const SizedBox(height: 4),
          const Text('Studio Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
          const SizedBox(height: 20),

          // Tabs Navigation
          Row(
            children: [
              _buildTabButton('My Profile', 0),
              const SizedBox(width: 12),
              _buildTabButton('Team & Access', 1),
              const SizedBox(width: 12),
              _buildTabButton('Security & Auth', 2),
              const SizedBox(width: 12),
              _buildTabButton('Studio Info', 3),
            ],
          ),
          const SizedBox(height: 24),

          // Tab Content
          if (_activeTab == 0) _buildProfileTab(),
          if (_activeTab == 1) _buildTeamTab(),
          if (_activeTab == 2) _buildSecurityTab(),
          if (_activeTab == 3) _buildStudioInfoTab(),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int idx) {
    final isSelected = _activeTab == idx;
    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      selectedColor: const Color(0xFFDC2626),
      backgroundColor: const Color(0xFF0F0F13),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? const Color(0xFFDC2626) : Colors.white.withValues(alpha: 0.08)),
      ),
      onSelected: (selected) {
        if (selected) setState(() => _activeTab = idx);
      },
    );
  }

  Widget _buildProfileTab() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'A',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_nameController.text.isNotEmpty ? _nameController.text : 'Studio Admin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(_userEmail, style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF181820), borderRadius: BorderRadius.circular(4)),
                    child: Text(_userRole.toUpperCase(), style: const TextStyle(color: Color(0xFFDC2626), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Color(0xFF181820), height: 36),

          const Text('Full Name', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF14141B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Phone Number', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _phoneController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: '+91 9876543210',
              filled: true,
              fillColor: const Color(0xFF14141B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Designation / Studio Role', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _customRoleController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. Creative Director & Studio Lead',
              filled: true,
              fillColor: const Color(0xFF14141B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _updateProfile,
            child: const Text('Save Profile Changes', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamTab() {
    return Container(
      padding: const EdgeInsets.all(24),
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
                  Text('STUDIO TEAM MEMBERS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.4)),
                  SizedBox(height: 3),
                  Text('Active team members with studio dashboard and pipeline access.', style: TextStyle(fontSize: 12, color: Color(0xFF71717A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF181820), borderRadius: BorderRadius.circular(6)),
                child: Text('${_teamMembers.length} Members', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _teamMembers.length,
            separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.04), height: 20),
            itemBuilder: (ctx, idx) {
              final m = _teamMembers[idx];
              final name = m['name'] ?? 'Team Member';
              final email = m['email'] ?? '';
              final role = (m['role'] ?? 'staff').toString().toUpperCase();

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1F1F2A),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(email, style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: role == 'ADMIN' ? const Color(0x22DC2626) : const Color(0xFF181820),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: role == 'ADMIN' ? const Color(0x55DC2626) : Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Text(role, style: TextStyle(color: role == 'ADMIN' ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Change Account Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          const Text('Enter your current password and a new secure password.', style: TextStyle(color: Color(0xFF71717A), fontSize: 12)),
          const SizedBox(height: 20),

          const Text('Current Password', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _currentPassController,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF14141B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
          ),
          const SizedBox(height: 14),

          const Text('New Password', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _newPassController,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Minimum 6 characters',
              filled: true,
              fillColor: const Color(0xFF14141B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
          ),
          const SizedBox(height: 14),

          const Text('Confirm New Password', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _confirmPassController,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF14141B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _changePassword,
            child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStudioInfoTab() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Studio Brand & Region', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildInfoRow('Studio Platform', 'Looplyn V2 Enterprise Dark Noir'),
          _buildInfoRow('Primary Timezone', 'Asia/Kolkata (IST +05:30)'),
          _buildInfoRow('Default Currency', 'INR (₹)'),
          _buildInfoRow('API Gateway', 'https://core.looplyn.tech/api/v1'),
          _buildInfoRow('Client Portal Domain', 'https://work.looplyn.tech'),
          _buildInfoRow('Security Architecture', 'Stateless JWT + PostgreSQL RLS'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
