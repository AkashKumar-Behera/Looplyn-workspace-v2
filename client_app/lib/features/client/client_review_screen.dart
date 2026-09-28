import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

class ClientReviewScreen extends StatefulWidget {
  final Map<String, dynamic>? contentItem;
  const ClientReviewScreen({super.key, this.contentItem});

  @override
  State<ClientReviewScreen> createState() => _ClientReviewScreenState();
}

class _ClientReviewScreenState extends State<ClientReviewScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoadingComments = true;
  bool _isActionLoading = false;
  late String _currentStatus;
  late Map<String, dynamic> _item;

  @override
  void initState() {
    super.initState();
    _item = widget.contentItem ?? {
      'id': 'sample-1',
      'title': 'Diwali Campaign Reel Draft',
      'description': 'Festive promo highlighting premium offer hooks and brand identity.',
      'platform': 'INSTAGRAM',
      'format': 'REEL',
      'status': 'IN_REVIEW',
    };
    _currentStatus = _item['status'] ?? 'IN_REVIEW';
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final data = await _api.getComments(_item['id']);
      if (mounted) {
        setState(() {
          _comments = data;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _handleApprove() async {
    setState(() => _isActionLoading = true);
    try {
      final res = await _api.approveContent(_item['id']);
      if (res['success'] == true) {
        setState(() => _currentStatus = 'APPROVED');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.success,
            content: Text('Content has been successfully approved! ✅'),
          ),
        );
        _loadComments();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve content')),
      );
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _showRequestChangesDialog() {
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.surfaceLight)),
        title: const Text('Request Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What changes would you like the agency team to make?', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Please change the headline font and background music...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
            onPressed: () async {
              final text = feedbackController.text.trim();
              if (text.isEmpty) return;
              Navigator.of(ctx).pop();
              setState(() => _isActionLoading = true);
              try {
                await _api.requestChanges(_item['id'], text);
                setState(() => _currentStatus = 'IN_PROGRESS');
                _loadComments();
              } finally {
                if (mounted) setState(() => _isActionLoading = false);
              }
            },
            child: const Text('Submit Feedback'),
          ),
        ],
      ),
    );
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();
    try {
      await _api.addComment(_item['id'], text);
      _loadComments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post comment')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = _currentStatus == 'APPROVED';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _item['title'] ?? 'Review Content',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isApproved ? AppTheme.success.withValues(alpha: 0.15) : AppTheme.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isApproved ? AppTheme.success.withValues(alpha: 0.4) : AppTheme.warning.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                _currentStatus,
                style: TextStyle(
                  color: isApproved ? AppTheme.success : AppTheme.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left: Media Preview & Post Details
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reel / Video Preview Placeholder (9:16 aspect box)
                  Center(
                    child: Container(
                      width: 320,
                      height: 500,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.surfaceLight),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.playCircle, size: 54, color: AppTheme.accent),
                          const SizedBox(height: 12),
                          Text(
                            _item['platform'] ?? 'INSTAGRAM REEL',
                            style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Click to preview high-res media',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Post Description & Caption
                  const Text('Draft Caption', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.surfaceLight),
                    ),
                    child: Text(
                      _item['description'] ?? 'No caption added yet.',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right: Real-time Comments Thread & 1-Tap Action Bar
          Container(
            width: 380,
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(left: BorderSide(color: AppTheme.surfaceLight)),
            ),
            child: Column(
              children: [
                // 1-Tap Actions Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.surfaceLight)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Review Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.black,
                              ),
                              icon: const Icon(LucideIcons.check, size: 16),
                              label: const Text('Approve'),
                              onPressed: _isActionLoading || isApproved ? null : _handleApprove,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.accent),
                                foregroundColor: AppTheme.accent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(LucideIcons.messageSquare, size: 16),
                              label: const Text('Changes'),
                              onPressed: _isActionLoading ? null : _showRequestChangesDialog,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Comments List
                Expanded(
                  child: _isLoadingComments
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _comments.isEmpty
                          ? const Center(child: Text('No comments yet. Start the feedback!', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _comments.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, idx) {
                                final c = _comments[idx];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.surfaceLight),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            c['author_name'] ?? 'Team Member',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: AppTheme.surfaceLight,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              (c['author_role'] ?? 'staff').toString().toUpperCase(),
                                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        c['comment'] ?? '',
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),

                // Comment Input Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    border: Border(top: BorderSide(color: AppTheme.surfaceLight)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Add feedback or remark...',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onSubmitted: (_) => _postComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
                        icon: const Icon(LucideIcons.send, size: 16),
                        onPressed: _postComment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
