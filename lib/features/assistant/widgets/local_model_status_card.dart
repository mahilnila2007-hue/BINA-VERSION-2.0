import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/assistant_chat_model.dart';
import '../services/local_ai_model_service.dart';

class LocalModelStatusCard extends StatelessWidget {
  final LocalAIModelService modelService;
  final VoidCallback onDownloadOrReload;

  const LocalModelStatusCard({
    super.key,
    required this.modelService,
    required this.onDownloadOrReload,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = modelService.status == LocalModelStatus.online;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOnline ? const Color(0xFFBFDBFE) : AppTheme.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isOnline
                      ? AppTheme.statusNormal.withValues(alpha: 0.12)
                      : AppTheme.statusWarning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isOnline ? Icons.psychology_rounded : Icons.cloud_off_rounded,
                  color: isOnline ? AppTheme.statusNormal : AppTheme.statusWarning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Qwen2.5-7B-Instruct (HF Router)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      modelService.modelName,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnline
                      ? AppTheme.statusNormal.withValues(alpha: 0.1)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isOnline ? AppTheme.statusNormal : const Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOnline ? "AI ONLINE ●" : "AI OFFLINE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isOnline ? AppTheme.statusNormal : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSpecItem("Model", "Qwen2.5-7B-Instruct"),
              _buildSpecItem("Provider", "Hugging Face Router"),
              _buildSpecItem("Endpoint", "OpenAI-Compatible"),
              _buildSpecItem("Status", isOnline ? "Active" : "Check Token"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textDark),
        ),
      ],
    );
  }
}
