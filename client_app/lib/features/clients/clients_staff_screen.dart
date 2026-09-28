import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class ClientsStaffScreen extends StatefulWidget {
  const ClientsStaffScreen({super.key});

  @override
  State<ClientsStaffScreen> createState() => _ClientsStaffScreenState();
}

class _ClientsStaffScreenState extends State<ClientsStaffScreen> {
  final _api = ApiClient();
  int _activeTab = 0; // 0 = Clients, 1 = Staff
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _clients = [];
  List<dynamic> _staff = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final clientsFuture = _api.getClients();
      final staffFuture = _api.getStaff();
      final results = await Future.wait([clientsFuture, staffFuture]);

      if (mounted) {
        setState(() {
          _clients = results[0];
          _staff = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load clients and staff from database';
          _isLoading = false;
        });
      }
    }
  }

  Color _getDeterministicColor(String name) {
    const colors = [
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFEF4444),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF06B6D4),
    ];
    if (name.isEmpty) return colors[0];
    final hash = name.codeUnits.reduce((a, b) => a + b);
    return colors[hash % colors.length];
  }

  void _showAddClientModal() {
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
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
            title: const Text('Add New Client Brand', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
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
                    const Text('Contact Person Name *', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Mamta Khemka',
                        filled: true,
                        fillColor: const Color(0xFF09090C),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Brand / Company Name', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: companyCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. SAAJ CRAFT',
                        filled: true,
                        fillColor: const Color(0xFF09090C),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Client Portal Email (For Login)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'client@brand.com',
                        filled: true,
                        fillColor: const Color(0xFF09090C),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Phone Number', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: phoneCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. 7873753251',
                        filled: true,
                        fillColor: const Color(0xFF09090C),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Initial Portal Password (Optional)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Min 6 characters',
                        filled: true,
                        fillColor: const Color(0xFF09090C),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0151C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final company = companyCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final pass = passCtrl.text.trim();

                        if (name.isEmpty) {
                          setDialogState(() => dialogError = 'Please enter client name');
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });

                        try {
                          final res = await _api.createClient({
                            'name': name,
                            'company': company.isNotEmpty ? company : name,
                            if (email.isNotEmpty) 'email': email,
                            if (phone.isNotEmpty) 'phone': phone,
                            if (pass.isNotEmpty) 'password': pass,
                          });

                          if (res['success'] == true) {
                            if (!context.mounted) return;
                            Navigator.pop(ctx);
                            _fetchData();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text('Client "$name" created successfully!'), backgroundColor: const Color(0xFF059669)),
                            );
                          } else {
                            setDialogState(() {
                              dialogError = res['error'] ?? 'Failed to create client';
                              isSubmitting = false;
                            });
                          }
                        } catch (err: any) {
                          setDialogState(() {
                            dialogError = 'Error creating client. Check network connection.';
                            isSubmitting = false;
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Client'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddStaffModal() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Lead Designer & Video Editor');
    final phoneCtrl = TextEditingController();
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
            title: const Text('Add Staff Member', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
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
                    const Text('Staff Member Name *', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Sugandha Mandhyan',
                        filled: true,
                        fillColor: const Color(0xFF09090C),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Email Address (For Login) *', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'sugandha@looplyn.tech',
                        filled: true,
                        fillColor: const Color(0xFF09090C),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Role Title', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: roleCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Video Editor / Graphic Designer',
                        filled: true,
                        fillColor: const Color(0xFF09090C),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Phone Number', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: phoneCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Optional',
                        filled: true,
                        fillColor: const Color(0xFF09090C),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Initial Password *', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Min 6 characters',
                        filled: true,
                        fillColor: const Color(0xFF09090C),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0151C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final customRole = roleCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final pass = passCtrl.text.trim();

                        if (name.isEmpty || email.isEmpty || pass.length < 6) {
                          setDialogState(() => dialogError = 'Name, email, and password (min 6 chars) required');
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });

                        try {
                          final res = await _api.createStaff({
                            'name': name,
                            'email': email,
                            'password': pass,
                            'custom_role': customRole.isNotEmpty ? customRole : 'Designer',
                            if (phone.isNotEmpty) 'phone': phone,
                            'role': 'staff',
                          });

                          if (res['success'] == true) {
                            if (!context.mounted) return;
                            Navigator.pop(ctx);
                            _fetchData();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text('Staff member "$name" added!'), backgroundColor: const Color(0xFF059669)),
                            );
                          } else {
                            setDialogState(() {
                              dialogError = res['error'] ?? 'Failed to create staff member';
                              isSubmitting = false;
                            });
                          }
                        } catch (_) {
                          setDialogState(() {
                            dialogError = 'Error creating staff member.';
                            isSubmitting = false;
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Staff'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(String id, String name, bool isClient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111116),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          isClient ? 'Delete Client Brand' : 'Delete Staff Member',
          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to permanently delete "$name"? This action cannot be undone.',
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (isClient) {
        await _api.deleteClient(id);
      } else {
        await _api.deleteStaff(id);
      }
      _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed "$name" successfully'), backgroundColor: const Color(0xFF059669)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete item'), backgroundColor: Color(0xFFDC2626)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _activeTab == 0 ? _clients : _staff;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client & Staff',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage your agency client accounts, staff access, and permissions.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0151C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _activeTab == 0 ? _showAddClientModal : _showAddStaffModal,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  _activeTab == 0 ? '+ Add client' : '+ Add staff',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tabs: Clients (count) | Staff (count)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildTabButton('Clients (${_clients.length})', 0),
              const SizedBox(width: 16),
              _buildTabButton('Staff (${_staff.length})', 1),
            ],
          ),
          const SizedBox(height: 16),

          // Main Table Area
          if (_isLoading) ...[
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFFC0151C)))),
          ] else if (_errorMessage != null) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Text(_errorMessage!, style: const TextStyle(color: Color(0xFFEF4444))),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF181820), foregroundColor: Colors.white),
                      onPressed: _fetchData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (list.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F13),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  Icon(_activeTab == 0 ? Icons.business_center_outlined : Icons.people_outline_rounded, size: 36, color: const Color(0xFF52525B)),
                  const SizedBox(height: 12),
                  Text(
                    _activeTab == 0 ? 'No Client Brands Found' : 'No Staff Members Found',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _activeTab == 0 ? 'Click "+ Add client" to create your first client portal.' : 'Click "+ Add staff" to onboard team designers.',
                    style: const TextStyle(color: Color(0xFF71717A), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC0151C), foregroundColor: Colors.white),
                    onPressed: _activeTab == 0 ? _showAddClientModal : _showAddStaffModal,
                    icon: const Icon(Icons.add, size: 15),
                    label: Text(_activeTab == 0 ? 'Add Client' : 'Add Staff'),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F13),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  // Table Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 4,
                          child: Text(
                            'ACCOUNT',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF71717A), letterSpacing: 0.6),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'COMPANY / ROLE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF71717A), letterSpacing: 0.6),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'PHONE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF71717A), letterSpacing: 0.6),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'OPEN ITEMS',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF71717A), letterSpacing: 0.6),
                          ),
                        ),
                        SizedBox(width: 40),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),

                  // Table Rows
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.04), height: 1),
                    itemBuilder: (context, idx) {
                      final item = list[idx];
                      final id = item['id']?.toString() ?? '';
                      final name = item['name']?.toString() ?? 'Unnamed';
                      final email = item['email']?.toString() ?? '';
                      final phone = item['phone']?.toString() ?? '-';
                      final company = (item['company'] ?? item['custom_role'] ?? 'LOOPLYN CORE').toString();
                      final openItems = '${item['open_items_count'] ?? 0} OPEN ITEMS';
                      final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
                      final avatarColor = _getDeterministicColor(name);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            // Account Avatar + Name + Portal Status
                            Expanded(
                              flex: 4,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: avatarColor.withValues(alpha: 0.18),
                                    child: Text(
                                      initial,
                                      style: TextStyle(
                                        color: avatarColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
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
                                        const SizedBox(height: 2),
                                        Text(
                                          email.isNotEmpty ? email : phone,
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF10B981),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              _activeTab == 0 ? 'CLIENT PORTAL ACTIVE' : 'ACTIVE STAFF MEMBER',
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF10B981),
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Company / Role Pill
                            Expanded(
                              flex: 3,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF18181E),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: Text(
                                    company.toUpperCase(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.4),
                                  ),
                                ),
                              ),
                            ),

                            // Phone
                            Expanded(
                              flex: 2,
                              child: Text(
                                phone,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                              ),
                            ),

                            // Open Items
                            Expanded(
                              flex: 2,
                              child: Text(
                                openItems,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.4),
                              ),
                            ),

                            // Trash action
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF71717A)),
                              tooltip: 'Remove',
                              onPressed: () => _confirmDelete(id, name, _activeTab == 0),
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
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _activeTab == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF71717A),
              ),
            ),
            const SizedBox(height: 4),
            if (isSelected)
              Container(
                width: 24,
                height: 2,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
