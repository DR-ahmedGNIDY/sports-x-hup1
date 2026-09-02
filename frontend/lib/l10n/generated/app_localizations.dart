import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'Sport X Hub'**
  String get appTitle;

  /// No description provided for @themeToggleTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تبديل الوضع الليلي'**
  String get themeToggleTooltip;

  /// No description provided for @switchToEnglish.
  ///
  /// In ar, this message translates to:
  /// **'التبديل إلى الإنجليزية'**
  String get switchToEnglish;

  /// No description provided for @switchToArabic.
  ///
  /// In ar, this message translates to:
  /// **'التبديل إلى العربية'**
  String get switchToArabic;

  /// No description provided for @rolePlayer.
  ///
  /// In ar, this message translates to:
  /// **'لاعب'**
  String get rolePlayer;

  /// No description provided for @roleClub.
  ///
  /// In ar, this message translates to:
  /// **'نادي'**
  String get roleClub;

  /// No description provided for @passwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة مرور جديدة'**
  String get newPasswordLabel;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور الجديدة'**
  String get confirmNewPasswordLabel;

  /// No description provided for @authWelcomeBack.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بعودتك'**
  String get authWelcomeBack;

  /// No description provided for @authLogIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get authLogIn;

  /// No description provided for @authEmailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get authEmailLabel;

  /// No description provided for @authEmailValidation.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدًا إلكترونيًا صحيحًا'**
  String get authEmailValidation;

  /// No description provided for @authIdentifierLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني أو رقم الموبايل'**
  String get authIdentifierLabel;

  /// No description provided for @authIdentifierValidation.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني أو رقم موبايلك'**
  String get authIdentifierValidation;

  /// No description provided for @authPasswordValidation.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور'**
  String get authPasswordValidation;

  /// No description provided for @authForgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get authForgotPassword;

  /// No description provided for @authNoAccount.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get authNoAccount;

  /// No description provided for @authRegister.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get authRegister;

  /// No description provided for @authNoAccountRegisterMobile.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟ إنشاء حساب'**
  String get authNoAccountRegisterMobile;

  /// No description provided for @authCreateAccountTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get authCreateAccountTitle;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In ar, this message translates to:
  /// **'8 أحرف على الأقل'**
  String get authPasswordMinLength;

  /// No description provided for @authConfirmPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get authConfirmPassword;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get authPasswordMismatch;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين كلمة المرور'**
  String get authForgotPasswordTitle;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كلمة مرور جديدة'**
  String get authResetPasswordTitle;

  /// No description provided for @authResetPasswordAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين كلمة المرور'**
  String get authResetPasswordAppBarTitle;

  /// No description provided for @authForgotSentMessage.
  ///
  /// In ar, this message translates to:
  /// **'إذا كان هناك حساب مسجل بهذا البريد الإلكتروني، تم إرسال رابط إعادة التعيين. في بيئة التطوير، تحقق من سجل الـ backend للحصول على الرابط.'**
  String get authForgotSentMessage;

  /// No description provided for @authSendResetLink.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رابط إعادة التعيين'**
  String get authSendResetLink;

  /// No description provided for @authBackToLogin.
  ///
  /// In ar, this message translates to:
  /// **'العودة لتسجيل الدخول'**
  String get authBackToLogin;

  /// No description provided for @authResetDoneMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم إعادة تعيين كلمة المرور بنجاح. يمكنك تسجيل الدخول الآن.'**
  String get authResetDoneMessage;

  /// No description provided for @authGoToLogin.
  ///
  /// In ar, this message translates to:
  /// **'الذهاب لتسجيل الدخول'**
  String get authGoToLogin;

  /// No description provided for @authResetPasswordButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين كلمة المرور'**
  String get authResetPasswordButton;

  /// No description provided for @authResetTokenMissing.
  ///
  /// In ar, this message translates to:
  /// **'رابط إعادة التعيين هذا غير مكتمل.'**
  String get authResetTokenMissing;

  /// No description provided for @marketingNavHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get marketingNavHome;

  /// No description provided for @marketingNavPlayers.
  ///
  /// In ar, this message translates to:
  /// **'اللاعبون'**
  String get marketingNavPlayers;

  /// No description provided for @marketingNavClubs.
  ///
  /// In ar, this message translates to:
  /// **'الأندية'**
  String get marketingNavClubs;

  /// No description provided for @marketingNavAbout.
  ///
  /// In ar, this message translates to:
  /// **'من نحن'**
  String get marketingNavAbout;

  /// No description provided for @marketingNavPricing.
  ///
  /// In ar, this message translates to:
  /// **'الأسعار'**
  String get marketingNavPricing;

  /// No description provided for @marketingNavContact.
  ///
  /// In ar, this message translates to:
  /// **'تواصل معنا'**
  String get marketingNavContact;

  /// No description provided for @homeHeroTitle.
  ///
  /// In ar, this message translates to:
  /// **'هنا يتم اكتشاف اللاعبين.'**
  String get homeHeroTitle;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اللاعب يبني ملفًا شخصيًا موثوقًا. النادي يجد هذا اللاعب من خلال البحث. النادي يتواصل معه مباشرة — بدون وسيط، بدون تعقيد.'**
  String get homeHeroSubtitle;

  /// No description provided for @homeGetStarted.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الآن'**
  String get homeGetStarted;

  /// No description provided for @homeBrowsePlayers.
  ///
  /// In ar, this message translates to:
  /// **'تصفح اللاعبين'**
  String get homeBrowsePlayers;

  /// No description provided for @homeFeatureBuildTitle.
  ///
  /// In ar, this message translates to:
  /// **'ابنِ ملفك الشخصي'**
  String get homeFeatureBuildTitle;

  /// No description provided for @homeFeatureBuildBody.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات الشخصية، الإحصائيات الرياضية، الصور، الفيديو، الإنجازات، وبيانات التواصل — كل ما يحتاجه النادي لتقييمك.'**
  String get homeFeatureBuildBody;

  /// No description provided for @homeFeatureFoundTitle.
  ///
  /// In ar, this message translates to:
  /// **'كن مكتشفًا'**
  String get homeFeatureFoundTitle;

  /// No description provided for @homeFeatureFoundBody.
  ///
  /// In ar, this message translates to:
  /// **'الأندية تبحث حسب الدولة، العمر، المركز، الطول، الوزن، القدم المفضلة، والرياضة — لتصل بالضبط لمن تحتاجه.'**
  String get homeFeatureFoundBody;

  /// No description provided for @homeFeatureContactedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مباشر'**
  String get homeFeatureContactedTitle;

  /// No description provided for @homeFeatureContactedBody.
  ///
  /// In ar, this message translates to:
  /// **'واتساب، بريد إلكتروني، أو هاتف — النادي يتواصل معك مباشرة في اللحظة التي يجدك فيها.'**
  String get homeFeatureContactedBody;

  /// No description provided for @installAppLabel.
  ///
  /// In ar, this message translates to:
  /// **'تثبيت التطبيق'**
  String get installAppLabel;

  /// No description provided for @installAppIosTitle.
  ///
  /// In ar, this message translates to:
  /// **'التثبيت على الشاشة الرئيسية'**
  String get installAppIosTitle;

  /// No description provided for @installAppIosStep1.
  ///
  /// In ar, this message translates to:
  /// **'اضغط زر المشاركة في شريط Safari.'**
  String get installAppIosStep1;

  /// No description provided for @installAppIosStep2.
  ///
  /// In ar, this message translates to:
  /// **'اختر «إضافة إلى الشاشة الرئيسية».'**
  String get installAppIosStep2;

  /// No description provided for @installAppIosStep3.
  ///
  /// In ar, this message translates to:
  /// **'اضغط «إضافة» — سيفتح التطبيق بملء الشاشة بعدها.'**
  String get installAppIosStep3;

  /// No description provided for @aboutTitle.
  ///
  /// In ar, this message translates to:
  /// **'عن Sport X Hub'**
  String get aboutTitle;

  /// No description provided for @aboutBody1.
  ///
  /// In ar, this message translates to:
  /// **'Sport X Hub سوق احترافي لاكتشاف المواهب الرياضية يربط بين اللاعبين والأندية. منصتنا موجودة لتحقيق حلقة واحدة: اللاعب يبني ملفًا شخصيًا موثوقًا، والنادي يجد هذا اللاعب من خلال البحث، والنادي يتواصل معه مباشرة.'**
  String get aboutBody1;

  /// No description provided for @aboutBody2.
  ///
  /// In ar, this message translates to:
  /// **'بدون تعقيد، بدون وسيط، بدون مميزات زائدة — فقط أسرع طريق من ملف شخصي حقيقي إلى محادثة حقيقية.'**
  String get aboutBody2;

  /// No description provided for @pricingTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأسعار'**
  String get pricingTitle;

  /// No description provided for @pricingSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'الانضمام إلى Sport X Hub مجاني خلال فترة الإطلاق.'**
  String get pricingSubtitle;

  /// No description provided for @pricingFree.
  ///
  /// In ar, this message translates to:
  /// **'مجاني'**
  String get pricingFree;

  /// No description provided for @pricingPlayerFeature1.
  ///
  /// In ar, this message translates to:
  /// **'ملف لاعب كامل مع صور وفيديو'**
  String get pricingPlayerFeature1;

  /// No description provided for @pricingPlayerFeature2.
  ///
  /// In ar, this message translates to:
  /// **'الإنجازات وروابط التواصل الاجتماعي'**
  String get pricingPlayerFeature2;

  /// No description provided for @pricingPlayerFeature3.
  ///
  /// In ar, this message translates to:
  /// **'إظهار عام أو خاص'**
  String get pricingPlayerFeature3;

  /// No description provided for @pricingPlayerFeature4.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مباشر من الأندية المهتمة'**
  String get pricingPlayerFeature4;

  /// No description provided for @pricingClubFeature1.
  ///
  /// In ar, this message translates to:
  /// **'البحث عن اللاعبين بـ 7 فلاتر'**
  String get pricingClubFeature1;

  /// No description provided for @pricingClubFeature2.
  ///
  /// In ar, this message translates to:
  /// **'حفظ اللاعبين في قائمة مختصرة'**
  String get pricingClubFeature2;

  /// No description provided for @pricingClubFeature3.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مباشر عبر واتساب / بريد إلكتروني / هاتف'**
  String get pricingClubFeature3;

  /// No description provided for @pricingClubFeature4.
  ///
  /// In ar, this message translates to:
  /// **'صفحة ملف تعريفي للنادي'**
  String get pricingClubFeature4;

  /// No description provided for @contactTitle.
  ///
  /// In ar, this message translates to:
  /// **'تواصل معنا'**
  String get contactTitle;

  /// No description provided for @contactSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أسئلة، ملاحظات، أو استفسارات شراكة — أرسل لنا رسالة.'**
  String get contactSubtitle;

  /// No description provided for @contactNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get contactNameLabel;

  /// No description provided for @contactMessageLabel.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة'**
  String get contactMessageLabel;

  /// No description provided for @contactRequiredValidation.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب'**
  String get contactRequiredValidation;

  /// No description provided for @contactSendMessage.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرسالة'**
  String get contactSendMessage;

  /// No description provided for @contactSuccessMessage.
  ///
  /// In ar, this message translates to:
  /// **'شكرًا لك — استلمنا رسالتك وسنتواصل معك قريبًا.'**
  String get contactSuccessMessage;

  /// No description provided for @playersNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد لاعبون مطابقون لهذه الفلاتر.'**
  String get playersNoResults;

  /// No description provided for @filtersTooltip.
  ///
  /// In ar, this message translates to:
  /// **'الفلاتر'**
  String get filtersTooltip;

  /// No description provided for @playerSearchNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'ابحث باسم اللاعب'**
  String get playerSearchNameLabel;

  /// No description provided for @searchResultsCountLabel.
  ///
  /// In ar, this message translates to:
  /// **'{count} لاعب متاح'**
  String searchResultsCountLabel(int count);

  /// No description provided for @clubsListingTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأندية على Sport X Hub'**
  String get clubsListingTitle;

  /// No description provided for @clubsNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أندية لعرضها حاليًا.'**
  String get clubsNoResults;

  /// No description provided for @unnamedClub.
  ///
  /// In ar, this message translates to:
  /// **'نادٍ بدون اسم'**
  String get unnamedClub;

  /// No description provided for @dashboardRoleAdmin.
  ///
  /// In ar, this message translates to:
  /// **'أدمن'**
  String get dashboardRoleAdmin;

  /// No description provided for @dashboardTitleWithRole.
  ///
  /// In ar, this message translates to:
  /// **'لوحة تحكم {role}'**
  String dashboardTitleWithRole(String role);

  /// No description provided for @dashboardComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'لوحة تحكم {role} — قريبًا في مرحلة لاحقة'**
  String dashboardComingSoon(String role);

  /// No description provided for @dashboardSidebarTitle.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get dashboardSidebarTitle;

  /// No description provided for @dashboardLatestNewsTitle.
  ///
  /// In ar, this message translates to:
  /// **'آخر الأخبار'**
  String get dashboardLatestNewsTitle;

  /// No description provided for @dashboardStatsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إحصائيات النادي'**
  String get dashboardStatsTitle;

  /// No description provided for @dashboardMyProfile.
  ///
  /// In ar, this message translates to:
  /// **'ملفي الشخصي'**
  String get dashboardMyProfile;

  /// No description provided for @dashboardEditProfile.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملف الشخصي'**
  String get dashboardEditProfile;

  /// No description provided for @dashboardAdminUsers.
  ///
  /// In ar, this message translates to:
  /// **'الأدمن — المستخدمون'**
  String get dashboardAdminUsers;

  /// No description provided for @dashboardAdminPlayersClubs.
  ///
  /// In ar, this message translates to:
  /// **'الأدمن — اللاعبون والأندية'**
  String get dashboardAdminPlayersClubs;

  /// No description provided for @dashboardMyClub.
  ///
  /// In ar, this message translates to:
  /// **'ملف النادي'**
  String get dashboardMyClub;

  /// No description provided for @dashboardEditClubProfile.
  ///
  /// In ar, this message translates to:
  /// **'تعديل ملف النادي'**
  String get dashboardEditClubProfile;

  /// No description provided for @dashboardSearchPlayers.
  ///
  /// In ar, this message translates to:
  /// **'البحث عن اللاعبين'**
  String get dashboardSearchPlayers;

  /// No description provided for @mobileSearchNavLabel.
  ///
  /// In ar, this message translates to:
  /// **'البحث'**
  String get mobileSearchNavLabel;

  /// No description provided for @dashboardSavedPlayers.
  ///
  /// In ar, this message translates to:
  /// **'اللاعبون المحفوظون'**
  String get dashboardSavedPlayers;

  /// No description provided for @dashboardAccountSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الحساب'**
  String get dashboardAccountSettings;

  /// No description provided for @dashboardAdminMobileHint.
  ///
  /// In ar, this message translates to:
  /// **'أدوات الأدمن متاحة على الحاسوب فقط.'**
  String get dashboardAdminMobileHint;

  /// No description provided for @dashboardNavSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get dashboardNavSettings;

  /// No description provided for @logoutTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logoutTooltip;

  /// No description provided for @saveLabel.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get saveLabel;

  /// No description provided for @cancelLabel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancelLabel;

  /// No description provided for @deleteLabel.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get deleteLabel;

  /// No description provided for @previousPageLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة السابقة'**
  String get previousPageLabel;

  /// No description provided for @nextPageLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة التالية'**
  String get nextPageLabel;

  /// No description provided for @showPasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'إظهار كلمة المرور'**
  String get showPasswordLabel;

  /// No description provided for @hidePasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء كلمة المرور'**
  String get hidePasswordLabel;

  /// No description provided for @clearSearchLabel.
  ///
  /// In ar, this message translates to:
  /// **'مسح البحث'**
  String get clearSearchLabel;

  /// No description provided for @editLabel.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get editLabel;

  /// No description provided for @sendLabel.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get sendLabel;

  /// No description provided for @playLabel.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get playLabel;

  /// No description provided for @pauseLabel.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get pauseLabel;

  /// No description provided for @removeLabel.
  ///
  /// In ar, this message translates to:
  /// **'إزالة'**
  String get removeLabel;

  /// No description provided for @anyOption.
  ///
  /// In ar, this message translates to:
  /// **'أي'**
  String get anyOption;

  /// No description provided for @previewLabel.
  ///
  /// In ar, this message translates to:
  /// **'معاينة'**
  String get previewLabel;

  /// No description provided for @sectionAboutTitle.
  ///
  /// In ar, this message translates to:
  /// **'نبذة'**
  String get sectionAboutTitle;

  /// No description provided for @backLabel.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get backLabel;

  /// No description provided for @backToPlayersLabel.
  ///
  /// In ar, this message translates to:
  /// **'العودة إلى اللاعبين'**
  String get backToPlayersLabel;

  /// No description provided for @shareProfileLabel.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الملف'**
  String get shareProfileLabel;

  /// No description provided for @shareProfileLinkCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ رابط الملف الشخصي'**
  String get shareProfileLinkCopied;

  /// No description provided for @ageLabel.
  ///
  /// In ar, this message translates to:
  /// **'العمر'**
  String get ageLabel;

  /// No description provided for @birthYearLabel.
  ///
  /// In ar, this message translates to:
  /// **'سنة الميلاد'**
  String get birthYearLabel;

  /// No description provided for @playerProfileBadge.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي للاعب'**
  String get playerProfileBadge;

  /// No description provided for @playerInformationTitle.
  ///
  /// In ar, this message translates to:
  /// **'معلومات اللاعب'**
  String get playerInformationTitle;

  /// No description provided for @noClubTitle.
  ///
  /// In ar, this message translates to:
  /// **'بدون نادٍ'**
  String get noClubTitle;

  /// No description provided for @noClubSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'غير منضم لأي نادٍ حاليًا'**
  String get noClubSubtitle;

  /// No description provided for @personalInfoTitle.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات الشخصية'**
  String get personalInfoTitle;

  /// No description provided for @firstNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الأول'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم العائلة'**
  String get lastNameLabel;

  /// No description provided for @dateOfBirthLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الميلاد'**
  String get dateOfBirthLabel;

  /// No description provided for @selectDateLabel.
  ///
  /// In ar, this message translates to:
  /// **'اختر تاريخًا'**
  String get selectDateLabel;

  /// No description provided for @nationalityLabel.
  ///
  /// In ar, this message translates to:
  /// **'الجنسية'**
  String get nationalityLabel;

  /// No description provided for @countryLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدولة'**
  String get countryLabel;

  /// No description provided for @cityLabel.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get cityLabel;

  /// No description provided for @sportsInfoTitle.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات الرياضية'**
  String get sportsInfoTitle;

  /// No description provided for @sportLabel.
  ///
  /// In ar, this message translates to:
  /// **'الرياضة'**
  String get sportLabel;

  /// No description provided for @positionLabel.
  ///
  /// In ar, this message translates to:
  /// **'المركز'**
  String get positionLabel;

  /// No description provided for @footballPositionSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'مركز اللعب'**
  String get footballPositionSectionTitle;

  /// No description provided for @footballPositionPickerSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر مركزك الأساسي في الملعب'**
  String get footballPositionPickerSubtitle;

  /// No description provided for @footballPositionEditHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على مركز لتعيينه كمركز أساسي (اضغط مرة أخرى لإلغائه). اضغط مطولًا لإضافته أو إزالته كمركز بديل.'**
  String get footballPositionEditHint;

  /// No description provided for @footballPositionViewHint.
  ///
  /// In ar, this message translates to:
  /// **'المراكز المميزة تعرض مراكز هذا اللاعب.'**
  String get footballPositionViewHint;

  /// No description provided for @footballPositionPrimaryLabel.
  ///
  /// In ar, this message translates to:
  /// **'مركزك الحالي'**
  String get footballPositionPrimaryLabel;

  /// No description provided for @footballPositionSecondaryLabel.
  ///
  /// In ar, this message translates to:
  /// **'مركز بديل'**
  String get footballPositionSecondaryLabel;

  /// No description provided for @footballPositionOtherLabel.
  ///
  /// In ar, this message translates to:
  /// **'المراكز الأخرى'**
  String get footballPositionOtherLabel;

  /// No description provided for @footballPositionNoneSelected.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم تحديد مركز بعد'**
  String get footballPositionNoneSelected;

  /// No description provided for @footballPositionGk.
  ///
  /// In ar, this message translates to:
  /// **'حارس مرمى'**
  String get footballPositionGk;

  /// No description provided for @footballPositionLb.
  ///
  /// In ar, this message translates to:
  /// **'ظهير أيسر'**
  String get footballPositionLb;

  /// No description provided for @footballPositionCb.
  ///
  /// In ar, this message translates to:
  /// **'قلب دفاع'**
  String get footballPositionCb;

  /// No description provided for @footballPositionRb.
  ///
  /// In ar, this message translates to:
  /// **'ظهير أيمن'**
  String get footballPositionRb;

  /// No description provided for @footballPositionCdm.
  ///
  /// In ar, this message translates to:
  /// **'وسط دفاعي'**
  String get footballPositionCdm;

  /// No description provided for @footballPositionCm.
  ///
  /// In ar, this message translates to:
  /// **'وسط الملعب'**
  String get footballPositionCm;

  /// No description provided for @footballPositionCam.
  ///
  /// In ar, this message translates to:
  /// **'صانع ألعاب'**
  String get footballPositionCam;

  /// No description provided for @footballPositionLw.
  ///
  /// In ar, this message translates to:
  /// **'جناح أيسر'**
  String get footballPositionLw;

  /// No description provided for @footballPositionRw.
  ///
  /// In ar, this message translates to:
  /// **'جناح أيمن'**
  String get footballPositionRw;

  /// No description provided for @footballPositionSt.
  ///
  /// In ar, this message translates to:
  /// **'مهاجم'**
  String get footballPositionSt;

  /// No description provided for @footballPositionCf.
  ///
  /// In ar, this message translates to:
  /// **'مهاجم صريح'**
  String get footballPositionCf;

  /// No description provided for @footballPositionGkDesc.
  ///
  /// In ar, this message translates to:
  /// **'حماية المرمى والتصدي للكرات'**
  String get footballPositionGkDesc;

  /// No description provided for @footballPositionLbDesc.
  ///
  /// In ar, this message translates to:
  /// **'دعم الدفاع والهجوم من الجهة اليسرى'**
  String get footballPositionLbDesc;

  /// No description provided for @footballPositionCbDesc.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف الهجمات وحماية المرمى'**
  String get footballPositionCbDesc;

  /// No description provided for @footballPositionRbDesc.
  ///
  /// In ar, this message translates to:
  /// **'دعم الدفاع والهجوم من الجهة اليمنى'**
  String get footballPositionRbDesc;

  /// No description provided for @footballPositionCdmDesc.
  ///
  /// In ar, this message translates to:
  /// **'حماية الدفاع واستعادة الكرات'**
  String get footballPositionCdmDesc;

  /// No description provided for @footballPositionCmDesc.
  ///
  /// In ar, this message translates to:
  /// **'ربط الدفاع بالهجوم'**
  String get footballPositionCmDesc;

  /// No description provided for @footballPositionCamDesc.
  ///
  /// In ar, this message translates to:
  /// **'صناعة الفرص وكسر خطوط الدفاع'**
  String get footballPositionCamDesc;

  /// No description provided for @footballPositionLwDesc.
  ///
  /// In ar, this message translates to:
  /// **'سرعة ومهارة على الطرف الأيسر'**
  String get footballPositionLwDesc;

  /// No description provided for @footballPositionRwDesc.
  ///
  /// In ar, this message translates to:
  /// **'سرعة ومهارة على الطرف الأيمن'**
  String get footballPositionRwDesc;

  /// No description provided for @footballPositionStDesc.
  ///
  /// In ar, this message translates to:
  /// **'هداف الفريق ورأس الحربة'**
  String get footballPositionStDesc;

  /// No description provided for @footballPositionCfDesc.
  ///
  /// In ar, this message translates to:
  /// **'مهاجم أمامي وصانع الفرص'**
  String get footballPositionCfDesc;

  /// No description provided for @basketballPositionSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'مركز اللعب'**
  String get basketballPositionSectionTitle;

  /// No description provided for @basketballPositionPickerSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر مركزك الأساسي في الملعب'**
  String get basketballPositionPickerSubtitle;

  /// No description provided for @basketballPositionEditHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على مركز لتعيينه كمركز أساسي (اضغط مرة أخرى لإلغائه). اضغط مطولًا لإضافته أو إزالته كمركز بديل.'**
  String get basketballPositionEditHint;

  /// No description provided for @basketballPositionViewHint.
  ///
  /// In ar, this message translates to:
  /// **'المراكز المميزة تعرض مراكز هذا اللاعب.'**
  String get basketballPositionViewHint;

  /// No description provided for @basketballPositionPrimaryLabel.
  ///
  /// In ar, this message translates to:
  /// **'مركزك الحالي'**
  String get basketballPositionPrimaryLabel;

  /// No description provided for @basketballPositionSecondaryLabel.
  ///
  /// In ar, this message translates to:
  /// **'مركز بديل'**
  String get basketballPositionSecondaryLabel;

  /// No description provided for @basketballPositionOtherLabel.
  ///
  /// In ar, this message translates to:
  /// **'المراكز الأخرى'**
  String get basketballPositionOtherLabel;

  /// No description provided for @basketballPositionNoneSelected.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم تحديد مركز بعد'**
  String get basketballPositionNoneSelected;

  /// No description provided for @basketballPositionPg.
  ///
  /// In ar, this message translates to:
  /// **'صانع اللعب'**
  String get basketballPositionPg;

  /// No description provided for @basketballPositionSg.
  ///
  /// In ar, this message translates to:
  /// **'مسدد خلفي'**
  String get basketballPositionSg;

  /// No description provided for @basketballPositionSf.
  ///
  /// In ar, this message translates to:
  /// **'لاعب ارتكاز صغير'**
  String get basketballPositionSf;

  /// No description provided for @basketballPositionPf.
  ///
  /// In ar, this message translates to:
  /// **'لاعب ارتكاز قوي'**
  String get basketballPositionPf;

  /// No description provided for @basketballPositionC.
  ///
  /// In ar, this message translates to:
  /// **'سنتر'**
  String get basketballPositionC;

  /// No description provided for @basketballPositionPgDesc.
  ///
  /// In ar, this message translates to:
  /// **'يقود الهجوم وينظم اللعب'**
  String get basketballPositionPgDesc;

  /// No description provided for @basketballPositionSgDesc.
  ///
  /// In ar, this message translates to:
  /// **'متخصص في التسديد من الخارج'**
  String get basketballPositionSgDesc;

  /// No description provided for @basketballPositionSfDesc.
  ///
  /// In ar, this message translates to:
  /// **'لاعب متنوع في الهجوم والدفاع'**
  String get basketballPositionSfDesc;

  /// No description provided for @basketballPositionPfDesc.
  ///
  /// In ar, this message translates to:
  /// **'قوة في الدفاع والريباوند'**
  String get basketballPositionPfDesc;

  /// No description provided for @basketballPositionCDesc.
  ///
  /// In ar, this message translates to:
  /// **'حماية السلة والريباوند'**
  String get basketballPositionCDesc;

  /// No description provided for @preferredFootLabel.
  ///
  /// In ar, this message translates to:
  /// **'القدم المفضلة'**
  String get preferredFootLabel;

  /// No description provided for @heightLabel.
  ///
  /// In ar, this message translates to:
  /// **'الطول (سم)'**
  String get heightLabel;

  /// No description provided for @weightLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوزن (كجم)'**
  String get weightLabel;

  /// No description provided for @heightStatLabel.
  ///
  /// In ar, this message translates to:
  /// **'الطول'**
  String get heightStatLabel;

  /// No description provided for @weightStatLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوزن'**
  String get weightStatLabel;

  /// No description provided for @currentStatusLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحالة الحالية'**
  String get currentStatusLabel;

  /// No description provided for @currentClubLabel.
  ///
  /// In ar, this message translates to:
  /// **'النادي الحالي'**
  String get currentClubLabel;

  /// No description provided for @statusStatLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get statusStatLabel;

  /// No description provided for @preferredFootLeft.
  ///
  /// In ar, this message translates to:
  /// **'اليسرى'**
  String get preferredFootLeft;

  /// No description provided for @preferredFootRight.
  ///
  /// In ar, this message translates to:
  /// **'اليمنى'**
  String get preferredFootRight;

  /// No description provided for @preferredFootBoth.
  ///
  /// In ar, this message translates to:
  /// **'كلتاهما'**
  String get preferredFootBoth;

  /// No description provided for @aboutContactTitle.
  ///
  /// In ar, this message translates to:
  /// **'نبذة وتواصل'**
  String get aboutContactTitle;

  /// No description provided for @bioLabel.
  ///
  /// In ar, this message translates to:
  /// **'نبذة تعريفية'**
  String get bioLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phoneLabel;

  /// No description provided for @contactEmailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني للتواصل'**
  String get contactEmailLabel;

  /// No description provided for @whatsappLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الواتساب'**
  String get whatsappLabel;

  /// No description provided for @photosVideosTitle.
  ///
  /// In ar, this message translates to:
  /// **'الصور والفيديوهات'**
  String get photosVideosTitle;

  /// No description provided for @addPhotoLabel.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صورة'**
  String get addPhotoLabel;

  /// No description provided for @addVideoLabel.
  ///
  /// In ar, this message translates to:
  /// **'إضافة فيديو'**
  String get addVideoLabel;

  /// No description provided for @achievementsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإنجازات'**
  String get achievementsTitle;

  /// No description provided for @noAchievementsYet.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم إضافة أي إنجازات بعد.'**
  String get noAchievementsYet;

  /// No description provided for @addAchievementTooltip.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إنجاز'**
  String get addAchievementTooltip;

  /// No description provided for @editAchievementTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الإنجاز'**
  String get editAchievementTitle;

  /// No description provided for @addAchievementTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إنجاز'**
  String get addAchievementTitle;

  /// No description provided for @achievementTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get achievementTitleLabel;

  /// No description provided for @yearLabel.
  ///
  /// In ar, this message translates to:
  /// **'السنة'**
  String get yearLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get descriptionLabel;

  /// No description provided for @achievementValidation.
  ///
  /// In ar, this message translates to:
  /// **'أدخل عنوانًا وسنة صحيحة.'**
  String get achievementValidation;

  /// No description provided for @socialLinksTitle.
  ///
  /// In ar, this message translates to:
  /// **'روابط التواصل الاجتماعي'**
  String get socialLinksTitle;

  /// No description provided for @noSocialLinksYet.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم إضافة أي روابط تواصل اجتماعي بعد.'**
  String get noSocialLinksYet;

  /// No description provided for @addSocialLinkTooltip.
  ///
  /// In ar, this message translates to:
  /// **'إضافة رابط تواصل اجتماعي'**
  String get addSocialLinkTooltip;

  /// No description provided for @editSocialLinkTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل رابط التواصل الاجتماعي'**
  String get editSocialLinkTitle;

  /// No description provided for @addSocialLinkTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة رابط تواصل اجتماعي'**
  String get addSocialLinkTitle;

  /// No description provided for @platformLabel.
  ///
  /// In ar, this message translates to:
  /// **'المنصة'**
  String get platformLabel;

  /// No description provided for @platformHint.
  ///
  /// In ar, this message translates to:
  /// **'انستجرام، يوتيوب، إكس…'**
  String get platformHint;

  /// No description provided for @urlLabel.
  ///
  /// In ar, this message translates to:
  /// **'الرابط'**
  String get urlLabel;

  /// No description provided for @socialLinkValidation.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسم المنصة والرابط.'**
  String get socialLinkValidation;

  /// No description provided for @visibilityTitle.
  ///
  /// In ar, this message translates to:
  /// **'إظهار الملف الشخصي'**
  String get visibilityTitle;

  /// No description provided for @visibilityPublicDesc.
  ///
  /// In ar, this message translates to:
  /// **'ملفك الشخصي ظاهر للأندية في نتائج البحث.'**
  String get visibilityPublicDesc;

  /// No description provided for @visibilityPrivateDesc.
  ///
  /// In ar, this message translates to:
  /// **'ملفك الشخصي مخفي عن البحث والعرض العام.'**
  String get visibilityPrivateDesc;

  /// No description provided for @publicProfileLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملف شخصي عام'**
  String get publicProfileLabel;

  /// No description provided for @unnamedPlayer.
  ///
  /// In ar, this message translates to:
  /// **'لاعب بدون اسم'**
  String get unnamedPlayer;

  /// No description provided for @galleryTitle.
  ///
  /// In ar, this message translates to:
  /// **'معرض الصور'**
  String get galleryTitle;

  /// No description provided for @contactSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'التواصل'**
  String get contactSectionTitle;

  /// No description provided for @contactPhoneValue.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف: {value}'**
  String contactPhoneValue(String value);

  /// No description provided for @contactEmailValue.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني: {value}'**
  String contactEmailValue(String value);

  /// No description provided for @contactWhatsappValue.
  ///
  /// In ar, this message translates to:
  /// **'واتساب: {value}'**
  String contactWhatsappValue(String value);

  /// No description provided for @savePlayerTooltip.
  ///
  /// In ar, this message translates to:
  /// **'حفظ اللاعب'**
  String get savePlayerTooltip;

  /// No description provided for @removeSavedTooltip.
  ///
  /// In ar, this message translates to:
  /// **'إزالة من المحفوظين'**
  String get removeSavedTooltip;

  /// No description provided for @contactWhatsappButton.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get contactWhatsappButton;

  /// No description provided for @contactEmailButton.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get contactEmailButton;

  /// No description provided for @contactCallButton.
  ///
  /// In ar, this message translates to:
  /// **'اتصال'**
  String get contactCallButton;

  /// No description provided for @myProfileTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملفي الشخصي'**
  String get myProfileTitle;

  /// No description provided for @clubInfoTitle.
  ///
  /// In ar, this message translates to:
  /// **'معلومات النادي'**
  String get clubInfoTitle;

  /// No description provided for @clubNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم النادي'**
  String get clubNameLabel;

  /// No description provided for @foundedYearLabel.
  ///
  /// In ar, this message translates to:
  /// **'سنة التأسيس'**
  String get foundedYearLabel;

  /// No description provided for @levelLabel.
  ///
  /// In ar, this message translates to:
  /// **'المستوى'**
  String get levelLabel;

  /// No description provided for @clubLevelAmateur.
  ///
  /// In ar, this message translates to:
  /// **'هاوٍ'**
  String get clubLevelAmateur;

  /// No description provided for @clubLevelSemiProfessional.
  ///
  /// In ar, this message translates to:
  /// **'شبه محترف'**
  String get clubLevelSemiProfessional;

  /// No description provided for @clubLevelProfessional.
  ///
  /// In ar, this message translates to:
  /// **'محترف'**
  String get clubLevelProfessional;

  /// No description provided for @clubLevelLegacyValueHint.
  ///
  /// In ar, this message translates to:
  /// **'القيمة الحالية: {value}'**
  String clubLevelLegacyValueHint(String value);

  /// No description provided for @foundedStatLabel.
  ///
  /// In ar, this message translates to:
  /// **'التأسيس'**
  String get foundedStatLabel;

  /// No description provided for @clubLogoTitle.
  ///
  /// In ar, this message translates to:
  /// **'شعار النادي'**
  String get clubLogoTitle;

  /// No description provided for @uploadingLabel.
  ///
  /// In ar, this message translates to:
  /// **'جارِ الرفع…'**
  String get uploadingLabel;

  /// No description provided for @uploadLogoLabel.
  ///
  /// In ar, this message translates to:
  /// **'رفع الشعار'**
  String get uploadLogoLabel;

  /// No description provided for @clubPlayersTitle.
  ///
  /// In ar, this message translates to:
  /// **'لاعبو النادي'**
  String get clubPlayersTitle;

  /// No description provided for @clubPlayersAddPlayerLabel.
  ///
  /// In ar, this message translates to:
  /// **'إضافة لاعب'**
  String get clubPlayersAddPlayerLabel;

  /// No description provided for @clubPlayersEmptyState.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم إضافة أي لاعب بعد.'**
  String get clubPlayersEmptyState;

  /// No description provided for @clubPlayerAccountCreatedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء حساب اللاعب'**
  String get clubPlayerAccountCreatedTitle;

  /// No description provided for @clubPlayerUsernameValue.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم: {username}'**
  String clubPlayerUsernameValue(String username);

  /// No description provided for @clubPlayerPasswordValue.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور: {password}'**
  String clubPlayerPasswordValue(String password);

  /// No description provided for @clubPlayerDoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get clubPlayerDoneLabel;

  /// No description provided for @clubPlayerSelectCountryError.
  ///
  /// In ar, this message translates to:
  /// **'اختر الدولة.'**
  String get clubPlayerSelectCountryError;

  /// No description provided for @clubPlayerFieldRequiredValidation.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب'**
  String get clubPlayerFieldRequiredValidation;

  /// No description provided for @clubPlayerFirstNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الأول'**
  String get clubPlayerFirstNameLabel;

  /// No description provided for @clubPlayerLastNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم العائلة'**
  String get clubPlayerLastNameLabel;

  /// No description provided for @clubPlayerCountryLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدولة'**
  String get clubPlayerCountryLabel;

  /// No description provided for @clubPlayerPhoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get clubPlayerPhoneLabel;

  /// No description provided for @clubPlayerPhoneHint.
  ///
  /// In ar, this message translates to:
  /// **'بدون صفر في البداية'**
  String get clubPlayerPhoneHint;

  /// No description provided for @clubPlayerPhoneInvalid.
  ///
  /// In ar, this message translates to:
  /// **'رقم غير صحيح'**
  String get clubPlayerPhoneInvalid;

  /// No description provided for @clubPlayerEmailOptionalLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني (اختياري)'**
  String get clubPlayerEmailOptionalLabel;

  /// No description provided for @clubPlayerDobValueLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الميلاد: {date}'**
  String clubPlayerDobValueLabel(String date);

  /// No description provided for @clubPlayerDobOptionalLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الميلاد (اختياري)'**
  String get clubPlayerDobOptionalLabel;

  /// No description provided for @clubPlayerNationalityOptionalLabel.
  ///
  /// In ar, this message translates to:
  /// **'الجنسية (اختياري)'**
  String get clubPlayerNationalityOptionalLabel;

  /// No description provided for @clubPlayerCityOptionalLabel.
  ///
  /// In ar, this message translates to:
  /// **'المدينة (اختياري)'**
  String get clubPlayerCityOptionalLabel;

  /// No description provided for @clubPlayerSportOptionalLabel.
  ///
  /// In ar, this message translates to:
  /// **'الرياضة (اختياري)'**
  String get clubPlayerSportOptionalLabel;

  /// No description provided for @clubPlayerPositionOptionalLabel.
  ///
  /// In ar, this message translates to:
  /// **'المركز (اختياري)'**
  String get clubPlayerPositionOptionalLabel;

  /// No description provided for @clubPlayerPreferredFootOptionalLabel.
  ///
  /// In ar, this message translates to:
  /// **'القدم المفضلة (اختياري)'**
  String get clubPlayerPreferredFootOptionalLabel;

  /// No description provided for @clubPlayerHeightLabel.
  ///
  /// In ar, this message translates to:
  /// **'الطول (سم)'**
  String get clubPlayerHeightLabel;

  /// No description provided for @clubPlayerWeightLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوزن (كجم)'**
  String get clubPlayerWeightLabel;

  /// No description provided for @clubPlayerBioOptionalLabel.
  ///
  /// In ar, this message translates to:
  /// **'نبذة (اختياري)'**
  String get clubPlayerBioOptionalLabel;

  /// No description provided for @clubPlayerCreateAccountButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get clubPlayerCreateAccountButton;

  /// No description provided for @clubPlayerNextLabel.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get clubPlayerNextLabel;

  /// No description provided for @clubPlayerStepBasicInfoTitle.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات الأساسية'**
  String get clubPlayerStepBasicInfoTitle;

  /// No description provided for @clubPlayerStepSportsInfoTitle.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات الرياضية'**
  String get clubPlayerStepSportsInfoTitle;

  /// No description provided for @clubPlayerStepContactTitle.
  ///
  /// In ar, this message translates to:
  /// **'التواصل'**
  String get clubPlayerStepContactTitle;

  /// No description provided for @clubPlayerStepAccountTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get clubPlayerStepAccountTitle;

  /// No description provided for @clubPlayerStepIndicatorLabel.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة {step} من {total}'**
  String clubPlayerStepIndicatorLabel(int step, int total);

  /// No description provided for @clubPlayerReviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'المراجعة وإنشاء الحساب'**
  String get clubPlayerReviewTitle;

  /// No description provided for @clubPlayerReviewSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'راجع البيانات أدناه، ثم أنشئ حساب اللاعب.'**
  String get clubPlayerReviewSubtitle;

  /// No description provided for @clubPlayerSendWhatsAppButton.
  ///
  /// In ar, this message translates to:
  /// **'إرسال عبر واتساب'**
  String get clubPlayerSendWhatsAppButton;

  /// No description provided for @clubPlayerResendCredentialsWhatsAppButton.
  ///
  /// In ar, this message translates to:
  /// **'إرسال بيانات الدخول عبر واتساب'**
  String get clubPlayerResendCredentialsWhatsAppButton;

  /// No description provided for @clubPlayerCredentialsWhatsAppMessage.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً {firstName}، تم إنشاء حسابك في سبورت اكس هب من قبل نادي {clubName}.\nاسم المستخدم: {username}\nكلمة المرور: {password}\nيرجى تسجيل الدخول وتغيير كلمة المرور من الإعدادات.'**
  String clubPlayerCredentialsWhatsAppMessage(
    String firstName,
    String clubName,
    String username,
    String password,
  );

  /// No description provided for @clubDashboardTotalPlayersLabel.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي اللاعبين'**
  String get clubDashboardTotalPlayersLabel;

  /// No description provided for @clubDashboardCompleteProfilesLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملفات مكتملة'**
  String get clubDashboardCompleteProfilesLabel;

  /// No description provided for @clubDashboardIncompleteProfilesLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملفات غير مكتملة'**
  String get clubDashboardIncompleteProfilesLabel;

  /// No description provided for @clubDashboardPercentOfRosterLabel.
  ///
  /// In ar, this message translates to:
  /// **'{percent}% من الإجمالي'**
  String clubDashboardPercentOfRosterLabel(int percent);

  /// No description provided for @clubHomeViewPublicProfileLabel.
  ///
  /// In ar, this message translates to:
  /// **'عرض الملف العام'**
  String get clubHomeViewPublicProfileLabel;

  /// No description provided for @clubDashboardRecentPlayersTitle.
  ///
  /// In ar, this message translates to:
  /// **'أحدث اللاعبين المضافين'**
  String get clubDashboardRecentPlayersTitle;

  /// No description provided for @clubDashboardViewAllLabel.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get clubDashboardViewAllLabel;

  /// No description provided for @clubDashboardEmptyStateHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف أول لاعب لناديك للبدء'**
  String get clubDashboardEmptyStateHint;

  /// No description provided for @clubDashboardAddedOnLabel.
  ///
  /// In ar, this message translates to:
  /// **'أُضيف في {date}'**
  String clubDashboardAddedOnLabel(String date);

  /// No description provided for @clubDashboardFoundedLabel.
  ///
  /// In ar, this message translates to:
  /// **'تأسس عام {year}'**
  String clubDashboardFoundedLabel(int year);

  /// No description provided for @clubDashboardCompletenessTitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتمال الملفات الشخصية للاعبين'**
  String get clubDashboardCompletenessTitle;

  /// No description provided for @clubDashboardCompletenessMissingLabel.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر نقصًا: {fields}'**
  String clubDashboardCompletenessMissingLabel(String fields);

  /// No description provided for @clubDashboardAddPlayerDescription.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حساب لاعب وأضفه إلى قائمة ناديك.'**
  String get clubDashboardAddPlayerDescription;

  /// No description provided for @clubDashboardMyPlayersDescription.
  ///
  /// In ar, this message translates to:
  /// **'اعرض قائمة لاعبي ناديك وأدرها.'**
  String get clubDashboardMyPlayersDescription;

  /// No description provided for @clubDashboardFindPlayersDescription.
  ///
  /// In ar, this message translates to:
  /// **'اكتشف اللاعبين المتاحين على Sport X Hub.'**
  String get clubDashboardFindPlayersDescription;

  /// No description provided for @clubDashboardSavedPlayersDescription.
  ///
  /// In ar, this message translates to:
  /// **'راجع اللاعبين الذين قمت بحفظهم.'**
  String get clubDashboardSavedPlayersDescription;

  /// No description provided for @clubDashboardEditProfileDescription.
  ///
  /// In ar, this message translates to:
  /// **'حدّث الملف التعريفي العام لناديك.'**
  String get clubDashboardEditProfileDescription;

  /// No description provided for @clubPlayerEditTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل بيانات اللاعب'**
  String get clubPlayerEditTitle;

  /// No description provided for @clubPlayerViewAction.
  ///
  /// In ar, this message translates to:
  /// **'عرض الملف الشخصي'**
  String get clubPlayerViewAction;

  /// No description provided for @clubPlayerEditAction.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get clubPlayerEditAction;

  /// No description provided for @clubPlayerRemoveAction.
  ///
  /// In ar, this message translates to:
  /// **'إزالة من النادي'**
  String get clubPlayerRemoveAction;

  /// No description provided for @clubPlayerRemoveTitle.
  ///
  /// In ar, this message translates to:
  /// **'إزالة هذا اللاعب من ناديك؟'**
  String get clubPlayerRemoveTitle;

  /// No description provided for @clubPlayerRemoveContent.
  ///
  /// In ar, this message translates to:
  /// **'سيظل حساب اللاعب متاحًا وملفه الشخصي كما هو — سيفقد ناديك فقط صلاحية إدارته.'**
  String get clubPlayerRemoveContent;

  /// No description provided for @clubPlayerRemoveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إزالة'**
  String get clubPlayerRemoveConfirm;

  /// No description provided for @clubPlayerRemovedMessage.
  ///
  /// In ar, this message translates to:
  /// **'تمت إزالة اللاعب من ناديك.'**
  String get clubPlayerRemovedMessage;

  /// No description provided for @clubPlayersSearchLabel.
  ///
  /// In ar, this message translates to:
  /// **'البحث بالاسم أو رقم الهاتف'**
  String get clubPlayersSearchLabel;

  /// No description provided for @clubPlayersAnyFilterOption.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get clubPlayersAnyFilterOption;

  /// No description provided for @clubPlayersSportFilterLabel.
  ///
  /// In ar, this message translates to:
  /// **'الرياضة'**
  String get clubPlayersSportFilterLabel;

  /// No description provided for @clubPlayersPositionFilterLabel.
  ///
  /// In ar, this message translates to:
  /// **'المركز'**
  String get clubPlayersPositionFilterLabel;

  /// No description provided for @clubPlayersNoSearchResults.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد لاعبون مطابقون لهذا البحث/الفلاتر.'**
  String get clubPlayersNoSearchResults;

  /// No description provided for @clubPlayersTableColumnPlayer.
  ///
  /// In ar, this message translates to:
  /// **'اللاعب'**
  String get clubPlayersTableColumnPlayer;

  /// No description provided for @clubPlayersTableColumnActions.
  ///
  /// In ar, this message translates to:
  /// **'الإجراءات'**
  String get clubPlayersTableColumnActions;

  /// No description provided for @clubPlayersTableColumnCompleteness.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get clubPlayersTableColumnCompleteness;

  /// No description provided for @clubPlayerProfileCompleteLabel.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get clubPlayerProfileCompleteLabel;

  /// No description provided for @clubPlayerProfilePercentCompleteLabel.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل بنسبة {percent}%'**
  String clubPlayerProfilePercentCompleteLabel(int percent);

  /// No description provided for @minAgeLabel.
  ///
  /// In ar, this message translates to:
  /// **'أقل عمر'**
  String get minAgeLabel;

  /// No description provided for @maxAgeLabel.
  ///
  /// In ar, this message translates to:
  /// **'أكبر عمر'**
  String get maxAgeLabel;

  /// No description provided for @minHeightLabel.
  ///
  /// In ar, this message translates to:
  /// **'أقل طول (سم)'**
  String get minHeightLabel;

  /// No description provided for @maxHeightLabel.
  ///
  /// In ar, this message translates to:
  /// **'أكبر طول (سم)'**
  String get maxHeightLabel;

  /// No description provided for @applyFiltersLabel.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق الفلاتر'**
  String get applyFiltersLabel;

  /// No description provided for @noSavedPlayers.
  ///
  /// In ar, this message translates to:
  /// **'لم تحفظ أي لاعبين بعد.'**
  String get noSavedPlayers;

  /// No description provided for @settingsAccountGroup.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get settingsAccountGroup;

  /// No description provided for @settingsAppearanceGroup.
  ///
  /// In ar, this message translates to:
  /// **'المظهر واللغة'**
  String get settingsAppearanceGroup;

  /// No description provided for @signedInAs.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الدخول باسم {email}'**
  String signedInAs(String email);

  /// No description provided for @emailSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get emailSectionTitle;

  /// No description provided for @newEmailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني الجديد'**
  String get newEmailLabel;

  /// No description provided for @saveEmailLabel.
  ///
  /// In ar, this message translates to:
  /// **'حفظ البريد الإلكتروني'**
  String get saveEmailLabel;

  /// No description provided for @emailUpdatedMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث البريد الإلكتروني.'**
  String get emailUpdatedMessage;

  /// No description provided for @passwordUpdatedMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث كلمة المرور.'**
  String get passwordUpdatedMessage;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الحالية'**
  String get currentPasswordLabel;

  /// No description provided for @changePasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة المرور'**
  String get changePasswordLabel;

  /// No description provided for @playersClubsNavLabel.
  ///
  /// In ar, this message translates to:
  /// **'اللاعبون والأندية'**
  String get playersClubsNavLabel;

  /// No description provided for @usersTabLabel.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون'**
  String get usersTabLabel;

  /// No description provided for @deleteUserTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف المستخدم؟'**
  String get deleteUserTitle;

  /// No description provided for @deleteUserContent.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف {email} نهائيًا. لا يمكن التراجع عن هذا الإجراء.'**
  String deleteUserContent(String email);

  /// No description provided for @activateLabel.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get activateLabel;

  /// No description provided for @suspendLabel.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get suspendLabel;

  /// No description provided for @deleteUserTooltip.
  ///
  /// In ar, this message translates to:
  /// **'حذف المستخدم'**
  String get deleteUserTooltip;

  /// No description provided for @noUsersFound.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مستخدمون.'**
  String get noUsersFound;

  /// No description provided for @emailColumnLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get emailColumnLabel;

  /// No description provided for @roleColumnLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get roleColumnLabel;

  /// No description provided for @statusColumnLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get statusColumnLabel;

  /// No description provided for @actionsColumnLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإجراءات'**
  String get actionsColumnLabel;

  /// No description provided for @loadMoreLabel.
  ///
  /// In ar, this message translates to:
  /// **'تحميل المزيد'**
  String get loadMoreLabel;

  /// No description provided for @playersTabLabel.
  ///
  /// In ar, this message translates to:
  /// **'اللاعبون'**
  String get playersTabLabel;

  /// No description provided for @clubsTabLabel.
  ///
  /// In ar, this message translates to:
  /// **'الأندية'**
  String get clubsTabLabel;

  /// No description provided for @removePlayerProfileTitle.
  ///
  /// In ar, this message translates to:
  /// **'إزالة ملف اللاعب؟'**
  String get removePlayerProfileTitle;

  /// No description provided for @removePlayerProfileContent.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف ملف {name} نهائيًا، بما في ذلك صوره وفيديوهاته. لا يمكن التراجع عن هذا الإجراء.'**
  String removePlayerProfileContent(String name);

  /// No description provided for @thisPlayerFallback.
  ///
  /// In ar, this message translates to:
  /// **'هذا اللاعب'**
  String get thisPlayerFallback;

  /// No description provided for @removeProfileTooltip.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الملف الشخصي'**
  String get removeProfileTooltip;

  /// No description provided for @noPlayerProfilesFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ملفات لاعبين.'**
  String get noPlayerProfilesFound;

  /// No description provided for @nameColumnLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get nameColumnLabel;

  /// No description provided for @sportColumnLabel.
  ///
  /// In ar, this message translates to:
  /// **'الرياضة'**
  String get sportColumnLabel;

  /// No description provided for @positionColumnLabel.
  ///
  /// In ar, this message translates to:
  /// **'المركز'**
  String get positionColumnLabel;

  /// No description provided for @visibilityColumnLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإظهار'**
  String get visibilityColumnLabel;

  /// No description provided for @unnamedShort.
  ///
  /// In ar, this message translates to:
  /// **'بدون اسم'**
  String get unnamedShort;

  /// No description provided for @removeClubProfileTitle.
  ///
  /// In ar, this message translates to:
  /// **'إزالة ملف النادي؟'**
  String get removeClubProfileTitle;

  /// No description provided for @removeClubProfileContent.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف ملف {name} نهائيًا، بما في ذلك شعاره. لا يمكن التراجع عن هذا الإجراء.'**
  String removeClubProfileContent(String name);

  /// No description provided for @thisClubFallback.
  ///
  /// In ar, this message translates to:
  /// **'هذا النادي'**
  String get thisClubFallback;

  /// No description provided for @noClubProfilesFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ملفات أندية.'**
  String get noClubProfilesFound;

  /// No description provided for @playerProfileNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'هذا الملف الشخصي للاعب غير متاح.'**
  String get playerProfileNotAvailable;

  /// No description provided for @clubProfileNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'هذا الملف الشخصي للنادي غير متاح.'**
  String get clubProfileNotAvailable;

  /// No description provided for @dashboardWelcomeMessage.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بعودتك، {name}'**
  String dashboardWelcomeMessage(String name);

  /// No description provided for @dashboardWelcomeMessageNoName.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بعودتك'**
  String get dashboardWelcomeMessageNoName;

  /// No description provided for @dashboardProfileCompletionTitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتمال الملف الشخصي'**
  String get dashboardProfileCompletionTitle;

  /// No description provided for @dashboardProfileCompletePercent.
  ///
  /// In ar, this message translates to:
  /// **'اكتمل {percent}%'**
  String dashboardProfileCompletePercent(int percent);

  /// No description provided for @dashboardProfileCompleteMessage.
  ///
  /// In ar, this message translates to:
  /// **'ملفك الشخصي مكتمل — عمل رائع.'**
  String get dashboardProfileCompleteMessage;

  /// No description provided for @dashboardMissingFieldsHint.
  ///
  /// In ar, this message translates to:
  /// **'أكمل هذه البيانات لتظهر لعدد أكبر من الأندية:'**
  String get dashboardMissingFieldsHint;

  /// No description provided for @dashboardStatSavedByClubs.
  ///
  /// In ar, this message translates to:
  /// **'أندية حفظت ملفك'**
  String get dashboardStatSavedByClubs;

  /// No description provided for @dashboardStatMedia.
  ///
  /// In ar, this message translates to:
  /// **'عناصر الوسائط'**
  String get dashboardStatMedia;

  /// No description provided for @dashboardStatAchievements.
  ///
  /// In ar, this message translates to:
  /// **'الإنجازات'**
  String get dashboardStatAchievements;

  /// No description provided for @dashboardQuickActionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات سريعة'**
  String get dashboardQuickActionsTitle;

  /// No description provided for @dashboardMissingProfilePhoto.
  ///
  /// In ar, this message translates to:
  /// **'صورة الملف الشخصي'**
  String get dashboardMissingProfilePhoto;

  /// No description provided for @dashboardMissingContact.
  ///
  /// In ar, this message translates to:
  /// **'بيانات التواصل'**
  String get dashboardMissingContact;

  /// No description provided for @noSportsInfoYet.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم إضافة معلومات رياضية بعد.'**
  String get noSportsInfoYet;

  /// No description provided for @profileCompletionLabel.
  ///
  /// In ar, this message translates to:
  /// **'اكتمال الملف الشخصي: {percent}%'**
  String profileCompletionLabel(int percent);

  /// No description provided for @fieldsRemainingHint.
  ///
  /// In ar, this message translates to:
  /// **'{count} حقول متبقية لإكمال ملفك الشخصي.'**
  String fieldsRemainingHint(int count);

  /// No description provided for @profilePhotoSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'الصورة الشخصية'**
  String get profilePhotoSectionTitle;

  /// No description provided for @changePhotoLabel.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الصورة'**
  String get changePhotoLabel;

  /// No description provided for @uploadPhotoLabel.
  ///
  /// In ar, this message translates to:
  /// **'رفع صورة'**
  String get uploadPhotoLabel;

  /// No description provided for @saveAndViewProfileLabel.
  ///
  /// In ar, this message translates to:
  /// **'حفظ وعرض الملف الشخصي'**
  String get saveAndViewProfileLabel;

  /// No description provided for @profileSavedMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الملف الشخصي.'**
  String get profileSavedMessage;

  /// No description provided for @communityNavLabel.
  ///
  /// In ar, this message translates to:
  /// **'المجتمع'**
  String get communityNavLabel;

  /// No description provided for @communityEmptyState.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فيديوهات بعد لهذه الرياضة/الفئة.'**
  String get communityEmptyState;

  /// No description provided for @homeFeedEmptyState.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد نشاط بعد في رياضتك. أول فيديو أو صورة تتنشر هتظهر هنا.'**
  String get homeFeedEmptyState;

  /// No description provided for @homeFeedNewPostTooltip.
  ///
  /// In ar, this message translates to:
  /// **'نشر صورة'**
  String get homeFeedNewPostTooltip;

  /// No description provided for @homeFeedNewPostTitle.
  ///
  /// In ar, this message translates to:
  /// **'نشر صورة'**
  String get homeFeedNewPostTitle;

  /// No description provided for @homeFeedChooseImageLabel.
  ///
  /// In ar, this message translates to:
  /// **'اختر صورة'**
  String get homeFeedChooseImageLabel;

  /// No description provided for @homeFeedCaptionLabel.
  ///
  /// In ar, this message translates to:
  /// **'وصف (اختياري)'**
  String get homeFeedCaptionLabel;

  /// No description provided for @homeFeedSportLabel.
  ///
  /// In ar, this message translates to:
  /// **'الرياضة'**
  String get homeFeedSportLabel;

  /// No description provided for @homeFeedPostButtonLabel.
  ///
  /// In ar, this message translates to:
  /// **'نشر'**
  String get homeFeedPostButtonLabel;

  /// No description provided for @homeFeedPostMissingImageError.
  ///
  /// In ar, this message translates to:
  /// **'اختر صورة قبل النشر.'**
  String get homeFeedPostMissingImageError;

  /// No description provided for @homeFeedPostMissingSportError.
  ///
  /// In ar, this message translates to:
  /// **'اختر الرياضة قبل النشر.'**
  String get homeFeedPostMissingSportError;

  /// No description provided for @homeFeedPostTooLargeError.
  ///
  /// In ar, this message translates to:
  /// **'حجم هذه الصورة أكبر من الحد المسموح به وهو {limit} ميجابايت. اختر ملفًا أصغر.'**
  String homeFeedPostTooLargeError(int limit);

  /// No description provided for @homeFeedPostSuccessMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم النشر بنجاح.'**
  String get homeFeedPostSuccessMessage;

  /// No description provided for @homeFeedComposerPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'بماذا تريد مشاركة النادي؟'**
  String get homeFeedComposerPlaceholder;

  /// No description provided for @homeFeedCreateFirstPostCta.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ أول منشور'**
  String get homeFeedCreateFirstPostCta;

  /// No description provided for @homeFeedTabAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get homeFeedTabAll;

  /// No description provided for @homeFeedTabPhotos.
  ///
  /// In ar, this message translates to:
  /// **'الصور'**
  String get homeFeedTabPhotos;

  /// No description provided for @homeFeedTabVideos.
  ///
  /// In ar, this message translates to:
  /// **'الفيديوهات'**
  String get homeFeedTabVideos;

  /// No description provided for @homeFeedFilteredEmptyState.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد شيء من هذا النوع بعد.'**
  String get homeFeedFilteredEmptyState;

  /// No description provided for @feedSharePostLabel.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get feedSharePostLabel;

  /// No description provided for @feedSharePostLinkCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ رابط المنشور'**
  String get feedSharePostLinkCopied;

  /// No description provided for @feedLikeTooltip.
  ///
  /// In ar, this message translates to:
  /// **'إعجاب'**
  String get feedLikeTooltip;

  /// No description provided for @feedUnlikeTooltip.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الإعجاب'**
  String get feedUnlikeTooltip;

  /// No description provided for @feedCommentsTooltip.
  ///
  /// In ar, this message translates to:
  /// **'التعليقات'**
  String get feedCommentsTooltip;

  /// No description provided for @feedLikeActionLabel.
  ///
  /// In ar, this message translates to:
  /// **'أعجبني'**
  String get feedLikeActionLabel;

  /// No description provided for @feedCommentActionLabel.
  ///
  /// In ar, this message translates to:
  /// **'تعليق'**
  String get feedCommentActionLabel;

  /// No description provided for @feedLikesCountLabel.
  ///
  /// In ar, this message translates to:
  /// **'{count} إعجاب'**
  String feedLikesCountLabel(int count);

  /// No description provided for @feedCommentsCountLabel.
  ///
  /// In ar, this message translates to:
  /// **'{count} تعليق'**
  String feedCommentsCountLabel(int count);

  /// No description provided for @feedCaptionShowMoreLabel.
  ///
  /// In ar, this message translates to:
  /// **'عرض المزيد'**
  String get feedCaptionShowMoreLabel;

  /// No description provided for @feedCaptionShowLessLabel.
  ///
  /// In ar, this message translates to:
  /// **'عرض أقل'**
  String get feedCaptionShowLessLabel;

  /// No description provided for @feedPostOptionsTooltip.
  ///
  /// In ar, this message translates to:
  /// **'خيارات المنشور'**
  String get feedPostOptionsTooltip;

  /// No description provided for @feedCopyPostLinkLabel.
  ///
  /// In ar, this message translates to:
  /// **'نسخ رابط المنشور'**
  String get feedCopyPostLinkLabel;

  /// No description provided for @feedPlayVideoLabel.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل الفيديو'**
  String get feedPlayVideoLabel;

  /// No description provided for @moreNavLabel.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get moreNavLabel;

  /// No description provided for @allCategoryLabel.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get allCategoryLabel;

  /// No description provided for @skillsSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'المهارات'**
  String get skillsSectionTitle;

  /// No description provided for @traitsTitle.
  ///
  /// In ar, this message translates to:
  /// **'السمات'**
  String get traitsTitle;

  /// No description provided for @traitsCaption.
  ///
  /// In ar, this message translates to:
  /// **'بتزيد كل ما ترفع فيديوهات أكتر في المهارة دي — والفيديوهات اللي بتاخد لايكات أكتر بتزيد أسرع.'**
  String get traitsCaption;

  /// No description provided for @traitsFootballOnlyMessage.
  ///
  /// In ar, this message translates to:
  /// **'السمات متاحة حاليًا للاعبين كرة القدم بس.'**
  String get traitsFootballOnlyMessage;

  /// No description provided for @setSportFirstMessage.
  ///
  /// In ar, this message translates to:
  /// **'حدّد رياضتك في بروفايلك عشان تقدر تشوف الصفحة دي.'**
  String get setSportFirstMessage;

  /// No description provided for @videosEmptyState.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فيديوهات بعد في هذه الفئة.'**
  String get videosEmptyState;

  /// No description provided for @videoDeleteTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الفيديو؟'**
  String get videoDeleteTitle;

  /// No description provided for @videoDeleteContent.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن التراجع عن هذا الإجراء.'**
  String get videoDeleteContent;

  /// No description provided for @videoMakePrivate.
  ///
  /// In ar, this message translates to:
  /// **'جعله خاصًا'**
  String get videoMakePrivate;

  /// No description provided for @videoMakePublic.
  ///
  /// In ar, this message translates to:
  /// **'جعله عامًا'**
  String get videoMakePublic;

  /// No description provided for @videoEditTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'تعديل العنوان'**
  String get videoEditTitleLabel;

  /// No description provided for @videoUploadTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة فيديو'**
  String get videoUploadTitle;

  /// No description provided for @videoChooseFileLabel.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملف فيديو'**
  String get videoChooseFileLabel;

  /// No description provided for @videoTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الفيديو (اختياري)'**
  String get videoTitleLabel;

  /// No description provided for @videoCategoryLabel.
  ///
  /// In ar, this message translates to:
  /// **'الفئة'**
  String get videoCategoryLabel;

  /// No description provided for @videoCategoriesLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الفئات.'**
  String get videoCategoriesLoadError;

  /// No description provided for @videoVisibilityPublic.
  ///
  /// In ar, this message translates to:
  /// **'عام'**
  String get videoVisibilityPublic;

  /// No description provided for @videoVisibilityPrivate.
  ///
  /// In ar, this message translates to:
  /// **'خاص'**
  String get videoVisibilityPrivate;

  /// No description provided for @videoUploadButtonLabel.
  ///
  /// In ar, this message translates to:
  /// **'رفع'**
  String get videoUploadButtonLabel;

  /// No description provided for @videoUploadMissingFieldsError.
  ///
  /// In ar, this message translates to:
  /// **'اختر فيديو وفئة قبل الرفع.'**
  String get videoUploadMissingFieldsError;

  /// No description provided for @videoUploadTooLargeError.
  ///
  /// In ar, this message translates to:
  /// **'حجم هذا الفيديو أكبر من الحد المسموح به وهو {limit} ميجابايت. اختر ملفًا أصغر.'**
  String videoUploadTooLargeError(int limit);

  /// No description provided for @videoUploadTimeoutError.
  ///
  /// In ar, this message translates to:
  /// **'استغرق الرفع وقتًا طويلاً وانتهت مهلته. تحقق من اتصالك وحاول مرة أخرى.'**
  String get videoUploadTimeoutError;

  /// No description provided for @videoPlaybackErrorMessage.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تشغيل هذا الفيديو.'**
  String get videoPlaybackErrorMessage;

  /// No description provided for @videoPlaybackRetryLabel.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get videoPlaybackRetryLabel;

  /// No description provided for @videoPlaybackMuteTooltip.
  ///
  /// In ar, this message translates to:
  /// **'كتم الصوت'**
  String get videoPlaybackMuteTooltip;

  /// No description provided for @videoPlaybackUnmuteTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل الصوت'**
  String get videoPlaybackUnmuteTooltip;

  /// No description provided for @videoCommentsTitle.
  ///
  /// In ar, this message translates to:
  /// **'التعليقات'**
  String get videoCommentsTitle;

  /// No description provided for @videoCommentsEmptyState.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تعليقات بعد. كن أول من يعلق.'**
  String get videoCommentsEmptyState;

  /// No description provided for @videoCommentHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف تعليقًا…'**
  String get videoCommentHint;

  /// No description provided for @videoCommentsLoadMore.
  ///
  /// In ar, this message translates to:
  /// **'تحميل المزيد'**
  String get videoCommentsLoadMore;

  /// No description provided for @videoCommentDeleteTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف التعليق؟'**
  String get videoCommentDeleteTitle;

  /// No description provided for @videoCommentDeleteContent.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن التراجع عن هذا الإجراء.'**
  String get videoCommentDeleteContent;

  /// No description provided for @pageOfPagesLabel.
  ///
  /// In ar, this message translates to:
  /// **'صفحة {page} من {lastPage}'**
  String pageOfPagesLabel(int page, int lastPage);

  /// No description provided for @communityActivityLabel.
  ///
  /// In ar, this message translates to:
  /// **'{total} فيديو في {sport}'**
  String communityActivityLabel(int total, String sport);

  /// No description provided for @invitationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدعوات'**
  String get invitationsTitle;

  /// No description provided for @invitationsReceivedTab.
  ///
  /// In ar, this message translates to:
  /// **'الواردة'**
  String get invitationsReceivedTab;

  /// No description provided for @invitationsSentTab.
  ///
  /// In ar, this message translates to:
  /// **'المُرسَلة'**
  String get invitationsSentTab;

  /// No description provided for @invitationsEmptyReceived.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد دعوات بعد. طلبات الانضمام إلى ناديك ستظهر هنا.'**
  String get invitationsEmptyReceived;

  /// No description provided for @invitationsEmptySent.
  ///
  /// In ar, this message translates to:
  /// **'لم تُرسل دعوة لأي لاعب بعد.'**
  String get invitationsEmptySent;

  /// No description provided for @invitationStatusPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get invitationStatusPending;

  /// No description provided for @invitationStatusAccepted.
  ///
  /// In ar, this message translates to:
  /// **'مقبولة'**
  String get invitationStatusAccepted;

  /// No description provided for @invitationStatusRejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوضة'**
  String get invitationStatusRejected;

  /// No description provided for @invitationStatusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغاة'**
  String get invitationStatusCancelled;

  /// No description provided for @invitationStatusExpired.
  ///
  /// In ar, this message translates to:
  /// **'منتهية'**
  String get invitationStatusExpired;

  /// No description provided for @invitationAcceptLabel.
  ///
  /// In ar, this message translates to:
  /// **'قبول'**
  String get invitationAcceptLabel;

  /// No description provided for @invitationRejectLabel.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get invitationRejectLabel;

  /// No description provided for @invitationCancelInvitationLabel.
  ///
  /// In ar, this message translates to:
  /// **'سحب'**
  String get invitationCancelInvitationLabel;

  /// No description provided for @invitationViewProfileLabel.
  ///
  /// In ar, this message translates to:
  /// **'عرض الملف'**
  String get invitationViewProfileLabel;

  /// No description provided for @invitationRejectConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'رفض هذا الطلب؟'**
  String get invitationRejectConfirmTitle;

  /// No description provided for @invitationRejectConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن التراجع عن ذلك. يمكنه إرسال طلب جديد لاحقًا.'**
  String get invitationRejectConfirmBody;

  /// No description provided for @invitationCancelConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'سحب هذه الدعوة؟'**
  String get invitationCancelConfirmTitle;

  /// No description provided for @invitationCancelConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن التراجع عن ذلك. يمكنك دعوته مرة أخرى لاحقًا.'**
  String get invitationCancelConfirmBody;

  /// No description provided for @invitationAcceptedFeedback.
  ///
  /// In ar, this message translates to:
  /// **'تم القبول. انضم اللاعب إلى ناديك.'**
  String get invitationAcceptedFeedback;

  /// No description provided for @invitationRejectedFeedback.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض الطلب.'**
  String get invitationRejectedFeedback;

  /// No description provided for @invitationCancelledFeedback.
  ///
  /// In ar, this message translates to:
  /// **'تم سحب الدعوة.'**
  String get invitationCancelledFeedback;

  /// No description provided for @invitationSentFeedback.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال الدعوة.'**
  String get invitationSentFeedback;

  /// No description provided for @invitationExpiresOn.
  ///
  /// In ar, this message translates to:
  /// **'تنتهي في {date}'**
  String invitationExpiresOn(String date);

  /// No description provided for @invitePlayerLabel.
  ///
  /// In ar, this message translates to:
  /// **'دعوة إلى النادي'**
  String get invitePlayerLabel;

  /// No description provided for @invitePlayerTitle.
  ///
  /// In ar, this message translates to:
  /// **'دعوة لاعب'**
  String get invitePlayerTitle;

  /// No description provided for @invitePlayerBody.
  ///
  /// In ar, this message translates to:
  /// **'ادعُ {name} للانضمام إلى ناديك. يمكنه القبول أو الرفض.'**
  String invitePlayerBody(String name);

  /// No description provided for @inviteLabel.
  ///
  /// In ar, this message translates to:
  /// **'دعوة'**
  String get inviteLabel;

  /// No description provided for @invitationMessageLabel.
  ///
  /// In ar, this message translates to:
  /// **'رسالة (اختياري)'**
  String get invitationMessageLabel;

  /// No description provided for @invitationMessageHint.
  ///
  /// In ar, this message translates to:
  /// **'اذكر سبب رغبتك في انضمامه.'**
  String get invitationMessageHint;

  /// No description provided for @inviteByCodeTitle.
  ///
  /// In ar, this message translates to:
  /// **'دعوة بالكود'**
  String get inviteByCodeTitle;

  /// No description provided for @inviteByCodeLookUpLabel.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get inviteByCodeLookUpLabel;

  /// No description provided for @playerCodeLabel.
  ///
  /// In ar, this message translates to:
  /// **'كود اللاعب'**
  String get playerCodeLabel;

  /// No description provided for @playerCodeHint.
  ///
  /// In ar, this message translates to:
  /// **'PLY-000123'**
  String get playerCodeHint;

  /// No description provided for @playerCodeNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد لاعب عام بهذا الكود.'**
  String get playerCodeNotFound;

  /// No description provided for @clubCodeLabel.
  ///
  /// In ar, this message translates to:
  /// **'كود النادي'**
  String get clubCodeLabel;

  /// No description provided for @copyCodeTooltip.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الكود'**
  String get copyCodeTooltip;

  /// No description provided for @publicCodeCopiedFeedback.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الكود'**
  String get publicCodeCopiedFeedback;

  /// No description provided for @clubDashboardInvitationsDescription.
  ///
  /// In ar, this message translates to:
  /// **'راجع طلبات الانضمام والدعوات التي أرسلتها.'**
  String get clubDashboardInvitationsDescription;

  /// No description provided for @playerInvitationsEmptyReceived.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد دعوات بعد. الأندية التي تدعوك ستظهر هنا.'**
  String get playerInvitationsEmptyReceived;

  /// No description provided for @playerInvitationsEmptySent.
  ///
  /// In ar, this message translates to:
  /// **'لم تطلب الانضمام إلى أي نادٍ بعد.'**
  String get playerInvitationsEmptySent;

  /// No description provided for @requestToJoinLabel.
  ///
  /// In ar, this message translates to:
  /// **'طلب انضمام'**
  String get requestToJoinLabel;

  /// No description provided for @requestToJoinTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب الانضمام إلى النادي'**
  String get requestToJoinTitle;

  /// No description provided for @requestToJoinBody.
  ///
  /// In ar, this message translates to:
  /// **'اطلب من {name} ضمّك إلى الفريق. يمكنه القبول أو الرفض.'**
  String requestToJoinBody(String name);

  /// No description provided for @joinRequestSentFeedback.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال الطلب.'**
  String get joinRequestSentFeedback;

  /// No description provided for @joinByCodeTitle.
  ///
  /// In ar, this message translates to:
  /// **'الانضمام بالكود'**
  String get joinByCodeTitle;

  /// No description provided for @clubCodeHint.
  ///
  /// In ar, this message translates to:
  /// **'CLB-000123'**
  String get clubCodeHint;

  /// No description provided for @clubCodeNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد نادٍ بهذا الكود.'**
  String get clubCodeNotFound;

  /// No description provided for @playerCodeShareHint.
  ///
  /// In ar, this message translates to:
  /// **'شاركه مع الأندية'**
  String get playerCodeShareHint;

  /// No description provided for @membershipJoinedOn.
  ///
  /// In ar, this message translates to:
  /// **'انضم في {date}'**
  String membershipJoinedOn(String date);

  /// No description provided for @clubMembersTitle.
  ///
  /// In ar, this message translates to:
  /// **'اللاعبون ({count})'**
  String clubMembersTitle(int count);

  /// No description provided for @notificationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد شيء بعد. عندما يراسلك نادٍ أو لاعب سيظهر هنا.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsUnreadOnlyLabel.
  ///
  /// In ar, this message translates to:
  /// **'غير المقروءة فقط'**
  String get notificationsUnreadOnlyLabel;

  /// No description provided for @notificationsMarkAllReadLabel.
  ///
  /// In ar, this message translates to:
  /// **'تعليم الكل كمقروء'**
  String get notificationsMarkAllReadLabel;

  /// No description provided for @notificationsUnreadLabel.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one{إشعار واحد غير مقروء} two{إشعاران غير مقروءين} few{{count} إشعارات غير مقروءة} many{{count} إشعارًا غير مقروء} other{{count} إشعار غير مقروء}}'**
  String notificationsUnreadLabel(int count);

  /// No description provided for @notificationInvitationFromClub.
  ///
  /// In ar, this message translates to:
  /// **'{name} دعاك للانضمام إلى النادي.'**
  String notificationInvitationFromClub(String name);

  /// No description provided for @notificationJoinRequestFromPlayer.
  ///
  /// In ar, this message translates to:
  /// **'{name} طلب الانضمام إلى ناديك.'**
  String notificationJoinRequestFromPlayer(String name);

  /// No description provided for @notificationInvitationAccepted.
  ///
  /// In ar, this message translates to:
  /// **'{name} قَبِل دعوتك.'**
  String notificationInvitationAccepted(String name);

  /// No description provided for @notificationInvitationRejected.
  ///
  /// In ar, this message translates to:
  /// **'{name} رفض دعوتك.'**
  String notificationInvitationRejected(String name);

  /// No description provided for @genericErrorMessage.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ ما. الرجاء المحاولة مرة أخرى.'**
  String get genericErrorMessage;

  /// No description provided for @retryButtonLabel.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retryButtonLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
