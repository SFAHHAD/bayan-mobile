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
import 'package:bayan/core/repositories/schedule_repository.dart';
import 'package:bayan/core/repositories/wallet_repository.dart';
import 'package:bayan/core/repositories/voice_repository.dart';
import 'package:bayan/core/repositories/poll_repository.dart';
import 'package:bayan/core/repositories/question_repository.dart';
import 'package:bayan/core/repositories/referral_repository.dart';
import 'package:bayan/core/repositories/marketplace_repository.dart';
import 'package:bayan/core/repositories/verification_repository.dart';
import 'package:bayan/core/repositories/series_repository.dart';
import 'package:bayan/core/repositories/recommendation_repository.dart';
import 'package:bayan/core/repositories/activity_log_repository.dart';
import 'package:bayan/core/repositories/log_repository.dart';
import 'package:bayan/core/repositories/config_repository.dart';
import 'package:bayan/core/repositories/loyalty_repository.dart';
import 'package:bayan/core/repositories/semantic_search_repository.dart';
import 'package:bayan/core/repositories/subscription_repository.dart';
import 'package:bayan/core/repositories/governance_repository.dart';
import 'package:bayan/core/services/crash_recovery_service.dart';
import 'package:bayan/core/services/payment_service.dart';
import 'package:bayan/core/services/prefetch_service.dart';
import 'package:bayan/core/repositories/transcription_repository.dart';
import 'package:bayan/core/repositories/bug_report_repository.dart';
import 'package:bayan/core/repositories/seo_repository.dart';
import 'package:bayan/core/services/pdf_report_service.dart';
import 'package:bayan/core/services/reputation_service.dart';
import 'package:bayan/core/services/bug_report_service.dart';
import 'package:bayan/core/services/predictive_notification_service.dart';
import 'package:bayan/core/services/rate_limiter_service.dart';
import 'package:bayan/core/services/production_service.dart';
import 'package:bayan/core/repositories/onboarding_repository.dart';
import 'package:bayan/core/repositories/voice_print_repository.dart';
import 'package:bayan/core/services/feed_warmup_service.dart';
import 'package:bayan/core/services/voice_print_service.dart';
import 'package:bayan/core/providers/e2e_provider.dart';

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

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepository(ref.read(supabaseClientProvider)),
);

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.read(supabaseClientProvider)),
);

final pollRepositoryProvider = Provider<PollRepository>(
  (ref) => PollRepository(ref.read(supabaseClientProvider)),
);

final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) => QuestionRepository(ref.read(supabaseClientProvider)),
);

final referralRepositoryProvider = Provider<ReferralRepository>(
  (ref) => ReferralRepository(ref.read(supabaseClientProvider)),
);

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>(
  (ref) => MarketplaceRepository(ref.read(supabaseClientProvider)),
);

final verificationRepositoryProvider = Provider<VerificationRepository>(
  (ref) => VerificationRepository(ref.read(supabaseClientProvider)),
);

final seriesRepositoryProvider = Provider<SeriesRepository>(
  (ref) => SeriesRepository(ref.read(supabaseClientProvider)),
);

final recommendationRepositoryProvider = Provider<RecommendationRepository>(
  (ref) => RecommendationRepository(ref.read(supabaseClientProvider)),
);

final activityLogRepositoryProvider = Provider<ActivityLogRepository>(
  (ref) => ActivityLogRepository(ref.read(supabaseClientProvider)),
);

final logRepositoryProvider = Provider<LogRepository>(
  (ref) => LogRepository(ref.read(supabaseClientProvider)),
);

final configRepositoryProvider = Provider<ConfigRepository>(
  (ref) => ConfigRepository(ref.read(supabaseClientProvider)),
);

final crashRecoveryServiceProvider = Provider<CrashRecoveryService>(
  (ref) => CrashRecoveryService(
    ref.read(logRepositoryProvider),
    ref.read(supabaseClientProvider),
  ),
);

final loyaltyRepositoryProvider = Provider<LoyaltyRepository>(
  (ref) => LoyaltyRepository(ref.read(supabaseClientProvider)),
);

final semanticSearchRepositoryProvider = Provider<SemanticSearchRepository>(
  (ref) => SemanticSearchRepository(ref.read(supabaseClientProvider)),
);

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(ref.read(supabaseClientProvider)),
);

final prefetchServiceProvider = Provider<PrefetchService>(
  (ref) => PrefetchService(ref.read(recommendationRepositoryProvider)),
);

final governanceRepositoryProvider = Provider<GovernanceRepository>(
  (ref) => GovernanceRepository(ref.read(supabaseClientProvider)),
);

final reputationServiceProvider = Provider<ReputationService>(
  (ref) => ReputationService(ref.read(supabaseClientProvider)),
);

final paymentServiceProvider = Provider<PaymentService>(
  (ref) => PaymentService(ref.read(subscriptionRepositoryProvider)),
);

final transcriptionRepositoryProvider = Provider<TranscriptionRepository>(
  (ref) => TranscriptionRepository(ref.read(supabaseClientProvider)),
);

final pdfReportServiceProvider = Provider<PdfReportService>(
  (_) => PdfReportService(),
);

final bugReportRepositoryProvider = Provider<BugReportRepository>(
  (ref) => BugReportRepository(ref.read(supabaseClientProvider)),
);

final seoRepositoryProvider = Provider<SeoRepository>(
  (ref) => SeoRepository(ref.read(supabaseClientProvider)),
);

final bugReportServiceProvider = Provider<BugReportService>(
  (ref) => BugReportService(
    ref.read(bugReportRepositoryProvider),
    ref.read(logRepositoryProvider),
  ),
);

final predictiveNotificationServiceProvider =
    Provider<PredictiveNotificationService>(
      (ref) => PredictiveNotificationService(ref.read(supabaseClientProvider)),
    );

final rateLimiterServiceProvider = Provider<RateLimiterService>(
  (ref) => RateLimiterService(ref.read(supabaseClientProvider)),
);

final productionServiceProvider = Provider<ProductionService>(
  (ref) => ProductionService(ref.read(supabaseClientProvider)),
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.read(supabaseClientProvider)),
);

final voicePrintRepositoryProvider = Provider<VoicePrintRepository>(
  (ref) => VoicePrintRepository(ref.read(supabaseClientProvider)),
);

final feedWarmupServiceProvider = Provider<FeedWarmupService>(
  (ref) => FeedWarmupService(
    ref.read(recommendationRepositoryProvider),
    ref.read(prefetchServiceProvider),
  ),
);

final voicePrintServiceProvider = Provider<VoicePrintService>(
  (ref) => VoicePrintService(
    ref.read(e2eServiceProvider),
    ref.read(voicePrintRepositoryProvider),
  ),
);
