import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bayan/core/services/database_service.dart';
import 'package:bayan/core/repositories/diwan_repository.dart';
import 'package:bayan/core/repositories/message_repository.dart';
import 'package:bayan/core/repositories/participant_repository.dart';
import 'package:bayan/core/repositories/profile_repository.dart';
import 'package:bayan/core/repositories/moderation_repository.dart';
import 'package:bayan/core/repositories/search_repository.dart';
import 'package:bayan/core/repositories/social_repository.dart';
import 'package:bayan/core/repositories/tag_repository.dart';
import 'package:bayan/core/repositories/analytics_repository.dart';
import 'package:bayan/core/repositories/voice_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => DatabaseService(client: ref.read(supabaseClientProvider)),
);

final diwanRepositoryProvider = Provider<DiwanRepository>(
  (ref) => DiwanRepository(ref.read(supabaseClientProvider)),
);

final messageRepositoryProvider = Provider<MessageRepository>(
  (ref) => MessageRepository(ref.read(supabaseClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.read(supabaseClientProvider)),
);

final participantRepositoryProvider = Provider<ParticipantRepository>(
  (ref) => ParticipantRepository(ref.read(supabaseClientProvider)),
);

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SocialRepository(ref.read(supabaseClientProvider)),
);

final voiceRepositoryProvider = Provider<VoiceRepository>(
  (ref) => VoiceRepository(ref.read(supabaseClientProvider)),
);

final tagRepositoryProvider = Provider<TagRepository>(
  (ref) => TagRepository(ref.read(supabaseClientProvider)),
);

final moderationRepositoryProvider = Provider<ModerationRepository>(
  (ref) => ModerationRepository(ref.read(supabaseClientProvider)),
);

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.read(supabaseClientProvider)),
);

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepository(ref.read(supabaseClientProvider)),
);
