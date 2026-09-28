import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';

class FilesStorageScreen extends StatefulWidget {
  const FilesStorageScreen({super.key});

  @override
  State<FilesStorageScreen> createState() => _FilesStorageScreenState();
}

class _FilesStorageScreenState extends State<FilesStorageScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  String _selectedCategory = 'all';
  List<dynamic> _files = [];
  List<dynamic> _clients = [];

  final List<Map<String, String>> _categories = [
    {'key': 'all', 'label': 'All Assets'},
    {'key': 'videos', 'label': 'Videos & Reels'},
    {'key': 'graphics', 'label': 'Carousels & Posts'},
    {'key': 'branding', 'label': 'Brand Guidelines'},
    {'key': 'documents', 'label': 'Briefs & Docs'},
  ];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getFiles(category: _selectedCategory),
        _api.getClients(),
      ]);

      if (mounted) {
        setState(() {
          _files = results[0];
          _clients = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openFileUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $url')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid URL: $url')),
      );
    }
  }

  Future<void> _deleteFile(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14141B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        title: const Text('Move File to Trash?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('This asset link will be moved to trash and retained for 30 days.', style: TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.deleteFile(id);
        _loadFiles();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete asset')));
      }
    }
  }

  void _showAddFileModal() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    String? selectedClient = _clients.isNotEmpty ? _clients[0]['id'] : null;
    String category = 'videos';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF14141B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            title: const Row(
              children: [
                Icon(Icons.drive_folder_upload_rounded, color: Color(0xFFDC2626), size: 22),
                SizedBox(width: 8),
                Text('Add Asset / Drive Link', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Asset Name *', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Diwali Promo Master Cut v2.mp4',
                        hintStyle: const TextStyle(color: Color(0xFF52525B)),
                        filled: true,
                        fillColor: const Color(0xFF0F0F13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Google Drive / Asset URL *', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: urlController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'https://drive.google.com/file/d/...',
                        hintStyle: const TextStyle(color: Color(0xFF52525B)),
                        filled: true,
                        fillColor: const Color(0xFF0F0F13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Client & Category
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Client', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F0F13),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedClient,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF181820),
                                    items: _clients.map<DropdownMenuItem<String>>((cl) {
                                      return DropdownMenuItem<String>(
                                        value: cl['id'],
                                        child: Text(cl['name'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setModalState(() => selectedClient = val),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Category', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F0F13),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: category,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF181820),
                                    items: const [
                                      DropdownMenuItem(value: 'videos', child: Text('Videos & Reels', style: TextStyle(color: Colors.white, fontSize: 13))),
                                      DropdownMenuItem(value: 'graphics', child: Text('Graphics & Carousels', style: TextStyle(color: Colors.white, fontSize: 13))),
                                      DropdownMenuItem(value: 'branding', child: Text('Brand Guidelines', style: TextStyle(color: Colors.white, fontSize: 13))),
                                      DropdownMenuItem(value: 'documents', child: Text('Documents', style: TextStyle(color: Colors.white, fontSize: 13))),
                                    ],
                                    onChanged: (val) => setModalState(() => category = val!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A)))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                onPressed: () async {
                  if (nameController.text.trim().isEmpty || urlController.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    await _api.createFile({
                      'name': nameController.text.trim(),
                      'url': urlController.text.trim(),
                      'client_id': selectedClient,
                      'category': category,
                    });
                    _loadFiles();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add file asset')));
                  }
                },
                child: const Text('Save Asset Link'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Add Asset Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Asset Library & Cloud Files', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('${_files.length} creative assets in studio library', style: const TextStyle(fontSize: 13, color: Color(0xFF71717A))),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_link_rounded, size: 18),
                label: const Text('+ Add Asset Link', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                onPressed: _showAddFileModal,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Categories Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat['label']!),
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
                      if (selected) {
                        setState(() => _selectedCategory = cat['key']!);
                        _loadFiles();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Files Grid
          Expanded(
            child: _files.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_open_outlined, size: 48, color: Color(0xFF52525B)),
                        const SizedBox(height: 12),
                        const Text('No assets in this category yet', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Add Google Drive links or video cuts to share with team & clients', style: TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFDC2626)), foregroundColor: const Color(0xFFDC2626)),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add First Asset'),
                          onPressed: _showAddFileModal,
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : 2);
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.35,
                        ),
                        itemCount: _files.length,
                        itemBuilder: (ctx, idx) {
                          final file = _files[idx];
                          final name = file['name'] ?? 'Untitled File';
                          final client = file['client_name'] ?? 'Agency Master';
                          final url = file['url'] ?? '';
                          final cat = (file['category'] ?? 'documents').toString().toUpperCase();

                          IconData fileIcon = Icons.insert_drive_file_outlined;
                          Color iconColor = const Color(0xFF3B82F6);
                          if (cat.contains('VIDEO')) {
                            fileIcon = Icons.video_file_outlined;
                            iconColor = const Color(0xFFDC2626);
                          } else if (cat.contains('GRAPHIC')) {
                            fileIcon = Icons.image_outlined;
                            iconColor = const Color(0xFF10B981);
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F0F13),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                      child: Icon(fileIcon, size: 20, color: iconColor),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_horiz, size: 16, color: Color(0xFF71717A)),
                                      color: const Color(0xFF1A1A24),
                                      onSelected: (val) {
                                        if (val == 'OPEN') _openFileUrl(url);
                                        if (val == 'DELETE') _deleteFile(file['id']);
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(value: 'OPEN', child: Text('Open Link', style: TextStyle(color: Colors.white, fontSize: 12))),
                                        const PopupMenuItem(value: 'DELETE', child: Text('Move to Trash', style: TextStyle(color: Color(0xFFDC2626), fontSize: 12))),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      client.toString().toUpperCase(),
                                      style: const TextStyle(color: Color(0xFF71717A), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                    ),
                                  ],
                                ),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => _openFileUrl(url),
                                    child: Row(
                                      children: [
                                        const Text('Open file', style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_outward_rounded, size: 12, color: Color(0xFFDC2626)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
