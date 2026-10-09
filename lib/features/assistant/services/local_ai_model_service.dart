import 'dart:async';
import '../models/assistant_chat_model.dart';

abstract class LocalAIModelService {
  LocalModelStatus get status;
  Stream<LocalModelStatus> get statusStream;
  bool get isModelAvailable;
  String get modelName;
  String get modelFormat;
  String get modelSizeDisplay;
  String get storageRequirementDisplay;

  Future<void> initializeModel();
  Future<void> downloadModel({void Function(double progress)? onProgress});
  Future<void> loadModel();
  Future<Map<String, String>> runInternalModelSelfTest();
  Stream<String> generateResponseStream({
    required String userPrompt,
    required TriaxStructuredPayload currentContext,
    required List<TriaxChatMessage> conversationHistory,
  });
  Future<String> generateSessionSummary(TriaxStructuredPayload currentContext);
  void clearConversation();
  void dispose();
}
