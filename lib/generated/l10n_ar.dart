// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class SAr extends S {
  SAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'ASEC';

  @override
  String get appTagline => 'شاهد. تعلّم. اختبر.';

  @override
  String get roleAdmin => 'مدير';

  @override
  String get roleTeacher => 'معلم';

  @override
  String get roleStudent => 'طالب';

  @override
  String get roleParent => 'ولي أمر';

  @override
  String get typeVideo => 'فيديو';

  @override
  String get typePdf => 'ملف PDF';

  @override
  String get typeImage => 'صورة';

  @override
  String get typeExam => 'امتحان';

  @override
  String get typeQuiz => 'اختبار قصير';

  @override
  String get attendance => 'الحضور';

  @override
  String get grades => 'الدرجات';

  @override
  String get messages => 'الرسائل';

  @override
  String permissionPublishDesc(String type) {
    return 'يمكنه إضافة وتعديل وحذف محتوى $type';
  }

  @override
  String get permissionAttendanceDesc => 'يمكنه تسجيل الحضور لفصوله';

  @override
  String get permissionGradesDesc => 'يمكنه مراجعة نتائج الطلاب ورصد الدرجات';

  @override
  String get permissionMessagesDesc => 'يمكنه مراسلة أولياء الأمور';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get discard => 'تجاهل';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get add => 'إضافة';

  @override
  String get close => 'إغلاق';

  @override
  String get done => 'تم';

  @override
  String get retry => 'حاول مرة أخرى';

  @override
  String get search => 'بحث';

  @override
  String get all => 'الكل';

  @override
  String get primaryColor => 'اللون الأساسي';

  @override
  String get secondaryColor => 'اللون الثانوي';

  @override
  String get colors => 'الألوان';

  @override
  String get errWrongCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get errInvalidEmail => 'البريد الإلكتروني غير صالح.';

  @override
  String get errEmailInUse => 'يوجد حساب بهذا البريد الإلكتروني بالفعل.';

  @override
  String get errWeakPassword => 'استخدم 6 أحرف على الأقل لكلمة المرور.';

  @override
  String get errUserDisabled => 'تم تعطيل هذا الحساب.';

  @override
  String get errTooManyRequests =>
      'محاولات كثيرة. انتظر دقيقة ثم حاول مرة أخرى.';

  @override
  String get errNetwork => 'لا يوجد اتصال. تحقق من الشبكة وحاول مرة أخرى.';

  @override
  String get errProfileMissing =>
      'هذا الحساب ليس له ملف. اطلب من المدير إنشاءه من لوحة التحكم.';

  @override
  String get errAccountInactive => 'هذا الحساب موقوف. تواصل مع المركز.';

  @override
  String get errFirestoreUnavailable =>
      'تم تسجيل الدخول لكن قاعدة البيانات لم تستجب. تأكد من إنشاء Firestore في مشروع Firebase.';

  @override
  String get errRulesDenied =>
      'رفضت قاعدة البيانات الطلب. انشر قواعد Firestore: firebase deploy --only firestore:rules';

  @override
  String get errSetupAlreadyDone =>
      'تم الإعداد بالفعل لهذا المشروع. سجّل الدخول.';

  @override
  String get errNotConfigured =>
      'لم يتم إعداد Firebase بعد. شغّل flutterfire configure.';

  @override
  String get errUnknown => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get failPermission =>
      'ليس لديك صلاحية لذلك. اطلب من المدير أو انشر قواعد Firestore.';

  @override
  String get failIndex =>
      'تحتاج هذه القائمة إلى فهرس. انشر firestore.indexes.json.';

  @override
  String get failNotFound => 'لم يعد موجودًا.';

  @override
  String get failUpload => 'لم يكتمل الرفع. حاول مرة أخرى.';

  @override
  String get typeVideos => 'الفيديوهات';

  @override
  String get typePdfs => 'ملفات PDF';

  @override
  String get typeImages => 'الصور';

  @override
  String get typeExams => 'الامتحانات';

  @override
  String get typeQuizzes => 'الاختبارات القصيرة';

  @override
  String get present => 'حاضر';

  @override
  String get absent => 'غائب';

  @override
  String get lateStatus => 'متأخر';

  @override
  String get excused => 'بعذر';

  @override
  String get resetEmailSent =>
      'إذا كان لهذا البريد حساب، فسيصلك رابط إعادة التعيين.';

  @override
  String get consoleHeadline => 'مركزك بالكامل في شاشة واحدة.';

  @override
  String get consoleSubheadline =>
      'الدروس والامتحانات والحضور وأولياء الأمور — بشكل منظم.';

  @override
  String get enterEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get enterName => 'أدخل الاسم';

  @override
  String get setupTitle => 'إعداد المركز';

  @override
  String get welcomeBack => 'مرحبًا بعودتك';

  @override
  String get setupSubtitle =>
      'أنشئ حساب المدير الأول. يعمل هذا مرة واحدة فقط لكل مشروع.';

  @override
  String get signInSubtitle => 'سجّل الدخول بالحساب الذي أعطاك إياه المركز.';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get fullNameHint => 'مثال: عمرو مصباح';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get createAdminAccount => 'إنشاء حساب المدير';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get backToSignIn => 'العودة لتسجيل الدخول';

  @override
  String get setupCenter => 'أول مرة؟ قم بإعداد المركز';

  @override
  String get consoleAccountsHint =>
      'يسجّل المدير والمعلمون الدخول هنا. يستخدم الطلاب وأولياء الأمور تطبيق الهاتف.';

  @override
  String get tabletAccountsHint =>
      'يسجّل الجميع الدخول هنا — الطلاب وأولياء الأمور والمعلمون والمديرون.';

  @override
  String get mobileAccountsHint =>
      'يسجّل الطلاب وأولياء الأمور الدخول هنا. يستخدم المعلمون جهازًا لوحيًا أو كمبيوتر.';

  @override
  String get wrongDeviceMobileTitle => 'افتح هذا الحساب على هاتف أو جهاز لوحي';

  @override
  String get wrongDeviceDesktopTitle =>
      'افتح هذا الحساب على جهاز لوحي أو كمبيوتر';

  @override
  String wrongDeviceMobileBody(String role) {
    return 'حسابات $role تستخدم تطبيق مستقبل على الهاتف أو الجهاز اللوحي. ثبّته هناك وسجّل الدخول بنفس البريد.';
  }

  @override
  String wrongDeviceDesktopBody(String role) {
    return 'حسابات $role تستخدم لوحة التحكم على الجهاز اللوحي أو الكمبيوتر. افتح مستقبل هناك وسجّل الدخول بنفس البريد.';
  }

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get pressBackAgainToExit => 'اضغط رجوع مرة أخرى للخروج';

  @override
  String get debugPreviewAnyway => 'معاينة على أي حال (نسخة التطوير)';

  @override
  String get debugPreviewHint =>
      'فقط في نسخة التطوير. يمكنك إلغاؤه من الإعدادات.';

  @override
  String get overview => 'نظرة عامة';

  @override
  String get teachers => 'المعلمون';

  @override
  String get students => 'الطلاب';

  @override
  String get parents => 'أولياء الأمور';

  @override
  String get sections => 'الفصول';

  @override
  String get content => 'المحتوى';

  @override
  String get myStudents => 'طلابي';

  @override
  String get settings => 'الإعدادات';

  @override
  String get signOutQuestion => 'تسجيل الخروج؟';

  @override
  String get signOutBody => 'ستحتاج بريدك وكلمة المرور للعودة.';

  @override
  String helloName(String name) {
    return 'مرحبًا، $name';
  }

  @override
  String get overviewAdminSub => 'هذه نظرة على مركزك اليوم.';

  @override
  String get overviewTeacherSub => 'فصولك ومحتواك ونتائجك في لمحة.';

  @override
  String get contentLibrary => 'مكتبة المحتوى';

  @override
  String itemsCount(String count) {
    return '$count عنصر';
  }

  @override
  String get recentlyAdded => 'أضيف مؤخرًا';

  @override
  String get noContentYet => 'لا يوجد محتوى بعد.';

  @override
  String get demoFailed => 'تعذّر إنشاء البيانات التجريبية';

  @override
  String get demoTitle => 'بيانات تجريبية';

  @override
  String demoBody(String password) {
    return 'يملأ كل الأقسام ما عدا الفيديوهات ببيانات تجريبية: أعضاء بصلاحيات كورسات، واختبارات، واختبار شهادة لكل كورس حقيقي، ونتائج، وسير ذاتية، وطلبات الموقع. الفيديوهات تبقى كما هي — تأتي من مجلد Drive. كل حساب تجريبي يدخل بكلمة المرور $password.';
  }

  @override
  String get removeDemo => 'حذف البيانات التجريبية';

  @override
  String get removeDemoQuestion => 'حذف كل البيانات التجريبية؟';

  @override
  String get removeDemoBody =>
      'يحذف كل عضو وفيديو واختبار ونتيجة وسيرة ذاتية تجريبية. ما أنشأته أنت أو أعضاؤك لن يتأثر.';

  @override
  String get demoRemoved => 'تم حذف البيانات التجريبية';

  @override
  String get fillDemo => 'إنشاء بيانات تجريبية';

  @override
  String demoFilled(String email) {
    return 'البيانات التجريبية جاهزة — سجّل الخروج وجرّب $email';
  }

  @override
  String demoCounts(
    String members,
    String quizzes,
    String certificates,
    String results,
    String cvs,
    String inbox,
  ) {
    return '$members عضو · $quizzes اختبار · $certificates اختبار شهادة · $results نتيجة · $cvs سيرة ذاتية · $inbox طلب من الموقع';
  }

  @override
  String get demoAccountsHint =>
      'حسابات التجربة حسابات حقيقية على نطاق لا يستقبل بريدًا. حذف البيانات يتركها فارغة، وإعادة الإنشاء تستخدمها من جديد.';

  @override
  String get myContent => 'محتواي';

  @override
  String get resultsReceived => 'النتائج المستلمة';

  @override
  String get yourPermissions => 'صلاحياتك';

  @override
  String get yourPermissionsSub =>
      'يحددها المدير. اطلب منه إن احتجت شيئًا غير متاح.';

  @override
  String get nobodyFound => 'لا يوجد أحد يطابق البحث.';

  @override
  String get addTeacher => 'إضافة معلم';

  @override
  String get editTeacher => 'تعديل المعلم';

  @override
  String get addStudent => 'إضافة طالب';

  @override
  String get editStudent => 'تعديل الطالب';

  @override
  String get addParent => 'إضافة ولي أمر';

  @override
  String get editParent => 'تعديل ولي الأمر';

  @override
  String get accountCreateHint => 'سيسجّل الدخول بهذا البريد وكلمة المرور.';

  @override
  String get createAccount => 'إنشاء الحساب';

  @override
  String get phone => 'الهاتف';

  @override
  String get passwordShareHint => 'شاركها معه بشكل خاص. 6 أحرف على الأقل.';

  @override
  String get generate => 'توليد';

  @override
  String get subject => 'المادة';

  @override
  String get subjectHint => 'مثال: الرياضيات';

  @override
  String get teachesSections => 'يدرّس هذه الفصول';

  @override
  String get noSectionsYet => 'لا توجد فصول بعد — أضفها من صفحة الفصول.';

  @override
  String get permissions => 'الصلاحيات';

  @override
  String get section => 'الفصل';

  @override
  String get children => 'الأبناء';

  @override
  String get accountActive => 'الحساب مفعّل';

  @override
  String get accountActiveHint => 'أوقفه لمنع الدخول دون حذف أي بيانات.';

  @override
  String get roleLabel => 'الدور';

  @override
  String get saved => 'تم الحفظ';

  @override
  String deleteQuestion(String name) {
    return 'حذف $name؟';
  }

  @override
  String get deletePersonBody =>
      'سيُحذف ملفه ولن يتمكن من الدخول. تبقى نتائجه وحضوره محفوظة.';

  @override
  String get deleted => 'تم الحذف';

  @override
  String get name => 'الاسم';

  @override
  String get noSection => 'بدون فصل';

  @override
  String get status => 'الحالة';

  @override
  String get active => 'مفعّل';

  @override
  String get inactive => 'موقوف';

  @override
  String get switchOff => 'إيقاف';

  @override
  String get switchOn => 'تفعيل';

  @override
  String get peopleSub => 'أنشئ الحسابات وحدد الفصول وتحكم في الصلاحيات.';

  @override
  String get nobodyYet => 'لا يوجد أحد بعد';

  @override
  String get nobodyYetSub =>
      'أضف أول شخص من الزر بالأعلى، أو أنشئ بيانات تجريبية من الإعدادات.';

  @override
  String deleteSectionWithStudents(String count) {
    return 'يوجد $count طالب في هذا الفصل. سيبقون بدون فصل حتى تنقلهم.';
  }

  @override
  String get deleteSectionBody => 'سيُحذف الفصل ولن يظهر المحتوى المخصص له.';

  @override
  String get sectionsSub =>
      'قسّم الطلاب إلى فصول. المحتوى والحضور والمعلمون منظمون حسب الفصل.';

  @override
  String get addSection => 'إضافة فصل';

  @override
  String get editSection => 'تعديل الفصل';

  @override
  String get noSectionsTitle => 'لا توجد فصول بعد';

  @override
  String get noSectionsSub => 'أنشئ أول فصل ثم أضف إليه الطلاب.';

  @override
  String studentsCount(String count) {
    return '$count طالب';
  }

  @override
  String teachersCount(String count) {
    return '$count معلم';
  }

  @override
  String get sectionName => 'اسم الفصل';

  @override
  String get sectionNameHint => 'مثال: الصف السابع — أ';

  @override
  String get level => 'المستوى';

  @override
  String get levelHint => 'مثال: الصف السابع';

  @override
  String get description => 'الوصف';

  @override
  String get addQuestion => 'إضافة سؤال';

  @override
  String get questionText => 'السؤال';

  @override
  String get points => 'الدرجة';

  @override
  String optionN(String n) {
    return 'الاختيار $n';
  }

  @override
  String get addOption => 'إضافة اختيار';

  @override
  String get markCorrectHint => 'حدّد الإجابة الصحيحة';

  @override
  String fileTooLarge(String mb) {
    return 'الملف أكبر من $mb ميجابايت.';
  }

  @override
  String get enterTitle => 'أدخل العنوان';

  @override
  String get enterValidLink => 'أدخل رابطًا كاملًا يبدأ بـ https://';

  @override
  String get chooseFile => 'اختر ملفًا';

  @override
  String get questionsIncomplete =>
      'كل سؤال يحتاج نصًا واختيارين على الأقل وإجابة صحيحة.';

  @override
  String newItem(String type) {
    return '$type جديد';
  }

  @override
  String editItem(String type) {
    return 'تعديل $type';
  }

  @override
  String get assessmentHint =>
      'أسئلة اختيار من متعدد تُصحّح تلقائيًا عند تسليم الطالب.';

  @override
  String get fileHint => 'ارفع ملفًا إلى Firebase Storage أو الصق رابطًا.';

  @override
  String get title => 'العنوان';

  @override
  String get descriptionHint => 'عمّ يدور هذا؟';

  @override
  String get file => 'الملف';

  @override
  String get uploadFile => 'رفع ملف';

  @override
  String get pasteLink => 'لصق رابط';

  @override
  String get link => 'الرابط';

  @override
  String get timeLimit => 'المدة';

  @override
  String get minutes => 'دقائق';

  @override
  String get zeroUntimed => '0 = بدون حد زمني';

  @override
  String questionsTotal(String count, String points) {
    return '$count سؤال · $points نقطة';
  }

  @override
  String get assignToSections => 'تخصيص للفصول';

  @override
  String get noSectionsAssigned => 'لم يتم تعيينك لأي فصل بعد. اطلب من المدير.';

  @override
  String get assignToStudents => '…أو لطلاب بعينهم';

  @override
  String get noDueDate => 'بدون موعد تسليم — اضغط للتحديد';

  @override
  String dueOn(String date) {
    return 'التسليم $date';
  }

  @override
  String get published => 'منشور';

  @override
  String get publishedHint => 'عند الإيقاف يبقى مسودة لا يراها غيرك.';

  @override
  String get notAssignedWarning => 'لم يُخصص لأحد بعد — لن يراه أي طالب.';

  @override
  String allowedTypes(String types) {
    return 'المسموح: $types';
  }

  @override
  String get browse => 'استعراض';

  @override
  String get replace => 'استبدال';

  @override
  String uploadingPercent(String percent) {
    return 'جارٍ الرفع… $percent%';
  }

  @override
  String get deleteAssessmentBody =>
      'لن يراه الطلاب بعد الآن. النتائج المسلّمة تبقى في الدرجات.';

  @override
  String get deleteContentBody => 'لن يراه الطلاب، وسيُحذف الملف المرفوع.';

  @override
  String get contentAdminSub => 'كل ما نشره جميع المعلمين.';

  @override
  String get contentTeacherSub =>
      'ارفع الدروس وأنشئ الامتحانات ثم خصصها لفصل أو لطلاب بعينهم.';

  @override
  String get addContent => 'إضافة محتوى';

  @override
  String get noContentPermission => 'لم يمنحك المدير صلاحية نشر المحتوى بعد.';

  @override
  String get noContentSub =>
      'استخدم \"إضافة محتوى\" لرفع أول درس أو إنشاء اختبار.';

  @override
  String get notAssigned => 'غير مخصص';

  @override
  String get draft => 'مسودة';

  @override
  String questionsShort(String count, String time) {
    return '$count سؤال · $time';
  }

  @override
  String get untimed => 'بدون وقت';

  @override
  String minutesShort(String n) {
    return '$n دقيقة';
  }

  @override
  String get open => 'فتح';

  @override
  String get attendanceSaved => 'تم حفظ الحضور';

  @override
  String get attendanceSub => 'اختر الفصل واليوم وحدد حالة كل طالب ثم احفظ.';

  @override
  String get noStudentsInSection => 'لا يوجد طلاب في هذا الفصل';

  @override
  String get noStudentsInSectionSub =>
      'يضيف المدير الطلاب إلى الفصول من صفحة الطلاب.';

  @override
  String unmarkedCount(String count) {
    return '$count بدون تسجيل';
  }

  @override
  String get markAllPresent => 'تسجيل الكل حاضر';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get notSavedYet => 'لم يُحفظ بعد';

  @override
  String get gradesSub =>
      'تصل النتائج هنا فور تسليم الطالب. عدّل الدرجة أو أضف ملاحظة في أي وقت.';

  @override
  String get noAssessments => 'لا توجد امتحانات أو اختبارات بعد';

  @override
  String get noAssessmentsSub => 'أنشئ واحدًا من صفحة المحتوى.';

  @override
  String pointsTotal(String points) {
    return '$points درجة';
  }

  @override
  String get submitted => 'سلّموا';

  @override
  String get missing => 'لم يسلّموا';

  @override
  String get average => 'المتوسط';

  @override
  String get notSubmittedYet => 'لم يسلّموا بعد';

  @override
  String get gradedByTeacher => 'صحّحه المعلم';

  @override
  String get autoMarked => 'تصحيح تلقائي';

  @override
  String get enterGrade => 'إدخال الدرجة';

  @override
  String get editGrade => 'تعديل الدرجة';

  @override
  String scoreRange(String max) {
    return 'أدخل درجة من 0 إلى $max.';
  }

  @override
  String get score => 'الدرجة';

  @override
  String get feedback => 'ملاحظات';

  @override
  String get feedbackHint => 'تظهر للطالب ولأولياء أمره.';

  @override
  String get aboutAssignment => 'بخصوص واجب';

  @override
  String get noMessagesYet => 'لا توجد رسائل بعد';

  @override
  String get noMessagesYetSub => 'ابدأ المحادثة — تصل الرسائل فورًا.';

  @override
  String aboutTitle(String title) {
    return 'بخصوص: $title';
  }

  @override
  String get typeMessage => 'اكتب رسالة…';

  @override
  String aboutChild(String name) {
    return 'بخصوص $name';
  }

  @override
  String get you => 'أنت';

  @override
  String get messagesTeacherSub => 'محادثات مع أولياء الأمور، محادثة لكل طالب.';

  @override
  String get noConversations => 'لا توجد محادثات بعد';

  @override
  String get noConversationsTeacherSub =>
      'يمكن لأولياء الأمور مراسلتك من تطبيقهم، أو ابدأ محادثة من صفحة طلابي.';

  @override
  String parentOf(String name) {
    return 'ولي أمر $name';
  }

  @override
  String get myStudentsSub =>
      'الطلاب في الفصول التي تدرّسها. اضغط على أحدهم لعرض النتائج والحضور وأولياء الأمور.';

  @override
  String get noParentsLinked =>
      'لا يوجد ولي أمر مرتبط بعد. يربطهم المدير من صفحة أولياء الأمور.';

  @override
  String get message => 'مراسلة';

  @override
  String get noAttendanceYet => 'لم يُسجّل حضور بعد.';

  @override
  String attendanceRate(String percent) {
    return 'الحضور $percent%';
  }

  @override
  String get results => 'النتائج';

  @override
  String get noResultsYet => 'لا توجد نتائج بعد.';

  @override
  String get appearance => 'المظهر';

  @override
  String get language => 'اللغة';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get haptics => 'الاهتزاز عند اللمس';

  @override
  String get branding => 'ألوان الهوية';

  @override
  String get resetColors => 'استعادة الألوان الافتراضية';

  @override
  String get brandingLocalHint => 'تُحفظ على هذا الجهاز.';

  @override
  String get developer => 'المطوّر';

  @override
  String get clearDeviceOverride => 'إلغاء معاينة الجهاز';

  @override
  String get clearDeviceOverrideSub => 'يوقف محاكاة نوع الجهاز ويسجّل الخروج.';

  @override
  String get account => 'الحساب';

  @override
  String get overdue => 'متأخر';

  @override
  String get startNow => 'ابدأ';

  @override
  String questionsCount(String count) {
    return '$count سؤال';
  }

  @override
  String get openExternally => 'فتح في تطبيق آخر';

  @override
  String get videoFailed => 'تعذّر تشغيل الفيديو. جرّب فتحه في تطبيق آخر.';

  @override
  String pageOf(String page, String pages) {
    return 'صفحة $page من $pages';
  }

  @override
  String get pdfFailed => 'تعذّر فتح الملف هنا. اضغط لفتحه في تطبيق آخر.';

  @override
  String get pinchToZoom => 'قرّب بإصبعين للتكبير';

  @override
  String get questions => 'الأسئلة';

  @override
  String notTakenYet(String name) {
    return 'لم يؤدِّ $name هذا بعد.';
  }

  @override
  String get examRules =>
      'أجب عن كل الأسئلة ثم سلّم. يمكنك التنقل بين الأسئلة بحرية. يمكنك التسليم مرة واحدة فقط.';

  @override
  String startExam(String type) {
    return 'ابدأ $type';
  }

  @override
  String get submitQuestion => 'تسليم إجاباتك؟';

  @override
  String submitWithBlanks(String count) {
    return 'ما زال $count سؤال بدون إجابة. لا يمكنك تعديل الإجابات بعد التسليم.';
  }

  @override
  String get submitBody => 'لا يمكنك تعديل الإجابات بعد التسليم.';

  @override
  String get submit => 'تسليم';

  @override
  String get keepGoing => 'متابعة';

  @override
  String get submitFailed => 'تعذّر التسليم';

  @override
  String get alreadySubmitted => 'لقد سلّمت هذا من قبل.';

  @override
  String get leaveExamQuestion => 'الخروج دون تسليم؟';

  @override
  String get leaveExamBody => 'ستفقد إجاباتك.';

  @override
  String get leave => 'خروج';

  @override
  String questionNofM(String n, String m) {
    return 'سؤال $n من $m';
  }

  @override
  String get previous => 'السابق';

  @override
  String get next => 'التالي';

  @override
  String get timeUp => 'انتهى الوقت — تم تسليم إجاباتك تلقائيًا.';

  @override
  String get submittedTitle => 'تم التسليم!';

  @override
  String get review => 'المراجعة';

  @override
  String get verdictExcellent => 'عمل ممتاز!';

  @override
  String get verdictGood => 'أحسنت!';

  @override
  String get verdictPass => 'ناجح';

  @override
  String get verdictKeepTrying => 'استمر في التدريب';

  @override
  String get home => 'الرئيسية';

  @override
  String get libraryTab => 'المكتبة';

  @override
  String get profile => 'حسابي';

  @override
  String get goodMorning => 'صباح الخير';

  @override
  String get goodAfternoon => 'مساء الخير';

  @override
  String get goodEvening => 'مساء الخير';

  @override
  String get nothingAssignedYet => 'لا يوجد شيء مخصص لك بعد';

  @override
  String get nothingAssignedYetSub =>
      'عندما يشارك معلموك الدروس أو الامتحانات ستظهر هنا.';

  @override
  String get continueLearning => 'تابع التعلم';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get upNext => 'التالي';

  @override
  String get newThisWeek => 'جديد';

  @override
  String get toDo => 'مطلوب';

  @override
  String get searchLessons => 'ابحث في الدروس والامتحانات والمعلمين…';

  @override
  String get nothingHere => 'لا يوجد شيء هنا';

  @override
  String get nothingHereSub => 'جرّب فلترًا أو بحثًا آخر.';

  @override
  String get averageGrade => 'متوسط الدرجات';

  @override
  String resultsCountLabel(String count) {
    return '$count نتيجة';
  }

  @override
  String daysRecorded(String count) {
    return '$count يوم مسجل';
  }

  @override
  String get lastDays => 'آخر الأيام';

  @override
  String get absencesAndLate => 'أيام الغياب والتأخير';

  @override
  String get myProgress => 'تقدّمي';

  @override
  String get noChildrenLinked => 'لا يوجد أبناء مرتبطون بعد';

  @override
  String get noChildrenLinkedSub => 'اطلب من المركز ربط أبنائك بحسابك.';

  @override
  String get yourChildren => 'أبناؤك';

  @override
  String get messageATeacher => 'مراسلة معلم';

  @override
  String get assignments => 'الواجبات';

  @override
  String get chooseTeacher => 'اختر المعلم';

  @override
  String get noTeachersToMessage =>
      'لا يوجد معلم لهذا الفصل يمكنه استقبال الرسائل بعد.';

  @override
  String get whichChild => 'بخصوص أي من أبنائك؟';

  @override
  String get newMessage => 'رسالة جديدة';

  @override
  String get noConversationsParentSub =>
      'اضغط \"رسالة جديدة\" لمراسلة أحد معلمي ابنك.';

  @override
  String get dashboard => 'لوحة المعلومات';

  @override
  String get dashboardAdminSub => 'الحضور والنتائج والمحتوى في المركز كله.';

  @override
  String get dashboardTeacherSub => 'الحضور والنتائج للفصول التي تدرّسها.';

  @override
  String get attendanceRateLabel => 'نسبة الحضور';

  @override
  String get averageScoreLabel => 'متوسط الدرجات';

  @override
  String get gradedResultsLabel => 'النتائج المصححة';

  @override
  String get publishedContentLabel => 'المحتوى المنشور';

  @override
  String get attendanceByStatus => 'الحضور حسب الحالة';

  @override
  String get attendanceByDay => 'الحضور حسب اليوم';

  @override
  String get averageBySection => 'متوسط الدرجات حسب الفصل';

  @override
  String get scoreBands => 'شرائح الدرجات';

  @override
  String get resultsByType => 'النتائج حسب النوع';

  @override
  String get band0 => 'أقل من ٥٠';

  @override
  String get band50 => '٥٠–٦٤';

  @override
  String get band65 => '٦٥–٧٩';

  @override
  String get band80 => '٨٠–١٠٠';

  @override
  String get charts => 'الرسوم';

  @override
  String get filters => 'التصفية';

  @override
  String get clear => 'مسح';

  @override
  String get apply => 'تطبيق';

  @override
  String get periodLabel => 'الفترة';

  @override
  String get period30 => 'آخر ٣٠ يومًا';

  @override
  String get period90 => 'آخر ٩٠ يومًا';

  @override
  String get periodAll => 'كل الفترات';

  @override
  String get onlyBelowPass => 'النتائج أقل من ٥٠٪ فقط';

  @override
  String get onlyAbsences => 'الغياب والتأخير فقط';

  @override
  String get exportTitle => 'تصدير';

  @override
  String get exportFileName => 'اسم الملف';

  @override
  String exportSaved(String path) {
    return 'تم الحفظ في $path';
  }

  @override
  String get exportFailedTitle => 'تعذّر التصدير';

  @override
  String get exportCancelled => 'تم إلغاء التصدير.';

  @override
  String get student => 'الطالب';

  @override
  String get assessment => 'التقييم';

  @override
  String get dateLabel => 'التاريخ';

  @override
  String rowsShown(String shown, String total) {
    return '$shown من $total';
  }

  @override
  String get nothingToChart => 'لا توجد بيانات للعرض بعد';

  @override
  String get nothingToChartSub =>
      'تمتلئ الرسوم تدريجيًا مع رصد الحضور وتصحيح التقييمات.';

  @override
  String get noRowsMatch => 'لا شيء يطابق هذه التصفية.';

  @override
  String get dashboardSearchHint => 'ابحث عن طالب أو تقييم';

  @override
  String get exportCsv => 'تصدير CSV';

  @override
  String get enterFileName => 'أدخل اسم الملف';

  @override
  String get focusOverdue => 'متأخر — أنهِه أولًا';

  @override
  String get focusNext => 'مهمتك التالية';

  @override
  String get focusNew => 'جديد لك';

  @override
  String get allCaughtUp => 'أنجزت كل شيء';

  @override
  String get allCaughtUpSub =>
      'لا توجد اختبارات بانتظارك. وقت مناسب لمراجعة درس.';

  @override
  String get dueToday => 'مستحق اليوم';

  @override
  String get dueTomorrow => 'مستحق غدًا';

  @override
  String dueInDays(String n) {
    return 'مستحق خلال $n أيام';
  }

  @override
  String overdueByDays(String n) {
    return 'متأخر $n أيام';
  }

  @override
  String get todayLabel => 'اليوم';

  @override
  String get notRecordedToday => 'لم يُسجَّل بعد';

  @override
  String get dayStreak => 'أيام متتالية';

  @override
  String get latestResult => 'آخر نتيجة';

  @override
  String aboveAverage(String n) {
    return 'أعلى من متوسطك بـ $n نقاط';
  }

  @override
  String belowAverage(String n) {
    return 'أقل من متوسطك بـ $n نقاط';
  }

  @override
  String get onYourAverage => 'مطابق لمتوسطك';

  @override
  String assessmentsDone(String done, String total) {
    return 'أنجزت $done من $total اختبارات';
  }

  @override
  String get atAGlance => 'نظرة سريعة';

  @override
  String get noResultYetShort => 'ستظهر نتيجتك الأولى هنا.';

  @override
  String get roleUser => 'عضو';

  @override
  String get roleAdminBadge => 'مشرف';

  @override
  String get heroTitle => 'كل ما تحتاجه للتعلّم في مكان واحد.';

  @override
  String get heroSubtitle => 'شاهد الدروس ثم أدِّ الاختبار قبل انتهاء الوقت.';

  @override
  String get createYourAccount => 'أنشئ حسابك';

  @override
  String get registerSubtitle =>
      'دقيقة واحدة للتسجيل، ثم يصبح كل شيء متاحًا لك.';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get haveAccount => 'لديك حساب بالفعل؟';

  @override
  String get noAccount => 'مستخدم جديد؟';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get errPasswordsDiffer => 'كلمتا المرور غير متطابقتين.';

  @override
  String get phoneHint => 'اختياري';

  @override
  String welcomeName(String name) {
    return 'أهلًا $name';
  }

  @override
  String get signInAsAdminHint => 'حساب المشرف يسجّل الدخول من هنا أيضًا.';

  @override
  String get registerHint => 'حسابك حساب عضو. المشرف حساب واحد فقط.';

  @override
  String get quizzes => 'الاختبارات';

  @override
  String get quizzesAdminSub => 'اكتب الأسئلة وحدّد المؤقّت وفترة الإتاحة.';

  @override
  String get quizzesUserSub =>
      'أدِّ الاختبار أثناء إتاحته. يبدأ المؤقّت عند البدء.';

  @override
  String get newQuiz => 'اختبار جديد';

  @override
  String get editQuiz => 'تعديل الاختبار';

  @override
  String get quizTitleHint => 'الوحدة الثالثة — مراجعة';

  @override
  String get availabilityWindow => 'فترة الإتاحة';

  @override
  String get availabilityHint => 'اتركهما فارغين ليظل متاحًا بلا موعد انتهاء.';

  @override
  String get opensAt => 'يفتح';

  @override
  String get closesAt => 'يغلق';

  @override
  String get notSet => 'غير محدد';

  @override
  String get clearDate => 'مسح';

  @override
  String get errWindowBackwards => 'يجب أن يكون موعد الإغلاق بعد موعد الفتح.';

  @override
  String get errNoQuestions => 'أضف سؤالًا واحدًا على الأقل.';

  @override
  String get quizSaved => 'تم حفظ الاختبار';

  @override
  String get deleteQuizBody =>
      'سيُحذف الاختبار وكل المحاولات عليه، ولا يمكن التراجع.';

  @override
  String get noQuizzesTitle => 'لا توجد اختبارات بعد';

  @override
  String get noQuizzesAdminSub =>
      'اكتب أول اختبار: الأسئلة والمؤقّت وفترة الإتاحة.';

  @override
  String get noQuizzesUserSub => 'لا يوجد اختبار متاح الآن. عد لاحقًا.';

  @override
  String get attempts => 'المحاولات';

  @override
  String get attemptsSub => 'من أدّى هذا الاختبار وكيف كانت نتيجته.';

  @override
  String get noAttemptsYet => 'لم يؤدِّ أحد هذا الاختبار بعد';

  @override
  String get noAttemptsYetSub => 'تظهر النتائج هنا فور تسليم أول محاولة.';

  @override
  String attemptsCount(String count) {
    return '$count محاولة';
  }

  @override
  String get autoSubmitted => 'انتهى الوقت';

  @override
  String get takenOn => 'تاريخ الأداء';

  @override
  String get startQuiz => 'ابدأ الاختبار';

  @override
  String quizRulesTimed(String count, String minutes) {
    return '$count سؤال · $minutes دقيقة. يستمر المؤقّت بعد البدء، ويُسلَّم الاختبار تلقائيًا عند وصوله إلى الصفر.';
  }

  @override
  String quizRulesUntimed(String count) {
    return '$count سؤال بلا حد زمني. خذ وقتك.';
  }

  @override
  String get timeLeft => 'الوقت المتبقي';

  @override
  String quizNotOpenYet(String date) {
    return 'يفتح $date';
  }

  @override
  String get quizClosed => 'مغلق';

  @override
  String quizClosesOn(String date) {
    return 'يغلق $date';
  }

  @override
  String get quizOpenNow => 'متاح الآن';

  @override
  String get quizWindowClosedBody => 'هذا الاختبار غير متاح حاليًا.';

  @override
  String get yourScore => 'نتيجتك';

  @override
  String correctOfTotal(String correct, String total) {
    return '$correct من $total صحيحة';
  }

  @override
  String get yourAnswer => 'إجابتك';

  @override
  String get correctAnswer => 'الإجابة الصحيحة';

  @override
  String get noAnswer => 'بدون إجابة';

  @override
  String get takeAgain => 'أعِد المحاولة';

  @override
  String get alreadyTakenBody => 'لقد أدّيت هذا الاختبار من قبل. هذه نتيجتك.';

  @override
  String get backToQuizzes => 'العودة إلى الاختبارات';

  @override
  String get answered => 'تمت الإجابة';

  @override
  String get videosAdminSub => 'ارفع درسًا ليظهر لكل الأعضاء.';

  @override
  String get videosUserSub => 'كل الدروس المنشورة.';

  @override
  String get addVideo => 'إضافة فيديو';

  @override
  String get videoLoading => 'جارٍ تحميل الدرس';

  @override
  String get importDriveLessons => 'إضافة دروس Drive';

  @override
  String driveLessonsAdded(int count) {
    return 'تمت إضافة $count درسًا من Google Drive';
  }

  @override
  String get editVideo => 'تعديل الفيديو';

  @override
  String get chooseVideoFile => 'اختر ملف فيديو';

  @override
  String get videoSaved => 'تم حفظ الفيديو';

  @override
  String get deleteVideoBody => 'سيُحذف الفيديو وملفه، ولا يمكن التراجع.';

  @override
  String get noVideosTitle => 'لا توجد فيديوهات بعد';

  @override
  String get noVideosAdminSub => 'ارفع أول درس ليظهر للأعضاء فورًا.';

  @override
  String get noVideosUserSub => 'ستظهر الدروس هنا فور نشرها.';

  @override
  String get watchNow => 'مشاهدة';

  @override
  String get uploadingVideo => 'جارٍ رفع الفيديو…';

  @override
  String get uploadCancel => 'إلغاء الرفع';

  @override
  String get noFileChosen => 'لم يتم اختيار ملف';

  @override
  String megabytes(String size) {
    return '$size ميجابايت';
  }

  @override
  String get videoStillUploading => 'انتظر حتى ينتهي الرفع.';

  @override
  String get members => 'الأعضاء';

  @override
  String get membersSub => 'كل من سجّل في التطبيق.';

  @override
  String get noMembersYet => 'لا يوجد أعضاء بعد';

  @override
  String get noMembersYetSub => 'يظهرون هنا فور تسجيل أول عضو.';

  @override
  String get totalMembers => 'الأعضاء';

  @override
  String get totalQuizzes => 'الاختبارات';

  @override
  String get totalVideos => 'الفيديوهات';

  @override
  String get totalAttempts => 'المحاولات';

  @override
  String get dashboardAsecSub => 'نظرة سريعة على مركزك.';

  @override
  String memberSince(String date) {
    return 'عضو منذ $date';
  }

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get profileSaved => 'تم حفظ الملف الشخصي';

  @override
  String get publish => 'نشر';

  @override
  String get errKeychain =>
      'تعذّر على النظام حفظ الجلسة في سلسلة المفاتيح على هذا الماك. يجب توقيع التطبيق بحساب مطوّر Apple — راجع SETUP.md.';

  @override
  String get failStorageUnavailable =>
      'خدمة التخزين غير مُفعّلة في هذا المشروع. فعّل Storage من لوحة Firebase (Build > Storage) ثم انشر ملف storage.rules.';

  @override
  String get startedAt => 'وقت البدء';

  @override
  String get finishedAt => 'وقت التسليم';

  @override
  String get timeTaken => 'المدة المستغرقة';

  @override
  String get answerSheet => 'ورقة الإجابة';

  @override
  String blanksCount(String count) {
    return '$count بدون إجابة';
  }

  @override
  String minutesSeconds(String m, String s) {
    return '$m د $s ث';
  }

  @override
  String get theirAnswer => 'إجابته';

  @override
  String get openAttempt => 'عرض الإجابات';

  @override
  String attemptOf(String name, String quiz) {
    return '$name — $quiz';
  }

  @override
  String questionNumber(String n) {
    return 'السؤال $n';
  }

  @override
  String pointsEarned(String earned, String total) {
    return '$earned / $total نقطة';
  }

  @override
  String get attemptsByDay => 'المحاولات حسب اليوم';

  @override
  String get averageByQuiz => 'متوسط الدرجات لكل اختبار';

  @override
  String get topMembers => 'الأعلى نتيجة';

  @override
  String get latestAttempts => 'أحدث المحاولات';

  @override
  String get member => 'العضو';

  @override
  String get quizLabel => 'الاختبار';

  @override
  String get last7Days => 'آخر 7 أيام';

  @override
  String get allQuizzesAvg => 'عبر كل الاختبارات';

  @override
  String get nothingToChartAsec =>
      'تمتلئ الرسوم عندما يبدأ الأعضاء أداء الاختبارات.';

  @override
  String get seeAllAttempts => 'افتح الاختبار لعرضها كلها';

  @override
  String get resultsAdminSub => 'كل المحاولات لكل الأعضاء في جميع الاختبارات.';

  @override
  String get searchMember => 'ابحث عن عضو';

  @override
  String get allQuizzes => 'كل الاختبارات';

  @override
  String get membersWhoTook => 'الأعضاء المشاركون';

  @override
  String get passRate => 'نسبة النجاح';

  @override
  String get noAttemptsMatch => 'لا توجد محاولة مطابقة لهذا البحث';

  @override
  String get noAttemptsMatchSub => 'امسح البحث أو اختر اختبارًا آخر.';

  @override
  String get cvs => 'الأفضل';

  @override
  String get myCv => 'سيرتي الذاتية';

  @override
  String get cvDirectorySub => 'كل عضو نشر سيرته الذاتية.';

  @override
  String get cvAdminSub => 'كل السير الذاتية في المركز وحالة مراجعتها.';

  @override
  String get createCv => 'أنشئ سيرتك الذاتية';

  @override
  String get editCv => 'تعديل سيرتك الذاتية';

  @override
  String get cvSaved => 'تم حفظ السيرة الذاتية';

  @override
  String get cvNotAllowedTitle => 'نموذج السيرة الذاتية غير متاح لك بعد';

  @override
  String get cvNotAllowedSub => 'اطلب من المشرف تفعيله لحسابك.';

  @override
  String get allowCv => 'السيرة';

  @override
  String get allowCvHint => 'يسمح لهذا العضو بكتابة سيرة ذاتية';

  @override
  String get cvPersonal => 'البيانات الشخصية';

  @override
  String get cvProfession => 'التخصص المهني';

  @override
  String get cvSkillsSection => 'المهارات واللغات';

  @override
  String get cvLinks => 'الروابط';

  @override
  String get cvPhoto => 'الصورة';

  @override
  String get cvLocation => 'المحافظة';

  @override
  String get militaryStatus => 'الموقف من التجنيد';

  @override
  String get graduationYear => 'سنة التخرج';

  @override
  String get cvSpecialization => 'التخصص';

  @override
  String get jobRole => 'المسمى الوظيفي';

  @override
  String get proSkills => 'المهارات المهنية';

  @override
  String get softSkillsLabel => 'المهارات الشخصية';

  @override
  String get languagesLabel => 'اللغات';

  @override
  String get bioLabel => 'نبذة عنك';

  @override
  String get bioHint => 'سطران أو ثلاثة: ماذا تعمل وما الذي تبحث عنه.';

  @override
  String get facebookLabel => 'فيسبوك';

  @override
  String get linkedinLabel => 'لينكدإن';

  @override
  String get driveLabel => 'ملف السيرة الذاتية';

  @override
  String get cvFileHint =>
      'ارفع ملف السيرة نفسه — PDF أو Word، حتى 10 ميجابايت.';

  @override
  String get uploadCvFile => 'رفع ملف السيرة';

  @override
  String get noCvFile => 'لم يتم رفع ملف بعد';

  @override
  String get removeFile => 'حذف الملف';

  @override
  String get downloadCv => 'تحميل السيرة الذاتية';

  @override
  String get cvSummary => 'نبذة';

  @override
  String get cvEducation => 'التعليم والحالة';

  @override
  String get portfolioLabel => 'معرض الأعمال';

  @override
  String get choosePhoto => 'اختر صورة';

  @override
  String get pickRoleFirst => 'اختر المسمى الوظيفي أولًا لتظهر مهاراته هنا.';

  @override
  String selectedCount(String count) {
    return 'تم اختيار $count';
  }

  @override
  String get cvIncomplete => 'أكمل كل الحقول المعلَّمة بـ * قبل الحفظ.';

  @override
  String get pickSome => 'اضغط للاختيار';

  @override
  String get noneChosen => 'لم يتم الاختيار بعد';

  @override
  String get cvPending => 'قيد الانتظار';

  @override
  String get cvReviewed => 'تمت المراجعة';

  @override
  String get cvShortlisted => 'مرشّح';

  @override
  String get cvRejected => 'مرفوض';

  @override
  String get reviewState => 'المراجعة';

  @override
  String get noCvsTitle => 'لا توجد سير ذاتية بعد';

  @override
  String get noCvsSubUser => 'تظهر السير الذاتية هنا عندما ينشرها الأعضاء.';

  @override
  String get noCvsSubAdmin => 'اسمح لعضو بكتابة سيرته من صفحة الأعضاء.';

  @override
  String get searchCv => 'ابحث بالاسم أو المسمى أو المهارة';

  @override
  String get deleteCvBody => 'ستُحذف السيرة الذاتية وصورتها، ولا يمكن التراجع.';

  @override
  String get contactDetails => 'بيانات التواصل';

  @override
  String cvUpdatedOn(String date) {
    return 'آخر تحديث $date';
  }

  @override
  String get yourCvIsLive => 'سيرتك الذاتية ظاهرة لبقية الأعضاء.';

  @override
  String get enterPhone => 'أدخل رقم الهاتف';

  @override
  String get cvAllowed => 'مسموح';

  @override
  String get cvNotAllowed => 'غير مسموح';

  @override
  String get joinedLabel => 'تاريخ التسجيل';

  @override
  String get cvColumn => 'نموذج السيرة';

  @override
  String get searchMembers => 'ابحث عن عضو بالاسم أو البريد أو الهاتف';

  @override
  String get dangerZone => 'منطقة الخطر';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountHint => 'حذف حسابك وملفك الشخصي نهائيًا.';

  @override
  String get deleteAccountQuestion => 'حذف حسابك؟';

  @override
  String get deleteAccountBody =>
      'سيتم حذف ملفك الشخصي وسيرتك الذاتية وتسجيل خروجك. لا يمكن التراجع عن ذلك.';

  @override
  String get deleteAccountPasswordBody => 'أدخل كلمة المرور للتأكيد.';

  @override
  String get deleteAccountFailed => 'تعذّر حذف الحساب';

  @override
  String kpiNewThisWeek(int count) {
    return '+$count هذا الأسبوع';
  }

  @override
  String kpiNewThisMonth(int count) {
    return '+$count هذا الشهر';
  }

  @override
  String kpiOpenNow(int count) {
    return '$count متاح الآن';
  }

  @override
  String get kpiCvAccess => 'صلاحية السيرة';

  @override
  String get kpiDrafts => 'مسودات';

  @override
  String get kpiLibrarySize => 'حجم المكتبة';

  @override
  String get kpiUpcoming => 'قادم';

  @override
  String get kpiTimedOut => 'انتهى وقتها';

  @override
  String get videoLinkTitle => 'رابط الفيديو';

  @override
  String get videoLinkCaption =>
      'الصق رابطًا مباشرًا لملف ‎.mp4‎ أو رابط Google Drive (مشارك لـ «أي شخص لديه الرابط») — دون رفع.';

  @override
  String get videoLinkLabel => 'الرابط';

  @override
  String get videoLinkInvalid => 'أدخل رابطًا كاملًا يبدأ بـ https://';

  @override
  String get videoOrUpload => 'أو ارفع ملفًا';

  @override
  String get playerSpeed => 'السرعة';

  @override
  String get playerLoop => 'تكرار';

  @override
  String get playerRestart => 'من البداية';

  @override
  String get playerMute => 'كتم الصوت';

  @override
  String get playerFullScreen => 'ملء الشاشة';

  @override
  String playerResumedAt(String time) {
    return 'استكمال من $time';
  }

  @override
  String get playerStartOver => 'ابدأ من جديد';

  @override
  String get playerDuration => 'المدة';

  @override
  String get playerShortcuts =>
      'مسافة: تشغيل / إيقاف · ← →: ١٠ ثوانٍ · ↑ ↓: الصوت · F: ملء الشاشة · M: كتم';

  @override
  String get agoJustNow => 'الآن';

  @override
  String agoMinutes(int count) {
    return 'منذ $count دقيقة';
  }

  @override
  String agoHours(int count) {
    return 'منذ $count ساعة';
  }

  @override
  String agoDays(int count) {
    return 'منذ $count يوم';
  }

  @override
  String agoWeeks(int count) {
    return 'منذ $count أسبوع';
  }

  @override
  String agoMonths(int count) {
    return 'منذ $count شهر';
  }

  @override
  String agoYears(int count) {
    return 'منذ $count سنة';
  }

  @override
  String get nowPlaying => 'يعمل الآن';

  @override
  String get videoNewTag => 'جديد';

  @override
  String get autoplay => 'تشغيل تلقائي';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterRecent => 'أضيف حديثًا';

  @override
  String get filterContinue => 'متابعة المشاهدة';

  @override
  String get filterWatched => 'تمت مشاهدته';

  @override
  String get noLessonsMatch => 'لا توجد دروس';

  @override
  String get noLessonsMatchSub => 'جرّب كلمة أو فلترًا آخر.';

  @override
  String get searchVideos => 'ابحث في الفيديوهات';

  @override
  String lessonNumber(int n) {
    return 'الدرس $n';
  }

  @override
  String finishLessonFirst(int n) {
    return 'أكمل الدرس $n أولًا';
  }

  @override
  String get watchedBadge => 'تمت المشاهدة';

  @override
  String get finishThisLessonFirst => 'أكمل هذا الدرس أولًا لفتح الدرس التالي.';

  @override
  String get noSkipAhead => 'لا يمكنك التقديم — شاهد الدرس لفتح الباقي.';

  @override
  String get lessonCompleted => 'مكتمل';

  @override
  String courseProgress(int watched, int total) {
    return 'شاهدت $watched من $total دروس';
  }

  @override
  String get courseComplete => 'اكتملت الدورة — شاهدت كل الدروس!';

  @override
  String get permVideos => 'الفيديوهات';

  @override
  String get permQuizzes => 'الاختبارات';

  @override
  String get permResults => 'النتائج';

  @override
  String get permMembers => 'الأعضاء';

  @override
  String get permCvs => 'السير الذاتية';

  @override
  String get permWebsite => 'الموقع الإلكتروني';

  @override
  String get ctlGroupSections => 'قائمة الأعضاء';

  @override
  String get ctlGroupVideos => 'دروس الفيديو';

  @override
  String get ctlGroupGeneral => 'التطبيق كله';

  @override
  String get ctlGroupDashboard => 'لوحة المدير';

  @override
  String get ctlGroupCalculators => 'الحاسبات';

  @override
  String get ctlCalcHint =>
      'تشغيل: كل الأعضاء يستطيعون فتحها. إيقاف: مخفية عن كل الأعضاء (المدير ما زال يراها).';

  @override
  String get ctlCalcEngHint =>
      'إيقاف (الافتراضي): فقط الأعضاء الذين فتحتها لهم من صفحة الأعضاء. تشغيل: كل الأعضاء.';

  @override
  String get controlCentre => 'مركز التحكم';

  @override
  String get controlCentreHint =>
      'شغّل أو أوقف أجزاء التطبيق للجميع. التغيير فوري.';

  @override
  String get ctlTurnAllOn => 'تشغيل الكل';

  @override
  String get ctlSectionVideos => 'الفيديوهات';

  @override
  String get ctlSectionVideosHint => 'يرى الأعضاء صفحة الفيديوهات.';

  @override
  String get ctlSectionQuizzes => 'الاختبارات';

  @override
  String get ctlSectionQuizzesHint => 'يرى الأعضاء صفحة الاختبارات.';

  @override
  String get ctlSectionCvDirectory => 'دليل السير الذاتية';

  @override
  String get ctlSectionCvDirectoryHint => 'يتصفح الأعضاء سير الجميع.';

  @override
  String get ctlSectionMyCv => 'سيرتي الذاتية';

  @override
  String get ctlSectionMyCvHint => 'يرى الأعضاء المسموح لهم نموذج السيرة.';

  @override
  String get ctlVideoSequential => 'فتح الدروس بالترتيب';

  @override
  String get ctlVideoSequentialHint => 'لا يُفتح الدرس إلا بعد مشاهدة السابق.';

  @override
  String get ctlVideoBlockSkip => 'منع التقديم';

  @override
  String get ctlVideoBlockSkipHint => 'لا يمكن تجاوز ما لم يُشاهد.';

  @override
  String get ctlVideoAutoplay => 'تشغيل الدرس التالي تلقائيًا';

  @override
  String get ctlVideoAutoplayHint => 'يبدأ الدرس التالي عند انتهاء الحالي.';

  @override
  String get ctlVideoUpNext => 'قائمة التالي';

  @override
  String get ctlVideoUpNextHint => 'عرض باقي الدروس بجانب المشغّل.';

  @override
  String get ctlVideoOptionsBar => 'شريط خيارات المشغّل';

  @override
  String get ctlVideoOptionsBarHint =>
      'تقديم وتكرار وإعادة وصوت وسرعة تحت الفيديو.';

  @override
  String get ctlVideoSpeed => 'سرعة التشغيل';

  @override
  String get ctlVideoSpeedHint => 'يمكن المشاهدة من 0.5x إلى 2x.';

  @override
  String get ctlVideoResume => 'استكمال من حيث توقفت';

  @override
  String get ctlVideoResumeHint => 'إعادة فتح الدرس تبدأ من آخر موضع.';

  @override
  String get ctlVideoSearch => 'البحث والفلاتر';

  @override
  String get ctlVideoSearchHint => 'مربع البحث والفلاتر في صفحة الفيديوهات.';

  @override
  String get ctlVideoCourseProgress => 'شريط تقدم الدورة';

  @override
  String get ctlVideoCourseProgressHint => '\"شاهدت 3 من 10\" في الأعلى.';

  @override
  String get ctlVideoDownloads => 'التحميل داخل التطبيق (بدون إنترنت)';

  @override
  String get ctlVideoDownloadsHint =>
      'يحفظ الأعضاء الدروس داخل ASEC — مشفّرة لهذا الجهاز والحساب فقط — ويشاهدونها بدون إنترنت. الإيقاف يمسح الدروس المحفوظة من كل الأجهزة.';

  @override
  String get ctlAnimations => 'الحركات';

  @override
  String get ctlAnimationsHint => 'انتقالات الصفحات وحركات الظهور.';

  @override
  String get ctlRegistration => 'التسجيل الجديد';

  @override
  String get ctlRegistrationHint => 'إظهار \"تسجيل\" في شاشة الدخول.';

  @override
  String get ctlScreenProtection => 'منع لقطات الشاشة';

  @override
  String get ctlScreenProtectionHint =>
      'تشغيل: لقطات الشاشة وتسجيل الشاشة لفيديوهات الدروس تظهر سوداء (أندرويد، iOS، ماك، ويندوز). إيقاف: مسموح.';

  @override
  String get ctlScreenshotException =>
      'السماح بلقطات الشاشة لـ amrmesbah33@gmail.com';

  @override
  String get ctlScreenshotExceptionHint =>
      'تشغيل: هذا الحساب يمكنه أخذ لقطات وتسجيل الشاشة حتى لو كانت ممنوعة على الجميع. إيقاف: ممنوع مثل الجميع.';

  @override
  String get shotAllowedTitle => 'لقطات الشاشة مسموحة';

  @override
  String get shotAllowedBody =>
      'تحذير: خيار \"منع لقطات الشاشة\" مغلق، لذلك كل الأعضاء يستطيعون الآن أخذ لقطات وتسجيل الشاشة. أعد تشغيله عند الانتهاء.';

  @override
  String get shotAllowedBlock => 'امنع الآن';

  @override
  String get shotAllowedKeep => 'اتركها مسموحة';

  @override
  String get ctlDashboardCharts => 'رسوم لوحة المدير';

  @override
  String get ctlDashboardChartsHint => 'الرسوم الأربعة تحت الأرقام.';

  @override
  String get ctlDashboardTable => 'جدول آخر المحاولات';

  @override
  String get ctlDashboardTableHint => 'الجدول أسفل لوحة المدير.';

  @override
  String get adminsTitle => 'المديرون';

  @override
  String get adminsHint => 'أنشئ مديرين واختر ما يديره كل منهم.';

  @override
  String get addAdmin => 'إضافة مدير';

  @override
  String get createAdmin => 'إنشاء المدير';

  @override
  String get noAdminsYet => 'لا يوجد مديرون آخرون بعد.';

  @override
  String get editPermissions => 'تعديل الصلاحيات';

  @override
  String get removeAdmin => 'حذف المدير';

  @override
  String get removeAdminQuestion => 'حذف هذا المدير؟';

  @override
  String get noPermissions => 'بلا صلاحيات — يفتح الإعدادات فقط.';

  @override
  String get permissionsTitle => 'الصلاحيات';

  @override
  String get adminCreated => 'تم إنشاء المدير ويمكنه الدخول الآن.';

  @override
  String get permissionsSaved => 'تم حفظ الصلاحيات';

  @override
  String get adminFormInvalid => 'أدخل اسمًا وبريدًا صحيحًا.';

  @override
  String get adminPasswordShort => 'كلمة المرور 6 أحرف على الأقل.';

  @override
  String get adminEmailInUse => 'هذا البريد له حساب بالفعل.';

  @override
  String removeAdminBody(String name) {
    return 'لن يتمكن $name من استخدام لوحة الإدارة. يمكن حذف حساب الدخول من Firebase.';
  }

  @override
  String get videoCategoriesTitle => 'الأقسام';

  @override
  String get videoCategoryGeneral => 'عام';

  @override
  String get allCategories => 'كل الأقسام';

  @override
  String get videoCategory => 'القسم';

  @override
  String get videoCategoryHint =>
      'الفيديوهات التي لها نفس القسم تظهر معًا (مثل GENERAL NOTES).';

  @override
  String videoCount(int count) {
    return '$count فيديو';
  }

  @override
  String get securityBlockedTitle => 'هذا الجهاز غير آمن لتشغيل ASEC';

  @override
  String get securityBlockedBody =>
      'لحماية الدروس لا يعمل ASEC أثناء تفعيل أيٍّ مما يلي. أوقفه ثم اضغط إعادة الفحص.';

  @override
  String get securityCheckAgain => 'إعادة الفحص';

  @override
  String get integrityDeveloperOptions =>
      'خيارات المطوّر مفعّلة (الإعدادات ← النظام ← خيارات المطوّر)';

  @override
  String get integrityUsbDebugging => 'تصحيح أخطاء USB مفعّل';

  @override
  String get integrityDebugger => 'يوجد مصحّح أخطاء متصل بالتطبيق';

  @override
  String get integrityDebuggable =>
      'هذه النسخة من التطبيق معدّلة — ثبّته من المصدر الرسمي';

  @override
  String get integrityRoot => 'الجهاز عليه صلاحيات روت';

  @override
  String get integrityJailbreak => 'الجهاز عليه جيلبريك';

  @override
  String get integrityHooking => 'توجد أدوات اختراق تعمل على الجهاز';

  @override
  String get certificateQuizzes => 'اختبارات الشهادات';

  @override
  String get certificateQuiz => 'اختبار الشهادة';

  @override
  String get certificateQuizzesAdminSub =>
      'اختبار نهائي واحد لكل كورس. من يحصل على 70% أو أكثر ينال شهادة من ASEC.';

  @override
  String get certificateQuizzesUserSub =>
      'أكمل كل دروس الكورس ثم اجتز اختباره النهائي بنسبة 70% لتحصل على شهادتك من ASEC.';

  @override
  String get newCertificateQuiz => 'اختبار شهادة جديد';

  @override
  String get noCertificateQuizzesTitle => 'لا توجد اختبارات شهادات بعد';

  @override
  String get noCertificateQuizzesAdminSub => 'أنشئ اختبارًا نهائيًا لكل كورس.';

  @override
  String get noCoursesTitle => 'لا توجد كورسات بعد';

  @override
  String get noCoursesUserSub => 'تظهر هنا الكورسات واختباراتها النهائية.';

  @override
  String get courseLabel => 'الكورس';

  @override
  String get courseCaption =>
      'يُفتح هذا الاختبار للعضو بعد مشاهدة كل دروس الكورس. درجة النجاح: 70%.';

  @override
  String get chooseCourse => 'اختر الكورس';

  @override
  String get errChooseCourse => 'اختر الكورس الذي يتبعه هذا الاختبار.';

  @override
  String certLocked(int watched, int total) {
    return 'شاهد كل الدروس أولًا · $watched/$total';
  }

  @override
  String get certReady => 'جاهز — ابدأ الاختبار النهائي';

  @override
  String certFailed(String percent) {
    return 'آخر محاولة $percent% · تحتاج 70% — حاول مرة أخرى';
  }

  @override
  String certPassed(String percent) {
    return 'نجحت بنسبة $percent% · اعرض شهادتك';
  }

  @override
  String get certNoExam => 'الاختبار النهائي قريبًا';

  @override
  String get certLockedSnack => 'أكمل كل دروس هذا الكورس ليُفتح اختباره.';

  @override
  String get passedTitle => 'مبروك، لقد نجحت!';

  @override
  String get failedTitle => 'لم تنجح بعد';

  @override
  String get failedBody => 'تحتاج 70% للنجاح. راجع الدروس ثم حاول مرة أخرى.';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get viewCertificate => 'عرض الشهادة';

  @override
  String lastTry(String percent) {
    return 'محاولتك الأخيرة: $percent% — تحتاج 70% للنجاح.';
  }

  @override
  String get certificateTitle => 'شهادتك';

  @override
  String get downloadPdf => 'تحميل PDF';

  @override
  String get passMark => 'درجة النجاح 70%';

  @override
  String get certificateBadge => 'شهادة';

  @override
  String get unitConverter => 'محوّل الوحدات';

  @override
  String get unitConverterSub => 'أهم الوحدات الهندسية — يعمل بدون إنترنت.';

  @override
  String get unitFrom => 'من';

  @override
  String get unitTo => 'إلى';

  @override
  String get unitValue => 'أدخل قيمة';

  @override
  String get swapUnits => 'تبديل الوحدتين';

  @override
  String get allConversions => 'كل التحويلات';

  @override
  String get openUnitConverter => 'محوّل الوحدات';

  @override
  String copiedValue(String value) {
    return 'تم نسخ $value';
  }

  @override
  String get engineeringCalc => 'الحاسبات الهندسية';

  @override
  String get engineeringCalcShort => 'الحسابات';

  @override
  String get engineeringCalcSub =>
      'تكييف، مكافحة حريق، أعمال صحية وغازات طبية — حسابات تصميم سريعة.';

  @override
  String get ductCalc => 'حاسبة مجاري الهواء';

  @override
  String get ductCalcShort => 'الدكت';

  @override
  String get pipeCalc => 'حاسبة مقاسات المواسير';

  @override
  String get pipeCalcShort => 'المواسير';

  @override
  String get plumbingFireCalc => 'السباكة';

  @override
  String get plumbingFireCalcShort => 'السباكة';

  @override
  String get fireCalc => 'مكافحة الحريق';

  @override
  String get fireCalcShort => 'الحريق';

  @override
  String get calcInputs => 'المدخلات';

  @override
  String get calcResults => 'النتائج';

  @override
  String get calcFormula => 'طريقة الحساب';

  @override
  String get calcReset => 'إعادة الضبط';

  @override
  String get calcTapHint =>
      'اضغط على النتيجة لتغيير وحدتها · اضغط مطولًا للنسخ';

  @override
  String get calcFillAll => 'املأ كل الحقول لعرض النتائج.';

  @override
  String get calcDisclaimer =>
      'تقدير تصميمي مبسّط. راجعه مع الكود المعتمد وحساب تفصيلي قبل إصدار المخططات.';

  @override
  String get calcExportPdf => 'تصدير PDF';

  @override
  String get calcExportExcel => 'تصدير Excel';

  @override
  String get calcItem => 'البند';

  @override
  String get calcValue => 'القيمة';

  @override
  String get calcUnit => 'الوحدة';

  @override
  String get calcDate => 'التاريخ';

  @override
  String get calcFileName => 'اسم الملف';

  @override
  String calcSaved(String name) {
    return 'تم الحفظ: $name';
  }

  @override
  String get offlineTitle => 'أنت غير متصل بالإنترنت';

  @override
  String get offlineBody =>
      'الأدوات التي لا تحتاج إلى الإنترنت تعمل هنا. يعود باقي التطبيق تلقائيًا فور عودة الاتصال.';

  @override
  String get offlineRetry => 'إعادة المحاولة';

  @override
  String get moreTab => 'المزيد';

  @override
  String get certificateShort => 'الشهادة';

  @override
  String get memberAccess => 'الصلاحية';

  @override
  String get editAccess => 'تعديل الصلاحية';

  @override
  String get accessCourses => 'الكورسات';

  @override
  String get accessAllCourses => 'كل الكورسات';

  @override
  String get accessCoursesCaption =>
      'اختر الكورسات التي يشاهدها هذا العضو. \"كل الكورسات\" تشمل أيضًا أي كورس يُضاف لاحقًا.';

  @override
  String get accessPlatforms => 'منصات الفيديو';

  @override
  String get accessPlatformsCaption =>
      'يستطيع العضو تسجيل الدخول من أي جهاز. الفيديوهات واختباراتها والشهادات تفتح فقط على المنصات المحددة، وباقي التطبيق يفتح على كل المنصات.';

  @override
  String get accessAllPlatforms => 'كل الأجهزة';

  @override
  String get accessPeriod => 'مدة الصلاحية';

  @override
  String get accessPermanent => 'دائمة';

  @override
  String get accessDates => 'من – إلى';

  @override
  String get accessFrom => 'من';

  @override
  String get accessUntil => 'إلى';

  @override
  String get accessPause => 'إيقاف مؤقت';

  @override
  String get accessResume => 'استئناف الصلاحية';

  @override
  String get accessPauseCaption =>
      'يوقف صلاحية العضو الآن. عند الاستئناف تُضاف أيام الإيقاف إلى تاريخ الانتهاء.';

  @override
  String accessPausedSince(String date) {
    return 'موقوف منذ $date';
  }

  @override
  String get accessPaused => 'موقوف مؤقتًا';

  @override
  String accessUntilShort(String date) {
    return 'حتى $date';
  }

  @override
  String accessCoursesCount(int count) {
    return '$count كورس';
  }

  @override
  String get accessSaved => 'تم حفظ الصلاحية';

  @override
  String get accessPickPlatform => 'اختر جهازًا واحدًا على الأقل.';

  @override
  String get accessPickCourse => 'اختر كورسًا واحدًا على الأقل أو كل الكورسات.';

  @override
  String get accessDatesInvalid =>
      'يجب أن يكون تاريخ الانتهاء بعد تاريخ البداية.';

  @override
  String get accessExpiredShort => 'منتهية';

  @override
  String get blockedTitlePaused => 'تم إيقاف صلاحيتك مؤقتًا';

  @override
  String get blockedBodyPaused =>
      'أوقفت ASEC صلاحيتك مؤقتًا. تواصل مع ASEC لاستئنافها — لن تخسر أيام الإيقاف.';

  @override
  String get blockedTitleExpired => 'انتهت مدة صلاحيتك';

  @override
  String blockedBodyExpired(String date) {
    return 'انتهت صلاحيتك في $date. تواصل مع ASEC لتجديدها.';
  }

  @override
  String get blockedTitleNotStarted => 'لم تبدأ صلاحيتك بعد';

  @override
  String blockedBodyNotStarted(String date) {
    return 'تبدأ صلاحيتك في $date.';
  }

  @override
  String get blockedTitlePlatform => 'غير متاح على هذا الجهاز';

  @override
  String blockedBodyPlatform(String platforms) {
    return 'يمكن استخدام حسابك على: $platforms.';
  }

  @override
  String get tbMember => 'العضو';

  @override
  String get tbThisDevice => 'هذا الجهاز';

  @override
  String get tbAllowedOn => 'مسموح على';

  @override
  String get tbStatus => 'الحالة';

  @override
  String get tbStarts => 'تبدأ';

  @override
  String get tbEnds => 'تنتهي';

  @override
  String get tbWrongDevice => 'جهاز غير مسموح';

  @override
  String get tbNotStarted => 'لم تبدأ';

  @override
  String get downloads => 'التنزيلات';

  @override
  String get downloadsSub =>
      'دروس محفوظة داخل تطبيق ASEC لمشاهدتها بدون إنترنت. تبقى داخل التطبيق فقط.';

  @override
  String get downloadVideo => 'تنزيل للمشاهدة بدون إنترنت';

  @override
  String get downloadStarted => 'جارٍ التنزيل — ستجده في التنزيلات';

  @override
  String get downloadCancel => 'إلغاء التنزيل';

  @override
  String get downloadFailed => 'فشل التنزيل — اضغط للمحاولة مرة أخرى';

  @override
  String get downloadDone => 'تم التنزيل — اضغط للحذف';

  @override
  String downloadRemoveQuestion(String title) {
    return 'حذف «$title» من التنزيلات؟';
  }

  @override
  String get downloadRemoveBody =>
      'سيبقى الدرس في الفيديوهات، لكنه لن يعمل بدون إنترنت بعد الآن.';

  @override
  String get downloadRemove => 'حذف';

  @override
  String get downloadsEmptyTitle => 'لا توجد تنزيلات بعد';

  @override
  String get downloadsEmptySub =>
      'اضغط على أيقونة التنزيل في أي درس داخل الفيديوهات لمشاهدته بدون إنترنت.';

  @override
  String downloadsStorage(String size) {
    return '$size مستخدمة على هذا الجهاز';
  }

  @override
  String get downloadsRemoveAll => 'حذف الكل';

  @override
  String get downloadsRemoveAllQuestion => 'حذف كل التنزيلات؟';

  @override
  String get updateTitle => 'يتوفر إصدار جديد';

  @override
  String get updateMessage =>
      'إصدار جديد من ASEC متاح الآن على Google Play مع تحسينات وإصلاحات.';

  @override
  String get updateRequiredTitle => 'التحديث مطلوب';

  @override
  String get updateRequiredMessage =>
      'هذا الإصدار لم يعد مدعومًا. يرجى التحديث من Google Play لمتابعة استخدام ASEC.';

  @override
  String get updateNow => 'تحديث الآن';

  @override
  String get updateLater => 'لاحقًا';

  @override
  String get updateWhatsNew => 'ما الجديد';

  @override
  String updateCurrentVersion(String version) {
    return 'إصدارك: $version';
  }

  @override
  String get patchReadyTitle => 'التحديث جاهز';

  @override
  String get patchReadyMessage =>
      'تم تنزيل التحسينات في الخلفية. أغلق التطبيق وافتحه مرة أخرى لتطبيقها.';

  @override
  String get patchRestart => 'إغلاق وإعادة الفتح';

  @override
  String get calcColumn => 'الحاسبات الهندسية';

  @override
  String get calcAllowed => 'مفعّلة';

  @override
  String get calcNotAllowed => 'مقفلة';

  @override
  String get settingsMySpace => 'مساحتي';

  @override
  String get settingsMySpaceHint =>
      'سيرتك الذاتية وشهاداتك ودروسك المحفوظة وأدواتك.';

  @override
  String homeGreeting(String name) {
    return 'أهلاً بعودتك يا $name';
  }

  @override
  String get homeSub => 'أكمل من حيث توقفت.';

  @override
  String get homeContinue => 'تابع المشاهدة';

  @override
  String get homeStart => 'ابدأ أول درس';

  @override
  String get homeStartSub => 'دوراتك جاهزة. افتح واحدة لتبدأ.';

  @override
  String get homeAllDone => 'شاهدت كل الدروس — أحسنت!';

  @override
  String get homeProgress => 'تقدّمك';

  @override
  String homeLessonsLeft(int count) {
    return 'متبقٍ $count درس';
  }

  @override
  String get homeQuickAccess => 'وصول سريع';

  @override
  String get homeCourses => 'دوراتك';

  @override
  String get homeSeeAll => 'عرض الكل';

  @override
  String get homeVideosHint => 'الدورات والدروس';

  @override
  String get homeConverterHint => 'يعمل بدون إنترنت';

  @override
  String get homeQuizzesHint => 'اختبر ما تعلمته';

  @override
  String get homeCvsHint => 'ابحث عن مهندسين';

  @override
  String get homeCertificateHint => 'احصل على شهادتك';

  @override
  String get homeCalcHint => 'تكييف، حريق، صحي';

  @override
  String get homeResume => 'استكمال';

  @override
  String homeLessonOf(int n, int total) {
    return 'الدرس $n من $total';
  }

  @override
  String get unitConverterShort => 'الوحدات';

  @override
  String get sectionQuizLabel => 'القسم';

  @override
  String get sectionQuizCaption =>
      'اختياري. اربط الاختبار بقسم من الكورس: يجده العضو في نهاية هذا القسم ويبدأه بعد مشاهدة كل دروسه.';

  @override
  String get sectionNone => 'بدون — اختبار عام';

  @override
  String get sectionQuizzesTitle => 'اختبار القسم';

  @override
  String get addSectionQuiz => 'إضافة اختبار';

  @override
  String get sectionQuizLocked => 'شاهد كل دروس هذا القسم لفتح الاختبار.';

  @override
  String get accessDevice => 'جهاز الدخول';

  @override
  String get accessDeviceCaption =>
      'يستطيع الأعضاء تسجيل الدخول من أي عدد من الأجهزة. الجهاز أدناه كان مربوطًا بالحساب سابقًا، ويمكنك إزالته أو حظره.';

  @override
  String get accessDeviceNone =>
      'لا يوجد جهاز مربوط — يستطيع العضو تسجيل الدخول من أي جهاز.';

  @override
  String get accessDeviceUnknown => 'جهاز';

  @override
  String accessDeviceSince(String date) {
    return 'منذ $date';
  }

  @override
  String get accessDeviceRemove => 'إزالة الجهاز';

  @override
  String get accessDeviceRemoveQuestion => 'إزالة هذا الجهاز؟';

  @override
  String accessDeviceRemoveBody(String device) {
    return 'سيُمنع العضو من الدخول على $device الآن، وأول جهاز يسجّل الدخول منه بعدها يصبح جهازه.';
  }

  @override
  String get accessDeviceRemoved =>
      'تمت إزالة الجهاز. يمكن للعضو الآن تسجيل الدخول من الجهاز الجديد.';

  @override
  String get blockedTitleOtherDevice => 'هذا الحساب مستخدم على جهاز آخر';

  @override
  String get blockedBodyOtherDevice =>
      'حسابك يعمل على جهاز واحد فقط. لاستخدام هذا الجهاز بدلًا منه، اطلب من الإدارة إزالة الجهاز القديم، ثم سجّل الخروج وادخل من جديد هنا.';

  @override
  String get blockedTitleDeviceRemoved => 'تمت إزالة هذا الجهاز';

  @override
  String get blockedBodyDeviceRemoved =>
      'أزالت الإدارة هذا الجهاز من حسابك. لاستخدامه مرة أخرى، سجّل الخروج ثم ادخل من جديد.';

  @override
  String get tbAccountDevice => 'جهاز الحساب';

  @override
  String get engEngagement => 'التفاعل';

  @override
  String get engEngagementSub => 'الإشعارات والنصائح ومكتبة الأعضاء ونجومهم.';

  @override
  String get engNotifications => 'الإشعارات';

  @override
  String get engNotificationsSub => 'رسائل من فريق ASEC.';

  @override
  String get engNotificationsEmpty => 'لا توجد إشعارات بعد';

  @override
  String get engNotificationsEmptySub =>
      'ستظهر هنا الرسائل الجديدة من الإدارة.';

  @override
  String get engSendNotification => 'إرسال إشعار';

  @override
  String get engSend => 'إرسال';

  @override
  String get engNotifSent => 'تم إرسال الإشعار';

  @override
  String get engNotifTitleHint => 'عنوان الإشعار';

  @override
  String get engNotifBodyHint => 'اكتب الرسالة التي سيقرأها الأعضاء';

  @override
  String get engNotifAdminSub =>
      'تُرسل لكل الأعضاء — تظهر تحت أيقونة الجرس في أعلى التطبيق مع عدد غير المقروء.';

  @override
  String get engTipsTricks => 'نصائح وحيل';

  @override
  String get engTipsAdminSub =>
      'تظهر النصائح فوق الصفحة الرئيسية للأعضاء عند فتح التطبيق. يمكن للعضو حفظ النصيحة، والرقم يوضح عدد من حفظها.';

  @override
  String get engAddTip => 'إضافة نصيحة';

  @override
  String get engTipAdded => 'تمت إضافة النصيحة';

  @override
  String get engTipTitleHint => 'عنوان النصيحة';

  @override
  String get engTipBodyHint => 'اكتب النصيحة';

  @override
  String get engTipSavedToast => 'تم الحفظ — تجدها في أيقونة المحفوظات بالأعلى';

  @override
  String get engTipTapToClose => 'اضغط في أي مكان للإغلاق';

  @override
  String engTipSavedCount(int count) {
    return 'حفظها $count';
  }

  @override
  String get engTipActive => 'تظهر للأعضاء';

  @override
  String get engTipsEmpty => 'لا توجد نصائح بعد';

  @override
  String get engSavedTips => 'النصائح المحفوظة';

  @override
  String get engSavedTipsSub => 'النصائح التي حفظتها.';

  @override
  String get engSavedTipsEmpty => 'لا توجد محفوظات بعد';

  @override
  String get engTipUnsave => 'إزالة من المحفوظات';

  @override
  String get engLibrary => 'المكتبة';

  @override
  String get engLibraryFiles => 'الملفات';

  @override
  String get engLibraryFilesHint => 'مستندات من ASEC';

  @override
  String get engLibraryBest => 'الأفضل';

  @override
  String get engLibraryBestHint => 'أفضل السير الذاتية في التطبيق';

  @override
  String get engLibraryCertificate => 'الشهادات';

  @override
  String get engLibrarySub => 'ملفات يشاركها معك فريق ASEC.';

  @override
  String get engLibraryEmpty => 'لا توجد ملفات بعد';

  @override
  String get engLibraryEmptySub => 'ستظهر هنا الملفات التي تضيفها الإدارة.';

  @override
  String get engLibraryAdminSub =>
      'ملفات مكتبة الأعضاء (الصفحة الرئيسية ← المكتبة ← الملفات).';

  @override
  String get engLeaderboardSub =>
      'ترتيب الأعضاء حسب النجوم التي حصلوا عليها من مشاهدة الكورسات.';

  @override
  String get engLeaderboardEmpty => 'لا توجد نجوم بعد';

  @override
  String get engYou => 'أنت';

  @override
  String get engMember => 'عضو';

  @override
  String get engStarsTab => 'النجوم';

  @override
  String get engStarsAdminSub =>
      'نجوم كل عضو في كل كورس — نجمة لكل 20% مشاهدة، وبحد أقصى 5 لكل كورس. اضغط على العضو لعرض كورساته.';

  @override
  String get engStarsHint => 'نجمة لكل 20% تشاهدها — 5 نجوم لكل كورس';

  @override
  String engStarsCount(int count) {
    return '$count نجمة';
  }

  @override
  String get engFilesTab => 'الملفات';

  @override
  String get engNewFolder => 'مجلد جديد';

  @override
  String get engFolderName => 'اسم المجلد';

  @override
  String get engFolderCreated => 'تم إنشاء المجلد';

  @override
  String get engRename => 'إعادة تسمية';

  @override
  String get engCourseFilesEmpty => 'لا توجد ملفات في هذا الكورس بعد';

  @override
  String get engCourseFilesEmptyAdmin => 'أنشئ مجلدًا ثم ارفع الملفات بداخله.';

  @override
  String get engFolderEmpty => 'هذا المجلد فارغ';

  @override
  String get engAllFolders => 'كل المجلدات';

  @override
  String engFileCount(int count) {
    return '$count ملف';
  }

  @override
  String get engDeleteFolderBody => 'سيتم حذف المجلد وكل الملفات بداخله.';

  @override
  String get engDeleteBody => 'لا يمكن التراجع عن هذا.';

  @override
  String get engFileUploaded => 'تم رفع الملف';

  @override
  String get engFileOpenFailed => 'تعذر فتح الملف';

  @override
  String get engFieldRequired => 'مطلوب';

  @override
  String get engCourseSequential => 'المشاهدة بالترتيب';

  @override
  String get engCourseSequentialHint =>
      'لا يفتح الفيديو إلا بعد مشاهدة الذي قبله';

  @override
  String get engVideoDefault => 'افتراضي';

  @override
  String get engVideoCustom => 'مخصص';

  @override
  String get engMakeDefault => 'اجعله افتراضي (لكل الأعضاء)';

  @override
  String get engMakeCustom => 'اجعله مخصص';

  @override
  String get engRulesMissing =>
      'غير مسموح من Firebase. انشر القواعد الجديدة: firebase deploy --only firestore:rules,storage';

  @override
  String get engChooseFolder => 'الرفع في أي مجلد؟';

  @override
  String get engChooseFolderSub =>
      'اختر مجلدًا أو أنشئ مجلدًا جديدًا — ثم اختر الملف.';

  @override
  String get engNoFoldersYet => 'لا توجد مجلدات بعد — أنشئ أول مجلد:';

  @override
  String get engOtherFiles => 'ملفات أخرى';

  @override
  String get engPartners => 'شركاء النجاح';

  @override
  String get engPartnersSub => 'شركات تعمل مع ASEC';

  @override
  String get engPartnersAdminSub =>
      'شعارات الشركاء — تدور في حلقة ثلاثية الأبعاد حول شعار ASEC في الصفحة الرئيسية للأعضاء (وتظهر على الموقع). تظهر المنشورة فقط.';

  @override
  String get engPartnerAdd => 'إضافة شريك';

  @override
  String get engPartnerName => 'اسم الشركة';

  @override
  String get engPartnerAdded => 'تمت إضافة الشريك';

  @override
  String get engPartnersEmpty => 'لا يوجد شركاء بعد — أضف أول شعار';

  @override
  String get updCardTitle => 'تحديث التطبيق';

  @override
  String get updCardHint =>
      'اطلب من مستخدمي أندرويد تحديث التطبيق. استخدم رقم البناء — الجزء بعد + في pubspec (1.0.1+9 ← 9).';

  @override
  String get updLatestBuild => 'أحدث بناء — تحديث اختياري';

  @override
  String get updLatestBuildHint =>
      'الإصدارات الأقل من هذا الرقم ترى رسالة \"إصدار جديد\" ويمكن إغلاقها.';

  @override
  String get updMinBuild => 'أقل بناء مسموح — تحديث إجباري';

  @override
  String get updMinBuildHint =>
      'الإصدارات الأقل من هذا الرقم يجب أن تُحدَّث، ولا يمكن إغلاق الرسالة.';

  @override
  String get updNotesEn => 'ما الجديد (إنجليزي)';

  @override
  String get updNotesAr => 'ما الجديد (عربي)';

  @override
  String get updWarning =>
      'ارفع هذه الأرقام فقط بعد نشر الإصدار الجديد على Google Play — وإلا سيُطلب من المستخدمين التحديث لإصدار غير متاح بعد.';

  @override
  String updStatusForced(String build) {
    return 'التحديث الإجباري مفعّل: الإصدارات الأقل من $build يجب أن تُحدَّث';
  }

  @override
  String get updStatusOff => 'لا يوجد تحديث إجباري';

  @override
  String updThisApp(String version) {
    return 'هذا التطبيق: $version';
  }

  @override
  String get updStopForcing => 'إيقاف الإجبار';

  @override
  String get updSaved => 'تم حفظ إعدادات التحديث';

  @override
  String get updUseThisVersion => 'استخدم هذا الإصدار';

  @override
  String get updBuildToUse => 'رقم البناء المطلوب التحديث إليه';

  @override
  String get updBuildToUseHint =>
      'تمت تعبئته من هذا التطبيق. غيّره إذا كان لإصدار أندرويد الجديد رقم مختلف.';

  @override
  String get updForceQuestion => 'هل تريد إجبار المستخدمين على التحديث؟';

  @override
  String get updOptional => 'اختياري';

  @override
  String get updForced => 'إجباري';

  @override
  String updOptionalSet(String build) {
    return 'تم ضبط التحديث الاختياري: الإصدارات الأقل من $build سيُطلب منها التحديث';
  }

  @override
  String get updEnterBuild => 'أدخل رقم البناء';

  @override
  String get permEngagement => 'التفاعل';

  @override
  String get permViewOnly => 'عرض فقط';

  @override
  String get permDashboardCharts => 'الرسوم البيانية';

  @override
  String get permDashboardTable => 'جدول آخر المحاولات';

  @override
  String get permVideosAdd => 'إضافة / رفع الفيديوهات وملفات الكورس';

  @override
  String get permVideosEdit => 'تعديل الفيديوهات وملفات الكورس';

  @override
  String get permVideosDelete => 'حذف الفيديوهات وملفات الكورس';

  @override
  String get permVideosPublish => 'نشر / إخفاء الفيديوهات';

  @override
  String get permVideosAccess =>
      'صلاحية الكورس (افتراضي / مخصص، المشاهدة بالترتيب)';

  @override
  String get permQuizzesCreate => 'إنشاء اختبارات';

  @override
  String get permQuizzesEdit => 'تعديل الاختبارات';

  @override
  String get permQuizzesDelete => 'حذف الاختبارات';

  @override
  String get permQuizzesOpen => 'فتح / إغلاق الاختبارات';

  @override
  String get permQuizzesCertificates => 'اختبارات الشهادات';

  @override
  String get permMembersBlock => 'تفعيل / إيقاف الأعضاء';

  @override
  String get permMembersAccess =>
      'تعديل الصلاحية (الكورسات، المدة، الإيقاف المؤقت، الحاسبات)';

  @override
  String get permMembersDevice => 'إعادة تعيين الجهاز';

  @override
  String get permCvsReview => 'مراجعة السير الذاتية (الحالة)';

  @override
  String get permCvsDelete => 'حذف السير الذاتية';

  @override
  String get permCvsGrant => 'منح صلاحية السيرة الذاتية';

  @override
  String get permEngNotifications => 'الإشعارات';

  @override
  String get permEngTips => 'النصائح والحيل';

  @override
  String get permEngLibrary => 'المكتبة';

  @override
  String get permEngStars => 'النجوم';

  @override
  String get permEngPartners => 'الشركاء';

  @override
  String get permWebContent => 'الصفحات والمقالات والمحتوى';

  @override
  String get permWebInbox => 'الوارد';

  @override
  String get permWebSettings => 'إعدادات الموقع ومركز التحكم';

  @override
  String get blockedTitleDeviceBlocked => 'هذا الجهاز محظور';

  @override
  String get blockedBodyDeviceBlocked =>
      'قامت الإدارة بحظر هذا الجهاز، ولا يمكن استخدام التطبيق عليه. تواصل مع الإدارة إذا كنت ترى أن هذا خطأ.';

  @override
  String get accessDeviceBlock => 'حظر الجهاز';

  @override
  String get accessDeviceBlockQuestion => 'حظر هذا الجهاز؟';

  @override
  String accessDeviceBlockBody(String device) {
    return 'سيتم حظر $device: أي شخص يسجّل الدخول عليه سيرى \"هذا الجهاز محظور\". ويمكن للعضو استخدام التطبيق على جهاز آخر.';
  }

  @override
  String get accessDeviceBlocked => 'تم حظر الجهاز.';

  @override
  String get accessDeviceUnblock => 'إلغاء الحظر';

  @override
  String get accessDeviceUnblocked => 'تم إلغاء حظر الجهاز.';

  @override
  String get videoLockTitle => 'الفيديوهات مفعّلة على جهاز آخر';

  @override
  String videoLockBody(String platform, String device) {
    return 'على $platform تعمل فيديوهاتك على $device فقط، وباقي التطبيق يعمل هنا بشكل طبيعي. لمشاهدة الفيديوهات على هذا الجهاز اطلب من الإدارة إزالة ذلك الجهاز.';
  }

  @override
  String get accessVideoDevices => 'أجهزة الفيديو';

  @override
  String get accessVideoDevicesCaption =>
      'يستطيع العضو تسجيل الدخول من أي جهاز، لكن الفيديوهات تعمل على جهاز واحد لكل منصة. أول جهاز يفتح الفيديوهات على المنصة يأخذها. أزل الجهاز ليختار العضو جهازًا آخر.';

  @override
  String get accessVideoDeviceEmpty =>
      'لم يُحدَّد بعد — أول جهاز يفتح الفيديوهات يأخذه.';

  @override
  String accessVideoDeviceRemoveBody(String device, String platform) {
    return 'ستتوقف الفيديوهات على $device، وأول جهاز $platform يفتح الفيديوهات بعدها يأخذ مكانه.';
  }

  @override
  String get accessVideoDeviceRemoved =>
      'تمت إزالة الجهاز. يمكن للعضو الآن فتح الفيديوهات على جهاز جديد.';

  @override
  String get courseFilesLocked => 'ملفات هذا الكورس مقفلة';

  @override
  String get courseFilesLockedSub => 'ستُفتح عندما تمنحك ASEC هذا الكورس.';

  @override
  String get accessBlockedDevices => 'الأجهزة المحظورة';

  @override
  String get captureAlertsTitle => 'تنبيهات تصوير الشاشة';

  @override
  String get captureAlertsCaption =>
      'الأعضاء الذين التقطوا صورة للشاشة أو سجّلوها داخل التطبيق. يتم الرصد على iPhone / iPad وأندرويد 14 فأحدث.';

  @override
  String get captureNone => 'لا توجد لقطات أو تسجيلات حتى الآن.';

  @override
  String get captureClear => 'مسح الكل';

  @override
  String get captureClearQuestion => 'مسح كل التنبيهات؟';

  @override
  String get captureClearBody => 'سيتم حذف كل تنبيهات لقطات الشاشة والتسجيل.';

  @override
  String captureShowAll(int count) {
    return 'عرض الكل ($count)';
  }

  @override
  String get captureShowLess => 'عرض أقل';

  @override
  String get captureScreenshot => 'لقطة شاشة';

  @override
  String get captureRecording => 'تسجيل الشاشة';

  @override
  String get capturePage => 'الصفحة';

  @override
  String get captureCourse => 'الكورس';

  @override
  String get captureLesson => 'الدرس / الاختبار';

  @override
  String get courseLocked => 'مغلق';

  @override
  String get courseLockedSnack =>
      'هذا الكورس غير مفتوح لك بعد. اطلب من الإدارة فتحه لك.';

  @override
  String get courseSubtitleEdit => 'عنوان فرعي';

  @override
  String get courseSubtitle => 'العنوان الفرعي للكورس';

  @override
  String get courseSubtitleHint => 'سطر قصير يظهر تحت اسم الكورس';

  @override
  String accessCoursePickPlatform(String course) {
    return 'اختر منصة واحدة على الأقل لـ $course';
  }

  @override
  String get accessCoursePlatforms => 'يفتح على';

  @override
  String get certPreview => 'معاينة الشهادة';

  @override
  String get certPreviewNote => 'نموذج — هكذا تظهر شهادة العضو.';

  @override
  String get certButtonLocked => 'الشهادة · أكمل الكورس للحصول عليها';

  @override
  String get certIssued => 'تم منح الشهادة · اعرضها';

  @override
  String get certIssueTitle => 'الشهادات';

  @override
  String get certIssueCaption =>
      'امنح هذا العضو شهادة كورس بدون الاختبار النهائي. تظهر له فوراً.';

  @override
  String get certIssue => 'منح';

  @override
  String get certRevoke => 'سحب';

  @override
  String get certRevoked => 'تم سحب الشهادة';

  @override
  String get certIssuedToast => 'تم منح الشهادة';

  @override
  String get libraryProjects => 'المشاريع';

  @override
  String get libraryProjectsHint => 'مشاريعنا من الموقع';

  @override
  String get webTab => 'الموقع';

  @override
  String get errorReportsTitle => 'تقارير الأخطاء';

  @override
  String get errorReportsCaption =>
      'كل خطأ واجهه أي مستخدم — من، متى، الجهاز، الصفحة والخطأ كاملاً. اضغط على أي خطأ للتفاصيل.';

  @override
  String get errorReportsNone => 'لا توجد أخطاء';

  @override
  String get errorReportsCopy => 'نسخ';

  @override
  String get errorReportsCopied => 'تم النسخ';

  @override
  String get errorReportsClearQuestion => 'مسح كل تقارير الأخطاء؟';

  @override
  String get errorReportsClearBody => 'سيتم حذف كل تقارير الأخطاء المحفوظة.';

  @override
  String get securityAlertsTitle => 'تنبيهات الحماية';

  @override
  String get securityAlertsCaption =>
      'كل محاولة لسحب الدروس من التطبيق — من، متى، الجهاز، وما تم اكتشافه. اضغط على أي تنبيه للتفاصيل.';

  @override
  String get securityAlertsNone => 'لم يتم اكتشاف أي محاولة';

  @override
  String get alertMitm => 'تم اكتشاف أداة اعتراض HTTPS';

  @override
  String get alertStreamGrab => 'تم حظر أداة تحميل';

  @override
  String get alertDownloadBurst => 'عدد كبير من التحميلات دفعة واحدة';

  @override
  String get alertOther => 'نشاط مشبوه';

  @override
  String get alertClearQuestion => 'مسح كل تنبيهات الحماية؟';

  @override
  String get alertClearBody => 'سيتم حذف كل تنبيهات الحماية المحفوظة.';

  @override
  String get onlineTitle => 'المتصلون الآن';

  @override
  String get onlineCaption =>
      'من يفتح التطبيق الآن. اضغط على أي عضو لفتح كل أدوات التحكم به.';

  @override
  String get onlineNone => 'لا أحد يفتح التطبيق الآن.';

  @override
  String get onlineViewAll => 'عرض الكل';

  @override
  String get onlineRecent => 'نشط مؤخرًا (آخر 24 ساعة)';

  @override
  String get onlineNoneRecent => 'لم يستخدم أحد التطبيق خلال آخر 24 ساعة.';

  @override
  String get onlineNow => 'متصل';

  @override
  String get onlineJustNow => 'الآن';

  @override
  String onlineAgoMinutes(int count) {
    return 'منذ $count دقيقة';
  }

  @override
  String onlineAgoHours(int count) {
    return 'منذ $count ساعة';
  }

  @override
  String onlineOnPage(String page) {
    return 'في: $page';
  }

  @override
  String get onlineAdminAccount => 'هذا حساب مشرف. يُدار من قسم المشرفين.';

  @override
  String get onlineMemberGone => 'هذا الحساب لم يعد موجودًا.';

  @override
  String get onlineAdminTag => 'مشرف';

  @override
  String get quizTab => 'الاختبار';

  @override
  String get myCertificatesSub => 'كل الشهادات التي حصلت عليها.';

  @override
  String get noCertificatesTitle => 'لا توجد شهادات بعد';

  @override
  String get noCertificatesSub =>
      'اجتز اختبار أي كورس من الإعدادات ← الاختبار لتحصل على أول شهادة لك.';

  @override
  String get accessUploadExcel => 'رفع ملف Excel';

  @override
  String get accessImportTitle => 'منح صلاحية الكورسات من ملف';

  @override
  String get accessImportMatched => 'الأعضاء في الملف';

  @override
  String get accessImportNoAccount =>
      'لا يوجد حساب بهذه الإيميلات — تم تخطيها (يجب أن يسجّلوا أولًا)';

  @override
  String get accessImportUnknownCourse =>
      'لا يوجد كورس بهذه الأسماء — راجع الكتابة (تم الحفظ على أي حال)';

  @override
  String get accessImportSkippedRows =>
      'صفوف تم تخطيها (ليست إيميل، أو بدون كورس)';

  @override
  String get accessImportAdd => 'إضافة هذه الكورسات';

  @override
  String get accessImportAddSub => 'يحتفظ الأعضاء بالكورسات التي لديهم.';

  @override
  String get accessImportReplace => 'استبدال';

  @override
  String get accessImportReplaceSub =>
      'كل عضو يأخذ الكورسات الموجودة في الملف فقط. تظل General Notes و Tips and Tricks مفتوحة.';

  @override
  String get accessImportSave => 'منح الصلاحية';

  @override
  String get accessImportSaved => 'تم حفظ الصلاحيات';

  @override
  String get accessImportNothing =>
      'لم يتم العثور على صف به إيميل عضو وكورس. العمود A: الإيميل، ثم أسماء الكورسات.';

  @override
  String get accessImportUnreadable =>
      'تعذّر قراءة الملف. احفظه بصيغة ‎.xlsx (Excel) أو ‎.csv وحاول مرة أخرى.';

  @override
  String get mySpaceLearning => 'تعلّمي';

  @override
  String get mySpaceResources => 'مواردي';

  @override
  String get mySpaceSaved => 'المحفوظات';

  @override
  String get mySpaceSavedSub => 'كل ما حفظته، مثل النصائح والحيل';

  @override
  String get mySpaceQuizzes => 'الاختبارات والنتائج';

  @override
  String get mySpaceQuizzesSub => 'أدِّ الاختبارات وشاهد درجاتك';

  @override
  String get mySpaceCertificates => 'شهاداتي';

  @override
  String get mySpaceCertificatesSub => 'اعرض شهاداتك وحمّلها';

  @override
  String get mySpaceCv => 'سيرتي الذاتية';

  @override
  String get mySpaceCvSub => 'أنشئ سيرتك الذاتية وحدّثها';

  @override
  String get mySpaceCvLocked => 'مقفلة — اطلب من المشرف السماح بسيرتك الذاتية';

  @override
  String get mySpaceDownloads => 'التنزيلات';

  @override
  String get mySpaceDownloadsSub => 'الدروس التي نزّلتها';

  @override
  String get mySpaceTools => 'الأدوات الهندسية';

  @override
  String get mySpaceToolsSub => 'الحاسبات وأدوات هندسية مفيدة';

  @override
  String get mySpaceToolsLocked => 'قريبًا';

  @override
  String get permEngQuestions => 'الرد على الأسئلة';

  @override
  String get engQuestions => 'الأسئلة';

  @override
  String get engQuestionsAdminSub =>
      'أسئلة الأعضاء. اكتب الرد وسيُنشر في الصفحة الرئيسية لكل الأعضاء.';

  @override
  String get qaTitle => 'أسئلة وأجوبة';

  @override
  String get qaAsk => 'اسأل سؤالًا';

  @override
  String get qaAskHint => 'اكتب سؤالك…';

  @override
  String get qaSend => 'إرسال';

  @override
  String get qaSent => 'تم إرسال سؤالك — سيظهر الرد هنا.';

  @override
  String get qaSeeMore => 'عرض المزيد';

  @override
  String get qaEmpty => 'لا توجد أسئلة مجاب عنها بعد';

  @override
  String get qaEmptySub => 'كن أول من يسأل — سيرد فريق ASEC.';

  @override
  String get qaWaiting => 'في انتظار الرد';

  @override
  String get qaMine => 'أسئلتي';

  @override
  String get qaAll => 'كل الأسئلة';

  @override
  String get qaTeam => 'فريق ASEC';

  @override
  String get qaAnswer => 'الرد';

  @override
  String get qaEditAnswer => 'تعديل الرد';

  @override
  String get qaAnswerHint => 'اكتب الرد…';

  @override
  String get qaPost => 'نشر الرد';

  @override
  String get qaPosted => 'تم نشر الرد';

  @override
  String get qaDeleteQuestion => 'حذف هذا السؤال؟';

  @override
  String get qaNoQuestions => 'لا توجد أسئلة بعد';

  @override
  String get fvLoadFailed => 'تعذّر تحميل هذا الملف';

  @override
  String get lessonNetworkBlocked => 'هذه الشبكة تحجب دروس ASEC (جدار حماية شركة أو جامعة أو مزوّد الإنترنت). جرّب اتصالًا آخر، مثل نقطة اتصال الهاتف، أو اطلب من مسؤول الشبكة السماح لـ ASEC، ثم اضغط «حاول مرة أخرى».';

  @override
  String get lessonUnreachable => 'تعذّر الوصول إلى الدرس. تحقّق من اتصال الإنترنت ثم اضغط «حاول مرة أخرى». إذا كانت المواقع الأخرى تفتح، فقد تكون هذه الشبكة تحجب ASEC؛ جرّب اتصالًا آخر (مثل نقطة اتصال الهاتف).';

  @override
  String get lessonTooSlow => 'يستغرق بدء الدرس وقتًا طويلًا. تحقّق من اتصال الإنترنت ثم اضغط «حاول مرة أخرى».';

  @override
  String get ctlOpenAllCourses => 'فتح كل الدورات لكل الأعضاء';

  @override
  String get ctlOpenAllCoursesHint => 'يستطيع كل عضو مسجّل مشاهدة كل الدورات، بما فيها الجديدة التي ترفعها، دون الحاجة لتحديد الدورات له. تبقى الحسابات المحظورة والوصول الموقوف وتواريخ الانتهاء وحدود المنصّات كما هي. عند الإيقاف: يرى كل عضو الدورات المحددة له في تعديل الوصول فقط.';

  @override
  String get ctlDownloadExpiry => 'تنتهي صلاحية التنزيلات بعد';

  @override
  String get ctlDownloadExpiryHint => 'يُحذف كل درس محفوظ بعد هذا العدد من الأيام من تنزيله. يعمل دون إنترنت، ولا يفيد إرجاع ساعة الجهاز.';

  @override
  String get ctlDownloadExpiryNever => 'أبدًا';

  @override
  String ctlDaysCount(int count) {
    return '$count يوم';
  }
}
