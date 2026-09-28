import 'package:flutter/material.dart';
import '../../core/looplyn_logo.dart';

class EmailTemplatesScreen extends StatefulWidget {
  const EmailTemplatesScreen({super.key});

  @override
  State<EmailTemplatesScreen> createState() => _EmailTemplatesScreenState();
}

class _EmailTemplatesScreenState extends State<EmailTemplatesScreen> {
  int _activeTab = 1; // 0 = Emails, 1 = Templates, 2 = Webhooks
  int _selectedTemplateIdx = 0;

  final List<Map<String, String>> _templates = [
    {
      'title': 'Deadline & Calendar Reminder',
      'subject': 'Reminder: Content Publication Scheduled for {{scheduled_date}}',
      'tag': 'SYS',
    },
    {
      'title': 'Client Welcome & Portal Access',
      'subject': 'Welcome to Looplyn Studio — Your Client Portal Access',
      'tag': 'SYS',
    },
    {
      'title': 'Content Review Notification',
      'subject': 'Action Required: New Content Item Ready for Review',
      'tag': 'SYS',
    },
    {
      'title': 'Password Reset Request',
      'subject': 'Reset Your Looplyn Account Password',
      'tag': 'SYS',
    },
  ];

  @override
  Widget build(BuildContext context) {
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
                  _buildHeaderTab('Emails', 0),
                  const SizedBox(width: 20),
                  _buildHeaderTab('Templates', 1),
                  const SizedBox(width: 20),
                  _buildHeaderTab('Webhooks', 2),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0151C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ Add template', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
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
                    SizedBox(width: 260, child: _buildTemplatesList()),
                    const SizedBox(width: 24),
                    Expanded(child: _buildTemplateEditor()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildTemplatesList(),
                    const SizedBox(height: 20),
                    _buildTemplateEditor(),
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

  Widget _buildTemplatesList() {
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
          itemCount: _templates.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final t = _templates[idx];
            final isSelected = _selectedTemplateIdx == idx;
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
                              t['title'] ?? '',
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
                            child: Text(
                              t['tag'] ?? '',
                              style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t['subject'] ?? '',
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

  Widget _buildTemplateEditor() {
    final t = _templates[_selectedTemplateIdx];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editor Controls Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t['title'] ?? '',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Row(
              children: [
                _buildSmallAction('Preview'),
                const SizedBox(width: 8),
                _buildSmallAction('HTML Code'),
                const SizedBox(width: 8),
                _buildSmallAction('Variables'),
                const SizedBox(width: 8),
                _buildSmallAction('Test send'),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC0151C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () {},
                  child: const Text('Save', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Subject Bar
        Container(
          padding: const EdgeInsets.all(12),
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
                      t['subject'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildVariablePill('{{client_name}}'),
                  _buildVariablePill('{{contact_first_name}}'),
                  _buildVariablePill('{{account_email}}'),
                  _buildVariablePill('{{brand_name}}'),
                  _buildVariablePill('{{issue_date}}'),
                  _buildVariablePill('{{workspace_url}}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Live Interactive Email Preview Card (White Mockup)
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const LooplynLogo(size: 24),
                          const SizedBox(width: 8),
                          RichText(
                            text: const TextSpan(
                              text: 'Looplyn',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
                              children: [
                                TextSpan(text: '▪', style: TextStyle(color: Color(0xFFDC2626))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Calendar Alert',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Content Schedule / {{scheduled_date}}',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hi Deepjyoti Motors — your scheduled content item "{{content_title}}" is set to publish on {{platform}}.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF1F2937), height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Content Title', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                        Text('{{content_title}}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black)),
                        SizedBox(height: 8),
                        Text('Platform & Date', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                        Text('{{platform}}  •  {{scheduled_date}}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {},
                      child: const Text('View Calendar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallAction(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF18181E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
    );
  }

  Widget _buildVariablePill(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F28),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: const TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontFamily: 'monospace', fontWeight: FontWeight.w600),
      ),
    );
  }
}
