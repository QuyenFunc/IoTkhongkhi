/// Generated file. Do not edit.
///
/// Original file: lib/l10n/app_vi.arb
/// To regenerate, run: `flutter gen-l10n`
///
/// Localization for IoT Air Quality Monitor App

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_vi.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[Locale('vi')];

  /// Tiêu đề ứng dụng
  ///
  /// In vi, this message translates to:
  /// **'Giám Sát Chất Lượng Không Khí IoT'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get login;

  /// No description provided for @register.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mật khẩu'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại mật khẩu'**
  String get resetPassword;

  /// No description provided for @signInWithGoogle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập với Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithFacebook.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập với Facebook'**
  String get signInWithFacebook;

  /// No description provided for @signInWithApple.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập với Apple'**
  String get signInWithApple;

  /// No description provided for @dashboard.
  ///
  /// In vi, this message translates to:
  /// **'Bảng điều khiển'**
  String get dashboard;

  /// No description provided for @devices.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị'**
  String get devices;

  /// No description provided for @monitoring.
  ///
  /// In vi, this message translates to:
  /// **'Giám sát'**
  String get monitoring;

  /// No description provided for @alerts.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo'**
  String get alerts;

  /// No description provided for @settings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ'**
  String get profile;

  /// No description provided for @addDevice.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thiết bị'**
  String get addDevice;

  /// No description provided for @scanQRCode.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR'**
  String get scanQRCode;

  /// No description provided for @deviceName.
  ///
  /// In vi, this message translates to:
  /// **'Tên thiết bị'**
  String get deviceName;

  /// No description provided for @deviceLocation.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí thiết bị'**
  String get deviceLocation;

  /// No description provided for @deviceStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái thiết bị'**
  String get deviceStatus;

  /// No description provided for @online.
  ///
  /// In vi, this message translates to:
  /// **'Trực tuyến'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In vi, this message translates to:
  /// **'Ngoại tuyến'**
  String get offline;

  /// No description provided for @lastUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật cuối'**
  String get lastUpdate;

  /// No description provided for @temperature.
  ///
  /// In vi, this message translates to:
  /// **'Nhiệt độ'**
  String get temperature;

  /// No description provided for @humidity.
  ///
  /// In vi, this message translates to:
  /// **'Độ ẩm'**
  String get humidity;

  /// No description provided for @airQuality.
  ///
  /// In vi, this message translates to:
  /// **'Chất lượng không khí'**
  String get airQuality;

  /// No description provided for @pressure.
  ///
  /// In vi, this message translates to:
  /// **'Áp suất'**
  String get pressure;

  /// No description provided for @hour1.
  ///
  /// In vi, this message translates to:
  /// **'1 giờ'**
  String get hour1;

  /// No description provided for @hours24.
  ///
  /// In vi, this message translates to:
  /// **'24 giờ'**
  String get hours24;

  /// No description provided for @days7.
  ///
  /// In vi, this message translates to:
  /// **'7 ngày'**
  String get days7;

  /// No description provided for @days30.
  ///
  /// In vi, this message translates to:
  /// **'30 ngày'**
  String get days30;

  /// No description provided for @export.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu'**
  String get export;

  /// No description provided for @share.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get share;

  /// No description provided for @analytics.
  ///
  /// In vi, this message translates to:
  /// **'Phân tích'**
  String get analytics;

  /// No description provided for @reports.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo'**
  String get reports;

  /// No description provided for @thresholdSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt ngưỡng'**
  String get thresholdSettings;

  /// No description provided for @notifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get notifications;

  /// No description provided for @connectivity.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối'**
  String get connectivity;

  /// No description provided for @theme.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get language;

  /// No description provided for @lightMode.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ sáng'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ tối'**
  String get darkMode;

  /// No description provided for @systemMode.
  ///
  /// In vi, this message translates to:
  /// **'Theo hệ thống'**
  String get systemMode;

  /// No description provided for @save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa'**
  String get edit;

  /// No description provided for @refresh.
  ///
  /// In vi, this message translates to:
  /// **'Làm mới'**
  String get refresh;

  /// No description provided for @loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi'**
  String get error;

  /// No description provided for @success.
  ///
  /// In vi, this message translates to:
  /// **'Thành công'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin'**
  String get info;

  /// No description provided for @noDevicesFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy thiết bị nào'**
  String get noDevicesFound;

  /// No description provided for @noDataAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Không có dữ liệu'**
  String get noDataAvailable;

  /// No description provided for @connectionError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi kết nối'**
  String get connectionError;

  /// No description provided for @invalidCredentials.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin đăng nhập không hợp lệ'**
  String get invalidCredentials;

  /// No description provided for @networkError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi mạng'**
  String get networkError;

  /// No description provided for @confirmDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận xóa'**
  String get confirmDelete;

  /// No description provided for @deleteDeviceMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn xóa thiết bị này?'**
  String get deleteDeviceMessage;

  /// No description provided for @yes.
  ///
  /// In vi, this message translates to:
  /// **'Có'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In vi, this message translates to:
  /// **'Không'**
  String get no;
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
      <String>['vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
