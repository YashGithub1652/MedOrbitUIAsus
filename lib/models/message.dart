class Message {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final bool isEmergency;
  final String urgency;
  final double riskScore;
  final String confidence;

  Message({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.metadata,
    this.isEmergency = false,
    this.urgency = 'low',
    this.riskScore = 0,
    this.confidence = 'medium',
  }) : timestamp = timestamp ?? DateTime.now();

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    role: json['role'] ?? 'assistant',
    content: json['content'] ?? '',
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    metadata: json['metadata'],
    isEmergency: json['is_emergency'] ?? false,
    urgency: json['urgency'] ?? 'low',
    riskScore: (json['risk_score'] ?? 0).toDouble(),
    confidence: json['confidence'] ?? 'medium',
  );
}
