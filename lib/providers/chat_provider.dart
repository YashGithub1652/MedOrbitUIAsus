import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/api_service.dart';

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final bool isStreaming;
  final String? conversationId;
  final String mode;
  final String streamingText;
  final bool isEmergency;
  final Map<String, dynamic>? emergencyData;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.conversationId,
    this.mode = 'general',
    this.streamingText = '',
    this.isEmergency = false,
    this.emergencyData,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? conversationId,
    String? mode,
    String? streamingText,
    bool? isEmergency,
    Map<String, dynamic>? emergencyData,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      conversationId: conversationId ?? this.conversationId,
      mode: mode ?? this.mode,
      streamingText: streamingText ?? this.streamingText,
      isEmergency: isEmergency ?? this.isEmergency,
      emergencyData: emergencyData ?? this.emergencyData,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(ChatState());

  final _api = ApiService();

  void setMode(String mode) {
    state = state.copyWith(mode: mode);
  }

  void clearChat() {
    state = ChatState(mode: state.mode);
  }

  Future<void> sendMessage(String text) async {
    final userMsg = Message(role: 'user', content: text);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      isEmergency: false,
    );

    try {
      state = state.copyWith(isStreaming: true, streamingText: '');
      String fullResponse = '';

      await for (final token in _api.streamQuery(
        text,
        conversationId: state.conversationId,
        mode: state.mode,
      )) {
        fullResponse += token;
        state = state.copyWith(streamingText: fullResponse);
      }

      final assistantMsg = Message(
        role: 'assistant',
        content: fullResponse.isEmpty ? 'No response received.' : fullResponse,
        isEmergency: state.isEmergency,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isLoading: false,
        isStreaming: false,
        streamingText: '',
      );
    } catch (e) {
      // Fallback to non-streaming
      try {
        final response = await _api.sendQuery(
          text,
          conversationId: state.conversationId,
          mode: state.mode,
        );

        final assistantMsg = Message(
          role: 'assistant',
          content: response['response'] ??
              'Sorry, I could not process your request.',
          isEmergency: response['is_emergency'] ?? false,
          urgency: response['urgency'] ?? 'low',
          riskScore: (response['risk_score'] ?? 0).toDouble(),
          confidence: response['confidence'] ?? 'medium',
        );

        state = state.copyWith(
          messages: [...state.messages, assistantMsg],
          isLoading: false,
          isStreaming: false,
          conversationId: response['conversation_id'],
          isEmergency: response['is_emergency'] ?? false,
        );
      } catch (e2) {
        final errorMsg = Message(
          role: 'assistant',
          content:
              '⚠️ Could not reach Ollama. Please ensure Ollama is running:\n1. Run: ollama serve\n2. Run: ollama pull qwen2.5:7b',
        );
        state = state.copyWith(
          messages: [...state.messages, errorMsg],
          isLoading: false,
          isStreaming: false,
        );
      }
    }
  }
}
