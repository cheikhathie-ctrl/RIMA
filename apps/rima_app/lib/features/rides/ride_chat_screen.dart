import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/colors.dart';

class RideChatScreen extends StatefulWidget {
  const RideChatScreen({
    super.key,
    required this.rideId,
    required this.otherPartyLabel,
  });

  final String rideId;
  final String otherPartyLabel;

  @override
  State<RideChatScreen> createState() => _RideChatScreenState();
}

class _RideChatScreenState extends State<RideChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;

  bool isLoading = true;
  bool isSending = false;
  String? loadError;
  String preferredLanguage = 'fr';
  List<Map<String, dynamic>> messages = [];

  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;
  bool get isRtlLanguage => preferredLanguage.toLowerCase() == 'ar';

  @override
  void initState() {
    super.initState();
    _loadPreferredLanguage();
    _loadMessages();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _loadMessages(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferredLanguage() async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('preferred_language')
          .eq('id', userId)
          .maybeSingle();
      if (!mounted || data == null) return;
      setState(() {
        preferredLanguage = data['preferred_language']?.toString() ?? 'fr';
      });
    } catch (e) {
      debugPrint('RIMA CHAT LANGUAGE ERROR: $e');
    }
  }

  Future<void> _loadMessages({bool silent = false}) async {
    try {
      final data = await Supabase.instance.client
          .from('ride_messages')
          .select(
            'id, ride_id, sender_user_id, message_text, original_language, '
            'translated_text, translated_language, translation_status, created_at',
          )
          .eq('ride_id', widget.rideId)
          .order('created_at', ascending: true);

      if (!mounted) return;
      final rows = List<Map<String, dynamic>>.from(
        data.map((item) => Map<String, dynamic>.from(item)),
      );
      final changed = rows.length != messages.length ||
          (rows.isNotEmpty && messages.isNotEmpty && rows.last['id'] != messages.last['id']);
      setState(() {
        messages = rows;
        isLoading = false;
        loadError = null;
      });
      if (changed) _scrollToBottom();
      await _markMessagesRead();
    } on PostgrestException catch (e) {
      debugPrint('RIMA CHAT LOAD ERROR: ${e.message}');
      if (!silent && mounted) {
        setState(() {
          isLoading = false;
          loadError = 'Unable to load messages.';
        });
      }
    } catch (e) {
      debugPrint('RIMA CHAT LOAD ERROR: $e');
      if (!silent && mounted) {
        setState(() {
          isLoading = false;
          loadError = 'Unable to load messages.';
        });
      }
    }
  }

  Future<void> _markMessagesRead() async {
    try {
      await Supabase.instance.client.rpc(
        'mark_ride_messages_read',
        params: {
          'p_ride_id': widget.rideId,
        },
      );
    } catch (e) {
      debugPrint(
        'RIMA CHAT MARK READ ERROR: $e',
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || isSending) return;

    setState(() => isSending = true);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'send-ride-message',
        body: {'ride_id': widget.rideId, 'message': text},
      );
      final data = response.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }
      _messageController.clear();
      await _loadMessages();
      if (mounted) _scrollToBottom();
    } on FunctionException catch (e) {
      debugPrint('RIMA CHAT SEND FUNCTION ERROR: ${e.details}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to send message.')),
        );
      }
    } catch (e) {
      debugPrint('RIMA CHAT SEND ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isRtlLanguage ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFDF7),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RIMA Chat',
                style: TextStyle(
                  color: RimaColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                widget.otherPartyLabel,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _translationBanner(),
              Expanded(child: _buildMessages()),
              _messageComposer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _translationBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6ED),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.translate_rounded, color: RimaColors.primary, size: 20),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Messages are automatically translated to your preferred language when needed.',
              style: TextStyle(fontSize: 12.5, color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: RimaColors.primary));
    }
    if (loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 46, color: RimaColors.primary),
              const SizedBox(height: 12),
              Text(loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              ElevatedButton(onPressed: _loadMessages, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 52, color: RimaColors.primary),
              SizedBox(height: 14),
              Text('No messages yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 6),
              Text(
                'Send a message about pickup, landmarks, timing, or the ride.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      reverse: false,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      itemCount: messages.length,
      itemBuilder: (context, index) => _messageBubble(messages[index]),
    );
  }

  Widget _messageBubble(Map<String, dynamic> message) {
    final isMine = message['sender_user_id']?.toString() == currentUserId;
    final originalText = message['message_text']?.toString() ?? '';
    final translatedText = message['translated_text']?.toString();
    final translationStatus = message['translation_status']?.toString() ?? 'not_needed';
    final translatedLanguage = message['translated_language']?.toString();
    final hasTranslation = translatedText != null && translatedText.trim().isNotEmpty && translationStatus == 'translated';
    final visibleText = isMine ? originalText : (hasTranslation ? translatedText : originalText);
    final createdAt = DateTime.tryParse(message['created_at']?.toString() ?? '')?.toLocal();

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
        decoration: BoxDecoration(
          color: isMine ? RimaColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          border: isMine ? null : Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              visibleText,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            if (!isMine && hasTranslation) ...[
              const SizedBox(height: 7),
              InkWell(
                onTap: () => _showOriginalMessage(originalText),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.translate_rounded, size: 15, color: RimaColors.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Translated to ${_languageLabel(translatedLanguage)} • View original',
                        style: const TextStyle(
                          color: RimaColors.primary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!isMine && translationStatus == 'failed') ...[
              const SizedBox(height: 6),
              const Text(
                'Translation unavailable — showing original message.',
                style: TextStyle(color: Colors.black45, fontSize: 10.5),
              ),
            ],
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                createdAt == null ? '' : _formatTime(createdAt),
                style: TextStyle(color: isMine ? Colors.white70 : Colors.black38, fontSize: 10.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOriginalMessage(String originalText) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFFFDF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.translate_rounded, color: RimaColors.primary),
                  SizedBox(width: 9),
                  Text('Original message', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 16),
              SelectableText(originalText, style: const TextStyle(fontSize: 16, height: 1.4)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x11000000))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !isSending,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Message ${widget.otherPartyLabel}',
                filled: true,
                fillColor: const Color(0xFFF6F6F2),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: isSending ? null : _sendMessage,
              style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: EdgeInsets.zero),
              child: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }

  String _languageLabel(String? code) {
    switch ((code ?? '').toLowerCase()) {
      case 'ar': return 'Arabic';
      case 'fr': return 'French';
      case 'en': return 'English';
      case 'ff': return 'Pulaar';
      case 'wo': return 'Wolof';
      case 'snk': return 'Soninke';
      default: return code ?? 'your language';
    }
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
