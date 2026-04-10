class VoiceClip {
  final String id;
  final String diwanId;
  final String speakerId;
  final String title;
  final String storagePath;
  final String? publicUrl;
  final int durationSeconds;
  final DateTime createdAt;

  const VoiceClip({
    required this.id,
    required this.diwanId,
    required this.speakerId,
    required this.title,
    required this.storagePath,
    this.publicUrl,
    this.durationSeconds = 0,
    required this.createdAt,
  });

  Duration get duration => Duration(seconds: durationSeconds);

  factory VoiceClip.fromMap(Map<String, dynamic> map) {
    return VoiceClip(
      id: map['id'] as String,
      diwanId: map['diwan_id'] as String,
      speakerId: map['speaker_id'] as String,
      title: map['title'] as String,
      storagePath: map['storage_path'] as String,
      publicUrl: map['public_url'] as String?,
      durationSeconds: (map['duration_seconds'] as int?) ?? 0,
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
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
