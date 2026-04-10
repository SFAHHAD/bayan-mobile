enum TranscriptionStatus { pending, processing, completed, failed }

class VoiceClip {
  final String id;
  final String diwanId;
  final String speakerId;
  final String title;
  final String storagePath;
  final String? publicUrl;
  final int durationSeconds;
  final String? transcriptText;
  final TranscriptionStatus transcriptionStatus;
  final DateTime createdAt;

  const VoiceClip({
    required this.id,
    required this.diwanId,
    required this.speakerId,
    required this.title,
    required this.storagePath,
    this.publicUrl,
    this.durationSeconds = 0,
    this.transcriptText,
    this.transcriptionStatus = TranscriptionStatus.pending,
    required this.createdAt,
  });

  Duration get duration => Duration(seconds: durationSeconds);

  bool get hasTranscript =>
      transcriptionStatus == TranscriptionStatus.completed &&
      transcriptText != null &&
      transcriptText!.isNotEmpty;

  static TranscriptionStatus _statusFromString(String? s) {
    switch (s) {
      case 'processing':
        return TranscriptionStatus.processing;
      case 'completed':
        return TranscriptionStatus.completed;
      case 'failed':
        return TranscriptionStatus.failed;
      default:
        return TranscriptionStatus.pending;
    }
  }

  static String statusToString(TranscriptionStatus s) {
    switch (s) {
      case TranscriptionStatus.pending:
        return 'pending';
      case TranscriptionStatus.processing:
        return 'processing';
      case TranscriptionStatus.completed:
        return 'completed';
      case TranscriptionStatus.failed:
        return 'failed';
    }
  }

  factory VoiceClip.fromMap(Map<String, dynamic> map) {
    return VoiceClip(
      id: map['id'] as String,
      diwanId: map['diwan_id'] as String,
      speakerId: map['speaker_id'] as String,
      title: map['title'] as String,
      storagePath: map['storage_path'] as String,
      publicUrl: map['public_url'] as String?,
      durationSeconds: (map['duration_seconds'] as int?) ?? 0,
      transcriptText: map['transcript_text'] as String?,
      transcriptionStatus: _statusFromString(
        map['transcription_status'] as String?,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'diwan_id': diwanId,
    'speaker_id': speakerId,
    'title': title,
    'storage_path': storagePath,
    'public_url': publicUrl,
    'duration_seconds': durationSeconds,
  };

  VoiceClip copyWith({
    String? id,
    String? diwanId,
    String? speakerId,
    String? title,
    String? storagePath,
    String? publicUrl,
    int? durationSeconds,
    String? transcriptText,
    TranscriptionStatus? transcriptionStatus,
    DateTime? createdAt,
  }) {
    return VoiceClip(
      id: id ?? this.id,
      diwanId: diwanId ?? this.diwanId,
      speakerId: speakerId ?? this.speakerId,
      title: title ?? this.title,
      storagePath: storagePath ?? this.storagePath,
      publicUrl: publicUrl ?? this.publicUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      transcriptText: transcriptText ?? this.transcriptText,
      transcriptionStatus: transcriptionStatus ?? this.transcriptionStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
