// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.g.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsGAr extends AppLocalizationsG {
  AppLocalizationsGAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'بيان';

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String get error_generic => 'حدث خطأ غير متوقع';

  @override
  String get error_network => 'تعذّر الاتصال بالشبكة';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get close => 'إغلاق';

  @override
  String get search => 'بحث';

  @override
  String get search_hint => 'ابحث عن ديوان أو مستخدم...';

  @override
  String get home => 'الرئيسية';

  @override
  String get discover => 'اكتشف';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get diwan_live => 'مباشر';

  @override
  String get diwan_premium => 'مميّز';

  @override
  String get join_diwan => 'انضمّ للديوان';

  @override
  String get leave_diwan => 'مغادرة الديوان';

  @override
  String listeners_count(int count) {
    return '$count مستمع';
  }

  @override
  String get follow => 'متابعة';

  @override
  String get unfollow => 'إلغاء المتابعة';

  @override
  String get followers => 'المتابعون';

  @override
  String get following => 'المتابَعون';

  @override
  String get verified => 'موثّق';

  @override
  String get gift => 'هدية';

  @override
  String get send_gift => 'أرسل هدية';

  @override
  String get wallet => 'المحفظة';

  @override
  String get balance => 'الرصيد';

  @override
  String get purchase_ticket => 'شراء تذكرة';

  @override
  String ticket_price(int price) {
    return 'سعر التذكرة: $price رمز';
  }

  @override
  String get insufficient_balance => 'رصيدك غير كافٍ لإتمام العملية';

  @override
  String get purchase_success => 'تمّت عملية الشراء بنجاح';

  @override
  String get series => 'السلاسل';

  @override
  String get subscribe_series => 'اشترك في السلسلة';

  @override
  String get unsubscribe_series => 'إلغاء الاشتراك';

  @override
  String episode_number(int number) {
    return 'الحلقة $number';
  }

  @override
  String new_episode_notification(String seriesTitle) {
    return 'حلقة جديدة في $seriesTitle';
  }

  @override
  String get activity_log => 'سجل النشاط';

  @override
  String get clear_history => 'حذف السجل';

  @override
  String get clear_history_confirm =>
      'هل تريد حذف سجل نشاطك بالكامل؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get history_cleared => 'تم حذف سجل النشاط بنجاح';

  @override
  String get pause_logging => 'إيقاف تتبع النشاط';

  @override
  String get resume_logging => 'استئناف تتبع النشاط';

  @override
  String get verification_title => 'توثيق الحساب';

  @override
  String get apply_verification => 'تقدّم بطلب التوثيق';

  @override
  String get verification_pending => 'طلبك قيد المراجعة';

  @override
  String get verification_approved => 'تمّ توثيق حسابك';

  @override
  String get verification_rejected => 'تمّ رفض طلبك';

  @override
  String get crash_recovery_title => 'استعادة الجلسة';

  @override
  String get crash_recovery_message =>
      'يبدو أنّ التطبيق أُغلق بشكل غير متوقع في الجلسة السابقة. هل تريد مسح ذاكرة التخزين المؤقت واستعادة جلستك؟';

  @override
  String get clear_cache_restore => 'مسح الذاكرة المؤقتة واستعادة الجلسة';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get maintenance_mode => 'التطبيق في وضع الصيانة';

  @override
  String get update_required => 'يرجى تحديث التطبيق للاستمرار';

  @override
  String get language_classical => 'العربية الفصحى';

  @override
  String get language_kuwaiti => 'اللهجة الكويتية';

  @override
  String get change_language => 'تغيير اللغة';
}

/// The translations for Arabic, as used in Kuwait (`ar_KW`).
class AppLocalizationsGArKw extends AppLocalizationsGAr {
  AppLocalizationsGArKw() : super('ar_KW');

  @override
  String get loading => 'يحمّل...';

  @override
  String get error_generic => 'صار خطأ مو متوقع';

  @override
  String get error_network => 'ما قدرنا نتصل بالشبكة';

  @override
  String get retry => 'حاول مرة ثانية';

  @override
  String get search_hint => 'دوّر على ديوان أو شخص...';

  @override
  String get diwan_live => 'لايف';

  @override
  String get diwan_premium => 'مميّز';

  @override
  String get join_diwan => 'ادخل الديوان';

  @override
  String get leave_diwan => 'اطلع من الديوان';

  @override
  String listeners_count(int count) {
    return '$count مستمع';
  }

  @override
  String get follow => 'تابع';

  @override
  String get unfollow => 'ما راح تابع';

  @override
  String get send_gift => 'أرسل هدية';

  @override
  String get purchase_ticket => 'اشتري تذكرة';

  @override
  String ticket_price(int price) {
    return 'سعر التذكرة: $price رمز';
  }

  @override
  String get insufficient_balance => 'ما عندك رصيد يكفي';

  @override
  String get purchase_success => 'تمّ الشراء';

  @override
  String get subscribe_series => 'اشترك بالسلسلة';

  @override
  String get unsubscribe_series => 'ألغِ الاشتراك';

  @override
  String episode_number(int number) {
    return 'الحلقة $number';
  }

  @override
  String new_episode_notification(String seriesTitle) {
    return 'حلقة جديدة في $seriesTitle';
  }

  @override
  String get clear_history => 'احذف السجل';

  @override
  String get clear_history_confirm =>
      'تبي تحذف كل سجل نشاطك؟ ما تقدر ترجع بعدين.';

  @override
  String get history_cleared => 'تم الحذف';

  @override
  String get pause_logging => 'وقّف التتبع';

  @override
  String get resume_logging => 'شغّل التتبع';

  @override
  String get apply_verification => 'قدّم طلب التوثيق';

  @override
  String get verification_pending => 'طلبك عند المراجعة';

  @override
  String get verification_approved => 'حسابك موثّق الحين';

  @override
  String get verification_rejected => 'رفضوا طلبك';

  @override
  String get crash_recovery_title => 'استعادة الجلسة';

  @override
  String get crash_recovery_message =>
      'يبيّن إن التطبيق توقف فجأة المرة اللي فاتت. تبي تمسح الذاكرة وترجع جلستك؟';

  @override
  String get clear_cache_restore => 'امسح الذاكرة وارجع الجلسة';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get maintenance_mode => 'التطبيق على صيانة هالحين';

  @override
  String get update_required => 'لازم تحدّث التطبيق عشان تكمل';

  @override
  String get language_classical => 'الفصحى';

  @override
  String get language_kuwaiti => 'الكويتي';
}
