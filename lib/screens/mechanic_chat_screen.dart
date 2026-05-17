import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/scan_result.dart';
import '../providers/vehicle_provider.dart';
import '../services/mechanic_chat_service.dart';
import '../theme/app_theme.dart';

class MechanicChatScreen extends StatefulWidget {
  final ScanResult? scan;
  final String?     vehicleInfo;
  final String?     initialMessage;

  const MechanicChatScreen({super.key, this.scan, this.vehicleInfo, this.initialMessage});

  @override
  State<MechanicChatScreen> createState() => _MechanicChatScreenState();
}

class _MechanicChatScreenState extends State<MechanicChatScreen> {
  static const Color _purple = Color(0xFF9C6FFF);
  static const int   _maxStoredMessages = 40;

  static const _quickPrompts = [
    'How do I replace this?',
    'What tools do I need?',
    'Is this safe to DIY?',
    'How much should this cost?',
    'What mistakes should I avoid?',
  ];

  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  String get _storageKey => widget.scan != null
      ? 'mechanic_chat_${widget.scan!.id}'
      : 'mechanic_chat_general';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    if (widget.initialMessage != null) {
      _inputCtrl.text = widget.initialMessage!;
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_storageKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        if (mounted) {
          setState(() {
            _messages = list
                .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
                .toList();
          });
          _scrollToBottom();
        }
      }
    } catch (_) {
      // Corrupt stored data — start fresh
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs   = await SharedPreferences.getInstance();
      final trimmed = _messages.length > _maxStoredMessages
          ? _messages.sublist(_messages.length - _maxStoredMessages)
          : _messages;
      await prefs.setString(
          _storageKey, jsonEncode(trimmed.map((m) => m.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _clearHistory() async {
    setState(() => _messages = []);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  // ── Send ───────────────────────────────────────────────────────────────────

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    _inputCtrl.clear();

    // Snapshot history before adding the new message
    final historySnapshot = List<ChatMessage>.from(_messages);

    final userMsg = ChatMessage.user(trimmed);
    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _scrollToBottom();

    final vp          = context.read<VehicleProvider>();
    final vehicleInfo = widget.vehicleInfo?.isNotEmpty == true
        ? widget.vehicleInfo!
        : widget.scan?.vehicleInfo.isNotEmpty == true
            ? widget.scan!.vehicleInfo
            : vp.vehicle?.displayName ?? '';

    final reply = await MechanicChatService.send(
      message:     trimmed,
      history:     historySnapshot,
      vehicleInfo: vehicleInfo,
      scan:        widget.scan,
    );

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage.assistant(reply));
        _isTyping = false;
      });
      _scrollToBottom();
      await _saveHistory();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildContextBanner(),
          Expanded(
            child: _messages.isEmpty && !_isTyping
                ? _buildEmptyState()
                : _buildMessageList(),
          ),
          _buildQuickChips(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.electricBlue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.4)),
            ),
            child: const Center(
              child: Text('W',
                  style: TextStyle(
                      color: AppTheme.electricBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          const Text('WRENIQ AI'),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: AppTheme.chromeAccent),
          tooltip: 'Clear chat',
          onPressed: _messages.isEmpty ? null : _clearHistory,
        ),
      ],
    );
  }

  // ── Context banner ─────────────────────────────────────────────────────────

  Widget _buildContextBanner() {
    final parts = <String>[];

    final vehicleStr = widget.vehicleInfo?.isNotEmpty == true
        ? widget.vehicleInfo!
        : context.watch<VehicleProvider>().vehicle?.displayName;
    if (vehicleStr != null) parts.add(vehicleStr);
    if (widget.scan != null) parts.add(widget.scan!.partName);

    if (parts.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(bottom: BorderSide(color: Color(0xFF1E1E2E))),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.chromeAccent, size: 13),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              parts.join('  ·  '),
              style: const TextStyle(color: AppTheme.chromeAccent, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.electricBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.electricBlue.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: AppTheme.electricBlue, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'Wreniq AI Mechanic',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask me anything about your vehicle repair.\nTap a suggestion or type your question.',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Message list ───────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    final itemCount = _messages.length + (_isTyping ? 1 : 0);
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: itemCount,
      itemBuilder: (_, i) {
        if (i == _messages.length) return _buildTypingBubble();
        return _buildBubble(_messages[i]);
      },
    );
  }

  // ── Message bubble ─────────────────────────────────────────────────────────

  Widget _buildBubble(ChatMessage msg) {
    final isUser = msg.role == 'user';
    return isUser ? _userBubble(msg) : _assistantBubble(msg.content);
  }

  Widget _userBubble(ChatMessage msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.electricBlue.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(18).copyWith(
              bottomRight: const Radius.circular(4)),
          border:
              Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.35)),
        ),
        child: Text(
          msg.content,
          style: const TextStyle(
              color: AppTheme.textPrimary, fontSize: 14, height: 1.5),
        ),
      ),
    );
  }

  Widget _assistantBubble(String content) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _wAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12, right: 64),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(18).copyWith(
                    bottomLeft: const Radius.circular(4)),
              ),
              child: Text(
                content,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 14, height: 1.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _wAvatar(),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: const Radius.circular(4)),
            ),
            child: const SizedBox(
              width: 36,
              height: 14,
              child: CircularProgressIndicator(
                  color: AppTheme.electricBlue, strokeWidth: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.electricBlue.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.35)),
      ),
      child: const Center(
        child: Text('W',
            style: TextStyle(
                color: AppTheme.electricBlue,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── Quick chips ────────────────────────────────────────────────────────────

  Widget _buildQuickChips() {
    if (_isTyping) return const SizedBox(height: 4);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _quickPrompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ActionChip(
          label: Text(_quickPrompts[i]),
          onPressed: () => _send(_quickPrompts[i]),
          backgroundColor: AppTheme.cardColor,
          side: BorderSide(color: _purple.withValues(alpha: 0.4)),
          labelStyle: const TextStyle(
              color: _purple, fontSize: 12, fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  // ── Input bar ──────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: Color(0xFF1E1E2E))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              enabled: !_isTyping,
              onSubmitted: _send,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ask a repair question…',
                hintStyle: const TextStyle(color: AppTheme.chromeAccent),
                filled: true,
                fillColor: AppTheme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _SendButton(
            onTap: () => _send(_inputCtrl.text),
            enabled: !_isTyping,
          ),
        ],
      ),
    );
  }
}

// ── Send button ───────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool enabled;

  const _SendButton({required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? AppTheme.electricBlue
              : AppTheme.electricBlue.withValues(alpha: 0.3),
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
