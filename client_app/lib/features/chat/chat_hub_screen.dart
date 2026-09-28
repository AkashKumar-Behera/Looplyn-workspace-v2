import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class ChatHubScreen extends StatefulWidget {
  const ChatHubScreen({super.key});

  @override
  State<ChatHubScreen> createState() => _ChatHubScreenState();
}

class _ChatHubScreenState extends State<ChatHubScreen> {
  final ApiClient _api = ApiClient();
  List<dynamic> _channels = [];
  List<dynamic> _peers = [];
  List<dynamic> _messages = [];
  dynamic _activeTarget; // can be a channel map or peer user map
  bool _isDirectChat = false;
  bool _isLoadingSidebar = true;
  bool _isLoadingMessages = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadSidebarData();
    // Auto-refresh messages every 4 seconds for real-time feel
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_activeTarget != null) {
        _fetchMessagesQuietly();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSidebarData() async {
    setState(() => _isLoadingSidebar = true);
    try {
      final results = await Future.wait([
        _api.getChannels(),
        _api.getChatPeers(),
      ]);

      if (mounted) {
        setState(() {
          _channels = results[0];
          _peers = results[1];
          _isLoadingSidebar = false;
          if (_activeTarget == null && _channels.isNotEmpty) {
            _selectChannel(_channels.first);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSidebar = false);
    }
  }

  Future<void> _selectChannel(dynamic channel) async {
    setState(() {
      _activeTarget = channel;
      _isDirectChat = false;
      _isLoadingMessages = true;
    });
    try {
      final msgs = await _api.getMessages(channel['id']);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoadingMessages = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMessages = false);
    }
  }

  Future<void> _selectPeer(dynamic peer) async {
    setState(() {
      _activeTarget = peer;
      _isDirectChat = true;
      _isLoadingMessages = true;
    });
    try {
      final msgs = await _api.getDirectMessages(peer['id']);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoadingMessages = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMessages = false);
    }
  }

  Future<void> _fetchMessagesQuietly() async {
    if (_activeTarget == null) return;
    try {
      List<dynamic> msgs;
      if (_isDirectChat) {
        msgs = await _api.getDirectMessages(_activeTarget['id']);
      } else {
        msgs = await _api.getMessages(_activeTarget['id']);
      }
      if (mounted && msgs.length != _messages.length) {
        setState(() => _messages = msgs);
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _activeTarget == null) return;

    _messageController.clear();
    try {
      Map<String, dynamic> res;
      if (_isDirectChat) {
        res = await _api.sendDirectMessage(_activeTarget['id'], text);
      } else {
        res = await _api.sendMessage(_activeTarget['id'], text);
      }

      if (res['success'] == true && res['message'] != null) {
        setState(() {
          _messages.add(res['message']);
        });
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send message')));
    }
  }

  void _showCreateChannelDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14141B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        title: const Text('Create Studio Channel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Channel Name', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. reels-production',
                filled: true,
                fillColor: const Color(0xFF0F0F13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                await _api.createChannel(name);
                _loadSidebarData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create channel')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: Channels & Direct Messages Sidebar
        Container(
          width: 280,
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0E),
            border: Border(right: BorderSide(color: Color(0xFF181820))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Messages & Hub', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                      tooltip: 'Create Channel',
                      onPressed: _showCreateChannelDialog,
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF181820), height: 1),

              // Sidebar lists
              Expanded(
                child: _isLoadingSidebar
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)))
                    : ListView(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        children: [
                          // 1. CHANNELS HEADER
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: Text('CHANNELS', style: TextStyle(color: Color(0xFF71717A), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                          ),
                          ..._channels.map((ch) {
                            final isSelected = !_isDirectChat && _activeTarget?['id'] == ch['id'];
                            return ListTile(
                              dense: true,
                              selected: isSelected,
                              selectedTileColor: const Color(0xFF181822),
                              leading: const Text('#', style: TextStyle(color: Color(0xFF71717A), fontWeight: FontWeight.bold, fontSize: 16)),
                              title: Text(
                                ch['name'] ?? '',
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFFEF4444) : Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              onTap: () => _selectChannel(ch),
                            );
                          }),

                          const SizedBox(height: 18),

                          // 2. DIRECT MESSAGES HEADER
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: Text('DIRECT MESSAGES', style: TextStyle(color: Color(0xFF71717A), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                          ),
                          if (_peers.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text('No peers available', style: TextStyle(color: Color(0xFF52525B), fontSize: 12)),
                            )
                          else
                            ..._peers.map((peer) {
                              final isSelected = _isDirectChat && _activeTarget?['id'] == peer['id'];
                              final name = peer['name'] ?? 'User';
                              final role = (peer['role'] ?? 'staff').toString().toUpperCase();

                              return ListTile(
                                dense: true,
                                selected: isSelected,
                                selectedTileColor: const Color(0xFF181822),
                                leading: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: const Color(0xFF1F1F2A),
                                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          color: isSelected ? const Color(0xFFEF4444) : Colors.white,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(color: const Color(0xFF181820), borderRadius: BorderRadius.circular(3)),
                                      child: Text(role, style: const TextStyle(fontSize: 8, color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                onTap: () => _selectPeer(peer),
                              );
                            }),
                        ],
                      ),
              ),
            ],
          ),
        ),

        // Right: Chat Thread Area
        Expanded(
          child: Container(
            color: const Color(0xFF070709),
            child: _activeTarget == null
                ? const Center(
                    child: Text('Select a channel or peer to start messaging', style: TextStyle(color: Color(0xFF71717A))),
                  )
                : Column(
                    children: [
                      // Chat Header Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F0F13),
                          border: Border(bottom: BorderSide(color: Color(0xFF181820))),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isDirectChat ? Icons.person_outline_rounded : Icons.tag_rounded,
                              color: const Color(0xFFDC2626),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isDirectChat ? (_activeTarget['name'] ?? 'Direct Message') : '#${_activeTarget['name']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                ),
                                Text(
                                  _isDirectChat ? (_activeTarget['email'] ?? '') : 'Studio Team Channel',
                                  style: const TextStyle(color: Color(0xFF71717A), fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Messages List
                      Expanded(
                        child: _isLoadingMessages
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)))
                            : _messages.isEmpty
                                ? const Center(
                                    child: Text('No messages yet. Send the first message!', style: TextStyle(color: Color(0xFF52525B), fontSize: 13)),
                                  )
                                : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(20),
                                    itemCount: _messages.length,
                                    itemBuilder: (ctx, idx) {
                                      final msg = _messages[idx];
                                      final sender = msg['sender_name'] ?? 'User';
                                      final text = msg['text'] ?? '';
                                      final time = msg['created_at'] != null
                                          ? DateTime.tryParse(msg['created_at'])?.toLocal()
                                          : null;
                                      final timeStr = time != null ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}' : '';

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 14),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: const Color(0xFF1F1F2A),
                                              child: Text(sender.isNotEmpty ? sender[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(sender, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                                      const SizedBox(width: 8),
                                                      Text(timeStr, style: const TextStyle(color: Color(0xFF52525B), fontSize: 10)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF13131A),
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                                    ),
                                                    child: Text(text, style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 13, height: 1.4)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                      ),

                      // Message Input Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F0F13),
                          border: Border(top: BorderSide(color: Color(0xFF181820))),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: _isDirectChat ? 'Message ${_activeTarget['name']}...' : 'Message #${_activeTarget['name']}...',
                                  hintStyle: const TextStyle(color: Color(0xFF52525B), fontSize: 13),
                                  filled: true,
                                  fillColor: const Color(0xFF181820),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                              ),
                              icon: const Icon(Icons.send_rounded, size: 18),
                              onPressed: _sendMessage,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
