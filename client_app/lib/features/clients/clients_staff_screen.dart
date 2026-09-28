import 'package:flutter/material.dart';

class ClientsStaffScreen extends StatefulWidget {
  const ClientsStaffScreen({super.key});

  @override
  State<ClientsStaffScreen> createState() => _ClientsStaffScreenState();
}

class _ClientsStaffScreenState extends State<ClientsStaffScreen> {
  int _activeTab = 0; // 0 = Clients, 1 = Staff

  final List<Map<String, dynamic>> _clients = [
    {
      'name': 'Saaj Craft',
      'contact': 'Mamta Khemka',
      'company': 'SAAJ CRAFT',
      'phone': '-',
      'openItems': '0 OPEN ITEMS',
      'initial': 'S',
      'color': const Color(0xFFFACC15),
    },
    {
      'name': 'DESIGN FUDGE STUDIO',
      'contact': 'SUGANDHA MANDHYAN',
      'company': 'DESIGN FUDGE STUDIO',
      'phone': '-',
      'openItems': '11 OPEN ITEMS',
      'initial': 'S',
      'color': const Color(0xFFE5E7EB),
    },
    {
      'name': 'Deepjyoti Motors',
      'contact': 'Sourav Mishra',
      'company': 'DEEPJYOTI MOTORS',
      'phone': '7653857084',
      'openItems': '9 OPEN ITEMS',
      'initial': 'D',
      'color': const Color(0xFF3B82F6),
    },
    {
      'name': 'Palette Stories',
      'contact': 'Sharmin Alam',
      'company': 'PALETTE STORIES',
      'phone': '7873753251',
      'openItems': '13 OPEN ITEMS',
      'initial': 'P',
      'color': const Color(0xFF10B981),
    },
    {
      'name': 'Shree Prashadam',
      'contact': 'Karan Khandelwal',
      'company': 'SHREE PRASHADAM',
      'phone': '7088861799',
      'openItems': '26 OPEN ITEMS',
      'initial': 'S',
      'color': const Color(0xFFEF4444),
    },
  ];

  final List<Map<String, dynamic>> _staff = [
    {
      'name': 'Sugandha Mandhyan',
      'contact': 'Lead Designer & Video Editor',
      'company': 'LOOPLYN CORE',
      'phone': '9876543210',
      'openItems': '14 TASKS',
      'initial': 'S',
      'color': const Color(0xFF8B5CF6),
    },
    {
      'name': 'Akash',
      'contact': 'Workspace Admin',
      'company': 'LOOPLYN CORE',
      'phone': '-',
      'openItems': 'ALL ACCESS',
      'initial': 'A',
      'color': const Color(0xFFDC2626),
    },
  ];

  void _showAddModal() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final companyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111116),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          _activeTab == 0 ? 'Add New Client' : 'Add Staff Member',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: _activeTab == 0 ? 'Client Name' : 'Staff Name',
                  filled: true,
                  fillColor: const Color(0xFF09090C),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Email address',
                  filled: true,
                  fillColor: const Color(0xFF09090C),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Phone Number (Optional)',
                  filled: true,
                  fillColor: const Color(0xFF09090C),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: companyCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Brand / Company Name',
                  filled: true,
                  fillColor: const Color(0xFF09090C),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  final list = _activeTab == 0 ? _clients : _staff;
                  list.add({
                    'name': nameCtrl.text,
                    'contact': emailCtrl.text,
                    'company': companyCtrl.text.isNotEmpty ? companyCtrl.text : 'CLIENT',
                    'phone': phoneCtrl.text.isNotEmpty ? phoneCtrl.text : '-',
                    'openItems': '0 OPEN ITEMS',
                    'initial': nameCtrl.text[0].toUpperCase(),
                    'color': const Color(0xFF3B82F6),
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: Text(_activeTab == 0 ? 'Create Client' : 'Create Staff'),
          ),
        ],
      ),
    );
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
                onPressed: _showAddModal,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  _activeTab == 0 ? '+ Add client' : '+ Add staff',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tabs: Clients (5) | Staff (5)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildTabButton('Clients (${_clients.length})', 0),
              const SizedBox(width: 16),
              _buildTabButton('Staff (${_staff.length})', 1),
            ],
          ),
          const SizedBox(height: 16),

          // Table Container
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
                          'COMPANY',
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
                                  backgroundColor: (item['color'] as Color).withValues(alpha: 0.2),
                                  child: Text(
                                    item['initial'] ?? 'C',
                                    style: TextStyle(
                                      color: item['color'] as Color,
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
                                        item['name'] ?? '',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item['contact'] ?? '',
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
                                          const Text(
                                            'CLIENT PORTAL ACTIVE',
                                            style: TextStyle(
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

                          // Company Pill
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
                                  item['company'] ?? '',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.4),
                                ),
                              ),
                            ),
                          ),

                          // Phone
                          Expanded(
                            flex: 2,
                            child: Text(
                              item['phone'] ?? '-',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                            ),
                          ),

                          // Open Items
                          Expanded(
                            flex: 2,
                            child: Text(
                              item['openItems'] ?? '0 OPEN ITEMS',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.4),
                            ),
                          ),

                          // Trash action
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF71717A)),
                            tooltip: 'Remove',
                            onPressed: () {
                              setState(() => list.removeAt(idx));
                            },
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
