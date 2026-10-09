import 'dart:async';
import 'local_ai_model_service.dart';
import '../models/assistant_chat_model.dart';
import '../../../services/huggingface_ai_service.dart';

class LocalQwenAIServiceImpl implements LocalAIModelService {
  final _statusController = StreamController<LocalModelStatus>.broadcast();
  LocalModelStatus _status = LocalModelStatus.online;
  bool _isAvailable = true;

  static const String qwenGeneralSystemPrompt = """
You are TRIAX AI, a helpful, intelligent, versatile AI assistant powered by Qwen2.5-7B-Instruct.

You can answer general-purpose questions, write code, explain concepts, summarize ideas, and engage in natural conversation just like ChatGPT.
""";

  static const String qwenTriaxSystemPrompt = """
You are TRIAX AI, an AI assistant for a research prototype that analyzes multimodal physiological signals.

You explain physiological signal patterns and the outputs of machine-learning models.

You must never claim to diagnose a disease or medical condition.

Use terms such as:
- physiological pattern
- abnormality indicator
- detected pattern
- elevated value
- reduced value
- requires clinical evaluation

Never say:
- diagnosis confirmed
- you have this disease
- you definitely have a medical condition

When explaining results:
1. Summarize the current sensor values.
2. Explain important feature changes.
3. Explain the TRIAX multimodal relationships.
4. Explain the existing ML model outputs.
5. Give a simple interpretation.
6. Mention when professional clinical evaluation may be appropriate.

Clearly distinguish measured data from AI interpretation.

TRIAX is a research prototype and is not intended for medical diagnosis.
""";

  LocalQwenAIServiceImpl() {
    _statusController.add(_status);
  }

  @override
  LocalModelStatus get status => _status;

  @override
  Stream<LocalModelStatus> get statusStream => _statusController.stream;

  @override
  bool get isModelAvailable => _isAvailable;

  @override
  String get modelName => "Qwen/Qwen2.5-7B-Instruct (Hugging Face Router)";

  @override
  String get modelFormat => "OpenAI-compatible Endpoint / Hugging Face Router";

  @override
  String get modelSizeDisplay => "7B Parameters";

  @override
  String get storageRequirementDisplay => "Cloud Router / Zero Local Storage";

  @override
  Future<void> initializeModel() async {
    _status = LocalModelStatus.online;
    _isAvailable = true;
    _statusController.add(_status);
  }

  @override
  Future<void> downloadModel({void Function(double progress)? onProgress}) async {
    _status = LocalModelStatus.online;
    _isAvailable = true;
    _statusController.add(_status);
  }

  @override
  Future<void> loadModel() async {
    _status = LocalModelStatus.online;
    _statusController.add(_status);
  }

  @override
  Future<Map<String, String>> runInternalModelSelfTest() async {
    final messages = [
      {"role": "system", "content": "You are a helpful AI assistant."},
      {"role": "user", "content": "What is 2 + 2? Answer in one short sentence."},
    ];

    try {
      final res = await HuggingFaceAIService.generateResponse(messages);
      _status = LocalModelStatus.online;
      _statusController.add(_status);
      return {
        'test_prompt': "What is 2 + 2?",
        'test_output': res,
        'status': 'PASSED (Connected to Qwen2.5-7B-Instruct on Hugging Face Router)',
      };
    } catch (e) {
      _status = LocalModelStatus.offline;
      _statusController.add(_status);
      return {
        'test_prompt': "What is 2 + 2?",
        'test_output': e.toString(),
        'status': 'FAILED (Check HF_TOKEN or Internet)',
      };
    }
  }

  @override
  Stream<String> generateResponseStream({
    required String userPrompt,
    required TriaxStructuredPayload currentContext,
    required List<TriaxChatMessage> conversationHistory,
  }) async* {
    final intent = TriaxIntentClassifier.classify(userPrompt);

    // Build message list for Qwen
    final messages = <Map<String, String>>[];

    if (intent == UserIntent.generalChat) {
      // MODE 1: General AI (ChatGPT-style conversation)
      messages.add({
        "role": "system",
        "content": qwenGeneralSystemPrompt,
      });
    } else {
      // MODE 2: TRIAX Physiological Analysis (Injects structured features & ML outputs)
      final contextJson = currentContext.toFormattedJsonString();
      messages.add({
        "role": "system",
        "content": "$qwenTriaxSystemPrompt\n\nCURRENT TRIAX PHYSIOLOGICAL CONTEXT:\n$contextJson\n\nUse the above data when answering the user's physiological questions. Do not invent missing values.",
      });
    }

    // Add conversation history
    for (final chat in conversationHistory.take(12)) {
      if (chat.isThinking) continue;
      if (chat.sender == MessageSender.user) {
        messages.add({"role": "user", "content": chat.text});
      } else if (chat.sender == MessageSender.assistant && chat.text.isNotEmpty) {
        messages.add({"role": "assistant", "content": chat.text});
      }
    }

    // Add current user prompt
    messages.add({"role": "user", "content": userPrompt});

    // Call real Hugging Face Inference Router API
    try {
      final generatedText = await HuggingFaceAIService.generateResponse(messages);
      _status = LocalModelStatus.online;
      _statusController.add(_status);

      // Stream generated tokens for natural visual cadence
      final words = generatedText.split(" ");
      for (int i = 0; i < words.length; i++) {
        yield words[i] + (i == words.length - 1 ? "" : " ");
        await Future.delayed(const Duration(milliseconds: 18));
      }
    } catch (e) {
      _status = LocalModelStatus.offline;
      _statusController.add(_status);
      rethrow;
    }
  }

  @override
  Future<String> generateSessionSummary(TriaxStructuredPayload currentContext) async {
    final messages = [
      {
        "role": "system",
        "content": qwenTriaxSystemPrompt,
      },
      {
        "role": "user",
        "content": """Analyze the following TRIAX session data and generate a concise TRIAX SESSION SUMMARY covering Cardiac, Stress, EEG, Neuromuscular, and Key observation.

TRIAX DATA:
${currentContext.toFormattedJsonString()}""",
      }
    ];

    try {
      final summary = await HuggingFaceAIService.generateResponse(messages);
      _status = LocalModelStatus.online;
      _statusController.add(_status);
      return summary;
    } catch (e) {
      _status = LocalModelStatus.offline;
      _statusController.add(_status);
      rethrow;
    }
  }

  @override
  void clearConversation() {
    // Reset session
  }

  @override
  void dispose() {
    _statusController.close();
  }
}
