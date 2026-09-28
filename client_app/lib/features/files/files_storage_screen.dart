import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

class FilesStorageScreen extends StatefulWidget {
  const FilesStorageScreen({super.key});

  @override
  State<FilesStorageScreen> createState() => _FilesStorageScreenState();
}

class _FilesStorageScreenState extends State<FilesStorageScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  int _activeCategoryIdx = 0; // 0 = ALL ITEMS, 1 = IMAGES, 2 = VIDEOS, 3 = DOCUMENTS
  bool _isGridView = true;
  List<dynamic> _files = [];
  List<dynamic> _clients = [];
  final TextEditingController _searchController = TextEditingController();

  // Sample files matching Screenshot 5 if database empty
  final List<Map<String, dynamic>> _sampleFiles = [
    {
      'id': 'f-1',
      'name': 'Monsoon Waterlogging...',
      'size': '18.9 MB',
      'type': 'VIDEO',
      'is_video': true,
      'thumbnail': 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=500&auto=format&fit=crop&q=60',
      'url': 'https://drive.google.com',
      'client': 'Deep Jyoti Motors',
    },
    {
      'id': 'f-2',
      'name': 'EV VS CNG VS DIESEL R...',
      'size': '32.2 MB',
      'type': 'VIDEO',
      'is_video': true,
      'thumbnail': 'https://images.unsplash.com/photo-1593941707882-a5bba14938c7?w=500&auto=format&fit=crop&q=60',
      'url': 'https://drive.google.com',
      'client': 'Deep Jyoti Motors',
    },
    {
      'id': 'f-3',
      'name': 'ev vs ice final draft reel....',
      'size': '87.7 MB',
      'type': 'VIDEO',
      'is_video': true,
      'thumbnail': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=60',
      'url': 'https://drive.google.com',
      'client': 'Deep Jyoti Motors',
    },
    {
      'id': 'f-4',
      'name': 'Auto Aey ki Daba.drp',
      'size': '511.8 KB',
      'type': 'X-ZIP',
      'is_video': false,
      'url': 'https://drive.google.com',
      'client': 'Deep Jyoti Motors',
    },
    {
      'id': 'f-5',
      'name': 'offers and finance .mp4',
      'size': '92.7 MB',
      'type': 'VIDEO',
      'is_video': true,
      'thumbnail': 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=500&auto=format&fit=crop&q=60',
      'url': 'https://drive.google.com',
      'client': 'Deep Jyoti Motors',
    },
    {
      'id': 'f-6',
      'name': 'our products.mp4',
      'size': '101.7 MB',
      'type': 'VIDEO',
      'is_video': true,
      'thumbnail': 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=500&auto=format&fit=crop&q=60',
      'url': 'https://drive.google.com',
      'client': 'Deep Jyoti Motors',
    },
    {
      'id': 'f-7',
      'name': 'our team.mp4',
      'size': '25 MB',
      'type': 'VIDEO',
      'is_video': true,
      'thumbnail': 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=500&auto=format&fit=crop&q=60',
      'url': 'https://drive.google.com',
      'client': 'Deep Jyoti Motors',
    },
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
        _api.getFiles(),
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
      }
    } catch (_) {}
  }

  Future<void> _deleteFile(String id) async {
    try {
      await _api.deleteFile(id);
      _loadFiles();
    } catch (_) {}
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
          final isDark = ThemeController.instance.isDark;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF14141B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: AppColors.border(isDark))),
            title: const Row(
              children: [
                Icon(Icons.upload_file_rounded, color: Color(0xFFDC2626), size: 22),
                SizedBox(width: 8),
                Text('Upload / Link Asset File', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Asset Name *', style: TextStyle(color: AppColors.textMuted(isDark), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Monsoon Waterlogging Final.mp4',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F0F13) : const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text('Google Drive / Media URL *', style: TextStyle(color: AppColors.textMuted(isDark), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: urlController,
                      style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'https://drive.google.com/file/d/...',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F0F13) : const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                              Text('Client', style: TextStyle(color: AppColors.textMuted(isDark), fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F0F13) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border(isDark)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedClient,
                                    isExpanded: true,
                                    dropdownColor: isDark ? const Color(0xFF181820) : Colors.white,
                                    items: _clients.map<DropdownMenuItem<String>>((cl) {
                                      return DropdownMenuItem<String>(
                                        value: cl['id'],
                                        child: Text(cl['name'], style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 13)),
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
                              Text('Category', style: TextStyle(color: AppColors.textMuted(isDark), fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F0F13) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border(isDark)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: category,
                                    isExpanded: true,
                                    dropdownColor: isDark ? const Color(0xFF181820) : Colors.white,
                                    items: const [
                                      DropdownMenuItem(value: 'videos', child: Text('Videos & Reels', style: TextStyle(fontSize: 13))),
                                      DropdownMenuItem(value: 'images', child: Text('Images & Posts', style: TextStyle(fontSize: 13))),
                                      DropdownMenuItem(value: 'documents', child: Text('Documents & Zip', style: TextStyle(fontSize: 13))),
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(isDark)))),
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
                  } catch (_) {}
                },
                child: const Text('Save Asset'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)));
    }

    // Use DB items if present, else fallback to the exact matching files from screenshot
    final displayFiles = _files.isNotEmpty ? _files : _sampleFiles;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Search & Status Bar
          Row(
            children: [
              // Search Input Box
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F0F13) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border(isDark)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 16, color: AppColors.textMuted(isDark)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search drive files...',
                            hintStyle: TextStyle(color: AppColors.textMuted(isDark), fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Connected Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1713) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 7, color: Color(0xFF10B981)),
                    SizedBox(width: 6),
                    Text('CONNECTED', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Refresh icon
              IconButton(
                icon: Icon(Icons.refresh_rounded, size: 18, color: AppColors.textMuted(isDark)),
                onPressed: _loadFiles,
                tooltip: 'Refresh Drive Sync',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Breadcrumbs & Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Breadcrumbs
              Row(
                children: [
                  Icon(Icons.home_outlined, size: 16, color: AppColors.textMuted(isDark)),
                  const SizedBox(width: 8),
                  Text('Root', style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark), fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Text('›', style: TextStyle(fontSize: 14, color: AppColors.textMuted(isDark))),
                  const SizedBox(width: 8),
                  Text('Deep Jyoti Motors', style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark), fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Text('›', style: TextStyle(fontSize: 14, color: AppColors.textMuted(isDark))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF181820) : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Pritam', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary(isDark))),
                  ),
                ],
              ),

              // Actions: Grid/List switch + Upload File
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F0F13) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border(isDark)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.grid_view_rounded, size: 16, color: _isGridView ? const Color(0xFFDC2626) : AppColors.textMuted(isDark)),
                          onPressed: () => setState(() => _isGridView = true),
                          tooltip: 'Grid View',
                        ),
                        IconButton(
                          icon: Icon(Icons.format_list_bulleted_rounded, size: 16, color: !_isGridView ? const Color(0xFFDC2626) : AppColors.textMuted(isDark)),
                          onPressed: () => setState(() => _isGridView = false),
                          tooltip: 'List View',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                    label: const Row(
                      children: [
                        Text('UPLOAD FILE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                      ],
                    ),
                    onPressed: _showAddFileModal,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3. Category Tabs & Items Count Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildCategoryTab('ALL ITEMS', 0, isDark),
                  const SizedBox(width: 24),
                  _buildCategoryTab('IMAGES', 1, isDark),
                  const SizedBox(width: 24),
                  _buildCategoryTab('VIDEOS', 2, isDark),
                  const SizedBox(width: 24),
                  _buildCategoryTab('DOCUMENTS', 3, isDark),
                ],
              ),
              Text('${displayFiles.length} items', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted(isDark))),
            ],
          ),
          const SizedBox(height: 20),

          // 4. Media Grid matching Screenshot 5
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : 2);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.25,
                ),
                itemCount: displayFiles.length,
                itemBuilder: (ctx, idx) {
                  final file = displayFiles[idx];
                  return _buildFileCard(file, isDark);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String title, int idx, bool isDark) {
    final isSelected = _activeCategoryIdx == idx;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _activeCategoryIdx = idx),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? (isDark ? Colors.white : const Color(0xFF111827)) : AppColors.textMuted(isDark),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            if (isSelected)
              Container(width: 32, height: 2, decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(2)))
            else
              const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(Map<String, dynamic> file, bool isDark) {
    final name = file['name'] ?? 'Untitled Asset';
    final size = file['size'] ?? '18.9 MB';
    final isVideo = file['is_video'] == true || (file['type'] ?? '').toString().toUpperCase().contains('VIDEO');
    final isZip = (file['type'] ?? '').toString().toUpperCase().contains('ZIP') || name.toString().endsWith('.drp');
    final thumb = file['thumbnail'];
    final url = file['url'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F13) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(isDark)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail Preview Area
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF14141B) : const Color(0xFFF3F4F6),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    image: thumb != null
                        ? DecorationImage(image: NetworkImage(thumb), fit: BoxFit.cover)
                        : null,
                  ),
                  child: isZip
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_zip_outlined, size: 38, color: AppColors.textMuted(isDark)),
                              const SizedBox(height: 4),
                              Text('X-ZIP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted(isDark))),
                            ],
                          ),
                        )
                      : null,
                ),
                if (isVideo)
                  Center(
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: const Center(
                        child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                if (isVideo)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('VIDEO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                    ),
                  ),
              ],
            ),
          ),

          // File Info Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(isDark),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        size,
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted(isDark)),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.download_rounded, size: 15, color: AppColors.textMuted(isDark)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Download',
                      onPressed: () => _openFileUrl(url),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.textMuted(isDark)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Move to Trash',
                      onPressed: () => _deleteFile(file['id']),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
