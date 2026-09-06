import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:juslegal/core/core.dart';
import '../models/chat_message_model.dart';
import '../providers/ai_provider.dart';

class AILegalChatScreen extends ConsumerStatefulWidget {
  final String userName;
  const AILegalChatScreen({super.key, required this.userName});
  @override
  ConsumerState<AILegalChatScreen> createState() => _AILegalChatScreenState();
}

class _AILegalChatScreenState extends ConsumerState<AILegalChatScreen>
    with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  // Fix 4: screen ownership provides one clear controller lifecycle.
  late final _spinnerController = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 950),
  )..repeat();
  late final _dotsController = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 900),
  )..repeat();

  // Fix 8: covers the provider's debounce interval before isSending is true.
  bool _isSendQueued = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(chatProvider).conversationHistory.isEmpty) {
        ref.read(chatProvider.notifier).addMessage(
          'assistant',
          'Hi ${widget.userName}! I\'m JusLegal, your AI legal assistant. '
              'How can I help you with your consumer issue today?',
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _spinnerController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? value]) async {
    final message = (value ?? _textController.text).trim();
    final chat = ref.read(chatProvider);
    if (message.isEmpty || chat.isSending || _isSendQueued) return;
    setState(() => _isSendQueued = true);
    _textController.clear();
    _scrollToBottom();
    try {
      await ref.read(chatProvider.notifier).sendUserMessageDebounced(message);
    } finally {
      if (mounted) setState(() => _isSendQueued = false);
    }
  }

  Future<void> _retryLastMessage() async {
    for (final message in ref.read(chatProvider).conversationHistory.reversed) {
      if (message.role == 'user') return _sendMessage(message.content);
    }
  }

  void _scrollToBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    final isSendUnavailable = chat.isSending || _isSendQueued;
    ref.listen<ChatState>(chatProvider, (previous, next) {
      if (previous?.conversationHistory.length != next.conversationHistory.length ||
          previous?.isSending != next.isSending) {
        _scrollToBottom();
      }
      // Fix 5: errors are kept in the persistent banner below the composer.
      // ChatNotifier clears state.error after a successful response.
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: AppColors.shadowStrong,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('JusLegal AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('Legal guidance, not legal advice', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          // Fix 7: expose a useful button name to screen readers.
          Semantics(
            button: true,
            label: 'Start a new chat',
            child: IconButton(
              tooltip: 'New chat',
              onPressed: isSendUnavailable ? null : () => ref.read(chatProvider.notifier).clearHistory(),
              icon: const Icon(Icons.add_comment_outlined),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: Column(children: [
            Expanded(child: _messageList(chat.conversationHistory)),
            if (chat.isSending) _TypingIndicator(spinnerAnimation: _spinnerController, dotsAnimation: _dotsController),
            // Fix 2: viewInsets lifts the composer; its scroll view prevents
            // a multi-line composer/banner from being obscured by the keyboard.
            AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
              child: _inputArea(chat, isSendUnavailable),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _messageList(List<ChatMessage> messages) => ListView.builder(
    controller: _scrollController,
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    itemCount: messages.length,
    itemBuilder: (context, index) => AppAnimations.fadeSlideIn(
      _MessageBubble(message: messages[index]),
      duration: const Duration(milliseconds: 280),
      beginOffset: const Offset(0, .04),
    ),
  );

  Widget _inputArea(ChatState chat, bool isSendUnavailable) {
    final showSuggestions = chat.conversationHistory.length <= 1;
    return SingleChildScrollView(
      // Fix 2: anchor the input at the visible bottom during keyboard resize.
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [BoxShadow(color: AppColors.shadowBlack.withValues(alpha: .12), blurRadius: 18, offset: const Offset(0, -4))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (showSuggestions) SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _SuggestionChip('Damaged online order', _sendMessage, enabled: !isSendUnavailable),
              _SuggestionChip('Banking fraud', _sendMessage, enabled: !isSendUnavailable),
              _SuggestionChip('Refund not received', _sendMessage, enabled: !isSendUnavailable),
            ]),
          ),
          if (showSuggestions) const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Semantics(
              textField: true,
              label: 'Legal issue message',
              child: TextField(
                controller: _textController,
                enabled: !isSendUnavailable,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Describe your legal issue...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surfaceBright,
                  border: _inputBorder(AppColors.border),
                  enabledBorder: _inputBorder(AppColors.border),
                  focusedBorder: _inputBorder(AppColors.legalGold, width: 1.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            )),
            const SizedBox(width: 8),
            Material(
              color: AppColors.legalGold,
              shape: const CircleBorder(),
              elevation: 8,
              shadowColor: AppColors.shadowGold,
              child: Semantics(
                // Fix 7: this stays meaningful when only the icon is read.
                button: true,
                label: isSendUnavailable ? 'Send message unavailable' : 'Send message',
                child: IconButton(
                  tooltip: 'Send message',
                  onPressed: isSendUnavailable ? null : _sendMessage,
                  style: IconButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: const Color(0xFF0B0F19)),
                  icon: const Icon(Icons.send_rounded),
                ),
              ),
            ),
          ]),
          if (_isSendQueued) const _QueuedSendIndicator(),
          if (chat.error != null) _ChatErrorBanner(error: chat.error!, onRetry: _retryLastMessage),
        ]),
      ),
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: color, width: width),
  );
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final maxWidth = math.min(MediaQuery.sizeOf(context).width * .80, 560.0);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        // Fix 1: every markdown descendant now receives a finite max width.
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isUser ? AppColors.userBubbleGradient : AppColors.botBubbleGradient,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(24), topRight: const Radius.circular(24),
              bottomLeft: Radius.circular(isUser ? 24 : 8), bottomRight: Radius.circular(isUser ? 8 : 24),
            ),
            border: Border.all(color: isUser ? AppColors.white.withValues(alpha: .35) : AppColors.white.withValues(alpha: .9)),
          ),
          child: isUser
              ? Text(message.content, softWrap: true, overflow: TextOverflow.clip, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.45, fontWeight: FontWeight.w600))
              : MarkdownBody(
                  // Fix 6: API content is untrusted, so HTML is encoded first.
                  data: _escapeHtml(message.content),
                  selectable: true,
                  // flutter_markdown 0.7.x does not expose MarkdownBody.softWrap;
                  // RichText soft-wraps by default. softLineBreak preserves this.
                  softLineBreak: true,
                  onTapLink: (text, href, title) => _openLink(context, href),
                  styleSheet: _markdownStyle(context),
                ),
        ),
      ),
    );
  }

  static String _escapeHtml(String value) => value.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  static Future<void> _openLink(BuildContext context, String? href) async {
    final uri = href == null ? null : Uri.tryParse(href.trim());
    // Fix 3: only absolute HTTP(S) URLs are safe to hand to url_launcher.
    final isSafeWebUri = uri != null && uri.hasAuthority &&
        (uri.scheme.toLowerCase() == 'https' || uri.scheme.toLowerCase() == 'http');
    if (!isSafeWebUri || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open this link.')));
    }
  }

  static MarkdownStyleSheet _markdownStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary, fontSize: 16, height: 1.5);
    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: base,
      h3: base?.copyWith(color: AppColors.legalGold, fontSize: 18, fontWeight: FontWeight.w700, height: 1.3),
      h3Padding: const EdgeInsets.only(top: 12, bottom: 4),
      strong: base?.copyWith(color: AppColors.legalGold, fontWeight: FontWeight.w700),
      a: base?.copyWith(color: AppColors.legalGold, decoration: TextDecoration.underline, decorationColor: AppColors.legalGold, fontWeight: FontWeight.w600),
      listBullet: base?.copyWith(color: AppColors.legalGold, fontSize: 16),
      listIndent: 24, listBulletPadding: const EdgeInsets.only(right: 8),
      code: const TextStyle(color: AppColors.textPrimary, backgroundColor: AppColors.grey100, fontFamily: 'monospace', fontSize: 14),
      codeblockDecoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(4)),
      codeblockPadding: const EdgeInsets.all(4), blockSpacing: 8,
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final Animation<double> spinnerAnimation;
  final Animation<double> dotsAnimation;
  const _TypingIndicator({required this.spinnerAnimation, required this.dotsAnimation});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 18, bottom: 10),
    child: Semantics(
      liveRegion: true, label: 'JusLegal is responding',
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(gradient: AppColors.botBubbleGradient, borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            RotationTransition(turns: spinnerAnimation, child: const Icon(Icons.sync_rounded, color: AppColors.legalGold, size: 18)),
            const SizedBox(width: 8), _AnimatedDots(animation: dotsAnimation), const SizedBox(width: 8),
            const Text('JusLegal is responding...', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ),
  );
}

class _AnimatedDots extends StatelessWidget {
  final Animation<double> animation;
  const _AnimatedDots({required this.animation});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) => SizedBox(
      width: 30, height: 16,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(3, (index) {
        final phase = (animation.value * 3 - index).abs();
        return Opacity(opacity: (1 - phase).clamp(.25, 1.0), child: const CircleAvatar(radius: 3, backgroundColor: AppColors.legalGold));
      })),
    ),
  );
}

class _QueuedSendIndicator extends StatelessWidget {
  const _QueuedSendIndicator();
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: 8),
    child: Semantics(
      liveRegion: true, label: 'Message queued for sending',
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
        SizedBox(width: 8), Text('Message queued…', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ]),
    ),
  );
}

class _ChatErrorBanner extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;
  const _ChatErrorBanner({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
    child: Semantics(
      liveRegion: true, label: 'Send failed: $error',
      child: Row(children: [
        Icon(Icons.error_outline, color: Colors.red.shade700), const SizedBox(width: 8),
        Expanded(child: Text(error, style: TextStyle(color: Colors.red.shade900))),
        // Fix 7: make the recovery control discoverable to screen readers.
        Semantics(button: true, label: 'Retry sending message', child: TextButton(onPressed: onRetry, child: const Text('Retry'))),
      ]),
    ),
  );
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final Future<void> Function([String?]) onTap;
  final bool enabled;
  const _SuggestionChip(this.label, this.onTap, {required this.enabled});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Semantics(
      button: true, enabled: enabled, label: 'Send suggested issue: $label',
      child: AppAnimations.pressScale(
        onTap: enabled ? () => onTap(label) : null,
        borderRadius: BorderRadius.circular(999), splashColor: AppColors.legalGold.withValues(alpha: .18),
        child: Opacity(
          opacity: enabled ? 1 : .55,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)),
            child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    ),
  );
}
