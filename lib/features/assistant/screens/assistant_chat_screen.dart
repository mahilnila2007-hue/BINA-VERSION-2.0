import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/state/triax_app_state.dart';
import '../models/assistant_chat_model.dart';
import '../services/local_ai_model_service.dart';
import '../services/local_qwen_ai_service_impl.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/local_model_status_card.dart';

class AssistantChatScreen extends StatefulWidget {
  const AssistantChatScreen({super.key});

  @override
  State<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends State<AssistantChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final LocalAIModelService _aiService;
  StreamSubscription? _statusSubscription;

  final List<TriaxChatMessage> _messages = [];
  bool _isGenerating = false;
  bool _showModelConfig = false;

  final List<String> _quickPrompts = [
    "What is AI?",
    "Explain machine learning",
    "Write a simple Python program",
    "How does EEG work?",
    "Explain my current signals",
    "Analyze my TRIAX result",
    "Explain my stress pattern",
  ];

  @override
  void initState() {
    super.initState();
    _aiService = LocalQwenAIServiceImpl();
    _statusSubscription = _aiService.statusStream.listen((status) {
      if (mounted) setState(() {});
    });

    // Initial greeting as requested
    _messages.add(
      TriaxChatMessage(
        id: 'msg-welcome',
        sender: MessageSender.assistant,
        text: "Hello! I'm TRIAX AI. I can answer general questions and help you understand your TRIAX physiological analysis.",
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _statusSubscription?.cancel();
    _aiService.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || _isGenerating) return;

    _textController.clear();
    final appState = Provider.of<TriaxAppState>(context, listen: false);
    final payload = TriaxStructuredPayload.fromState(
      data: appState.currentData,
      features: appState.features,
      fusionState: appState.fusionState,
      aiResults: appState.aiResults,
    );

    final userMsg = TriaxChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.user,
      text: prompt,
      timestamp: DateTime.now(),
    );

    final thinkingMsgId = 'msg-think-${DateTime.now().millisecondsSinceEpoch}';
    final thinkingMsg = TriaxChatMessage(
      id: thinkingMsgId,
      sender: MessageSender.assistant,
      text: "",
      timestamp: DateTime.now(),
      isThinking: true,
    );

    setState(() {
      _messages.add(userMsg);
      _messages.add(thinkingMsg);
      _isGenerating = true;
    });
    _scrollToBottom();

    StringBuffer responseAccumulator = StringBuffer();

    try {
      final stream = _aiService.generateResponseStream(
        userPrompt: prompt,
        currentContext: payload,
        conversationHistory: _messages,
      );

      bool isFirstToken = true;

      await for (final token in stream) {
        responseAccumulator.write(token);

        if (mounted) {
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == thinkingMsgId);
            if (idx != -1) {
              _messages[idx] = TriaxChatMessage(
                id: thinkingMsgId,
                sender: MessageSender.assistant,
                text: responseAccumulator.toString(),
                timestamp: DateTime.now(),
                isThinking: false,
              );
            }
          });
          if (isFirstToken) {
            _scrollToBottom();
            isFirstToken = false;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == thinkingMsgId);
          if (idx != -1) {
            _messages[idx] = TriaxChatMessage(
              id: thinkingMsgId,
              sender: MessageSender.assistant,
              text: "Error running local model inference: $e",
              timestamp: DateTime.now(),
              isThinking: false,
            );
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _analyzeCurrentSession() async {
    final appState = Provider.of<TriaxAppState>(context, listen: false);
    final payload = TriaxStructuredPayload.fromState(
      data: appState.currentData,
      features: appState.features,
      fusionState: appState.fusionState,
      aiResults: appState.aiResults,
    );

    final userMsg = TriaxChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.user,
      text: "Analyze Current Session",
      timestamp: DateTime.now(),
    );

    final thinkingMsgId = 'msg-think-${DateTime.now().millisecondsSinceEpoch}';
    final thinkingMsg = TriaxChatMessage(
      id: thinkingMsgId,
      sender: MessageSender.assistant,
      text: "",
      timestamp: DateTime.now(),
      isThinking: true,
    );

    setState(() {
      _messages.add(userMsg);
      _messages.add(thinkingMsg);
      _isGenerating = true;
    });
    _scrollToBottom();

    final summary = await _aiService.generateSessionSummary(payload);

    if (mounted) {
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == thinkingMsgId);
        if (idx != -1) {
          _messages[idx] = TriaxChatMessage(
            id: thinkingMsgId,
            sender: MessageSender.assistant,
            text: summary,
            timestamp: DateTime.now(),
            isThinking: false,
          );
        }
        _isGenerating = false;
      });
      _scrollToBottom();
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(
        TriaxChatMessage(
          id: 'msg-welcome-${DateTime.now().millisecondsSinceEpoch}',
          sender: MessageSender.assistant,
          text: "Chat memory cleared. I have synchronized with your latest live TRIAX physiological parameters. How can I assist?",
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<TriaxAppState>(context);
    final isOnline = _aiService.status == LocalModelStatus.online;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text("TRIAX AI Assistant"),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isOnline 
                    ? AppTheme.statusNormal.withValues(alpha: 0.12)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isOnline ? "AI ONLINE ●" : "AI OFFLINE",
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: isOnline ? AppTheme.statusNormal : const Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showModelConfig ? Icons.info : Icons.info_outline),
            tooltip: "Model Specs & Storage",
            onPressed: () {
              setState(() {
                _showModelConfig = !_showModelConfig;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'clear') _clearChat();
              if (val == 'summary') _analyzeCurrentSession();
              if (val == 'config') setState(() => _showModelConfig = !_showModelConfig);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'summary', child: Text("Analyze Current Session")),
              const PopupMenuItem(value: 'clear', child: Text("Clear Chat")),
              const PopupMenuItem(value: 'config', child: Text("Local Model Specs")),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Collapsible Model Specs Banner
            if (_showModelConfig) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: LocalModelStatusCard(
                  modelService: _aiService,
                  onDownloadOrReload: () {
                    _aiService.downloadModel(onProgress: (p) => setState(() {}));
                  },
                ),
              ),
            ],

            // Context Indicator Pill Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                border: const Border(
                  bottom: BorderSide(color: AppTheme.borderLight, width: 1.0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hub_outlined, size: 14, color: AppTheme.primaryNavy),
                  const SizedBox(width: 6),
                  Text(
                    "TRIAX Vector: ${appState.isDemoMode ? 'Demo Synth' : 'Real Stream'} • HR: ${appState.currentData.heartRate.toStringAsFixed(0)} bpm • Fusion: ${appState.fusionState.fusionIndex.toStringAsFixed(0)}%",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _analyzeCurrentSession,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "Session Summary",
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Chat Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return ChatMessageBubble(message: _messages[index]);
                },
              ),
            ),

            // Quick Prompt Chips
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _quickPrompts.length,
                itemBuilder: (context, idx) {
                  final p = _quickPrompts[idx];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(p),
                      labelStyle: const TextStyle(fontSize: 11.5, color: AppTheme.primaryNavy, fontWeight: FontWeight.w500),
                      backgroundColor: AppTheme.cardBg,
                      side: const BorderSide(color: AppTheme.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onPressed: _isGenerating ? null : () => _sendMessage(p),
                    ),
                  );
                },
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                border: const Border(
                  top: BorderSide(color: AppTheme.borderLight, width: 1.0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: "Ask TRIAX AI about your signals...",
                        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(color: AppTheme.borderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(color: AppTheme.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(color: AppTheme.primaryNavy, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryNavy,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: _isGenerating ? null : () => _sendMessage(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
