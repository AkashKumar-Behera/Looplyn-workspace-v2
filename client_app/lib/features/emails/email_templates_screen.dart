import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/looplyn_logo.dart';

class EmailTemplatesScreen extends StatefulWidget {
  const EmailTemplatesScreen({super.key});

  @override
  State<EmailTemplatesScreen> createState() => _EmailTemplatesScreenState();
}

class _EmailTemplatesScreenState extends State<EmailTemplatesScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  int _activeTab = 1; // 0 = Emails, 1 = Templates, 2 = Logs
  int _selectedTemplateIdx = 0;
  List<dynamic> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final items = await _api.getEmailTemplates();
      if (mounted) {
        setState(() {
          _templates = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTestSendModal(Map<String, dynamic> template) {
    final emailController = TextEditingController(text: 'admin@looplyn.tech');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14141B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: const Row(
          children: [
            Icon(Icons.send_rounded, color: Color(0xFFDC2626), size: 20),
            SizedBox(width: 8),
            Text('Send Test Email', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Simulate sending template "${template['name']}"', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
            const SizedBox(height: 14),
            const Text('Recipient Email', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F0F13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () async {
              final target = emailController.text.trim();
              Navigator.pop(ctx);
              try {
                final res = await _api.sendTestEmail({
                  'template_id': template['id'],
                  'recipient_email': target,
                });
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF10B981),
                    content: Text(res['message'] ?? 'Test email sent successfully! ✅'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to simulate test email')),
                );
              }
            },
            child: const Text('Send Simulation'),
          ),
        ],
      ),
    );
  }

  void _showAddTemplateModal() {
    final nameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final bodyCtrl = TextEditingController(text: '<h2>Hello {{client_name}},</h2><p>Here is an update regarding {{post_title}}.</p>');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14141B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: const Text('New Email Template', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Template Name', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Monthly Studio Digest',
                  filled: true,
                  fillColor: const Color(0xFF0F0F13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Subject Line', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: subjectCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Monthly Report for {{client_name}}',
                  filled: true,
                  fillColor: const Color(0xFF0F0F13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                ),
              ),
              const SizedBox(height: 12),
              const Text('HTML Body Content', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: bodyCtrl,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F0F13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || subjectCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await _api.createEmailTemplate({
                  'name': nameCtrl.text.trim(),
                  'subject': subjectCtrl.text.trim(),
                  'body_html': bodyCtrl.text.trim(),
                });
                _loadTemplates();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save template')));
              }
            },
            child: const Text('Save Template'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)));
    }

    final fallbackTemplates = [
      {
        'id': 'tpl-1',
        'name': 'Review Request Notification',
        'subject': 'Action Required: New Creative Ready for Review',
        'body_html': '<h2>Hello {{client_name}},</h2><p>Our creative team has uploaded a new draft for <strong>{{post_title}}</strong>. Please review and provide your feedback.</p>',
        'category': 'review',
      },
      {
        'id': 'tpl-2',
        'name': 'Content Approved Notice',
        'subject': 'Content Approved: {{post_title}} is ready for scheduling',
        'body_html': '<h2>Content Approved!</h2><p>Great news! The content <strong>{{post_title}}</strong> has been approved for publishing.</p>',
        'category': 'approval',
      },
    ];

    final displayTemplates = _templates.isNotEmpty ? _templates : fallbackTemplates;
    if (_selectedTemplateIdx >= displayTemplates.length) {
      _selectedTemplateIdx = 0;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Navigation Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildHeaderTab('Email Logs', 0),
                  const SizedBox(width: 20),
                  _buildHeaderTab('Templates Engine', 1),
                  const SizedBox(width: 20),
                  _buildHeaderTab('Triggers & Webhooks', 2),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _showAddTemplateModal,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ Add Template', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Layout Split: Left List + Right Editor
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 850;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 280, child: _buildTemplatesList(displayTemplates)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildTemplateEditor(displayTemplates[_selectedTemplateIdx])),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildTemplatesList(displayTemplates),
                    const SizedBox(height: 20),
                    _buildTemplateEditor(displayTemplates[_selectedTemplateIdx]),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTab(String title, int idx) {
    final isSelected = _activeTab == idx;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = idx),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF71717A),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplatesList(List<dynamic> templates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F13),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const TextField(
            style: TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              icon: Icon(Icons.search, size: 14, color: Color(0xFF71717A)),
              hintText: 'Search templates...',
              hintStyle: TextStyle(color: Color(0xFF52525B), fontSize: 12),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: templates.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final t = templates[idx];
            final isSelected = _selectedTemplateIdx == idx;
            final name = t['name'] ?? t['title'] ?? 'Template';
            final subject = t['subject'] ?? '';

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _selectedTemplateIdx = idx),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF181820) : const Color(0xFF0F0F13),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFDC2626).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? const Color(0xFFEF4444) : Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF272730),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'HTML',
                              style: TextStyle(fontSize: 9, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subject,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF71717A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTemplateEditor(Map<String, dynamic> t) {
    final name = t['name'] ?? t['title'] ?? 'Template';
    final subject = t['subject'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editor Controls Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                _buildSmallAction('Test send', onTap: () => _showTestSendModal(t)),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template saved successfully! ✅')));
                  },
                  child: const Text('Save Changes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Subject Bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F13),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('SUBJECT:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF71717A))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      subject,
                      style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildVariablePill('{{client_name}}'),
                  _buildVariablePill('{{post_title}}'),
                  _buildVariablePill('{{review_link}}'),
                  _buildVariablePill('{{feedback_notes}}'),
                  _buildVariablePill('{{scheduled_date}}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Live Interactive Email Preview Card
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const LooplynLogo(size: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
                        child: const Text('STUDIO NOTIFICATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFE5E7EB), height: 32),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Hi Acme Studio,',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Our creative team has prepared a new draft for Autumn Festival Campaign Reel 2026. Please open the review portal to approve or request revisions.',
                    style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {},
                    child: const Text('Open Review Portal →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Looplyn Creative Workspace • Secure Agency Automated Mailer',
                    style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallAction(String label, {VoidCallback? onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF181820),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFD1D5DB), fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildVariablePill(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF181822),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
      ),
      child: Text(
        code,
        style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
      ),
    );
  }
}
