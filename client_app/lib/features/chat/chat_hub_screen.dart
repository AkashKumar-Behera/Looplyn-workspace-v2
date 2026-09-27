import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

class ChatHubScreen extends StatefulWidget {
  const ChatHubScreen({super.key});

  @override
  State<ChatHubScreen> createState() => _ChatHubScreenState();
}

class _ChatHubScreenState extends State<ChatHubScreen> {
  final ApiClient _api = ApiClient();
  List<dynamic> _channels = [];
  List<dynamic> _messages = [];
  dynamic _selectedChannel;
  bool _isLoadingChannels = true;
  bool _isLoadingMessages = false;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    setState(() => _isLoadingChannels = true);
    try {
      final data = await _api.getChannels();
      setState(() {
        _channels = data;
        _isLoadingChannels = false;
        if (_channels.isNotEmpty && _selectedChannel == null) {
          _selectChannel(_channels.first);
        }
      });
    } catch (e) {
      setState(() => _isLoadingChannels = false);
    }
  }

  Future<void> _selectChannel(dynamic channel) async {
    setState(() {
      _selectedChannel = channel;
      _isLoadingMessages = true;
    });
    try {
      final msgs = await _api.getMessages(channel['id']);
      setState(() {
        _messages = msgs;
        _isLoadingMessages = false;
      });
    } catch (e) {
      setState(() => _isLoadingMessages = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _selectedChannel == null) return;

    _messageController.clear();
    try {
      final res = await _api.sendMessage(_selectedChannel['id'], text);
      if (res['success'] == true) {
        setState(() {
          _messages.add(res['message']);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  void _showCreateChannelDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.surfaceLight)),
        title: const Text('Create Channel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Channel Name', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'e.g. video-editors'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();
              await _api.createChannel(name);
              _loadChannels();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Row(
          children: [
            const Icon(LucideIcons.messageSquare, size: 20, color: AppTheme.accent),
            const SizedBox(width: 10),
            const Text('Chat Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, size: 18, color: Colors.white),
            onPressed: _showCreateChannelDialog,
          ),
        ],
      ),
      body: Row(
        children: [
          // Left: Channels List (Slack/Discord Style)
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(right: BorderSide(color: AppTheme.surfaceLight)),
            ),
            child: _isLoadingChannels
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _channels.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('No channels yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceLight, foregroundColor: Colors.white),
                              onPressed: _showCreateChannelDialog,
                              child: const Text('+ Create First Channel', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: _channels.length,
                        itemBuilder: (ctx, idx) {
                          final ch = _channels[idx];
                          final isSelected = _selectedChannel != null && _selectedChannel['id'] == ch['id'];

                          return ListTile(
                            dense: true,
                            selected: isSelected,
                            selectedTileColor: AppTheme.surfaceLight.withOpacity(0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            leading: Icon(
                              ch['type'] == 'CLIENT' ? LucideIcons.briefcase : LucideIcons.hash,
                              size: 16,
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                            ),
                            title: Text(
                              ch['name'] ?? 'general',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14,
                                color: isSelected ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                            onTap: () => _selectChannel(ch),
                          );
                        },
                      ),
          ),

          // Right: Active Channel Messages & Input Feed
          Expanded(
            child: _selectedChannel == null
                ? const Center(child: Text('Select a channel to view messages', style: TextStyle(color: AppTheme.textMuted)))
                : Column(
                    children: [
                      // Channel Header Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: const BoxDecoration(
                          color: AppTheme.surface,
                          border: Border(bottom: BorderSide(color: AppTheme.surfaceLight)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedChannel['type'] == 'CLIENT' ? LucideIcons.briefcase : LucideIcons.hash,
                              size: 18,
                              color: AppTheme.accent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedChannel['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                          ],
                        ),
                      ),

                      // Messages Stream List
                      Expanded(
                        child: _isLoadingMessages
                            ? const Center(child: CircularProgressIndicator(color: Colors.white))
                            : _messages.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(LucideIcons.messageCircle, size: 36, color: AppTheme.textMuted),
                                        const SizedBox(height: 8),
                                        Text('This is the start of #${_selectedChannel['name']}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(20),
                                    itemCount: _messages.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                                    itemBuilder: (ctx, idx) {
                                      final m = _messages[idx];
                                      return Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: AppTheme.surfaceLight,
                                            child: Text(
                                              (m['sender_name'] ?? 'U')[0].toUpperCase(),
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      m['sender_name'] ?? 'Member',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      (m['sender_role'] ?? 'staff').toString().toUpperCase(),
                                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  m['text'] ?? '',
                                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                      ),

                      // Message Input Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppTheme.surface,
                          border: Border(top: BorderSide(color: AppTheme.surfaceLight)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Message #${_selectedChannel['name']}...',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                              icon: const Icon(LucideIcons.send, size: 18),
                              onPressed: _sendMessage,
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
