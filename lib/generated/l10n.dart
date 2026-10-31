import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_ar.dart';
import 'l10n_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
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
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

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

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ASEC'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Watch. Learn. Test.'**
  String get appTagline;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get roleTeacher;

  /// No description provided for @roleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get roleStudent;

  /// No description provided for @roleParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get roleParent;

  /// No description provided for @typeVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get typeVideo;

  /// No description provided for @typePdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get typePdf;

  /// No description provided for @typeImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get typeImage;

  /// No description provided for @typeExam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get typeExam;

  /// No description provided for @typeQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get typeQuiz;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @grades.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get grades;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @permissionPublishDesc.
  ///
  /// In en, this message translates to:
  /// **'Can add, edit and delete {type} content'**
  String permissionPublishDesc(String type);

  /// No description provided for @permissionAttendanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Can take attendance for their sections'**
  String get permissionAttendanceDesc;

  /// No description provided for @permissionGradesDesc.
  ///
  /// In en, this message translates to:
  /// **'Can review and grade student results'**
  String get permissionGradesDesc;

  /// No description provided for @permissionMessagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Can message parents'**
  String get permissionMessagesDesc;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @primaryColor.
  ///
  /// In en, this message translates to:
  /// **'Primary colour'**
  String get primaryColor;

  /// No description provided for @secondaryColor.
  ///
  /// In en, this message translates to:
  /// **'Secondary colour'**
  String get secondaryColor;

  /// No description provided for @colors.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get colors;

  /// No description provided for @errWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. Please try again.'**
  String get errWrongCredentials;

  /// No description provided for @errInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That does not look like a valid email address.'**
  String get errInvalidEmail;

  /// No description provided for @errEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email.'**
  String get errEmailInUse;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters for the password.'**
  String get errWeakPassword;

  /// No description provided for @errUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get errUserDisabled;

  /// No description provided for @errTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a minute and try again.'**
  String get errTooManyRequests;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get errNetwork;

  /// No description provided for @errProfileMissing.
  ///
  /// In en, this message translates to:
  /// **'This account has no profile. Ask the admin to create it from the console.'**
  String get errProfileMissing;

  /// No description provided for @errAccountInactive.
  ///
  /// In en, this message translates to:
  /// **'This account is switched off. Contact the center.'**
  String get errAccountInactive;

  /// No description provided for @errFirestoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Signed in, but the database did not answer. Check that Firestore is created in your Firebase project.'**
  String get errFirestoreUnavailable;

  /// No description provided for @errRulesDenied.
  ///
  /// In en, this message translates to:
  /// **'The database refused the request. Deploy the Firestore rules: firebase deploy --only firestore:rules'**
  String get errRulesDenied;

  /// No description provided for @errSetupAlreadyDone.
  ///
  /// In en, this message translates to:
  /// **'Setup is already done on this project. Sign in instead.'**
  String get errSetupAlreadyDone;

  /// No description provided for @errNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Firebase is not configured yet. Run flutterfire configure.'**
  String get errNotConfigured;

  /// No description provided for @errUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errUnknown;

  /// No description provided for @failPermission.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission for this. Ask the admin, or deploy the Firestore rules.'**
  String get failPermission;

  /// No description provided for @failIndex.
  ///
  /// In en, this message translates to:
  /// **'This list needs a database index. Deploy firestore.indexes.json.'**
  String get failIndex;

  /// No description provided for @failNotFound.
  ///
  /// In en, this message translates to:
  /// **'It no longer exists.'**
  String get failNotFound;

  /// No description provided for @failUpload.
  ///
  /// In en, this message translates to:
  /// **'The upload did not finish. Try again.'**
  String get failUpload;

  /// No description provided for @typeVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get typeVideos;

  /// No description provided for @typePdfs.
  ///
  /// In en, this message translates to:
  /// **'PDFs'**
  String get typePdfs;

  /// No description provided for @typeImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get typeImages;

  /// No description provided for @typeExams.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get typeExams;

  /// No description provided for @typeQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get typeQuizzes;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @lateStatus.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get lateStatus;

  /// No description provided for @excused.
  ///
  /// In en, this message translates to:
  /// **'Excused'**
  String get excused;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'If that email has an account, a reset link is on its way.'**
  String get resetEmailSent;

  /// No description provided for @consoleHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your whole center, one screen.'**
  String get consoleHeadline;

  /// No description provided for @consoleSubheadline.
  ///
  /// In en, this message translates to:
  /// **'Lessons, exams, attendance and parents — organised.'**
  String get consoleSubheadline;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get enterName;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your center'**
  String get setupTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @setupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create the first admin account. This works once per project.'**
  String get setupSubtitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with the account the center gave you.'**
  String get signInSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Amr Mesbah'**
  String get fullNameHint;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @createAdminAccount.
  ///
  /// In en, this message translates to:
  /// **'Create admin account'**
  String get createAdminAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @setupCenter.
  ///
  /// In en, this message translates to:
  /// **'First time? Set up the center'**
  String get setupCenter;

  /// No description provided for @consoleAccountsHint.
  ///
  /// In en, this message translates to:
  /// **'Admins and teachers sign in here. Students and parents use the phone app.'**
  String get consoleAccountsHint;

  /// No description provided for @tabletAccountsHint.
  ///
  /// In en, this message translates to:
  /// **'Everyone signs in here — students, parents, teachers and admins.'**
  String get tabletAccountsHint;

  /// No description provided for @mobileAccountsHint.
  ///
  /// In en, this message translates to:
  /// **'Students and parents sign in here. Teachers use a tablet or computer.'**
  String get mobileAccountsHint;

  /// No description provided for @wrongDeviceMobileTitle.
  ///
  /// In en, this message translates to:
  /// **'Open this account on a phone or tablet'**
  String get wrongDeviceMobileTitle;

  /// No description provided for @wrongDeviceDesktopTitle.
  ///
  /// In en, this message translates to:
  /// **'Open this account on a tablet or computer'**
  String get wrongDeviceDesktopTitle;

  /// No description provided for @wrongDeviceMobileBody.
  ///
  /// In en, this message translates to:
  /// **'{role} accounts use the Mostakbal app on a phone or tablet. Install it there and sign in with the same email.'**
  String wrongDeviceMobileBody(String role);

  /// No description provided for @wrongDeviceDesktopBody.
  ///
  /// In en, this message translates to:
  /// **'{role} accounts use the console on a tablet or computer. Open Mostakbal there and sign in with the same email.'**
  String wrongDeviceDesktopBody(String role);

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgainToExit;

  /// No description provided for @debugPreviewAnyway.
  ///
  /// In en, this message translates to:
  /// **'Preview anyway (debug build)'**
  String get debugPreviewAnyway;

  /// No description provided for @debugPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Only in debug builds. Reset it from Settings.'**
  String get debugPreviewHint;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @teachers.
  ///
  /// In en, this message translates to:
  /// **'Teachers'**
  String get teachers;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get students;

  /// No description provided for @parents.
  ///
  /// In en, this message translates to:
  /// **'Parents'**
  String get parents;

  /// No description provided for @sections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get sections;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @myStudents.
  ///
  /// In en, this message translates to:
  /// **'My students'**
  String get myStudents;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @signOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutQuestion;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'You will need your email and password to come back.'**
  String get signOutBody;

  /// No description provided for @helloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloName(String name);

  /// No description provided for @overviewAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Here is your center today.'**
  String get overviewAdminSub;

  /// No description provided for @overviewTeacherSub.
  ///
  /// In en, this message translates to:
  /// **'Your classes, content and results at a glance.'**
  String get overviewTeacherSub;

  /// No description provided for @contentLibrary.
  ///
  /// In en, this message translates to:
  /// **'Content library'**
  String get contentLibrary;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(String count);

  /// No description provided for @recentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get recentlyAdded;

  /// No description provided for @noContentYet.
  ///
  /// In en, this message translates to:
  /// **'No content yet.'**
  String get noContentYet;

  /// No description provided for @demoFailed.
  ///
  /// In en, this message translates to:
  /// **'Demo data could not be written'**
  String get demoFailed;

  /// No description provided for @demoTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo data'**
  String get demoTitle;

  /// No description provided for @demoBody.
  ///
  /// In en, this message translates to:
  /// **'Fills every section except Videos with sample data: members with course access, quizzes, a certificate exam for each of your real courses, results, CVs and website requests. Videos stay exactly as they are — they come from your Drive folder. Every demo account signs in with the password {password}.'**
  String demoBody(String password);

  /// No description provided for @removeDemo.
  ///
  /// In en, this message translates to:
  /// **'Remove demo data'**
  String get removeDemo;

  /// No description provided for @removeDemoQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove all demo data?'**
  String get removeDemoQuestion;

  /// No description provided for @removeDemoBody.
  ///
  /// In en, this message translates to:
  /// **'Deletes every member, video, quiz, result and CV marked as demo. Anything you or your members created is not touched.'**
  String get removeDemoBody;

  /// No description provided for @demoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Demo data removed'**
  String get demoRemoved;

  /// No description provided for @fillDemo.
  ///
  /// In en, this message translates to:
  /// **'Fill demo data'**
  String get fillDemo;

  /// No description provided for @demoFilled.
  ///
  /// In en, this message translates to:
  /// **'Demo data is ready — sign out and try {email}'**
  String demoFilled(String email);

  /// No description provided for @demoCounts.
  ///
  /// In en, this message translates to:
  /// **'{members} members · {quizzes} quizzes · {certificates} certificate exams · {results} results · {cvs} CVs · {inbox} website requests'**
  String demoCounts(
    String members,
    String quizzes,
    String certificates,
    String results,
    String cvs,
    String inbox,
  );

  /// No description provided for @demoAccountsHint.
  ///
  /// In en, this message translates to:
  /// **'Demo accounts are real sign-ins on a domain that receives no mail. Removing the data leaves them empty; filling again adopts them back.'**
  String get demoAccountsHint;

  /// No description provided for @myContent.
  ///
  /// In en, this message translates to:
  /// **'My content'**
  String get myContent;

  /// No description provided for @resultsReceived.
  ///
  /// In en, this message translates to:
  /// **'Results received'**
  String get resultsReceived;

  /// No description provided for @yourPermissions.
  ///
  /// In en, this message translates to:
  /// **'What you can do'**
  String get yourPermissions;

  /// No description provided for @yourPermissionsSub.
  ///
  /// In en, this message translates to:
  /// **'Set by the admin. Ask them if something you need is missing.'**
  String get yourPermissionsSub;

  /// No description provided for @nobodyFound.
  ///
  /// In en, this message translates to:
  /// **'Nobody matches that search.'**
  String get nobodyFound;

  /// No description provided for @addTeacher.
  ///
  /// In en, this message translates to:
  /// **'Add teacher'**
  String get addTeacher;

  /// No description provided for @editTeacher.
  ///
  /// In en, this message translates to:
  /// **'Edit teacher'**
  String get editTeacher;

  /// No description provided for @addStudent.
  ///
  /// In en, this message translates to:
  /// **'Add student'**
  String get addStudent;

  /// No description provided for @editStudent.
  ///
  /// In en, this message translates to:
  /// **'Edit student'**
  String get editStudent;

  /// No description provided for @addParent.
  ///
  /// In en, this message translates to:
  /// **'Add parent'**
  String get addParent;

  /// No description provided for @editParent.
  ///
  /// In en, this message translates to:
  /// **'Edit parent'**
  String get editParent;

  /// No description provided for @accountCreateHint.
  ///
  /// In en, this message translates to:
  /// **'They sign in with this email and password.'**
  String get accountCreateHint;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @passwordShareHint.
  ///
  /// In en, this message translates to:
  /// **'Share it with them privately. At least 6 characters.'**
  String get passwordShareHint;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @subjectHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mathematics'**
  String get subjectHint;

  /// No description provided for @teachesSections.
  ///
  /// In en, this message translates to:
  /// **'Teaches these sections'**
  String get teachesSections;

  /// No description provided for @noSectionsYet.
  ///
  /// In en, this message translates to:
  /// **'No sections yet — add them in Sections.'**
  String get noSectionsYet;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @section.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get section;

  /// No description provided for @children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get children;

  /// No description provided for @accountActive.
  ///
  /// In en, this message translates to:
  /// **'Account active'**
  String get accountActive;

  /// No description provided for @accountActiveHint.
  ///
  /// In en, this message translates to:
  /// **'Switch off to block sign-in without deleting anything.'**
  String get accountActiveHint;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @deleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteQuestion(String name);

  /// No description provided for @deletePersonBody.
  ///
  /// In en, this message translates to:
  /// **'Their profile is removed and they can no longer sign in. Their results and attendance stay on record.'**
  String get deletePersonBody;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @noSection.
  ///
  /// In en, this message translates to:
  /// **'No section'**
  String get noSection;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get inactive;

  /// No description provided for @switchOff.
  ///
  /// In en, this message translates to:
  /// **'Switch off'**
  String get switchOff;

  /// No description provided for @switchOn.
  ///
  /// In en, this message translates to:
  /// **'Switch on'**
  String get switchOn;

  /// No description provided for @peopleSub.
  ///
  /// In en, this message translates to:
  /// **'Create accounts, set sections and control access.'**
  String get peopleSub;

  /// No description provided for @nobodyYet.
  ///
  /// In en, this message translates to:
  /// **'Nobody here yet'**
  String get nobodyYet;

  /// No description provided for @nobodyYetSub.
  ///
  /// In en, this message translates to:
  /// **'Add the first one with the button above, or fill demo data from Settings.'**
  String get nobodyYetSub;

  /// No description provided for @deleteSectionWithStudents.
  ///
  /// In en, this message translates to:
  /// **'{count} students are in this section. They will be left without a section until you move them.'**
  String deleteSectionWithStudents(String count);

  /// No description provided for @deleteSectionBody.
  ///
  /// In en, this message translates to:
  /// **'The section is removed. Content assigned to it stops showing for it.'**
  String get deleteSectionBody;

  /// No description provided for @sectionsSub.
  ///
  /// In en, this message translates to:
  /// **'Group students into classes. Content, attendance and teachers are organised by section.'**
  String get sectionsSub;

  /// No description provided for @addSection.
  ///
  /// In en, this message translates to:
  /// **'Add section'**
  String get addSection;

  /// No description provided for @editSection.
  ///
  /// In en, this message translates to:
  /// **'Edit section'**
  String get editSection;

  /// No description provided for @noSectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No sections yet'**
  String get noSectionsTitle;

  /// No description provided for @noSectionsSub.
  ///
  /// In en, this message translates to:
  /// **'Create your first class group, then add students to it.'**
  String get noSectionsSub;

  /// No description provided for @studentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} students'**
  String studentsCount(String count);

  /// No description provided for @teachersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} teachers'**
  String teachersCount(String count);

  /// No description provided for @sectionName.
  ///
  /// In en, this message translates to:
  /// **'Section name'**
  String get sectionName;

  /// No description provided for @sectionNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Grade 7 — A'**
  String get sectionNameHint;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @levelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Grade 7'**
  String get levelHint;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @addQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add question'**
  String get addQuestion;

  /// No description provided for @questionText.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get questionText;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @optionN.
  ///
  /// In en, this message translates to:
  /// **'Option {n}'**
  String optionN(String n);

  /// No description provided for @addOption.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get addOption;

  /// No description provided for @markCorrectHint.
  ///
  /// In en, this message translates to:
  /// **'Select the correct answer'**
  String get markCorrectHint;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That file is larger than {mb} MB.'**
  String fileTooLarge(String mb);

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get enterTitle;

  /// No description provided for @enterValidLink.
  ///
  /// In en, this message translates to:
  /// **'Enter a full link starting with https://'**
  String get enterValidLink;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get chooseFile;

  /// No description provided for @questionsIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Every question needs text, at least two options and a correct answer.'**
  String get questionsIncomplete;

  /// No description provided for @newItem.
  ///
  /// In en, this message translates to:
  /// **'New {type}'**
  String newItem(String type);

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit {type}'**
  String editItem(String type);

  /// No description provided for @assessmentHint.
  ///
  /// In en, this message translates to:
  /// **'Multiple-choice questions, marked automatically when the student submits.'**
  String get assessmentHint;

  /// No description provided for @fileHint.
  ///
  /// In en, this message translates to:
  /// **'Upload a file to Firebase Storage, or paste a link.'**
  String get fileHint;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What is this about?'**
  String get descriptionHint;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @uploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload file'**
  String get uploadFile;

  /// No description provided for @pasteLink.
  ///
  /// In en, this message translates to:
  /// **'Paste link'**
  String get pasteLink;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @timeLimit.
  ///
  /// In en, this message translates to:
  /// **'Time limit'**
  String get timeLimit;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @zeroUntimed.
  ///
  /// In en, this message translates to:
  /// **'0 = no time limit'**
  String get zeroUntimed;

  /// No description provided for @questionsTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} questions · {points} points'**
  String questionsTotal(String count, String points);

  /// No description provided for @assignToSections.
  ///
  /// In en, this message translates to:
  /// **'Assign to sections'**
  String get assignToSections;

  /// No description provided for @noSectionsAssigned.
  ///
  /// In en, this message translates to:
  /// **'You are not assigned to any section yet. Ask the admin.'**
  String get noSectionsAssigned;

  /// No description provided for @assignToStudents.
  ///
  /// In en, this message translates to:
  /// **'…or to single students'**
  String get assignToStudents;

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date — tap to set one'**
  String get noDueDate;

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueOn(String date);

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// No description provided for @publishedHint.
  ///
  /// In en, this message translates to:
  /// **'Off keeps it a draft that only you can see.'**
  String get publishedHint;

  /// No description provided for @notAssignedWarning.
  ///
  /// In en, this message translates to:
  /// **'Not assigned to anyone yet — no student will see it.'**
  String get notAssignedWarning;

  /// No description provided for @allowedTypes.
  ///
  /// In en, this message translates to:
  /// **'Allowed: {types}'**
  String allowedTypes(String types);

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @uploadingPercent.
  ///
  /// In en, this message translates to:
  /// **'Uploading… {percent}%'**
  String uploadingPercent(String percent);

  /// No description provided for @deleteAssessmentBody.
  ///
  /// In en, this message translates to:
  /// **'Students will no longer see it. Results already submitted stay in Grades.'**
  String get deleteAssessmentBody;

  /// No description provided for @deleteContentBody.
  ///
  /// In en, this message translates to:
  /// **'Students will no longer see it, and the uploaded file is deleted.'**
  String get deleteContentBody;

  /// No description provided for @contentAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Everything every teacher has published.'**
  String get contentAdminSub;

  /// No description provided for @contentTeacherSub.
  ///
  /// In en, this message translates to:
  /// **'Upload lessons and build exams, then assign them to a section or to single students.'**
  String get contentTeacherSub;

  /// No description provided for @addContent.
  ///
  /// In en, this message translates to:
  /// **'Add content'**
  String get addContent;

  /// No description provided for @noContentPermission.
  ///
  /// In en, this message translates to:
  /// **'The admin has not given you permission to publish content yet.'**
  String get noContentPermission;

  /// No description provided for @noContentSub.
  ///
  /// In en, this message translates to:
  /// **'Use “Add content” to upload your first lesson or build a quiz.'**
  String get noContentSub;

  /// No description provided for @notAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get notAssigned;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @questionsShort.
  ///
  /// In en, this message translates to:
  /// **'{count} questions · {time}'**
  String questionsShort(String count, String time);

  /// No description provided for @untimed.
  ///
  /// In en, this message translates to:
  /// **'untimed'**
  String get untimed;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String minutesShort(String n);

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @attendanceSaved.
  ///
  /// In en, this message translates to:
  /// **'Attendance saved'**
  String get attendanceSaved;

  /// No description provided for @attendanceSub.
  ///
  /// In en, this message translates to:
  /// **'Pick a section and a day, tap each student\'s status, then save.'**
  String get attendanceSub;

  /// No description provided for @noStudentsInSection.
  ///
  /// In en, this message translates to:
  /// **'No students in this section'**
  String get noStudentsInSection;

  /// No description provided for @noStudentsInSectionSub.
  ///
  /// In en, this message translates to:
  /// **'The admin adds students to sections from the Students page.'**
  String get noStudentsInSectionSub;

  /// No description provided for @unmarkedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} not marked'**
  String unmarkedCount(String count);

  /// No description provided for @markAllPresent.
  ///
  /// In en, this message translates to:
  /// **'Mark all present'**
  String get markAllPresent;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @notSavedYet.
  ///
  /// In en, this message translates to:
  /// **'Not saved yet'**
  String get notSavedYet;

  /// No description provided for @gradesSub.
  ///
  /// In en, this message translates to:
  /// **'Results arrive here the moment a student submits. Adjust a mark or add feedback any time.'**
  String get gradesSub;

  /// No description provided for @noAssessments.
  ///
  /// In en, this message translates to:
  /// **'No exams or quizzes yet'**
  String get noAssessments;

  /// No description provided for @noAssessmentsSub.
  ///
  /// In en, this message translates to:
  /// **'Create one from the Content page.'**
  String get noAssessmentsSub;

  /// No description provided for @pointsTotal.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String pointsTotal(String points);

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @missing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get missing;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @notSubmittedYet.
  ///
  /// In en, this message translates to:
  /// **'Not submitted yet'**
  String get notSubmittedYet;

  /// No description provided for @gradedByTeacher.
  ///
  /// In en, this message translates to:
  /// **'Graded by teacher'**
  String get gradedByTeacher;

  /// No description provided for @autoMarked.
  ///
  /// In en, this message translates to:
  /// **'Auto-marked'**
  String get autoMarked;

  /// No description provided for @enterGrade.
  ///
  /// In en, this message translates to:
  /// **'Enter grade'**
  String get enterGrade;

  /// No description provided for @editGrade.
  ///
  /// In en, this message translates to:
  /// **'Edit grade'**
  String get editGrade;

  /// No description provided for @scoreRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a score from 0 to {max}.'**
  String scoreRange(String max);

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Visible to the student and their parents.'**
  String get feedbackHint;

  /// No description provided for @aboutAssignment.
  ///
  /// In en, this message translates to:
  /// **'About an assignment'**
  String get aboutAssignment;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @noMessagesYetSub.
  ///
  /// In en, this message translates to:
  /// **'Say hello — messages arrive instantly.'**
  String get noMessagesYetSub;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About: {title}'**
  String aboutTitle(String title);

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get typeMessage;

  /// No description provided for @aboutChild.
  ///
  /// In en, this message translates to:
  /// **'About {name}'**
  String aboutChild(String name);

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @messagesTeacherSub.
  ///
  /// In en, this message translates to:
  /// **'Conversations with parents, one thread per child.'**
  String get messagesTeacherSub;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversations;

  /// No description provided for @noConversationsTeacherSub.
  ///
  /// In en, this message translates to:
  /// **'Parents can write to you from their app, or start one from My students.'**
  String get noConversationsTeacherSub;

  /// No description provided for @parentOf.
  ///
  /// In en, this message translates to:
  /// **'Parent of {name}'**
  String parentOf(String name);

  /// No description provided for @myStudentsSub.
  ///
  /// In en, this message translates to:
  /// **'Students in the sections you teach. Click one for results, attendance and parents.'**
  String get myStudentsSub;

  /// No description provided for @noParentsLinked.
  ///
  /// In en, this message translates to:
  /// **'No parent linked yet. The admin links parents from the Parents page.'**
  String get noParentsLinked;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @noAttendanceYet.
  ///
  /// In en, this message translates to:
  /// **'No attendance recorded yet.'**
  String get noAttendanceYet;

  /// No description provided for @attendanceRate.
  ///
  /// In en, this message translates to:
  /// **'Attendance {percent}%'**
  String attendanceRate(String percent);

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @noResultsYet.
  ///
  /// In en, this message translates to:
  /// **'No results yet.'**
  String get noResultsYet;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Vibration on tap'**
  String get haptics;

  /// No description provided for @branding.
  ///
  /// In en, this message translates to:
  /// **'Brand colours'**
  String get branding;

  /// No description provided for @resetColors.
  ///
  /// In en, this message translates to:
  /// **'Reset to default colours'**
  String get resetColors;

  /// No description provided for @brandingLocalHint.
  ///
  /// In en, this message translates to:
  /// **'Saved on this computer.'**
  String get brandingLocalHint;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @clearDeviceOverride.
  ///
  /// In en, this message translates to:
  /// **'Clear device preview'**
  String get clearDeviceOverride;

  /// No description provided for @clearDeviceOverrideSub.
  ///
  /// In en, this message translates to:
  /// **'Stops pretending this device is a phone / computer, and signs out.'**
  String get clearDeviceOverrideSub;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @startNow.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startNow;

  /// No description provided for @questionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String questionsCount(String count);

  /// No description provided for @openExternally.
  ///
  /// In en, this message translates to:
  /// **'Open in another app'**
  String get openExternally;

  /// No description provided for @videoFailed.
  ///
  /// In en, this message translates to:
  /// **'This video could not be played. Try opening it in another app.'**
  String get videoFailed;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {pages}'**
  String pageOf(String page, String pages);

  /// No description provided for @pdfFailed.
  ///
  /// In en, this message translates to:
  /// **'This PDF could not be opened here. Tap to open it in another app.'**
  String get pdfFailed;

  /// No description provided for @pinchToZoom.
  ///
  /// In en, this message translates to:
  /// **'Pinch to zoom'**
  String get pinchToZoom;

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questions;

  /// No description provided for @notTakenYet.
  ///
  /// In en, this message translates to:
  /// **'{name} has not taken this yet.'**
  String notTakenYet(String name);

  /// No description provided for @examRules.
  ///
  /// In en, this message translates to:
  /// **'Answer every question, then submit. You can move between questions freely. You can submit only once.'**
  String get examRules;

  /// No description provided for @startExam.
  ///
  /// In en, this message translates to:
  /// **'Start {type}'**
  String startExam(String type);

  /// No description provided for @submitQuestion.
  ///
  /// In en, this message translates to:
  /// **'Submit your answers?'**
  String get submitQuestion;

  /// No description provided for @submitWithBlanks.
  ///
  /// In en, this message translates to:
  /// **'{count} questions are still blank. You cannot change answers after submitting.'**
  String submitWithBlanks(String count);

  /// No description provided for @submitBody.
  ///
  /// In en, this message translates to:
  /// **'You cannot change answers after submitting.'**
  String get submitBody;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get keepGoing;

  /// No description provided for @submitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit'**
  String get submitFailed;

  /// No description provided for @alreadySubmitted.
  ///
  /// In en, this message translates to:
  /// **'You have already submitted this one.'**
  String get alreadySubmitted;

  /// No description provided for @leaveExamQuestion.
  ///
  /// In en, this message translates to:
  /// **'Leave without submitting?'**
  String get leaveExamQuestion;

  /// No description provided for @leaveExamBody.
  ///
  /// In en, this message translates to:
  /// **'Your answers will be lost.'**
  String get leaveExamBody;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @questionNofM.
  ///
  /// In en, this message translates to:
  /// **'Question {n} of {m}'**
  String questionNofM(String n, String m);

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @timeUp.
  ///
  /// In en, this message translates to:
  /// **'Time is up — your answers were submitted automatically.'**
  String get timeUp;

  /// No description provided for @submittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Submitted!'**
  String get submittedTitle;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @verdictExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent work!'**
  String get verdictExcellent;

  /// No description provided for @verdictGood.
  ///
  /// In en, this message translates to:
  /// **'Good job!'**
  String get verdictGood;

  /// No description provided for @verdictPass.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get verdictPass;

  /// No description provided for @verdictKeepTrying.
  ///
  /// In en, this message translates to:
  /// **'Keep practising'**
  String get verdictKeepTrying;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @libraryTab.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTab;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @nothingAssignedYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing assigned yet'**
  String get nothingAssignedYet;

  /// No description provided for @nothingAssignedYetSub.
  ///
  /// In en, this message translates to:
  /// **'When your teachers share lessons, exams or quizzes, they will appear here.'**
  String get nothingAssignedYetSub;

  /// No description provided for @continueLearning.
  ///
  /// In en, this message translates to:
  /// **'Continue learning'**
  String get continueLearning;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @upNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get upNext;

  /// No description provided for @newThisWeek.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newThisWeek;

  /// No description provided for @toDo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get toDo;

  /// No description provided for @searchLessons.
  ///
  /// In en, this message translates to:
  /// **'Search lessons, exams, teachers…'**
  String get searchLessons;

  /// No description provided for @nothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get nothingHere;

  /// No description provided for @nothingHereSub.
  ///
  /// In en, this message translates to:
  /// **'Try another filter or search.'**
  String get nothingHereSub;

  /// No description provided for @averageGrade.
  ///
  /// In en, this message translates to:
  /// **'Average grade'**
  String get averageGrade;

  /// No description provided for @resultsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String resultsCountLabel(String count);

  /// No description provided for @daysRecorded.
  ///
  /// In en, this message translates to:
  /// **'{count} days recorded'**
  String daysRecorded(String count);

  /// No description provided for @lastDays.
  ///
  /// In en, this message translates to:
  /// **'Latest days'**
  String get lastDays;

  /// No description provided for @absencesAndLate.
  ///
  /// In en, this message translates to:
  /// **'Absences and late days'**
  String get absencesAndLate;

  /// No description provided for @myProgress.
  ///
  /// In en, this message translates to:
  /// **'My progress'**
  String get myProgress;

  /// No description provided for @noChildrenLinked.
  ///
  /// In en, this message translates to:
  /// **'No children linked yet'**
  String get noChildrenLinked;

  /// No description provided for @noChildrenLinkedSub.
  ///
  /// In en, this message translates to:
  /// **'Ask the center to link your children to your account.'**
  String get noChildrenLinkedSub;

  /// No description provided for @yourChildren.
  ///
  /// In en, this message translates to:
  /// **'Your children'**
  String get yourChildren;

  /// No description provided for @messageATeacher.
  ///
  /// In en, this message translates to:
  /// **'Message a teacher'**
  String get messageATeacher;

  /// No description provided for @assignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get assignments;

  /// No description provided for @chooseTeacher.
  ///
  /// In en, this message translates to:
  /// **'Choose a teacher'**
  String get chooseTeacher;

  /// No description provided for @noTeachersToMessage.
  ///
  /// In en, this message translates to:
  /// **'No teacher of this section can receive messages yet.'**
  String get noTeachersToMessage;

  /// No description provided for @whichChild.
  ///
  /// In en, this message translates to:
  /// **'Which child is this about?'**
  String get whichChild;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessage;

  /// No description provided for @noConversationsParentSub.
  ///
  /// In en, this message translates to:
  /// **'Tap “New message” to write to one of your child\'s teachers.'**
  String get noConversationsParentSub;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @dashboardAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Attendance, results and content across the whole center.'**
  String get dashboardAdminSub;

  /// No description provided for @dashboardTeacherSub.
  ///
  /// In en, this message translates to:
  /// **'Attendance and results for the sections you teach.'**
  String get dashboardTeacherSub;

  /// No description provided for @attendanceRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Attendance rate'**
  String get attendanceRateLabel;

  /// No description provided for @averageScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Average score'**
  String get averageScoreLabel;

  /// No description provided for @gradedResultsLabel.
  ///
  /// In en, this message translates to:
  /// **'Results marked'**
  String get gradedResultsLabel;

  /// No description provided for @publishedContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Published content'**
  String get publishedContentLabel;

  /// No description provided for @attendanceByStatus.
  ///
  /// In en, this message translates to:
  /// **'Attendance by status'**
  String get attendanceByStatus;

  /// No description provided for @attendanceByDay.
  ///
  /// In en, this message translates to:
  /// **'Attendance by day'**
  String get attendanceByDay;

  /// No description provided for @averageBySection.
  ///
  /// In en, this message translates to:
  /// **'Average score by section'**
  String get averageBySection;

  /// No description provided for @scoreBands.
  ///
  /// In en, this message translates to:
  /// **'Score bands'**
  String get scoreBands;

  /// No description provided for @resultsByType.
  ///
  /// In en, this message translates to:
  /// **'Results by type'**
  String get resultsByType;

  /// No description provided for @band0.
  ///
  /// In en, this message translates to:
  /// **'Below 50'**
  String get band0;

  /// No description provided for @band50.
  ///
  /// In en, this message translates to:
  /// **'50–64'**
  String get band50;

  /// No description provided for @band65.
  ///
  /// In en, this message translates to:
  /// **'65–79'**
  String get band65;

  /// No description provided for @band80.
  ///
  /// In en, this message translates to:
  /// **'80–100'**
  String get band80;

  /// No description provided for @charts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get charts;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @periodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get periodLabel;

  /// No description provided for @period30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get period30;

  /// No description provided for @period90.
  ///
  /// In en, this message translates to:
  /// **'Last 90 days'**
  String get period90;

  /// No description provided for @periodAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get periodAll;

  /// No description provided for @onlyBelowPass.
  ///
  /// In en, this message translates to:
  /// **'Only results below 50%'**
  String get onlyBelowPass;

  /// No description provided for @onlyAbsences.
  ///
  /// In en, this message translates to:
  /// **'Only absences and late days'**
  String get onlyAbsences;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportTitle;

  /// No description provided for @exportFileName.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get exportFileName;

  /// No description provided for @exportSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String exportSaved(String path);

  /// No description provided for @exportFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailedTitle;

  /// No description provided for @exportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled.'**
  String get exportCancelled;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @assessment.
  ///
  /// In en, this message translates to:
  /// **'Assessment'**
  String get assessment;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @rowsShown.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total}'**
  String rowsShown(String shown, String total);

  /// No description provided for @nothingToChart.
  ///
  /// In en, this message translates to:
  /// **'Nothing to chart yet'**
  String get nothingToChart;

  /// No description provided for @nothingToChartSub.
  ///
  /// In en, this message translates to:
  /// **'Charts fill in as attendance is taken and assessments are marked.'**
  String get nothingToChartSub;

  /// No description provided for @noRowsMatch.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches these filters.'**
  String get noRowsMatch;

  /// No description provided for @dashboardSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search a student or an assessment'**
  String get dashboardSearchHint;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @enterFileName.
  ///
  /// In en, this message translates to:
  /// **'Enter a file name'**
  String get enterFileName;

  /// No description provided for @focusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue — finish it first'**
  String get focusOverdue;

  /// No description provided for @focusNext.
  ///
  /// In en, this message translates to:
  /// **'Your next task'**
  String get focusNext;

  /// No description provided for @focusNew.
  ///
  /// In en, this message translates to:
  /// **'New for you'**
  String get focusNew;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get allCaughtUp;

  /// No description provided for @allCaughtUpSub.
  ///
  /// In en, this message translates to:
  /// **'No exams or quizzes waiting. A good moment to review a lesson.'**
  String get allCaughtUpSub;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get dueTomorrow;

  /// No description provided for @dueInDays.
  ///
  /// In en, this message translates to:
  /// **'Due in {n} days'**
  String dueInDays(String n);

  /// No description provided for @overdueByDays.
  ///
  /// In en, this message translates to:
  /// **'{n} days overdue'**
  String overdueByDays(String n);

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @notRecordedToday.
  ///
  /// In en, this message translates to:
  /// **'Not recorded yet'**
  String get notRecordedToday;

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'day streak'**
  String get dayStreak;

  /// No description provided for @latestResult.
  ///
  /// In en, this message translates to:
  /// **'Latest result'**
  String get latestResult;

  /// No description provided for @aboveAverage.
  ///
  /// In en, this message translates to:
  /// **'{n} pts above your average'**
  String aboveAverage(String n);

  /// No description provided for @belowAverage.
  ///
  /// In en, this message translates to:
  /// **'{n} pts below your average'**
  String belowAverage(String n);

  /// No description provided for @onYourAverage.
  ///
  /// In en, this message translates to:
  /// **'Right on your average'**
  String get onYourAverage;

  /// No description provided for @assessmentsDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} exams & quizzes done'**
  String assessmentsDone(String done, String total);

  /// No description provided for @atAGlance.
  ///
  /// In en, this message translates to:
  /// **'At a glance'**
  String get atAGlance;

  /// No description provided for @noResultYetShort.
  ///
  /// In en, this message translates to:
  /// **'Your first result will show here.'**
  String get noResultYetShort;

  /// No description provided for @roleUser.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleUser;

  /// No description provided for @roleAdminBadge.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdminBadge;

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'Everything you need to learn, in one place.'**
  String get heroTitle;

  /// No description provided for @heroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Watch the lessons, then take the quiz before the time runs out.'**
  String get heroSubtitle;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A minute to sign up, then everything is open to you.'**
  String get registerSubtitle;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get register;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get noAccount;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @errPasswordsDiffer.
  ///
  /// In en, this message translates to:
  /// **'The two passwords are not the same.'**
  String get errPasswordsDiffer;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get phoneHint;

  /// No description provided for @welcomeName.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeName(String name);

  /// No description provided for @signInAsAdminHint.
  ///
  /// In en, this message translates to:
  /// **'The admin account signs in here too.'**
  String get signInAsAdminHint;

  /// No description provided for @registerHint.
  ///
  /// In en, this message translates to:
  /// **'Your account is a member account. The center keeps one admin.'**
  String get registerHint;

  /// No description provided for @quizzes.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get quizzes;

  /// No description provided for @quizzesAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Write the questions, set the timer and the window when it is open.'**
  String get quizzesAdminSub;

  /// No description provided for @quizzesUserSub.
  ///
  /// In en, this message translates to:
  /// **'Take a quiz while it is open. The timer starts when you do.'**
  String get quizzesUserSub;

  /// No description provided for @newQuiz.
  ///
  /// In en, this message translates to:
  /// **'New quiz'**
  String get newQuiz;

  /// No description provided for @editQuiz.
  ///
  /// In en, this message translates to:
  /// **'Edit quiz'**
  String get editQuiz;

  /// No description provided for @quizTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Unit 3 — revision'**
  String get quizTitleHint;

  /// No description provided for @availabilityWindow.
  ///
  /// In en, this message translates to:
  /// **'When it is open'**
  String get availabilityWindow;

  /// No description provided for @availabilityHint.
  ///
  /// In en, this message translates to:
  /// **'Leave both empty to keep it open with no end date.'**
  String get availabilityHint;

  /// No description provided for @opensAt.
  ///
  /// In en, this message translates to:
  /// **'Opens'**
  String get opensAt;

  /// No description provided for @closesAt.
  ///
  /// In en, this message translates to:
  /// **'Closes'**
  String get closesAt;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @clearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearDate;

  /// No description provided for @errWindowBackwards.
  ///
  /// In en, this message translates to:
  /// **'The closing time has to come after the opening time.'**
  String get errWindowBackwards;

  /// No description provided for @errNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'Add at least one question.'**
  String get errNoQuestions;

  /// No description provided for @quizSaved.
  ///
  /// In en, this message translates to:
  /// **'Quiz saved'**
  String get quizSaved;

  /// No description provided for @deleteQuizBody.
  ///
  /// In en, this message translates to:
  /// **'The quiz and every attempt on it are deleted. This cannot be undone.'**
  String get deleteQuizBody;

  /// No description provided for @noQuizzesTitle.
  ///
  /// In en, this message translates to:
  /// **'No quizzes yet'**
  String get noQuizzesTitle;

  /// No description provided for @noQuizzesAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Write your first one — questions, a timer, and when it is open.'**
  String get noQuizzesAdminSub;

  /// No description provided for @noQuizzesUserSub.
  ///
  /// In en, this message translates to:
  /// **'Nothing is open for you right now. Come back later.'**
  String get noQuizzesUserSub;

  /// No description provided for @attempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get attempts;

  /// No description provided for @attemptsSub.
  ///
  /// In en, this message translates to:
  /// **'Who has taken this quiz, and how they did.'**
  String get attemptsSub;

  /// No description provided for @noAttemptsYet.
  ///
  /// In en, this message translates to:
  /// **'Nobody has taken this quiz yet'**
  String get noAttemptsYet;

  /// No description provided for @noAttemptsYetSub.
  ///
  /// In en, this message translates to:
  /// **'Results appear here the moment somebody submits.'**
  String get noAttemptsYetSub;

  /// No description provided for @attemptsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} attempts'**
  String attemptsCount(String count);

  /// No description provided for @autoSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Time ran out'**
  String get autoSubmitted;

  /// No description provided for @takenOn.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get takenOn;

  /// No description provided for @startQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start the quiz'**
  String get startQuiz;

  /// No description provided for @quizRulesTimed.
  ///
  /// In en, this message translates to:
  /// **'{count} questions · {minutes} minutes. The timer keeps running once you start, and the quiz is submitted for you when it reaches zero.'**
  String quizRulesTimed(String count, String minutes);

  /// No description provided for @quizRulesUntimed.
  ///
  /// In en, this message translates to:
  /// **'{count} questions, no time limit. Take as long as you need.'**
  String quizRulesUntimed(String count);

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'Time left'**
  String get timeLeft;

  /// No description provided for @quizNotOpenYet.
  ///
  /// In en, this message translates to:
  /// **'Opens {date}'**
  String quizNotOpenYet(String date);

  /// No description provided for @quizClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get quizClosed;

  /// No description provided for @quizClosesOn.
  ///
  /// In en, this message translates to:
  /// **'Closes {date}'**
  String quizClosesOn(String date);

  /// No description provided for @quizOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get quizOpenNow;

  /// No description provided for @quizWindowClosedBody.
  ///
  /// In en, this message translates to:
  /// **'This quiz is not open right now.'**
  String get quizWindowClosedBody;

  /// No description provided for @yourScore.
  ///
  /// In en, this message translates to:
  /// **'Your score'**
  String get yourScore;

  /// No description provided for @correctOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total} correct'**
  String correctOfTotal(String correct, String total);

  /// No description provided for @yourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get yourAnswer;

  /// No description provided for @correctAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer'**
  String get correctAnswer;

  /// No description provided for @noAnswer.
  ///
  /// In en, this message translates to:
  /// **'Left blank'**
  String get noAnswer;

  /// No description provided for @takeAgain.
  ///
  /// In en, this message translates to:
  /// **'Take it again'**
  String get takeAgain;

  /// No description provided for @alreadyTakenBody.
  ///
  /// In en, this message translates to:
  /// **'You have already taken this quiz. Here is how you did.'**
  String get alreadyTakenBody;

  /// No description provided for @backToQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Back to quizzes'**
  String get backToQuizzes;

  /// No description provided for @answered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get answered;

  /// No description provided for @videosAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Upload a lesson and it appears for every member.'**
  String get videosAdminSub;

  /// No description provided for @videosUserSub.
  ///
  /// In en, this message translates to:
  /// **'Every lesson the center has published.'**
  String get videosUserSub;

  /// No description provided for @addVideo.
  ///
  /// In en, this message translates to:
  /// **'Add a video'**
  String get addVideo;

  /// No description provided for @videoLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading lesson'**
  String get videoLoading;

  /// No description provided for @importDriveLessons.
  ///
  /// In en, this message translates to:
  /// **'Add Drive lessons'**
  String get importDriveLessons;

  /// No description provided for @driveLessonsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} lessons added from Google Drive'**
  String driveLessonsAdded(int count);

  /// No description provided for @editVideo.
  ///
  /// In en, this message translates to:
  /// **'Edit video'**
  String get editVideo;

  /// No description provided for @chooseVideoFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a video file'**
  String get chooseVideoFile;

  /// No description provided for @videoSaved.
  ///
  /// In en, this message translates to:
  /// **'Video saved'**
  String get videoSaved;

  /// No description provided for @deleteVideoBody.
  ///
  /// In en, this message translates to:
  /// **'The video and its file are deleted. This cannot be undone.'**
  String get deleteVideoBody;

  /// No description provided for @noVideosTitle.
  ///
  /// In en, this message translates to:
  /// **'No videos yet'**
  String get noVideosTitle;

  /// No description provided for @noVideosAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Upload the first lesson — members see it straight away.'**
  String get noVideosAdminSub;

  /// No description provided for @noVideosUserSub.
  ///
  /// In en, this message translates to:
  /// **'Lessons appear here as soon as they are published.'**
  String get noVideosUserSub;

  /// No description provided for @watchNow.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get watchNow;

  /// No description provided for @uploadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Uploading the video…'**
  String get uploadingVideo;

  /// No description provided for @uploadCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel the upload'**
  String get uploadCancel;

  /// No description provided for @noFileChosen.
  ///
  /// In en, this message translates to:
  /// **'No file chosen'**
  String get noFileChosen;

  /// No description provided for @megabytes.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String megabytes(String size);

  /// No description provided for @videoStillUploading.
  ///
  /// In en, this message translates to:
  /// **'Wait for the upload to finish.'**
  String get videoStillUploading;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @membersSub.
  ///
  /// In en, this message translates to:
  /// **'Everybody who has registered.'**
  String get membersSub;

  /// No description provided for @noMembersYet.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get noMembersYet;

  /// No description provided for @noMembersYetSub.
  ///
  /// In en, this message translates to:
  /// **'They appear here the moment somebody registers.'**
  String get noMembersYetSub;

  /// No description provided for @totalMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get totalMembers;

  /// No description provided for @totalQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get totalQuizzes;

  /// No description provided for @totalVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get totalVideos;

  /// No description provided for @totalAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get totalAttempts;

  /// No description provided for @dashboardAsecSub.
  ///
  /// In en, this message translates to:
  /// **'Your center at a glance.'**
  String get dashboardAsecSub;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(String date);

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @errKeychain.
  ///
  /// In en, this message translates to:
  /// **'This Mac would not let the app save your session to the keychain. The app has to be signed with an Apple Development team — see SETUP.md.'**
  String get errKeychain;

  /// No description provided for @failStorageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cloud Storage is not ready for this project. Turn Storage on in the Firebase console (Build > Storage), then deploy storage.rules.'**
  String get failStorageUnavailable;

  /// No description provided for @startedAt.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get startedAt;

  /// No description provided for @finishedAt.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finishedAt;

  /// No description provided for @timeTaken.
  ///
  /// In en, this message translates to:
  /// **'Time taken'**
  String get timeTaken;

  /// No description provided for @answerSheet.
  ///
  /// In en, this message translates to:
  /// **'Answer sheet'**
  String get answerSheet;

  /// No description provided for @blanksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} left blank'**
  String blanksCount(String count);

  /// No description provided for @minutesSeconds.
  ///
  /// In en, this message translates to:
  /// **'{m} min {s} s'**
  String minutesSeconds(String m, String s);

  /// No description provided for @theirAnswer.
  ///
  /// In en, this message translates to:
  /// **'Their answer'**
  String get theirAnswer;

  /// No description provided for @openAttempt.
  ///
  /// In en, this message translates to:
  /// **'See the answers'**
  String get openAttempt;

  /// No description provided for @attemptOf.
  ///
  /// In en, this message translates to:
  /// **'{name} — {quiz}'**
  String attemptOf(String name, String quiz);

  /// No description provided for @questionNumber.
  ///
  /// In en, this message translates to:
  /// **'Question {n}'**
  String questionNumber(String n);

  /// No description provided for @pointsEarned.
  ///
  /// In en, this message translates to:
  /// **'{earned} / {total} pts'**
  String pointsEarned(String earned, String total);

  /// No description provided for @attemptsByDay.
  ///
  /// In en, this message translates to:
  /// **'Attempts by day'**
  String get attemptsByDay;

  /// No description provided for @averageByQuiz.
  ///
  /// In en, this message translates to:
  /// **'Average score by quiz'**
  String get averageByQuiz;

  /// No description provided for @topMembers.
  ///
  /// In en, this message translates to:
  /// **'Top members'**
  String get topMembers;

  /// No description provided for @latestAttempts.
  ///
  /// In en, this message translates to:
  /// **'Latest attempts'**
  String get latestAttempts;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @quizLabel.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quizLabel;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @allQuizzesAvg.
  ///
  /// In en, this message translates to:
  /// **'Across every quiz'**
  String get allQuizzesAvg;

  /// No description provided for @nothingToChartAsec.
  ///
  /// In en, this message translates to:
  /// **'Charts fill in as members take the quizzes.'**
  String get nothingToChartAsec;

  /// No description provided for @seeAllAttempts.
  ///
  /// In en, this message translates to:
  /// **'Open the quiz to see them all'**
  String get seeAllAttempts;

  /// No description provided for @resultsAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Every attempt, by every member, across every quiz.'**
  String get resultsAdminSub;

  /// No description provided for @searchMember.
  ///
  /// In en, this message translates to:
  /// **'Search a member'**
  String get searchMember;

  /// No description provided for @allQuizzes.
  ///
  /// In en, this message translates to:
  /// **'All quizzes'**
  String get allQuizzes;

  /// No description provided for @membersWhoTook.
  ///
  /// In en, this message translates to:
  /// **'Members who took'**
  String get membersWhoTook;

  /// No description provided for @passRate.
  ///
  /// In en, this message translates to:
  /// **'Pass rate'**
  String get passRate;

  /// No description provided for @noAttemptsMatch.
  ///
  /// In en, this message translates to:
  /// **'No attempt matches this search'**
  String get noAttemptsMatch;

  /// No description provided for @noAttemptsMatchSub.
  ///
  /// In en, this message translates to:
  /// **'Clear the search, or pick another quiz.'**
  String get noAttemptsMatchSub;

  /// No description provided for @cvs.
  ///
  /// In en, this message translates to:
  /// **'The Best'**
  String get cvs;

  /// No description provided for @myCv.
  ///
  /// In en, this message translates to:
  /// **'My CV'**
  String get myCv;

  /// No description provided for @cvDirectorySub.
  ///
  /// In en, this message translates to:
  /// **'Every member who has published a CV.'**
  String get cvDirectorySub;

  /// No description provided for @cvAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Every CV in the centre, with its review state.'**
  String get cvAdminSub;

  /// No description provided for @createCv.
  ///
  /// In en, this message translates to:
  /// **'Create your CV'**
  String get createCv;

  /// No description provided for @editCv.
  ///
  /// In en, this message translates to:
  /// **'Edit your CV'**
  String get editCv;

  /// No description provided for @cvSaved.
  ///
  /// In en, this message translates to:
  /// **'CV saved'**
  String get cvSaved;

  /// No description provided for @cvNotAllowedTitle.
  ///
  /// In en, this message translates to:
  /// **'The CV form is not open for you yet'**
  String get cvNotAllowedTitle;

  /// No description provided for @cvNotAllowedSub.
  ///
  /// In en, this message translates to:
  /// **'Ask the admin to switch it on for your account.'**
  String get cvNotAllowedSub;

  /// No description provided for @allowCv.
  ///
  /// In en, this message translates to:
  /// **'CV'**
  String get allowCv;

  /// No description provided for @allowCvHint.
  ///
  /// In en, this message translates to:
  /// **'Lets this member write a CV'**
  String get allowCvHint;

  /// No description provided for @cvPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get cvPersonal;

  /// No description provided for @cvProfession.
  ///
  /// In en, this message translates to:
  /// **'Profession'**
  String get cvProfession;

  /// No description provided for @cvSkillsSection.
  ///
  /// In en, this message translates to:
  /// **'Skills and languages'**
  String get cvSkillsSection;

  /// No description provided for @cvLinks.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get cvLinks;

  /// No description provided for @cvPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get cvPhoto;

  /// No description provided for @cvLocation.
  ///
  /// In en, this message translates to:
  /// **'Governorate'**
  String get cvLocation;

  /// No description provided for @militaryStatus.
  ///
  /// In en, this message translates to:
  /// **'Military status'**
  String get militaryStatus;

  /// No description provided for @graduationYear.
  ///
  /// In en, this message translates to:
  /// **'Graduation year'**
  String get graduationYear;

  /// No description provided for @cvSpecialization.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get cvSpecialization;

  /// No description provided for @jobRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get jobRole;

  /// No description provided for @proSkills.
  ///
  /// In en, this message translates to:
  /// **'Professional skills'**
  String get proSkills;

  /// No description provided for @softSkillsLabel.
  ///
  /// In en, this message translates to:
  /// **'Soft skills'**
  String get softSkillsLabel;

  /// No description provided for @languagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languagesLabel;

  /// No description provided for @bioLabel.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get bioLabel;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'Two or three lines. What you do, and what you are looking for.'**
  String get bioHint;

  /// No description provided for @facebookLabel.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebookLabel;

  /// No description provided for @linkedinLabel.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get linkedinLabel;

  /// No description provided for @driveLabel.
  ///
  /// In en, this message translates to:
  /// **'CV file'**
  String get driveLabel;

  /// No description provided for @cvFileHint.
  ///
  /// In en, this message translates to:
  /// **'Upload the CV itself — PDF or Word, up to 10 MB.'**
  String get cvFileHint;

  /// No description provided for @uploadCvFile.
  ///
  /// In en, this message translates to:
  /// **'Upload CV file'**
  String get uploadCvFile;

  /// No description provided for @noCvFile.
  ///
  /// In en, this message translates to:
  /// **'No file uploaded yet'**
  String get noCvFile;

  /// No description provided for @removeFile.
  ///
  /// In en, this message translates to:
  /// **'Remove the file'**
  String get removeFile;

  /// No description provided for @downloadCv.
  ///
  /// In en, this message translates to:
  /// **'Download CV'**
  String get downloadCv;

  /// No description provided for @cvSummary.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get cvSummary;

  /// No description provided for @cvEducation.
  ///
  /// In en, this message translates to:
  /// **'Education and status'**
  String get cvEducation;

  /// No description provided for @portfolioLabel.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolioLabel;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo'**
  String get choosePhoto;

  /// No description provided for @pickRoleFirst.
  ///
  /// In en, this message translates to:
  /// **'Pick a role first — its skills appear here.'**
  String get pickRoleFirst;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(String count);

  /// No description provided for @cvIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Fill in every field marked with * before saving.'**
  String get cvIncomplete;

  /// No description provided for @pickSome.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose'**
  String get pickSome;

  /// No description provided for @noneChosen.
  ///
  /// In en, this message translates to:
  /// **'Nothing chosen yet'**
  String get noneChosen;

  /// No description provided for @cvPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get cvPending;

  /// No description provided for @cvReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get cvReviewed;

  /// No description provided for @cvShortlisted.
  ///
  /// In en, this message translates to:
  /// **'Shortlisted'**
  String get cvShortlisted;

  /// No description provided for @cvRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get cvRejected;

  /// No description provided for @reviewState.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewState;

  /// No description provided for @noCvsTitle.
  ///
  /// In en, this message translates to:
  /// **'No CVs yet'**
  String get noCvsTitle;

  /// No description provided for @noCvsSubUser.
  ///
  /// In en, this message translates to:
  /// **'CVs appear here as members publish them.'**
  String get noCvsSubUser;

  /// No description provided for @noCvsSubAdmin.
  ///
  /// In en, this message translates to:
  /// **'Allow a member to write one from the Members page.'**
  String get noCvsSubAdmin;

  /// No description provided for @searchCv.
  ///
  /// In en, this message translates to:
  /// **'Search by name, role or skill'**
  String get searchCv;

  /// No description provided for @deleteCvBody.
  ///
  /// In en, this message translates to:
  /// **'The CV and its photo are deleted. This cannot be undone.'**
  String get deleteCvBody;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactDetails;

  /// No description provided for @cvUpdatedOn.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String cvUpdatedOn(String date);

  /// No description provided for @yourCvIsLive.
  ///
  /// In en, this message translates to:
  /// **'Your CV is visible to the other members.'**
  String get yourCvIsLive;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a phone number'**
  String get enterPhone;

  /// No description provided for @cvAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get cvAllowed;

  /// No description provided for @cvNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get cvNotAllowed;

  /// No description provided for @joinedLabel.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joinedLabel;

  /// No description provided for @cvColumn.
  ///
  /// In en, this message translates to:
  /// **'CV form'**
  String get cvColumn;

  /// No description provided for @searchMembers.
  ///
  /// In en, this message translates to:
  /// **'Search a member by name, email or phone'**
  String get searchMembers;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get dangerZone;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account and profile.'**
  String get deleteAccountHint;

  /// No description provided for @deleteAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountQuestion;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile and CV are deleted and you are signed out. This cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm.'**
  String get deleteAccountPasswordBody;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the account'**
  String get deleteAccountFailed;

  /// No description provided for @kpiNewThisWeek.
  ///
  /// In en, this message translates to:
  /// **'+{count} this week'**
  String kpiNewThisWeek(int count);

  /// No description provided for @kpiNewThisMonth.
  ///
  /// In en, this message translates to:
  /// **'+{count} this month'**
  String kpiNewThisMonth(int count);

  /// No description provided for @kpiOpenNow.
  ///
  /// In en, this message translates to:
  /// **'{count} open now'**
  String kpiOpenNow(int count);

  /// No description provided for @kpiCvAccess.
  ///
  /// In en, this message translates to:
  /// **'CV access'**
  String get kpiCvAccess;

  /// No description provided for @kpiDrafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get kpiDrafts;

  /// No description provided for @kpiLibrarySize.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get kpiLibrarySize;

  /// No description provided for @kpiUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get kpiUpcoming;

  /// No description provided for @kpiTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Timed out'**
  String get kpiTimedOut;

  /// No description provided for @videoLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Video link'**
  String get videoLinkTitle;

  /// No description provided for @videoLinkCaption.
  ///
  /// In en, this message translates to:
  /// **'Paste a direct .mp4 link or a Google Drive link (shared as “Anyone with the link”) — no upload needed.'**
  String get videoLinkCaption;

  /// No description provided for @videoLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get videoLinkLabel;

  /// No description provided for @videoLinkInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a full link that starts with https://'**
  String get videoLinkInvalid;

  /// No description provided for @videoOrUpload.
  ///
  /// In en, this message translates to:
  /// **'Or upload a file'**
  String get videoOrUpload;

  /// No description provided for @playerSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get playerSpeed;

  /// No description provided for @playerLoop.
  ///
  /// In en, this message translates to:
  /// **'Loop'**
  String get playerLoop;

  /// No description provided for @playerRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get playerRestart;

  /// No description provided for @playerMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get playerMute;

  /// No description provided for @playerFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get playerFullScreen;

  /// No description provided for @playerResumedAt.
  ///
  /// In en, this message translates to:
  /// **'Resumed at {time}'**
  String playerResumedAt(String time);

  /// No description provided for @playerStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get playerStartOver;

  /// No description provided for @playerDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get playerDuration;

  /// No description provided for @playerShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Space: play / pause · ← →: 10 s · ↑ ↓: volume · F: full screen · M: mute'**
  String get playerShortcuts;

  /// No description provided for @agoJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get agoJustNow;

  /// No description provided for @agoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String agoMinutes(int count);

  /// No description provided for @agoHours.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String agoHours(int count);

  /// No description provided for @agoDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String agoDays(int count);

  /// No description provided for @agoWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String agoWeeks(int count);

  /// No description provided for @agoMonths.
  ///
  /// In en, this message translates to:
  /// **'{count} months ago'**
  String agoMonths(int count);

  /// No description provided for @agoYears.
  ///
  /// In en, this message translates to:
  /// **'{count} years ago'**
  String agoYears(int count);

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'NOW PLAYING'**
  String get nowPlaying;

  /// No description provided for @videoNewTag.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get videoNewTag;

  /// No description provided for @autoplay.
  ///
  /// In en, this message translates to:
  /// **'Autoplay'**
  String get autoplay;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get filterRecent;

  /// No description provided for @filterContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue watching'**
  String get filterContinue;

  /// No description provided for @filterWatched.
  ///
  /// In en, this message translates to:
  /// **'Watched'**
  String get filterWatched;

  /// No description provided for @noLessonsMatch.
  ///
  /// In en, this message translates to:
  /// **'No lessons found'**
  String get noLessonsMatch;

  /// No description provided for @noLessonsMatchSub.
  ///
  /// In en, this message translates to:
  /// **'Try another word or filter.'**
  String get noLessonsMatchSub;

  /// No description provided for @searchVideos.
  ///
  /// In en, this message translates to:
  /// **'Search videos'**
  String get searchVideos;

  /// No description provided for @lessonNumber.
  ///
  /// In en, this message translates to:
  /// **'Lesson {n}'**
  String lessonNumber(int n);

  /// No description provided for @finishLessonFirst.
  ///
  /// In en, this message translates to:
  /// **'Finish lesson {n} first'**
  String finishLessonFirst(int n);

  /// No description provided for @watchedBadge.
  ///
  /// In en, this message translates to:
  /// **'Watched'**
  String get watchedBadge;

  /// No description provided for @finishThisLessonFirst.
  ///
  /// In en, this message translates to:
  /// **'Finish this lesson first to unlock the next one.'**
  String get finishThisLessonFirst;

  /// No description provided for @noSkipAhead.
  ///
  /// In en, this message translates to:
  /// **'You can\'t skip ahead — watch the lesson to unlock the rest.'**
  String get noSkipAhead;

  /// No description provided for @lessonCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get lessonCompleted;

  /// No description provided for @courseProgress.
  ///
  /// In en, this message translates to:
  /// **'{watched} of {total} lessons watched'**
  String courseProgress(int watched, int total);

  /// No description provided for @courseComplete.
  ///
  /// In en, this message translates to:
  /// **'Course complete — every lesson watched!'**
  String get courseComplete;

  /// No description provided for @permVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get permVideos;

  /// No description provided for @permQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get permQuizzes;

  /// No description provided for @permResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get permResults;

  /// No description provided for @permMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get permMembers;

  /// No description provided for @permCvs.
  ///
  /// In en, this message translates to:
  /// **'CVs'**
  String get permCvs;

  /// No description provided for @permWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get permWebsite;

  /// No description provided for @ctlGroupSections.
  ///
  /// In en, this message translates to:
  /// **'Member menu'**
  String get ctlGroupSections;

  /// No description provided for @ctlGroupVideos.
  ///
  /// In en, this message translates to:
  /// **'Video lessons'**
  String get ctlGroupVideos;

  /// No description provided for @ctlGroupGeneral.
  ///
  /// In en, this message translates to:
  /// **'Whole app'**
  String get ctlGroupGeneral;

  /// No description provided for @ctlGroupDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin dashboard'**
  String get ctlGroupDashboard;

  /// No description provided for @ctlGroupCalculators.
  ///
  /// In en, this message translates to:
  /// **'Calculators'**
  String get ctlGroupCalculators;

  /// No description provided for @ctlCalcHint.
  ///
  /// In en, this message translates to:
  /// **'On: every member can open it. Off: hidden from all members (admins still see it).'**
  String get ctlCalcHint;

  /// No description provided for @ctlCalcEngHint.
  ///
  /// In en, this message translates to:
  /// **'Off (default): only the members you unlocked on the Members page can open it. On: every member can.'**
  String get ctlCalcEngHint;

  /// No description provided for @controlCentre.
  ///
  /// In en, this message translates to:
  /// **'Control centre'**
  String get controlCentre;

  /// No description provided for @controlCentreHint.
  ///
  /// In en, this message translates to:
  /// **'Turn parts of the app on or off for everybody. Changes apply instantly.'**
  String get controlCentreHint;

  /// No description provided for @ctlTurnAllOn.
  ///
  /// In en, this message translates to:
  /// **'Turn all on'**
  String get ctlTurnAllOn;

  /// No description provided for @ctlSectionVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get ctlSectionVideos;

  /// No description provided for @ctlSectionVideosHint.
  ///
  /// In en, this message translates to:
  /// **'Members see the Videos page.'**
  String get ctlSectionVideosHint;

  /// No description provided for @ctlSectionQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get ctlSectionQuizzes;

  /// No description provided for @ctlSectionQuizzesHint.
  ///
  /// In en, this message translates to:
  /// **'Members see the Quizzes page.'**
  String get ctlSectionQuizzesHint;

  /// No description provided for @ctlSectionCvDirectory.
  ///
  /// In en, this message translates to:
  /// **'CV directory'**
  String get ctlSectionCvDirectory;

  /// No description provided for @ctlSectionCvDirectoryHint.
  ///
  /// In en, this message translates to:
  /// **'Members can browse everyone\'s CVs.'**
  String get ctlSectionCvDirectoryHint;

  /// No description provided for @ctlSectionMyCv.
  ///
  /// In en, this message translates to:
  /// **'My CV'**
  String get ctlSectionMyCv;

  /// No description provided for @ctlSectionMyCvHint.
  ///
  /// In en, this message translates to:
  /// **'Members allowed a CV see the CV form.'**
  String get ctlSectionMyCvHint;

  /// No description provided for @ctlVideoSequential.
  ///
  /// In en, this message translates to:
  /// **'Unlock lessons in order'**
  String get ctlVideoSequential;

  /// No description provided for @ctlVideoSequentialHint.
  ///
  /// In en, this message translates to:
  /// **'A lesson opens only after the previous one is watched.'**
  String get ctlVideoSequentialHint;

  /// No description provided for @ctlVideoBlockSkip.
  ///
  /// In en, this message translates to:
  /// **'Block skipping ahead'**
  String get ctlVideoBlockSkip;

  /// No description provided for @ctlVideoBlockSkipHint.
  ///
  /// In en, this message translates to:
  /// **'Members can\'t jump past what they\'ve watched.'**
  String get ctlVideoBlockSkipHint;

  /// No description provided for @ctlVideoAutoplay.
  ///
  /// In en, this message translates to:
  /// **'Autoplay next lesson'**
  String get ctlVideoAutoplay;

  /// No description provided for @ctlVideoAutoplayHint.
  ///
  /// In en, this message translates to:
  /// **'The next lesson starts when one ends.'**
  String get ctlVideoAutoplayHint;

  /// No description provided for @ctlVideoUpNext.
  ///
  /// In en, this message translates to:
  /// **'Up next list'**
  String get ctlVideoUpNext;

  /// No description provided for @ctlVideoUpNextHint.
  ///
  /// In en, this message translates to:
  /// **'Show the other lessons beside the player.'**
  String get ctlVideoUpNextHint;

  /// No description provided for @ctlVideoOptionsBar.
  ///
  /// In en, this message translates to:
  /// **'Player options bar'**
  String get ctlVideoOptionsBar;

  /// No description provided for @ctlVideoOptionsBarHint.
  ///
  /// In en, this message translates to:
  /// **'Skip, loop, restart, volume and speed under the video.'**
  String get ctlVideoOptionsBarHint;

  /// No description provided for @ctlVideoSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get ctlVideoSpeed;

  /// No description provided for @ctlVideoSpeedHint.
  ///
  /// In en, this message translates to:
  /// **'Members can watch at 0.5x – 2x.'**
  String get ctlVideoSpeedHint;

  /// No description provided for @ctlVideoResume.
  ///
  /// In en, this message translates to:
  /// **'Resume where you stopped'**
  String get ctlVideoResume;

  /// No description provided for @ctlVideoResumeHint.
  ///
  /// In en, this message translates to:
  /// **'Reopening a lesson jumps to the last position.'**
  String get ctlVideoResumeHint;

  /// No description provided for @ctlVideoSearch.
  ///
  /// In en, this message translates to:
  /// **'Search and filters'**
  String get ctlVideoSearch;

  /// No description provided for @ctlVideoSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search box and filter chips on the Videos page.'**
  String get ctlVideoSearchHint;

  /// No description provided for @ctlVideoCourseProgress.
  ///
  /// In en, this message translates to:
  /// **'Course progress bar'**
  String get ctlVideoCourseProgress;

  /// No description provided for @ctlVideoCourseProgressHint.
  ///
  /// In en, this message translates to:
  /// **'\"3 of 10 lessons watched\" at the top.'**
  String get ctlVideoCourseProgressHint;

  /// No description provided for @ctlAnimations.
  ///
  /// In en, this message translates to:
  /// **'Animations'**
  String get ctlAnimations;

  /// No description provided for @ctlAnimationsHint.
  ///
  /// In en, this message translates to:
  /// **'Page transitions and entrance animations.'**
  String get ctlAnimationsHint;

  /// No description provided for @ctlRegistration.
  ///
  /// In en, this message translates to:
  /// **'New sign-ups'**
  String get ctlRegistration;

  /// No description provided for @ctlRegistrationHint.
  ///
  /// In en, this message translates to:
  /// **'Show \"Register\" on the sign-in screen.'**
  String get ctlRegistrationHint;

  /// No description provided for @ctlScreenProtection.
  ///
  /// In en, this message translates to:
  /// **'Block screenshots'**
  String get ctlScreenProtection;

  /// No description provided for @ctlScreenProtectionHint.
  ///
  /// In en, this message translates to:
  /// **'On: screenshots and screen recordings of lesson videos come out black (Android, iOS, macOS, Windows). Off: allowed.'**
  String get ctlScreenProtectionHint;

  /// No description provided for @ctlScreenshotException.
  ///
  /// In en, this message translates to:
  /// **'Allow screenshots for amrmesbah33@gmail.com'**
  String get ctlScreenshotException;

  /// No description provided for @ctlScreenshotExceptionHint.
  ///
  /// In en, this message translates to:
  /// **'On: this account can take screenshots and screen recordings even while they are blocked for everyone else. Off: blocked like everyone.'**
  String get ctlScreenshotExceptionHint;

  /// No description provided for @shotAllowedTitle.
  ///
  /// In en, this message translates to:
  /// **'Screenshots are allowed'**
  String get shotAllowedTitle;

  /// No description provided for @shotAllowedBody.
  ///
  /// In en, this message translates to:
  /// **'Warning: \"Block screenshots\" is off, so every member can take screenshots and record the screen right now. Turn it back on when you are done.'**
  String get shotAllowedBody;

  /// No description provided for @shotAllowedBlock.
  ///
  /// In en, this message translates to:
  /// **'Block now'**
  String get shotAllowedBlock;

  /// No description provided for @shotAllowedKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep allowed'**
  String get shotAllowedKeep;

  /// No description provided for @ctlDashboardCharts.
  ///
  /// In en, this message translates to:
  /// **'Dashboard charts'**
  String get ctlDashboardCharts;

  /// No description provided for @ctlDashboardChartsHint.
  ///
  /// In en, this message translates to:
  /// **'The four charts under the numbers.'**
  String get ctlDashboardChartsHint;

  /// No description provided for @ctlDashboardTable.
  ///
  /// In en, this message translates to:
  /// **'Latest attempts table'**
  String get ctlDashboardTable;

  /// No description provided for @ctlDashboardTableHint.
  ///
  /// In en, this message translates to:
  /// **'The table at the bottom of the dashboard.'**
  String get ctlDashboardTableHint;

  /// No description provided for @adminsTitle.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get adminsTitle;

  /// No description provided for @adminsHint.
  ///
  /// In en, this message translates to:
  /// **'Create admins and choose what each one can manage.'**
  String get adminsHint;

  /// No description provided for @addAdmin.
  ///
  /// In en, this message translates to:
  /// **'Add admin'**
  String get addAdmin;

  /// No description provided for @createAdmin.
  ///
  /// In en, this message translates to:
  /// **'Create admin'**
  String get createAdmin;

  /// No description provided for @noAdminsYet.
  ///
  /// In en, this message translates to:
  /// **'No other admins yet.'**
  String get noAdminsYet;

  /// No description provided for @editPermissions.
  ///
  /// In en, this message translates to:
  /// **'Edit permissions'**
  String get editPermissions;

  /// No description provided for @removeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove admin'**
  String get removeAdmin;

  /// No description provided for @removeAdminQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove this admin?'**
  String get removeAdminQuestion;

  /// No description provided for @noPermissions.
  ///
  /// In en, this message translates to:
  /// **'No permissions — can only open Settings.'**
  String get noPermissions;

  /// No description provided for @permissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionsTitle;

  /// No description provided for @adminCreated.
  ///
  /// In en, this message translates to:
  /// **'Admin created. They can sign in now.'**
  String get adminCreated;

  /// No description provided for @permissionsSaved.
  ///
  /// In en, this message translates to:
  /// **'Permissions saved'**
  String get permissionsSaved;

  /// No description provided for @adminFormInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a name and a valid email.'**
  String get adminFormInvalid;

  /// No description provided for @adminPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'The password needs at least 6 characters.'**
  String get adminPasswordShort;

  /// No description provided for @adminEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account.'**
  String get adminEmailInUse;

  /// No description provided for @removeAdminBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will no longer be able to use the admin console. Their login can be deleted from the Firebase console.'**
  String removeAdminBody(String name);

  /// No description provided for @videoCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get videoCategoriesTitle;

  /// No description provided for @videoCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get videoCategoryGeneral;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @videoCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get videoCategory;

  /// No description provided for @videoCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Videos with the same category are grouped together (e.g. GENERAL NOTES).'**
  String get videoCategoryHint;

  /// No description provided for @videoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} videos'**
  String videoCount(int count);

  /// No description provided for @securityBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'This device is not safe for ASEC'**
  String get securityBlockedTitle;

  /// No description provided for @securityBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'To protect the lessons, ASEC does not run while any of the following is on. Turn it off, then tap Check again.'**
  String get securityBlockedBody;

  /// No description provided for @securityCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get securityCheckAgain;

  /// No description provided for @integrityDeveloperOptions.
  ///
  /// In en, this message translates to:
  /// **'Developer options are on (Settings → System → Developer options)'**
  String get integrityDeveloperOptions;

  /// No description provided for @integrityUsbDebugging.
  ///
  /// In en, this message translates to:
  /// **'USB debugging is on'**
  String get integrityUsbDebugging;

  /// No description provided for @integrityDebugger.
  ///
  /// In en, this message translates to:
  /// **'A debugger is attached to the app'**
  String get integrityDebugger;

  /// No description provided for @integrityDebuggable.
  ///
  /// In en, this message translates to:
  /// **'This copy of the app has been modified — install it from the official source'**
  String get integrityDebuggable;

  /// No description provided for @integrityRoot.
  ///
  /// In en, this message translates to:
  /// **'The device is rooted'**
  String get integrityRoot;

  /// No description provided for @integrityJailbreak.
  ///
  /// In en, this message translates to:
  /// **'The device is jailbroken'**
  String get integrityJailbreak;

  /// No description provided for @integrityHooking.
  ///
  /// In en, this message translates to:
  /// **'Hacking / hooking tools are running'**
  String get integrityHooking;

  /// No description provided for @certificateQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Certificate quizzes'**
  String get certificateQuizzes;

  /// No description provided for @certificateQuiz.
  ///
  /// In en, this message translates to:
  /// **'Certificate quiz'**
  String get certificateQuiz;

  /// No description provided for @certificateQuizzesAdminSub.
  ///
  /// In en, this message translates to:
  /// **'One final exam per course. Members who score 70% or more get an ASEC certificate.'**
  String get certificateQuizzesAdminSub;

  /// No description provided for @certificateQuizzesUserSub.
  ///
  /// In en, this message translates to:
  /// **'Finish every lesson of a course, then pass its final exam with 70% to earn your ASEC certificate.'**
  String get certificateQuizzesUserSub;

  /// No description provided for @newCertificateQuiz.
  ///
  /// In en, this message translates to:
  /// **'New certificate quiz'**
  String get newCertificateQuiz;

  /// No description provided for @noCertificateQuizzesTitle.
  ///
  /// In en, this message translates to:
  /// **'No certificate quizzes yet'**
  String get noCertificateQuizzesTitle;

  /// No description provided for @noCertificateQuizzesAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Create one final exam for each course.'**
  String get noCertificateQuizzesAdminSub;

  /// No description provided for @noCoursesTitle.
  ///
  /// In en, this message translates to:
  /// **'No courses yet'**
  String get noCoursesTitle;

  /// No description provided for @noCoursesUserSub.
  ///
  /// In en, this message translates to:
  /// **'Courses and their final exams appear here.'**
  String get noCoursesUserSub;

  /// No description provided for @courseLabel.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get courseLabel;

  /// No description provided for @courseCaption.
  ///
  /// In en, this message translates to:
  /// **'Members unlock this exam after watching every lesson of the course. Pass mark: 70%.'**
  String get courseCaption;

  /// No description provided for @chooseCourse.
  ///
  /// In en, this message translates to:
  /// **'Choose a course'**
  String get chooseCourse;

  /// No description provided for @errChooseCourse.
  ///
  /// In en, this message translates to:
  /// **'Choose the course this exam belongs to.'**
  String get errChooseCourse;

  /// No description provided for @certLocked.
  ///
  /// In en, this message translates to:
  /// **'Watch all lessons first · {watched}/{total}'**
  String certLocked(int watched, int total);

  /// No description provided for @certReady.
  ///
  /// In en, this message translates to:
  /// **'Ready — start the final exam'**
  String get certReady;

  /// No description provided for @certFailed.
  ///
  /// In en, this message translates to:
  /// **'Last try {percent}% · you need 70% — try again'**
  String certFailed(String percent);

  /// No description provided for @certPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed with {percent}% · view your certificate'**
  String certPassed(String percent);

  /// No description provided for @certNoExam.
  ///
  /// In en, this message translates to:
  /// **'Final exam coming soon'**
  String get certNoExam;

  /// No description provided for @certLockedSnack.
  ///
  /// In en, this message translates to:
  /// **'Finish every lesson in this course to unlock its exam.'**
  String get certLockedSnack;

  /// No description provided for @passedTitle.
  ///
  /// In en, this message translates to:
  /// **'Congratulations, you passed!'**
  String get passedTitle;

  /// No description provided for @failedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not passed yet'**
  String get failedTitle;

  /// No description provided for @failedBody.
  ///
  /// In en, this message translates to:
  /// **'You need 70% to pass. Review the lessons and try again.'**
  String get failedBody;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @viewCertificate.
  ///
  /// In en, this message translates to:
  /// **'View certificate'**
  String get viewCertificate;

  /// No description provided for @lastTry.
  ///
  /// In en, this message translates to:
  /// **'Your last try: {percent}% — you need 70% to pass.'**
  String lastTry(String percent);

  /// No description provided for @certificateTitle.
  ///
  /// In en, this message translates to:
  /// **'Your certificate'**
  String get certificateTitle;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @passMark.
  ///
  /// In en, this message translates to:
  /// **'Pass mark 70%'**
  String get passMark;

  /// No description provided for @certificateBadge.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get certificateBadge;

  /// No description provided for @unitConverter.
  ///
  /// In en, this message translates to:
  /// **'Unit converter'**
  String get unitConverter;

  /// No description provided for @unitConverterSub.
  ///
  /// In en, this message translates to:
  /// **'Main engineering units — works without internet.'**
  String get unitConverterSub;

  /// No description provided for @unitFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get unitFrom;

  /// No description provided for @unitTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get unitTo;

  /// No description provided for @unitValue.
  ///
  /// In en, this message translates to:
  /// **'Enter a value'**
  String get unitValue;

  /// No description provided for @swapUnits.
  ///
  /// In en, this message translates to:
  /// **'Swap units'**
  String get swapUnits;

  /// No description provided for @allConversions.
  ///
  /// In en, this message translates to:
  /// **'All conversions'**
  String get allConversions;

  /// No description provided for @openUnitConverter.
  ///
  /// In en, this message translates to:
  /// **'Unit converter'**
  String get openUnitConverter;

  /// No description provided for @copiedValue.
  ///
  /// In en, this message translates to:
  /// **'Copied {value}'**
  String copiedValue(String value);

  /// No description provided for @engineeringCalc.
  ///
  /// In en, this message translates to:
  /// **'Engineering calculators'**
  String get engineeringCalc;

  /// No description provided for @engineeringCalcShort.
  ///
  /// In en, this message translates to:
  /// **'Calculations'**
  String get engineeringCalcShort;

  /// No description provided for @engineeringCalcSub.
  ///
  /// In en, this message translates to:
  /// **'HVAC, fire fighting, plumbing and medical gas — quick design checks.'**
  String get engineeringCalcSub;

  /// No description provided for @ductCalc.
  ///
  /// In en, this message translates to:
  /// **'Duct calculator'**
  String get ductCalc;

  /// No description provided for @ductCalcShort.
  ///
  /// In en, this message translates to:
  /// **'Ducts'**
  String get ductCalcShort;

  /// No description provided for @pipeCalc.
  ///
  /// In en, this message translates to:
  /// **'Pipe sizer'**
  String get pipeCalc;

  /// No description provided for @pipeCalcShort.
  ///
  /// In en, this message translates to:
  /// **'Pipes'**
  String get pipeCalcShort;

  /// No description provided for @plumbingFireCalc.
  ///
  /// In en, this message translates to:
  /// **'Plumbing'**
  String get plumbingFireCalc;

  /// No description provided for @plumbingFireCalcShort.
  ///
  /// In en, this message translates to:
  /// **'Plumbing'**
  String get plumbingFireCalcShort;

  /// No description provided for @fireCalc.
  ///
  /// In en, this message translates to:
  /// **'Fire fighting'**
  String get fireCalc;

  /// No description provided for @fireCalcShort.
  ///
  /// In en, this message translates to:
  /// **'Firefighting'**
  String get fireCalcShort;

  /// No description provided for @calcInputs.
  ///
  /// In en, this message translates to:
  /// **'Inputs'**
  String get calcInputs;

  /// No description provided for @calcResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get calcResults;

  /// No description provided for @calcFormula.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get calcFormula;

  /// No description provided for @calcReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get calcReset;

  /// No description provided for @calcTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a result to change its unit · long-press to copy'**
  String get calcTapHint;

  /// No description provided for @calcFillAll.
  ///
  /// In en, this message translates to:
  /// **'Fill in every field to see the results.'**
  String get calcFillAll;

  /// No description provided for @calcDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Simplified design estimate. Check it against the governing code and a detailed calculation before issuing drawings.'**
  String get calcDisclaimer;

  /// No description provided for @calcExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get calcExportPdf;

  /// No description provided for @calcExportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get calcExportExcel;

  /// No description provided for @calcItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get calcItem;

  /// No description provided for @calcValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get calcValue;

  /// No description provided for @calcUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get calcUnit;

  /// No description provided for @calcDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get calcDate;

  /// No description provided for @calcFileName.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get calcFileName;

  /// No description provided for @calcSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {name}'**
  String calcSaved(String name);

  /// No description provided for @offlineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offlineTitle;

  /// No description provided for @offlineBody.
  ///
  /// In en, this message translates to:
  /// **'The tools that don\'t need the internet still work here. The rest of the app comes back as soon as you\'re online.'**
  String get offlineBody;

  /// No description provided for @offlineRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get offlineRetry;

  /// No description provided for @moreTab.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTab;

  /// No description provided for @certificateShort.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get certificateShort;

  /// No description provided for @memberAccess.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get memberAccess;

  /// No description provided for @editAccess.
  ///
  /// In en, this message translates to:
  /// **'Edit access'**
  String get editAccess;

  /// No description provided for @accessCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get accessCourses;

  /// No description provided for @accessAllCourses.
  ///
  /// In en, this message translates to:
  /// **'All courses'**
  String get accessAllCourses;

  /// No description provided for @accessCoursesCaption.
  ///
  /// In en, this message translates to:
  /// **'Choose the courses this member can watch. \"All courses\" also includes any course added later.'**
  String get accessCoursesCaption;

  /// No description provided for @accessPlatforms.
  ///
  /// In en, this message translates to:
  /// **'Video platforms'**
  String get accessPlatforms;

  /// No description provided for @accessPlatformsCaption.
  ///
  /// In en, this message translates to:
  /// **'The member can sign in on any device. Videos, video quizzes and certificates open only on the checked platforms; everything else opens everywhere.'**
  String get accessPlatformsCaption;

  /// No description provided for @accessAllPlatforms.
  ///
  /// In en, this message translates to:
  /// **'All devices'**
  String get accessAllPlatforms;

  /// No description provided for @accessPeriod.
  ///
  /// In en, this message translates to:
  /// **'Access period'**
  String get accessPeriod;

  /// No description provided for @accessPermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get accessPermanent;

  /// No description provided for @accessDates.
  ///
  /// In en, this message translates to:
  /// **'From – to'**
  String get accessDates;

  /// No description provided for @accessFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get accessFrom;

  /// No description provided for @accessUntil.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get accessUntil;

  /// No description provided for @accessPause.
  ///
  /// In en, this message translates to:
  /// **'Pause access'**
  String get accessPause;

  /// No description provided for @accessResume.
  ///
  /// In en, this message translates to:
  /// **'Resume access'**
  String get accessResume;

  /// No description provided for @accessPauseCaption.
  ///
  /// In en, this message translates to:
  /// **'Freezes the member\'s access now. When you resume, the paused days are added back to the end date.'**
  String get accessPauseCaption;

  /// No description provided for @accessPausedSince.
  ///
  /// In en, this message translates to:
  /// **'Paused since {date}'**
  String accessPausedSince(String date);

  /// No description provided for @accessPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get accessPaused;

  /// No description provided for @accessUntilShort.
  ///
  /// In en, this message translates to:
  /// **'until {date}'**
  String accessUntilShort(String date);

  /// No description provided for @accessCoursesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} courses'**
  String accessCoursesCount(int count);

  /// No description provided for @accessSaved.
  ///
  /// In en, this message translates to:
  /// **'Access saved'**
  String get accessSaved;

  /// No description provided for @accessPickPlatform.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one device.'**
  String get accessPickPlatform;

  /// No description provided for @accessPickCourse.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one course, or All courses.'**
  String get accessPickCourse;

  /// No description provided for @accessDatesInvalid.
  ///
  /// In en, this message translates to:
  /// **'The end date must be after the start date.'**
  String get accessDatesInvalid;

  /// No description provided for @accessExpiredShort.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get accessExpiredShort;

  /// No description provided for @blockedTitlePaused.
  ///
  /// In en, this message translates to:
  /// **'Your access is paused'**
  String get blockedTitlePaused;

  /// No description provided for @blockedBodyPaused.
  ///
  /// In en, this message translates to:
  /// **'ASEC has paused your access for now. Contact ASEC to resume it — you won\'t lose the paused days.'**
  String get blockedBodyPaused;

  /// No description provided for @blockedTitleExpired.
  ///
  /// In en, this message translates to:
  /// **'Your access has ended'**
  String get blockedTitleExpired;

  /// No description provided for @blockedBodyExpired.
  ///
  /// In en, this message translates to:
  /// **'Your access ended on {date}. Contact ASEC to renew it.'**
  String blockedBodyExpired(String date);

  /// No description provided for @blockedTitleNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Your access hasn\'t started yet'**
  String get blockedTitleNotStarted;

  /// No description provided for @blockedBodyNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Your access starts on {date}.'**
  String blockedBodyNotStarted(String date);

  /// No description provided for @blockedTitlePlatform.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device'**
  String get blockedTitlePlatform;

  /// No description provided for @blockedBodyPlatform.
  ///
  /// In en, this message translates to:
  /// **'Your account can be used on: {platforms}.'**
  String blockedBodyPlatform(String platforms);

  /// No description provided for @tbMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get tbMember;

  /// No description provided for @tbThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get tbThisDevice;

  /// No description provided for @tbAllowedOn.
  ///
  /// In en, this message translates to:
  /// **'Allowed on'**
  String get tbAllowedOn;

  /// No description provided for @tbStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get tbStatus;

  /// No description provided for @tbStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get tbStarts;

  /// No description provided for @tbEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get tbEnds;

  /// No description provided for @tbWrongDevice.
  ///
  /// In en, this message translates to:
  /// **'Wrong device'**
  String get tbWrongDevice;

  /// No description provided for @tbNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get tbNotStarted;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @downloadsSub.
  ///
  /// In en, this message translates to:
  /// **'Lessons saved inside ASEC to watch without internet. They stay in the app only.'**
  String get downloadsSub;

  /// No description provided for @downloadVideo.
  ///
  /// In en, this message translates to:
  /// **'Download for offline'**
  String get downloadVideo;

  /// No description provided for @downloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Downloading — you\'ll find it in Downloads'**
  String get downloadStarted;

  /// No description provided for @downloadCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get downloadCancel;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed — tap to try again'**
  String get downloadFailed;

  /// No description provided for @downloadDone.
  ///
  /// In en, this message translates to:
  /// **'Downloaded — tap to remove'**
  String get downloadDone;

  /// No description provided for @downloadRemoveQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove “{title}” from downloads?'**
  String downloadRemoveQuestion(String title);

  /// No description provided for @downloadRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'The lesson stays in Videos; it just won\'t play without internet any more.'**
  String get downloadRemoveBody;

  /// No description provided for @downloadRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get downloadRemove;

  /// No description provided for @downloadsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get downloadsEmptyTitle;

  /// No description provided for @downloadsEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Tap the download icon on a lesson in Videos to watch it without internet.'**
  String get downloadsEmptySub;

  /// No description provided for @downloadsStorage.
  ///
  /// In en, this message translates to:
  /// **'{size} used on this device'**
  String downloadsStorage(String size);

  /// No description provided for @downloadsRemoveAll.
  ///
  /// In en, this message translates to:
  /// **'Remove all'**
  String get downloadsRemoveAll;

  /// No description provided for @downloadsRemoveAllQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove all downloads?'**
  String get downloadsRemoveAllQuestion;

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get updateTitle;

  /// No description provided for @updateMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version of ASEC is ready on Google Play with improvements and fixes.'**
  String get updateMessage;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'This version is no longer supported. Please update from Google Play to keep using ASEC.'**
  String get updateRequiredMessage;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get updateWhatsNew;

  /// No description provided for @updateCurrentVersion.
  ///
  /// In en, this message translates to:
  /// **'Your version: {version}'**
  String updateCurrentVersion(String version);

  /// No description provided for @patchReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Update ready'**
  String get patchReadyTitle;

  /// No description provided for @patchReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'Improvements were downloaded in the background. Close and reopen the app to apply them.'**
  String get patchReadyMessage;

  /// No description provided for @patchRestart.
  ///
  /// In en, this message translates to:
  /// **'Close & reopen'**
  String get patchRestart;

  /// No description provided for @calcColumn.
  ///
  /// In en, this message translates to:
  /// **'Eng. calculators'**
  String get calcColumn;

  /// No description provided for @calcAllowed.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get calcAllowed;

  /// No description provided for @calcNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get calcNotAllowed;

  /// No description provided for @settingsMySpace.
  ///
  /// In en, this message translates to:
  /// **'My space'**
  String get settingsMySpace;

  /// No description provided for @settingsMySpaceHint.
  ///
  /// In en, this message translates to:
  /// **'Your CV, certificates, saved lessons and tools.'**
  String get settingsMySpaceHint;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeSub.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off.'**
  String get homeSub;

  /// No description provided for @homeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue watching'**
  String get homeContinue;

  /// No description provided for @homeStart.
  ///
  /// In en, this message translates to:
  /// **'Start your first lesson'**
  String get homeStart;

  /// No description provided for @homeStartSub.
  ///
  /// In en, this message translates to:
  /// **'Your courses are ready. Open one to begin.'**
  String get homeStartSub;

  /// No description provided for @homeAllDone.
  ///
  /// In en, this message translates to:
  /// **'Every lesson watched — well done!'**
  String get homeAllDone;

  /// No description provided for @homeProgress.
  ///
  /// In en, this message translates to:
  /// **'Your progress'**
  String get homeProgress;

  /// No description provided for @homeLessonsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} lessons to go'**
  String homeLessonsLeft(int count);

  /// No description provided for @homeQuickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick access'**
  String get homeQuickAccess;

  /// No description provided for @homeCourses.
  ///
  /// In en, this message translates to:
  /// **'Your courses'**
  String get homeCourses;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeVideosHint.
  ///
  /// In en, this message translates to:
  /// **'Courses & lessons'**
  String get homeVideosHint;

  /// No description provided for @homeConverterHint.
  ///
  /// In en, this message translates to:
  /// **'Works offline'**
  String get homeConverterHint;

  /// No description provided for @homeQuizzesHint.
  ///
  /// In en, this message translates to:
  /// **'Test what you learned'**
  String get homeQuizzesHint;

  /// No description provided for @homeCvsHint.
  ///
  /// In en, this message translates to:
  /// **'Find engineers'**
  String get homeCvsHint;

  /// No description provided for @homeCertificateHint.
  ///
  /// In en, this message translates to:
  /// **'Earn your certificate'**
  String get homeCertificateHint;

  /// No description provided for @homeCalcHint.
  ///
  /// In en, this message translates to:
  /// **'HVAC, fire, plumbing'**
  String get homeCalcHint;

  /// No description provided for @homeResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get homeResume;

  /// No description provided for @homeLessonOf.
  ///
  /// In en, this message translates to:
  /// **'Lesson {n} of {total}'**
  String homeLessonOf(int n, int total);

  /// No description provided for @unitConverterShort.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get unitConverterShort;

  /// No description provided for @sectionQuizLabel.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get sectionQuizLabel;

  /// No description provided for @sectionQuizCaption.
  ///
  /// In en, this message translates to:
  /// **'Optional. Link this quiz to a course section: members find it at the end of that section and can start it after watching all its lessons.'**
  String get sectionQuizCaption;

  /// No description provided for @sectionNone.
  ///
  /// In en, this message translates to:
  /// **'None — a general quiz'**
  String get sectionNone;

  /// No description provided for @sectionQuizzesTitle.
  ///
  /// In en, this message translates to:
  /// **'Section quiz'**
  String get sectionQuizzesTitle;

  /// No description provided for @addSectionQuiz.
  ///
  /// In en, this message translates to:
  /// **'Add quiz'**
  String get addSectionQuiz;

  /// No description provided for @sectionQuizLocked.
  ///
  /// In en, this message translates to:
  /// **'Watch every lesson of this section to unlock its quiz.'**
  String get sectionQuizLocked;

  /// No description provided for @accessDevice.
  ///
  /// In en, this message translates to:
  /// **'Login device'**
  String get accessDevice;

  /// No description provided for @accessDeviceCaption.
  ///
  /// In en, this message translates to:
  /// **'Members can sign in on any number of devices. The device below was locked to the account before; you can remove it or block it.'**
  String get accessDeviceCaption;

  /// No description provided for @accessDeviceNone.
  ///
  /// In en, this message translates to:
  /// **'No device locked — the member can sign in on any device.'**
  String get accessDeviceNone;

  /// No description provided for @accessDeviceUnknown.
  ///
  /// In en, this message translates to:
  /// **'A device'**
  String get accessDeviceUnknown;

  /// No description provided for @accessDeviceSince.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String accessDeviceSince(String date);

  /// No description provided for @accessDeviceRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove device'**
  String get accessDeviceRemove;

  /// No description provided for @accessDeviceRemoveQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove this device?'**
  String get accessDeviceRemoveQuestion;

  /// No description provided for @accessDeviceRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'The member is shut out of {device} now. The next device they sign in on becomes their device.'**
  String accessDeviceRemoveBody(String device);

  /// No description provided for @accessDeviceRemoved.
  ///
  /// In en, this message translates to:
  /// **'Device removed. The member can sign in on the new device now.'**
  String get accessDeviceRemoved;

  /// No description provided for @blockedTitleOtherDevice.
  ///
  /// In en, this message translates to:
  /// **'This account is used on another device'**
  String get blockedTitleOtherDevice;

  /// No description provided for @blockedBodyOtherDevice.
  ///
  /// In en, this message translates to:
  /// **'Your account works on one device only. To use this device instead, ask the admin to remove the old one, then sign out and sign in again here.'**
  String get blockedBodyOtherDevice;

  /// No description provided for @blockedTitleDeviceRemoved.
  ///
  /// In en, this message translates to:
  /// **'This device was removed'**
  String get blockedTitleDeviceRemoved;

  /// No description provided for @blockedBodyDeviceRemoved.
  ///
  /// In en, this message translates to:
  /// **'The admin removed this device from your account. To use it again, sign out and sign in.'**
  String get blockedBodyDeviceRemoved;

  /// No description provided for @tbAccountDevice.
  ///
  /// In en, this message translates to:
  /// **'Account device'**
  String get tbAccountDevice;

  /// No description provided for @engEngagement.
  ///
  /// In en, this message translates to:
  /// **'Engagement'**
  String get engEngagement;

  /// No description provided for @engEngagementSub.
  ///
  /// In en, this message translates to:
  /// **'Notifications, tips & tricks, the members\' Library and their stars.'**
  String get engEngagementSub;

  /// No description provided for @engNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get engNotifications;

  /// No description provided for @engNotificationsSub.
  ///
  /// In en, this message translates to:
  /// **'Messages from the ASEC team.'**
  String get engNotificationsSub;

  /// No description provided for @engNotificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get engNotificationsEmpty;

  /// No description provided for @engNotificationsEmptySub.
  ///
  /// In en, this message translates to:
  /// **'New messages from the admin appear here.'**
  String get engNotificationsEmptySub;

  /// No description provided for @engSendNotification.
  ///
  /// In en, this message translates to:
  /// **'Send notification'**
  String get engSendNotification;

  /// No description provided for @engSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get engSend;

  /// No description provided for @engNotifSent.
  ///
  /// In en, this message translates to:
  /// **'Notification sent'**
  String get engNotifSent;

  /// No description provided for @engNotifTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Notification title'**
  String get engNotifTitleHint;

  /// No description provided for @engNotifBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Write the message members will read'**
  String get engNotifBodyHint;

  /// No description provided for @engNotifAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Sent to every member — it appears under the bell in their app bar, with the number not read yet.'**
  String get engNotifAdminSub;

  /// No description provided for @engTipsTricks.
  ///
  /// In en, this message translates to:
  /// **'Tips & tricks'**
  String get engTipsTricks;

  /// No description provided for @engTipsAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Tips pop up over the members\' home page when they open the app. A member can save a tip; the number shows how many saved it.'**
  String get engTipsAdminSub;

  /// No description provided for @engAddTip.
  ///
  /// In en, this message translates to:
  /// **'Add tip'**
  String get engAddTip;

  /// No description provided for @engTipAdded.
  ///
  /// In en, this message translates to:
  /// **'Tip added'**
  String get engTipAdded;

  /// No description provided for @engTipTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Tip title'**
  String get engTipTitleHint;

  /// No description provided for @engTipBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Write the tip'**
  String get engTipBodyHint;

  /// No description provided for @engTipSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Saved — find it under the bookmark icon at the top'**
  String get engTipSavedToast;

  /// No description provided for @engTipTapToClose.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere to close'**
  String get engTipTapToClose;

  /// No description provided for @engTipSavedCount.
  ///
  /// In en, this message translates to:
  /// **'Saved by {count}'**
  String engTipSavedCount(int count);

  /// No description provided for @engTipActive.
  ///
  /// In en, this message translates to:
  /// **'Shown to members'**
  String get engTipActive;

  /// No description provided for @engTipsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tips yet'**
  String get engTipsEmpty;

  /// No description provided for @engSavedTips.
  ///
  /// In en, this message translates to:
  /// **'Saved tips'**
  String get engSavedTips;

  /// No description provided for @engSavedTipsSub.
  ///
  /// In en, this message translates to:
  /// **'The tips you saved.'**
  String get engSavedTipsSub;

  /// No description provided for @engSavedTipsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get engSavedTipsEmpty;

  /// No description provided for @engTipUnsave.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get engTipUnsave;

  /// No description provided for @engLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get engLibrary;

  /// No description provided for @engLibraryFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get engLibraryFiles;

  /// No description provided for @engLibraryFilesHint.
  ///
  /// In en, this message translates to:
  /// **'Documents from ASEC'**
  String get engLibraryFilesHint;

  /// No description provided for @engLibraryBest.
  ///
  /// In en, this message translates to:
  /// **'The best'**
  String get engLibraryBest;

  /// No description provided for @engLibraryBestHint.
  ///
  /// In en, this message translates to:
  /// **'The best CVs in the app'**
  String get engLibraryBestHint;

  /// No description provided for @engLibraryCertificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get engLibraryCertificate;

  /// No description provided for @engLibrarySub.
  ///
  /// In en, this message translates to:
  /// **'Files the ASEC team shares with you.'**
  String get engLibrarySub;

  /// No description provided for @engLibraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No files yet'**
  String get engLibraryEmpty;

  /// No description provided for @engLibraryEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Files added by the admin appear here.'**
  String get engLibraryEmptySub;

  /// No description provided for @engLibraryAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Files in the members\' Library (home page → Library → Files).'**
  String get engLibraryAdminSub;

  /// No description provided for @engLeaderboardSub.
  ///
  /// In en, this message translates to:
  /// **'Members ranked by the stars they earned watching courses.'**
  String get engLeaderboardSub;

  /// No description provided for @engLeaderboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stars yet'**
  String get engLeaderboardEmpty;

  /// No description provided for @engYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get engYou;

  /// No description provided for @engMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get engMember;

  /// No description provided for @engStarsTab.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get engStarsTab;

  /// No description provided for @engStarsAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Each member\'s stars per course — 1 star for every 20% watched, 5 at most per course. Tap a member to see their courses.'**
  String get engStarsAdminSub;

  /// No description provided for @engStarsHint.
  ///
  /// In en, this message translates to:
  /// **'1 star for every 20% you watch — 5 stars per course'**
  String get engStarsHint;

  /// No description provided for @engStarsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} stars'**
  String engStarsCount(int count);

  /// No description provided for @engFilesTab.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get engFilesTab;

  /// No description provided for @engNewFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get engNewFolder;

  /// No description provided for @engFolderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get engFolderName;

  /// No description provided for @engFolderCreated.
  ///
  /// In en, this message translates to:
  /// **'Folder created'**
  String get engFolderCreated;

  /// No description provided for @engRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get engRename;

  /// No description provided for @engCourseFilesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No files in this course yet'**
  String get engCourseFilesEmpty;

  /// No description provided for @engCourseFilesEmptyAdmin.
  ///
  /// In en, this message translates to:
  /// **'Create a folder, then upload files into it.'**
  String get engCourseFilesEmptyAdmin;

  /// No description provided for @engFolderEmpty.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get engFolderEmpty;

  /// No description provided for @engAllFolders.
  ///
  /// In en, this message translates to:
  /// **'All folders'**
  String get engAllFolders;

  /// No description provided for @engFileCount.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String engFileCount(int count);

  /// No description provided for @engDeleteFolderBody.
  ///
  /// In en, this message translates to:
  /// **'The folder and every file in it will be deleted.'**
  String get engDeleteFolderBody;

  /// No description provided for @engDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get engDeleteBody;

  /// No description provided for @engFileUploaded.
  ///
  /// In en, this message translates to:
  /// **'File uploaded'**
  String get engFileUploaded;

  /// No description provided for @engFileOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file'**
  String get engFileOpenFailed;

  /// No description provided for @engFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get engFieldRequired;

  /// No description provided for @engCourseSequential.
  ///
  /// In en, this message translates to:
  /// **'Watch in order'**
  String get engCourseSequential;

  /// No description provided for @engCourseSequentialHint.
  ///
  /// In en, this message translates to:
  /// **'A video opens only after the one before it is watched'**
  String get engCourseSequentialHint;

  /// No description provided for @engVideoDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get engVideoDefault;

  /// No description provided for @engVideoCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get engVideoCustom;

  /// No description provided for @engMakeDefault.
  ///
  /// In en, this message translates to:
  /// **'Make default (every member)'**
  String get engMakeDefault;

  /// No description provided for @engMakeCustom.
  ///
  /// In en, this message translates to:
  /// **'Make custom'**
  String get engMakeCustom;

  /// No description provided for @engRulesMissing.
  ///
  /// In en, this message translates to:
  /// **'Not allowed by Firebase. Deploy the new rules: firebase deploy --only firestore:rules,storage'**
  String get engRulesMissing;

  /// No description provided for @engChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Upload into which folder?'**
  String get engChooseFolder;

  /// No description provided for @engChooseFolderSub.
  ///
  /// In en, this message translates to:
  /// **'Pick a folder, or create a new one — then choose the file.'**
  String get engChooseFolderSub;

  /// No description provided for @engNoFoldersYet.
  ///
  /// In en, this message translates to:
  /// **'No folders yet — create the first one:'**
  String get engNoFoldersYet;

  /// No description provided for @engOtherFiles.
  ///
  /// In en, this message translates to:
  /// **'Other files'**
  String get engOtherFiles;

  /// No description provided for @engPartners.
  ///
  /// In en, this message translates to:
  /// **'Our partners'**
  String get engPartners;

  /// No description provided for @engPartnersSub.
  ///
  /// In en, this message translates to:
  /// **'Companies that work with ASEC'**
  String get engPartnersSub;

  /// No description provided for @engPartnersAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Partner logos — they turn in a 3D ring around the ASEC logo on the members\' home page (and show on the website). Only published ones appear.'**
  String get engPartnersAdminSub;

  /// No description provided for @engPartnerAdd.
  ///
  /// In en, this message translates to:
  /// **'Add partner'**
  String get engPartnerAdd;

  /// No description provided for @engPartnerName.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get engPartnerName;

  /// No description provided for @engPartnerAdded.
  ///
  /// In en, this message translates to:
  /// **'Partner added'**
  String get engPartnerAdded;

  /// No description provided for @engPartnersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No partners yet — add the first logo'**
  String get engPartnersEmpty;

  /// No description provided for @updCardTitle.
  ///
  /// In en, this message translates to:
  /// **'App update'**
  String get updCardTitle;

  /// No description provided for @updCardHint.
  ///
  /// In en, this message translates to:
  /// **'Ask Android users to update the app. Use the build number — the part after + in pubspec (1.0.1+9 → 9).'**
  String get updCardHint;

  /// No description provided for @updLatestBuild.
  ///
  /// In en, this message translates to:
  /// **'Latest build — optional update'**
  String get updLatestBuild;

  /// No description provided for @updLatestBuildHint.
  ///
  /// In en, this message translates to:
  /// **'Builds below this see a \"New version\" message they can close.'**
  String get updLatestBuildHint;

  /// No description provided for @updMinBuild.
  ///
  /// In en, this message translates to:
  /// **'Minimum build — forced update'**
  String get updMinBuild;

  /// No description provided for @updMinBuildHint.
  ///
  /// In en, this message translates to:
  /// **'Builds below this must update. The message can\'t be closed.'**
  String get updMinBuildHint;

  /// No description provided for @updNotesEn.
  ///
  /// In en, this message translates to:
  /// **'What\'s new (English)'**
  String get updNotesEn;

  /// No description provided for @updNotesAr.
  ///
  /// In en, this message translates to:
  /// **'What\'s new (Arabic)'**
  String get updNotesAr;

  /// No description provided for @updWarning.
  ///
  /// In en, this message translates to:
  /// **'Raise these numbers only after the new version is live on Google Play — otherwise users will be asked to update to a version they can\'t download yet.'**
  String get updWarning;

  /// No description provided for @updStatusForced.
  ///
  /// In en, this message translates to:
  /// **'Forced update is on: builds below {build} must update'**
  String updStatusForced(String build);

  /// No description provided for @updStatusOff.
  ///
  /// In en, this message translates to:
  /// **'No forced update'**
  String get updStatusOff;

  /// No description provided for @updThisApp.
  ///
  /// In en, this message translates to:
  /// **'This app: {version}'**
  String updThisApp(String version);

  /// No description provided for @updStopForcing.
  ///
  /// In en, this message translates to:
  /// **'Stop forcing'**
  String get updStopForcing;

  /// No description provided for @updSaved.
  ///
  /// In en, this message translates to:
  /// **'Update settings saved'**
  String get updSaved;

  /// No description provided for @updUseThisVersion.
  ///
  /// In en, this message translates to:
  /// **'Use this version'**
  String get updUseThisVersion;

  /// No description provided for @updBuildToUse.
  ///
  /// In en, this message translates to:
  /// **'Build number to update to'**
  String get updBuildToUse;

  /// No description provided for @updBuildToUseHint.
  ///
  /// In en, this message translates to:
  /// **'Filled from this app. Change it if your new Android build has a different number.'**
  String get updBuildToUseHint;

  /// No description provided for @updForceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Should users be forced to update?'**
  String get updForceQuestion;

  /// No description provided for @updOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get updOptional;

  /// No description provided for @updForced.
  ///
  /// In en, this message translates to:
  /// **'Forced'**
  String get updForced;

  /// No description provided for @updOptionalSet.
  ///
  /// In en, this message translates to:
  /// **'Optional update set: builds below {build} will be asked to update'**
  String updOptionalSet(String build);

  /// No description provided for @updEnterBuild.
  ///
  /// In en, this message translates to:
  /// **'Enter the build number'**
  String get updEnterBuild;

  /// No description provided for @permEngagement.
  ///
  /// In en, this message translates to:
  /// **'Engagement'**
  String get permEngagement;

  /// No description provided for @permViewOnly.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get permViewOnly;

  /// No description provided for @permDashboardCharts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get permDashboardCharts;

  /// No description provided for @permDashboardTable.
  ///
  /// In en, this message translates to:
  /// **'Latest attempts table'**
  String get permDashboardTable;

  /// No description provided for @permVideosAdd.
  ///
  /// In en, this message translates to:
  /// **'Add / upload videos and course files'**
  String get permVideosAdd;

  /// No description provided for @permVideosEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit videos and course files'**
  String get permVideosEdit;

  /// No description provided for @permVideosDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete videos and course files'**
  String get permVideosDelete;

  /// No description provided for @permVideosPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish / hide videos'**
  String get permVideosPublish;

  /// No description provided for @permVideosAccess.
  ///
  /// In en, this message translates to:
  /// **'Course access (default / custom, watch in order)'**
  String get permVideosAccess;

  /// No description provided for @permQuizzesCreate.
  ///
  /// In en, this message translates to:
  /// **'Create quizzes'**
  String get permQuizzesCreate;

  /// No description provided for @permQuizzesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit quizzes'**
  String get permQuizzesEdit;

  /// No description provided for @permQuizzesDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete quizzes'**
  String get permQuizzesDelete;

  /// No description provided for @permQuizzesOpen.
  ///
  /// In en, this message translates to:
  /// **'Open / close quizzes'**
  String get permQuizzesOpen;

  /// No description provided for @permQuizzesCertificates.
  ///
  /// In en, this message translates to:
  /// **'Certificate quizzes'**
  String get permQuizzesCertificates;

  /// No description provided for @permMembersBlock.
  ///
  /// In en, this message translates to:
  /// **'Activate / block members'**
  String get permMembersBlock;

  /// No description provided for @permMembersAccess.
  ///
  /// In en, this message translates to:
  /// **'Edit access (courses, period, pause, calculators)'**
  String get permMembersAccess;

  /// No description provided for @permMembersDevice.
  ///
  /// In en, this message translates to:
  /// **'Reset device'**
  String get permMembersDevice;

  /// No description provided for @permCvsReview.
  ///
  /// In en, this message translates to:
  /// **'Review CVs (status)'**
  String get permCvsReview;

  /// No description provided for @permCvsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete CVs'**
  String get permCvsDelete;

  /// No description provided for @permCvsGrant.
  ///
  /// In en, this message translates to:
  /// **'Give CV rights'**
  String get permCvsGrant;

  /// No description provided for @permEngNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permEngNotifications;

  /// No description provided for @permEngTips.
  ///
  /// In en, this message translates to:
  /// **'Tips & tricks'**
  String get permEngTips;

  /// No description provided for @permEngLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get permEngLibrary;

  /// No description provided for @permEngStars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get permEngStars;

  /// No description provided for @permEngPartners.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get permEngPartners;

  /// No description provided for @permWebContent.
  ///
  /// In en, this message translates to:
  /// **'Pages, articles and content'**
  String get permWebContent;

  /// No description provided for @permWebInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get permWebInbox;

  /// No description provided for @permWebSettings.
  ///
  /// In en, this message translates to:
  /// **'Site settings and control centre'**
  String get permWebSettings;

  /// No description provided for @blockedTitleDeviceBlocked.
  ///
  /// In en, this message translates to:
  /// **'This device is blocked'**
  String get blockedTitleDeviceBlocked;

  /// No description provided for @blockedBodyDeviceBlocked.
  ///
  /// In en, this message translates to:
  /// **'The admin blocked this device. The app can\'t be used on it. Contact the admin if you think this is a mistake.'**
  String get blockedBodyDeviceBlocked;

  /// No description provided for @accessDeviceBlock.
  ///
  /// In en, this message translates to:
  /// **'Block device'**
  String get accessDeviceBlock;

  /// No description provided for @accessDeviceBlockQuestion.
  ///
  /// In en, this message translates to:
  /// **'Block this device?'**
  String get accessDeviceBlockQuestion;

  /// No description provided for @accessDeviceBlockBody.
  ///
  /// In en, this message translates to:
  /// **'{device} will be blocked: anyone who signs in on it will see \"This device is blocked\". The member can still use the app on another device.'**
  String accessDeviceBlockBody(String device);

  /// No description provided for @accessDeviceBlocked.
  ///
  /// In en, this message translates to:
  /// **'Device blocked.'**
  String get accessDeviceBlocked;

  /// No description provided for @accessDeviceUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get accessDeviceUnblock;

  /// No description provided for @accessDeviceUnblocked.
  ///
  /// In en, this message translates to:
  /// **'Device unblocked.'**
  String get accessDeviceUnblocked;

  /// No description provided for @videoLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Videos are on another device'**
  String get videoLockTitle;

  /// No description provided for @videoLockBody.
  ///
  /// In en, this message translates to:
  /// **'On {platform}, your videos play only on {device}. The rest of the app works here as usual. To watch on this device instead, ask the admin to remove that device.'**
  String videoLockBody(String platform, String device);

  /// No description provided for @accessVideoDevices.
  ///
  /// In en, this message translates to:
  /// **'Video devices'**
  String get accessVideoDevices;

  /// No description provided for @accessVideoDevicesCaption.
  ///
  /// In en, this message translates to:
  /// **'The member can sign in on any device, but videos play on one device per platform. The first device that opens Videos on a platform takes it. Remove a device to let the member pick another.'**
  String get accessVideoDevicesCaption;

  /// No description provided for @accessVideoDeviceEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not chosen yet — the first device that opens Videos takes it.'**
  String get accessVideoDeviceEmpty;

  /// No description provided for @accessVideoDeviceRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Videos stop playing on {device}. The next {platform} device that opens Videos takes its place.'**
  String accessVideoDeviceRemoveBody(String device, String platform);

  /// No description provided for @accessVideoDeviceRemoved.
  ///
  /// In en, this message translates to:
  /// **'Device removed. The member can open videos on a new device now.'**
  String get accessVideoDeviceRemoved;

  /// No description provided for @courseFilesLocked.
  ///
  /// In en, this message translates to:
  /// **'This course\'s files are locked'**
  String get courseFilesLocked;

  /// No description provided for @courseFilesLockedSub.
  ///
  /// In en, this message translates to:
  /// **'They open once ASEC gives you this course.'**
  String get courseFilesLockedSub;

  /// No description provided for @accessBlockedDevices.
  ///
  /// In en, this message translates to:
  /// **'Blocked devices'**
  String get accessBlockedDevices;

  /// No description provided for @captureAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Screen capture alerts'**
  String get captureAlertsTitle;

  /// No description provided for @captureAlertsCaption.
  ///
  /// In en, this message translates to:
  /// **'Members who took a screenshot or recorded the screen inside the app. Detected on iPhone / iPad and Android 14+.'**
  String get captureAlertsCaption;

  /// No description provided for @captureNone.
  ///
  /// In en, this message translates to:
  /// **'No screenshots or recordings so far.'**
  String get captureNone;

  /// No description provided for @captureClear.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get captureClear;

  /// No description provided for @captureClearQuestion.
  ///
  /// In en, this message translates to:
  /// **'Clear all alerts?'**
  String get captureClearQuestion;

  /// No description provided for @captureClearBody.
  ///
  /// In en, this message translates to:
  /// **'Every screenshot and recording alert will be deleted.'**
  String get captureClearBody;

  /// No description provided for @captureShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all ({count})'**
  String captureShowAll(int count);

  /// No description provided for @captureShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get captureShowLess;

  /// No description provided for @captureScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get captureScreenshot;

  /// No description provided for @captureRecording.
  ///
  /// In en, this message translates to:
  /// **'Screen recording'**
  String get captureRecording;

  /// No description provided for @capturePage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get capturePage;

  /// No description provided for @captureCourse.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get captureCourse;

  /// No description provided for @captureLesson.
  ///
  /// In en, this message translates to:
  /// **'Lesson / quiz'**
  String get captureLesson;

  /// No description provided for @courseLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get courseLocked;

  /// No description provided for @courseLockedSnack.
  ///
  /// In en, this message translates to:
  /// **'This course isn\'t open for you yet. Ask the admin to give it to you.'**
  String get courseLockedSnack;

  /// No description provided for @courseSubtitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get courseSubtitleEdit;

  /// No description provided for @courseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Course subtitle'**
  String get courseSubtitle;

  /// No description provided for @courseSubtitleHint.
  ///
  /// In en, this message translates to:
  /// **'A short line shown under the course title'**
  String get courseSubtitleHint;

  /// No description provided for @accessCoursePickPlatform.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one platform for {course}'**
  String accessCoursePickPlatform(String course);

  /// No description provided for @accessCoursePlatforms.
  ///
  /// In en, this message translates to:
  /// **'Opens on'**
  String get accessCoursePlatforms;

  /// No description provided for @certPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview certificate'**
  String get certPreview;

  /// No description provided for @certPreviewNote.
  ///
  /// In en, this message translates to:
  /// **'A sample — this is how a member\'s certificate looks.'**
  String get certPreviewNote;

  /// No description provided for @certButtonLocked.
  ///
  /// In en, this message translates to:
  /// **'Certificate · finish the course to earn it'**
  String get certButtonLocked;

  /// No description provided for @certIssued.
  ///
  /// In en, this message translates to:
  /// **'Certificate issued · view it'**
  String get certIssued;

  /// No description provided for @certIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get certIssueTitle;

  /// No description provided for @certIssueCaption.
  ///
  /// In en, this message translates to:
  /// **'Give this member a course\'s certificate without the final exam. It shows up for them at once.'**
  String get certIssueCaption;

  /// No description provided for @certIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get certIssue;

  /// No description provided for @certRevoke.
  ///
  /// In en, this message translates to:
  /// **'Take back'**
  String get certRevoke;

  /// No description provided for @certRevoked.
  ///
  /// In en, this message translates to:
  /// **'Certificate taken back'**
  String get certRevoked;

  /// No description provided for @certIssuedToast.
  ///
  /// In en, this message translates to:
  /// **'Certificate issued'**
  String get certIssuedToast;

  /// No description provided for @libraryProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get libraryProjects;

  /// No description provided for @libraryProjectsHint.
  ///
  /// In en, this message translates to:
  /// **'Our projects from the website'**
  String get libraryProjectsHint;

  /// No description provided for @webTab.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get webTab;

  /// No description provided for @errorReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Error reports'**
  String get errorReportsTitle;

  /// No description provided for @errorReportsCaption.
  ///
  /// In en, this message translates to:
  /// **'Every error any user hit — who, when, device, page and the full error. Tap one for details.'**
  String get errorReportsCaption;

  /// No description provided for @errorReportsNone.
  ///
  /// In en, this message translates to:
  /// **'No errors reported'**
  String get errorReportsNone;

  /// No description provided for @errorReportsCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get errorReportsCopy;

  /// No description provided for @errorReportsCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get errorReportsCopied;

  /// No description provided for @errorReportsClearQuestion.
  ///
  /// In en, this message translates to:
  /// **'Clear all error reports?'**
  String get errorReportsClearQuestion;

  /// No description provided for @errorReportsClearBody.
  ///
  /// In en, this message translates to:
  /// **'Every saved error report will be deleted.'**
  String get errorReportsClearBody;

  /// No description provided for @securityAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Security alerts'**
  String get securityAlertsTitle;

  /// No description provided for @securityAlertsCaption.
  ///
  /// In en, this message translates to:
  /// **'Every attempt to pull the lessons out of the app — who, when, device, and what was found. Tap one for details.'**
  String get securityAlertsCaption;

  /// No description provided for @securityAlertsNone.
  ///
  /// In en, this message translates to:
  /// **'No attempts detected'**
  String get securityAlertsNone;

  /// No description provided for @alertMitm.
  ///
  /// In en, this message translates to:
  /// **'HTTPS sniffer detected'**
  String get alertMitm;

  /// No description provided for @alertStreamGrab.
  ///
  /// In en, this message translates to:
  /// **'Download tool blocked'**
  String get alertStreamGrab;

  /// No description provided for @alertDownloadBurst.
  ///
  /// In en, this message translates to:
  /// **'Too many downloads at once'**
  String get alertDownloadBurst;

  /// No description provided for @alertOther.
  ///
  /// In en, this message translates to:
  /// **'Suspicious activity'**
  String get alertOther;

  /// No description provided for @alertClearQuestion.
  ///
  /// In en, this message translates to:
  /// **'Clear all security alerts?'**
  String get alertClearQuestion;

  /// No description provided for @alertClearBody.
  ///
  /// In en, this message translates to:
  /// **'Every saved security alert will be deleted.'**
  String get alertClearBody;

  /// No description provided for @onlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get onlineTitle;

  /// No description provided for @onlineCaption.
  ///
  /// In en, this message translates to:
  /// **'Who has the app open right now. Tap a member to open all their controls.'**
  String get onlineCaption;

  /// No description provided for @onlineNone.
  ///
  /// In en, this message translates to:
  /// **'Nobody has the app open right now.'**
  String get onlineNone;

  /// No description provided for @onlineViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get onlineViewAll;

  /// No description provided for @onlineRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently active (last 24 hours)'**
  String get onlineRecent;

  /// No description provided for @onlineNoneRecent.
  ///
  /// In en, this message translates to:
  /// **'Nobody used the app in the last 24 hours.'**
  String get onlineNoneRecent;

  /// No description provided for @onlineNow.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineNow;

  /// No description provided for @onlineJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get onlineJustNow;

  /// No description provided for @onlineAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String onlineAgoMinutes(int count);

  /// No description provided for @onlineAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String onlineAgoHours(int count);

  /// No description provided for @onlineOnPage.
  ///
  /// In en, this message translates to:
  /// **'On: {page}'**
  String onlineOnPage(String page);

  /// No description provided for @onlineAdminAccount.
  ///
  /// In en, this message translates to:
  /// **'This is an admin account. Manage it from Admins.'**
  String get onlineAdminAccount;

  /// No description provided for @onlineMemberGone.
  ///
  /// In en, this message translates to:
  /// **'This account no longer exists.'**
  String get onlineMemberGone;

  /// No description provided for @onlineAdminTag.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get onlineAdminTag;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return SAr();
    case 'en':
      return SEn();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
