import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.g.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizationsG
/// returned by `AppLocalizationsG.of(context)`.
///
/// Applications need to include `AppLocalizationsG.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.g.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizationsG.localizationsDelegates,
///   supportedLocales: AppLocalizationsG.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizationsG.supportedLocales
/// property.
abstract class AppLocalizationsG {
  AppLocalizationsG(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizationsG of(BuildContext context) {
    return Localizations.of<AppLocalizationsG>(context, AppLocalizationsG)!;
  }

  static const LocalizationsDelegate<AppLocalizationsG> delegate =
      _AppLocalizationsGDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('ar', 'KW'),
  ];

  /// Application name
  ///
  /// In ar, this message translates to:
  /// **'بيان'**
  String get appName;

  /// Generic loading indicator text
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل...'**
  String get loading;

  /// Generic error message
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع'**
  String get error_generic;

  /// Network error message
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال بالشبكة'**
  String get error_network;

  /// Retry button label
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// Cancel button label
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// Confirm button label
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// Save button label
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// Delete button label
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// Close button label
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// Search label
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// Search input hint
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن ديوان أو مستخدم...'**
  String get search_hint;

  /// Home tab label
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// Discover tab label
  ///
  /// In ar, this message translates to:
  /// **'اكتشف'**
  String get discover;

  /// Notifications tab label
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications;

  /// Profile tab label
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profile;

  /// Live diwan badge
  ///
  /// In ar, this message translates to:
  /// **'مباشر'**
  String get diwan_live;

  /// Premium diwan badge
  ///
  /// In ar, this message translates to:
  /// **'مميّز'**
  String get diwan_premium;

  /// Join diwan button
  ///
  /// In ar, this message translates to:
  /// **'انضمّ للديوان'**
  String get join_diwan;

  /// Leave diwan button
  ///
  /// In ar, this message translates to:
  /// **'مغادرة الديوان'**
  String get leave_diwan;

  /// Listener count label
  ///
  /// In ar, this message translates to:
  /// **'{count} مستمع'**
  String listeners_count(int count);

  /// Follow button
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get follow;

  /// Unfollow button
  ///
  /// In ar, this message translates to:
  /// **'إلغاء المتابعة'**
  String get unfollow;

  /// Followers label
  ///
  /// In ar, this message translates to:
  /// **'المتابعون'**
  String get followers;

  /// Following label
  ///
  /// In ar, this message translates to:
  /// **'المتابَعون'**
  String get following;

  /// Verified badge label
  ///
  /// In ar, this message translates to:
  /// **'موثّق'**
  String get verified;

  /// Gift label
  ///
  /// In ar, this message translates to:
  /// **'هدية'**
  String get gift;

  /// Send gift button
  ///
  /// In ar, this message translates to:
  /// **'أرسل هدية'**
  String get send_gift;

  /// Wallet label
  ///
  /// In ar, this message translates to:
  /// **'المحفظة'**
  String get wallet;

  /// Balance label
  ///
  /// In ar, this message translates to:
  /// **'الرصيد'**
  String get balance;

  /// Purchase ticket button
  ///
  /// In ar, this message translates to:
  /// **'شراء تذكرة'**
  String get purchase_ticket;

  /// Ticket price with token count
  ///
  /// In ar, this message translates to:
  /// **'سعر التذكرة: {price} رمز'**
  String ticket_price(int price);

  /// Insufficient balance error
  ///
  /// In ar, this message translates to:
  /// **'رصيدك غير كافٍ لإتمام العملية'**
  String get insufficient_balance;

  /// Purchase success message
  ///
  /// In ar, this message translates to:
  /// **'تمّت عملية الشراء بنجاح'**
  String get purchase_success;

  /// Series label
  ///
  /// In ar, this message translates to:
  /// **'السلاسل'**
  String get series;

  /// Subscribe to series button
  ///
  /// In ar, this message translates to:
  /// **'اشترك في السلسلة'**
  String get subscribe_series;

  /// Unsubscribe from series
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الاشتراك'**
  String get unsubscribe_series;

  /// Episode number label
  ///
  /// In ar, this message translates to:
  /// **'الحلقة {number}'**
  String episode_number(int number);

  /// New episode notification title
  ///
  /// In ar, this message translates to:
  /// **'حلقة جديدة في {seriesTitle}'**
  String new_episode_notification(String seriesTitle);

  /// Activity log label
  ///
  /// In ar, this message translates to:
  /// **'سجل النشاط'**
  String get activity_log;

  /// Clear activity history button
  ///
  /// In ar, this message translates to:
  /// **'حذف السجل'**
  String get clear_history;

  /// Clear history confirmation message
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف سجل نشاطك بالكامل؟ لا يمكن التراجع عن هذا الإجراء.'**
  String get clear_history_confirm;

  /// History cleared success message
  ///
  /// In ar, this message translates to:
  /// **'تم حذف سجل النشاط بنجاح'**
  String get history_cleared;

  /// Pause activity logging label
  ///
  /// In ar, this message translates to:
  /// **'إيقاف تتبع النشاط'**
  String get pause_logging;

  /// Resume activity logging label
  ///
  /// In ar, this message translates to:
  /// **'استئناف تتبع النشاط'**
  String get resume_logging;

  /// Verification screen title
  ///
  /// In ar, this message translates to:
  /// **'توثيق الحساب'**
  String get verification_title;

  /// Apply for verification button
  ///
  /// In ar, this message translates to:
  /// **'تقدّم بطلب التوثيق'**
  String get apply_verification;

  /// Verification pending status
  ///
  /// In ar, this message translates to:
  /// **'طلبك قيد المراجعة'**
  String get verification_pending;

  /// Verification approved status
  ///
  /// In ar, this message translates to:
  /// **'تمّ توثيق حسابك'**
  String get verification_approved;

  /// Verification rejected status
  ///
  /// In ar, this message translates to:
  /// **'تمّ رفض طلبك'**
  String get verification_rejected;

  /// Crash recovery dialog title
  ///
  /// In ar, this message translates to:
  /// **'استعادة الجلسة'**
  String get crash_recovery_title;

  /// Crash recovery dialog message
  ///
  /// In ar, this message translates to:
  /// **'يبدو أنّ التطبيق أُغلق بشكل غير متوقع في الجلسة السابقة. هل تريد مسح ذاكرة التخزين المؤقت واستعادة جلستك؟'**
  String get crash_recovery_message;

  /// Clear cache & restore session button
  ///
  /// In ar, this message translates to:
  /// **'مسح الذاكرة المؤقتة واستعادة الجلسة'**
  String get clear_cache_restore;

  /// Dismiss button
  ///
  /// In ar, this message translates to:
  /// **'تجاهل'**
  String get dismiss;

  /// Maintenance mode banner
  ///
  /// In ar, this message translates to:
  /// **'التطبيق في وضع الصيانة'**
  String get maintenance_mode;

  /// Force update message
  ///
  /// In ar, this message translates to:
  /// **'يرجى تحديث التطبيق للاستمرار'**
  String get update_required;

  /// Classical Arabic dialect name
  ///
  /// In ar, this message translates to:
  /// **'العربية الفصحى'**
  String get language_classical;

  /// Kuwaiti dialect name
  ///
  /// In ar, this message translates to:
  /// **'اللهجة الكويتية'**
  String get language_kuwaiti;

  /// Change language button
  ///
  /// In ar, this message translates to:
  /// **'تغيير اللغة'**
  String get change_language;
}

class _AppLocalizationsGDelegate
    extends LocalizationsDelegate<AppLocalizationsG> {
  const _AppLocalizationsGDelegate();

  @override
  Future<AppLocalizationsG> load(Locale locale) {
    return SynchronousFuture<AppLocalizationsG>(
      lookupAppLocalizationsG(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsGDelegate old) => false;
}

AppLocalizationsG lookupAppLocalizationsG(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'ar':
      {
        switch (locale.countryCode) {
          case 'KW':
            return AppLocalizationsGArKw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsGAr();
  }

  throw FlutterError(
    'AppLocalizationsG.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
