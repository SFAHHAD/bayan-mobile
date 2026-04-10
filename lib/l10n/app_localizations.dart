import 'package:flutter/widgets.dart';

/// Hand-written AppLocalizations.
///
/// Supports two Arabic dialects:
///   - ar    → Classical Arabic  (الفصحى)   — default
///   - ar_KW → Kuwaiti dialect   (اللهجة الكويتية)
///
/// ARB files in lib/l10n/ are the canonical string source.
/// When ready to switch to gen_l10n code generation, run:
///   flutter gen-l10n
/// and replace this file with the generated output.
class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('ar'),
    Locale('ar', 'KW'),
  ];

  bool get _isKuwaiti =>
      locale.countryCode == 'KW' ||
      locale.languageCode == 'ar' && locale.countryCode == 'KW';

  // -------------------------------------------------------------------------
  // Generic
  // -------------------------------------------------------------------------

  String get appName => 'بيان';
  String get loading => _isKuwaiti ? 'يحمّل...' : 'جارٍ التحميل...';
  String get errorGeneric =>
      _isKuwaiti ? 'صار خطأ مو متوقع' : 'حدث خطأ غير متوقع';
  String get errorNetwork =>
      _isKuwaiti ? 'ما قدرنا نتصل بالشبكة' : 'تعذّر الاتصال بالشبكة';
  String get retry => _isKuwaiti ? 'حاول مرة ثانية' : 'إعادة المحاولة';
  String get cancel => 'إلغاء';
  String get confirm => 'تأكيد';
  String get save => 'حفظ';
  String get delete => _isKuwaiti ? 'احذف' : 'حذف';
  String get close => 'إغلاق';
  String get dismiss => 'تجاهل';

  // -------------------------------------------------------------------------
  // Navigation
  // -------------------------------------------------------------------------

  String get home => 'الرئيسية';
  String get discover => 'اكتشف';
  String get notifications => 'الإشعارات';
  String get profile => 'الملف الشخصي';

  // -------------------------------------------------------------------------
  // Search
  // -------------------------------------------------------------------------

  String get search => 'بحث';
  String get searchHint =>
      _isKuwaiti ? 'دوّر على ديوان أو شخص...' : 'ابحث عن ديوان أو مستخدم...';

  // -------------------------------------------------------------------------
  // Diwan
  // -------------------------------------------------------------------------

  String get diwanLive => _isKuwaiti ? 'لايف' : 'مباشر';
  String get diwanPremium => 'مميّز';
  String get joinDiwan => _isKuwaiti ? 'ادخل الديوان' : 'انضمّ للديوان';
  String get leaveDiwan => _isKuwaiti ? 'اطلع من الديوان' : 'مغادرة الديوان';

  String listenersCount(int count) =>
      '$count ${_isKuwaiti ? 'مستمع' : 'مستمع'}';

  // -------------------------------------------------------------------------
  // Social
  // -------------------------------------------------------------------------

  String get follow => _isKuwaiti ? 'تابع' : 'متابعة';
  String get unfollow => _isKuwaiti ? 'ما راح تابع' : 'إلغاء المتابعة';
  String get followers => 'المتابعون';
  String get following => 'المتابَعون';
  String get verified => 'موثّق';

  // -------------------------------------------------------------------------
  // Gifting & Wallet
  // -------------------------------------------------------------------------

  String get gift => 'هدية';
  String get sendGift => _isKuwaiti ? 'أرسل هدية' : 'أرسل هدية';
  String get wallet => 'المحفظة';
  String get balance => 'الرصيد';

  // -------------------------------------------------------------------------
  // Marketplace
  // -------------------------------------------------------------------------

  String get purchaseTicket => _isKuwaiti ? 'اشتري تذكرة' : 'شراء تذكرة';

  String ticketPrice(int price) =>
      _isKuwaiti ? 'سعر التذكرة: $price رمز' : 'سعر التذكرة: $price رمز';

  String get insufficientBalance =>
      _isKuwaiti ? 'ما عندك رصيد يكفي' : 'رصيدك غير كافٍ لإتمام العملية';

  String get purchaseSuccess =>
      _isKuwaiti ? 'تمّ الشراء' : 'تمّت عملية الشراء بنجاح';

  // -------------------------------------------------------------------------
  // Series
  // -------------------------------------------------------------------------

  String get series => 'السلاسل';
  String get subscribeSeries =>
      _isKuwaiti ? 'اشترك بالسلسلة' : 'اشترك في السلسلة';
  String get unsubscribeSeries =>
      _isKuwaiti ? 'ألغِ الاشتراك' : 'إلغاء الاشتراك';

  String episodeNumber(int number) =>
      '${_isKuwaiti ? "الحلقة" : "الحلقة"} $number';

  String newEpisodeNotification(String seriesTitle) =>
      'حلقة جديدة في $seriesTitle';

  // -------------------------------------------------------------------------
  // Activity Log / Privacy
  // -------------------------------------------------------------------------

  String get activityLog => 'سجل النشاط';
  String get clearHistory => _isKuwaiti ? 'احذف السجل' : 'حذف السجل';

  String get clearHistoryConfirm => _isKuwaiti
      ? 'تبي تحذف كل سجل نشاطك؟ ما تقدر ترجع بعدين.'
      : 'هل تريد حذف سجل نشاطك بالكامل؟ لا يمكن التراجع عن هذا الإجراء.';

  String get historyCleared =>
      _isKuwaiti ? 'تم الحذف' : 'تم حذف سجل النشاط بنجاح';

  String get pauseLogging => _isKuwaiti ? 'وقّف التتبع' : 'إيقاف تتبع النشاط';
  String get resumeLogging =>
      _isKuwaiti ? 'شغّل التتبع' : 'استئناف تتبع النشاط';

  // -------------------------------------------------------------------------
  // Verification
  // -------------------------------------------------------------------------

  String get verificationTitle => 'توثيق الحساب';
  String get applyVerification =>
      _isKuwaiti ? 'قدّم طلب التوثيق' : 'تقدّم بطلب التوثيق';
  String get verificationPending =>
      _isKuwaiti ? 'طلبك عند المراجعة' : 'طلبك قيد المراجعة';
  String get verificationApproved =>
      _isKuwaiti ? 'حسابك موثّق الحين' : 'تمّ توثيق حسابك';
  String get verificationRejected => _isKuwaiti ? 'رفضوا طلبك' : 'تمّ رفض طلبك';

  // -------------------------------------------------------------------------
  // Crash Recovery
  // -------------------------------------------------------------------------

  String get crashRecoveryTitle => 'استعادة الجلسة';

  String get crashRecoveryMessage => _isKuwaiti
      ? 'يبيّن إن التطبيق توقف فجأة المرة اللي فاتت. تبي تمسح الذاكرة وترجع جلستك؟'
      : 'يبدو أنّ التطبيق أُغلق بشكل غير متوقع في الجلسة السابقة. هل تريد مسح ذاكرة التخزين المؤقت واستعادة جلستك؟';

  String get clearCacheRestore => _isKuwaiti
      ? 'امسح الذاكرة وارجع الجلسة'
      : 'مسح الذاكرة المؤقتة واستعادة الجلسة';

  // -------------------------------------------------------------------------
  // Remote config / system
  // -------------------------------------------------------------------------

  String get maintenanceMode =>
      _isKuwaiti ? 'التطبيق على صيانة هالحين' : 'التطبيق في وضع الصيانة';

  String get updateRequired => _isKuwaiti
      ? 'لازم تحدّث التطبيق عشان تكمل'
      : 'يرجى تحديث التطبيق للاستمرار';

  // -------------------------------------------------------------------------
  // Language switching
  // -------------------------------------------------------------------------

  String get languageClassical => _isKuwaiti ? 'الفصحى' : 'العربية الفصحى';
  String get languageKuwaiti => _isKuwaiti ? 'الكويتي' : 'اللهجة الكويتية';
  String get changeLanguage => 'تغيير اللغة';
}

// ---------------------------------------------------------------------------
// Delegate
// ---------------------------------------------------------------------------
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ar';

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
