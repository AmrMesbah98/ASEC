// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ASEC';

  @override
  String get appTagline => 'Watch. Learn. Test.';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleTeacher => 'Teacher';

  @override
  String get roleStudent => 'Student';

  @override
  String get roleParent => 'Parent';

  @override
  String get typeVideo => 'Video';

  @override
  String get typePdf => 'PDF';

  @override
  String get typeImage => 'Image';

  @override
  String get typeExam => 'Exam';

  @override
  String get typeQuiz => 'Quiz';

  @override
  String get attendance => 'Attendance';

  @override
  String get grades => 'Grades';

  @override
  String get messages => 'Messages';

  @override
  String permissionPublishDesc(String type) {
    return 'Can add, edit and delete $type content';
  }

  @override
  String get permissionAttendanceDesc =>
      'Can take attendance for their sections';

  @override
  String get permissionGradesDesc => 'Can review and grade student results';

  @override
  String get permissionMessagesDesc => 'Can message parents';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get discard => 'Discard';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Try again';

  @override
  String get search => 'Search';

  @override
  String get all => 'All';

  @override
  String get primaryColor => 'Primary colour';

  @override
  String get secondaryColor => 'Secondary colour';

  @override
  String get colors => 'Colours';

  @override
  String get errWrongCredentials =>
      'Incorrect email or password. Please try again.';

  @override
  String get errInvalidEmail =>
      'That does not look like a valid email address.';

  @override
  String get errEmailInUse => 'An account already exists with this email.';

  @override
  String get errWeakPassword => 'Use at least 6 characters for the password.';

  @override
  String get errUserDisabled => 'This account has been disabled.';

  @override
  String get errTooManyRequests =>
      'Too many attempts. Wait a minute and try again.';

  @override
  String get errNetwork => 'No connection. Check your network and try again.';

  @override
  String get errProfileMissing =>
      'This account has no profile. Ask the admin to create it from the console.';

  @override
  String get errAccountInactive =>
      'This account is switched off. Contact the center.';

  @override
  String get errFirestoreUnavailable =>
      'Signed in, but the database did not answer. Check that Firestore is created in your Firebase project.';

  @override
  String get errRulesDenied =>
      'The database refused the request. Deploy the Firestore rules: firebase deploy --only firestore:rules';

  @override
  String get errSetupAlreadyDone =>
      'Setup is already done on this project. Sign in instead.';

  @override
  String get errNotConfigured =>
      'Firebase is not configured yet. Run flutterfire configure.';

  @override
  String get errUnknown => 'Something went wrong. Please try again.';

  @override
  String get failPermission =>
      'You do not have permission for this. Ask the admin, or deploy the Firestore rules.';

  @override
  String get failIndex =>
      'This list needs a database index. Deploy firestore.indexes.json.';

  @override
  String get failNotFound => 'It no longer exists.';

  @override
  String get failUpload => 'The upload did not finish. Try again.';

  @override
  String get typeVideos => 'Videos';

  @override
  String get typePdfs => 'PDFs';

  @override
  String get typeImages => 'Images';

  @override
  String get typeExams => 'Exams';

  @override
  String get typeQuizzes => 'Quizzes';

  @override
  String get present => 'Present';

  @override
  String get absent => 'Absent';

  @override
  String get lateStatus => 'Late';

  @override
  String get excused => 'Excused';

  @override
  String get resetEmailSent =>
      'If that email has an account, a reset link is on its way.';

  @override
  String get consoleHeadline => 'Your whole center, one screen.';

  @override
  String get consoleSubheadline =>
      'Lessons, exams, attendance and parents — organised.';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get enterName => 'Enter a name';

  @override
  String get setupTitle => 'Set up your center';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get setupSubtitle =>
      'Create the first admin account. This works once per project.';

  @override
  String get signInSubtitle => 'Sign in with the account the center gave you.';

  @override
  String get fullName => 'Full name';

  @override
  String get fullNameHint => 'e.g. Amr Mesbah';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get createAdminAccount => 'Create admin account';

  @override
  String get signIn => 'Sign in';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get setupCenter => 'First time? Set up the center';

  @override
  String get consoleAccountsHint =>
      'Admins and teachers sign in here. Students and parents use the phone app.';

  @override
  String get tabletAccountsHint =>
      'Everyone signs in here — students, parents, teachers and admins.';

  @override
  String get mobileAccountsHint =>
      'Students and parents sign in here. Teachers use a tablet or computer.';

  @override
  String get wrongDeviceMobileTitle => 'Open this account on a phone or tablet';

  @override
  String get wrongDeviceDesktopTitle =>
      'Open this account on a tablet or computer';

  @override
  String wrongDeviceMobileBody(String role) {
    return '$role accounts use the Mostakbal app on a phone or tablet. Install it there and sign in with the same email.';
  }

  @override
  String wrongDeviceDesktopBody(String role) {
    return '$role accounts use the console on a tablet or computer. Open Mostakbal there and sign in with the same email.';
  }

  @override
  String get signOut => 'Sign out';

  @override
  String get pressBackAgainToExit => 'Press back again to exit';

  @override
  String get debugPreviewAnyway => 'Preview anyway (debug build)';

  @override
  String get debugPreviewHint =>
      'Only in debug builds. Reset it from Settings.';

  @override
  String get overview => 'Overview';

  @override
  String get teachers => 'Teachers';

  @override
  String get students => 'Students';

  @override
  String get parents => 'Parents';

  @override
  String get sections => 'Sections';

  @override
  String get content => 'Content';

  @override
  String get myStudents => 'My students';

  @override
  String get settings => 'Settings';

  @override
  String get signOutQuestion => 'Sign out?';

  @override
  String get signOutBody =>
      'You will need your email and password to come back.';

  @override
  String helloName(String name) {
    return 'Hello, $name';
  }

  @override
  String get overviewAdminSub => 'Here is your center today.';

  @override
  String get overviewTeacherSub =>
      'Your classes, content and results at a glance.';

  @override
  String get contentLibrary => 'Content library';

  @override
  String itemsCount(String count) {
    return '$count items';
  }

  @override
  String get recentlyAdded => 'Recently added';

  @override
  String get noContentYet => 'No content yet.';

  @override
  String get demoFailed => 'Demo data could not be written';

  @override
  String get demoTitle => 'Demo data';

  @override
  String demoBody(String password) {
    return 'Fills every section except Videos with sample data: members with course access, quizzes, a certificate exam for each of your real courses, results, CVs and website requests. Videos stay exactly as they are — they come from your Drive folder. Every demo account signs in with the password $password.';
  }

  @override
  String get removeDemo => 'Remove demo data';

  @override
  String get removeDemoQuestion => 'Remove all demo data?';

  @override
  String get removeDemoBody =>
      'Deletes every member, video, quiz, result and CV marked as demo. Anything you or your members created is not touched.';

  @override
  String get demoRemoved => 'Demo data removed';

  @override
  String get fillDemo => 'Fill demo data';

  @override
  String demoFilled(String email) {
    return 'Demo data is ready — sign out and try $email';
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
    return '$members members · $quizzes quizzes · $certificates certificate exams · $results results · $cvs CVs · $inbox website requests';
  }

  @override
  String get demoAccountsHint =>
      'Demo accounts are real sign-ins on a domain that receives no mail. Removing the data leaves them empty; filling again adopts them back.';

  @override
  String get myContent => 'My content';

  @override
  String get resultsReceived => 'Results received';

  @override
  String get yourPermissions => 'What you can do';

  @override
  String get yourPermissionsSub =>
      'Set by the admin. Ask them if something you need is missing.';

  @override
  String get nobodyFound => 'Nobody matches that search.';

  @override
  String get addTeacher => 'Add teacher';

  @override
  String get editTeacher => 'Edit teacher';

  @override
  String get addStudent => 'Add student';

  @override
  String get editStudent => 'Edit student';

  @override
  String get addParent => 'Add parent';

  @override
  String get editParent => 'Edit parent';

  @override
  String get accountCreateHint => 'They sign in with this email and password.';

  @override
  String get createAccount => 'Create account';

  @override
  String get phone => 'Phone';

  @override
  String get passwordShareHint =>
      'Share it with them privately. At least 6 characters.';

  @override
  String get generate => 'Generate';

  @override
  String get subject => 'Subject';

  @override
  String get subjectHint => 'e.g. Mathematics';

  @override
  String get teachesSections => 'Teaches these sections';

  @override
  String get noSectionsYet => 'No sections yet — add them in Sections.';

  @override
  String get permissions => 'Permissions';

  @override
  String get section => 'Section';

  @override
  String get children => 'Children';

  @override
  String get accountActive => 'Account active';

  @override
  String get accountActiveHint =>
      'Switch off to block sign-in without deleting anything.';

  @override
  String get roleLabel => 'Role';

  @override
  String get saved => 'Saved';

  @override
  String deleteQuestion(String name) {
    return 'Delete $name?';
  }

  @override
  String get deletePersonBody =>
      'Their profile is removed and they can no longer sign in. Their results and attendance stay on record.';

  @override
  String get deleted => 'Deleted';

  @override
  String get name => 'Name';

  @override
  String get noSection => 'No section';

  @override
  String get status => 'Status';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Off';

  @override
  String get switchOff => 'Switch off';

  @override
  String get switchOn => 'Switch on';

  @override
  String get peopleSub => 'Create accounts, set sections and control access.';

  @override
  String get nobodyYet => 'Nobody here yet';

  @override
  String get nobodyYetSub =>
      'Add the first one with the button above, or fill demo data from Settings.';

  @override
  String deleteSectionWithStudents(String count) {
    return '$count students are in this section. They will be left without a section until you move them.';
  }

  @override
  String get deleteSectionBody =>
      'The section is removed. Content assigned to it stops showing for it.';

  @override
  String get sectionsSub =>
      'Group students into classes. Content, attendance and teachers are organised by section.';

  @override
  String get addSection => 'Add section';

  @override
  String get editSection => 'Edit section';

  @override
  String get noSectionsTitle => 'No sections yet';

  @override
  String get noSectionsSub =>
      'Create your first class group, then add students to it.';

  @override
  String studentsCount(String count) {
    return '$count students';
  }

  @override
  String teachersCount(String count) {
    return '$count teachers';
  }

  @override
  String get sectionName => 'Section name';

  @override
  String get sectionNameHint => 'e.g. Grade 7 — A';

  @override
  String get level => 'Level';

  @override
  String get levelHint => 'e.g. Grade 7';

  @override
  String get description => 'Description';

  @override
  String get addQuestion => 'Add question';

  @override
  String get questionText => 'Question';

  @override
  String get points => 'Points';

  @override
  String optionN(String n) {
    return 'Option $n';
  }

  @override
  String get addOption => 'Add option';

  @override
  String get markCorrectHint => 'Select the correct answer';

  @override
  String fileTooLarge(String mb) {
    return 'That file is larger than $mb MB.';
  }

  @override
  String get enterTitle => 'Enter a title';

  @override
  String get enterValidLink => 'Enter a full link starting with https://';

  @override
  String get chooseFile => 'Choose a file';

  @override
  String get questionsIncomplete =>
      'Every question needs text, at least two options and a correct answer.';

  @override
  String newItem(String type) {
    return 'New $type';
  }

  @override
  String editItem(String type) {
    return 'Edit $type';
  }

  @override
  String get assessmentHint =>
      'Multiple-choice questions, marked automatically when the student submits.';

  @override
  String get fileHint => 'Upload a file to Firebase Storage, or paste a link.';

  @override
  String get title => 'Title';

  @override
  String get descriptionHint => 'What is this about?';

  @override
  String get file => 'File';

  @override
  String get uploadFile => 'Upload file';

  @override
  String get pasteLink => 'Paste link';

  @override
  String get link => 'Link';

  @override
  String get timeLimit => 'Time limit';

  @override
  String get minutes => 'Minutes';

  @override
  String get zeroUntimed => '0 = no time limit';

  @override
  String questionsTotal(String count, String points) {
    return '$count questions · $points points';
  }

  @override
  String get assignToSections => 'Assign to sections';

  @override
  String get noSectionsAssigned =>
      'You are not assigned to any section yet. Ask the admin.';

  @override
  String get assignToStudents => '…or to single students';

  @override
  String get noDueDate => 'No due date — tap to set one';

  @override
  String dueOn(String date) {
    return 'Due $date';
  }

  @override
  String get published => 'Published';

  @override
  String get publishedHint => 'Off keeps it a draft that only you can see.';

  @override
  String get notAssignedWarning =>
      'Not assigned to anyone yet — no student will see it.';

  @override
  String allowedTypes(String types) {
    return 'Allowed: $types';
  }

  @override
  String get browse => 'Browse';

  @override
  String get replace => 'Replace';

  @override
  String uploadingPercent(String percent) {
    return 'Uploading… $percent%';
  }

  @override
  String get deleteAssessmentBody =>
      'Students will no longer see it. Results already submitted stay in Grades.';

  @override
  String get deleteContentBody =>
      'Students will no longer see it, and the uploaded file is deleted.';

  @override
  String get contentAdminSub => 'Everything every teacher has published.';

  @override
  String get contentTeacherSub =>
      'Upload lessons and build exams, then assign them to a section or to single students.';

  @override
  String get addContent => 'Add content';

  @override
  String get noContentPermission =>
      'The admin has not given you permission to publish content yet.';

  @override
  String get noContentSub =>
      'Use “Add content” to upload your first lesson or build a quiz.';

  @override
  String get notAssigned => 'Not assigned';

  @override
  String get draft => 'Draft';

  @override
  String questionsShort(String count, String time) {
    return '$count questions · $time';
  }

  @override
  String get untimed => 'untimed';

  @override
  String minutesShort(String n) {
    return '$n min';
  }

  @override
  String get open => 'Open';

  @override
  String get attendanceSaved => 'Attendance saved';

  @override
  String get attendanceSub =>
      'Pick a section and a day, tap each student\'s status, then save.';

  @override
  String get noStudentsInSection => 'No students in this section';

  @override
  String get noStudentsInSectionSub =>
      'The admin adds students to sections from the Students page.';

  @override
  String unmarkedCount(String count) {
    return '$count not marked';
  }

  @override
  String get markAllPresent => 'Mark all present';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get notSavedYet => 'Not saved yet';

  @override
  String get gradesSub =>
      'Results arrive here the moment a student submits. Adjust a mark or add feedback any time.';

  @override
  String get noAssessments => 'No exams or quizzes yet';

  @override
  String get noAssessmentsSub => 'Create one from the Content page.';

  @override
  String pointsTotal(String points) {
    return '$points pts';
  }

  @override
  String get submitted => 'Submitted';

  @override
  String get missing => 'Missing';

  @override
  String get average => 'Average';

  @override
  String get notSubmittedYet => 'Not submitted yet';

  @override
  String get gradedByTeacher => 'Graded by teacher';

  @override
  String get autoMarked => 'Auto-marked';

  @override
  String get enterGrade => 'Enter grade';

  @override
  String get editGrade => 'Edit grade';

  @override
  String scoreRange(String max) {
    return 'Enter a score from 0 to $max.';
  }

  @override
  String get score => 'Score';

  @override
  String get feedback => 'Feedback';

  @override
  String get feedbackHint => 'Visible to the student and their parents.';

  @override
  String get aboutAssignment => 'About an assignment';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get noMessagesYetSub => 'Say hello — messages arrive instantly.';

  @override
  String aboutTitle(String title) {
    return 'About: $title';
  }

  @override
  String get typeMessage => 'Write a message…';

  @override
  String aboutChild(String name) {
    return 'About $name';
  }

  @override
  String get you => 'You';

  @override
  String get messagesTeacherSub =>
      'Conversations with parents, one thread per child.';

  @override
  String get noConversations => 'No conversations yet';

  @override
  String get noConversationsTeacherSub =>
      'Parents can write to you from their app, or start one from My students.';

  @override
  String parentOf(String name) {
    return 'Parent of $name';
  }

  @override
  String get myStudentsSub =>
      'Students in the sections you teach. Click one for results, attendance and parents.';

  @override
  String get noParentsLinked =>
      'No parent linked yet. The admin links parents from the Parents page.';

  @override
  String get message => 'Message';

  @override
  String get noAttendanceYet => 'No attendance recorded yet.';

  @override
  String attendanceRate(String percent) {
    return 'Attendance $percent%';
  }

  @override
  String get results => 'Results';

  @override
  String get noResultsYet => 'No results yet.';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get haptics => 'Vibration on tap';

  @override
  String get branding => 'Brand colours';

  @override
  String get resetColors => 'Reset to default colours';

  @override
  String get brandingLocalHint => 'Saved on this computer.';

  @override
  String get developer => 'Developer';

  @override
  String get clearDeviceOverride => 'Clear device preview';

  @override
  String get clearDeviceOverrideSub =>
      'Stops pretending this device is a phone / computer, and signs out.';

  @override
  String get account => 'Account';

  @override
  String get overdue => 'Overdue';

  @override
  String get startNow => 'Start';

  @override
  String questionsCount(String count) {
    return '$count questions';
  }

  @override
  String get openExternally => 'Open in another app';

  @override
  String get videoFailed =>
      'This video could not be played. Try opening it in another app.';

  @override
  String pageOf(String page, String pages) {
    return 'Page $page of $pages';
  }

  @override
  String get pdfFailed =>
      'This PDF could not be opened here. Tap to open it in another app.';

  @override
  String get pinchToZoom => 'Pinch to zoom';

  @override
  String get questions => 'Questions';

  @override
  String notTakenYet(String name) {
    return '$name has not taken this yet.';
  }

  @override
  String get examRules =>
      'Answer every question, then submit. You can move between questions freely. You can submit only once.';

  @override
  String startExam(String type) {
    return 'Start $type';
  }

  @override
  String get submitQuestion => 'Submit your answers?';

  @override
  String submitWithBlanks(String count) {
    return '$count questions are still blank. You cannot change answers after submitting.';
  }

  @override
  String get submitBody => 'You cannot change answers after submitting.';

  @override
  String get submit => 'Submit';

  @override
  String get keepGoing => 'Keep going';

  @override
  String get submitFailed => 'Could not submit';

  @override
  String get alreadySubmitted => 'You have already submitted this one.';

  @override
  String get leaveExamQuestion => 'Leave without submitting?';

  @override
  String get leaveExamBody => 'Your answers will be lost.';

  @override
  String get leave => 'Leave';

  @override
  String questionNofM(String n, String m) {
    return 'Question $n of $m';
  }

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get timeUp =>
      'Time is up — your answers were submitted automatically.';

  @override
  String get submittedTitle => 'Submitted!';

  @override
  String get review => 'Review';

  @override
  String get verdictExcellent => 'Excellent work!';

  @override
  String get verdictGood => 'Good job!';

  @override
  String get verdictPass => 'Passed';

  @override
  String get verdictKeepTrying => 'Keep practising';

  @override
  String get home => 'Home';

  @override
  String get libraryTab => 'Library';

  @override
  String get profile => 'Profile';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get nothingAssignedYet => 'Nothing assigned yet';

  @override
  String get nothingAssignedYetSub =>
      'When your teachers share lessons, exams or quizzes, they will appear here.';

  @override
  String get continueLearning => 'Continue learning';

  @override
  String get seeAll => 'See all';

  @override
  String get upNext => 'Up next';

  @override
  String get newThisWeek => 'New';

  @override
  String get toDo => 'To do';

  @override
  String get searchLessons => 'Search lessons, exams, teachers…';

  @override
  String get nothingHere => 'Nothing here';

  @override
  String get nothingHereSub => 'Try another filter or search.';

  @override
  String get averageGrade => 'Average grade';

  @override
  String resultsCountLabel(String count) {
    return '$count results';
  }

  @override
  String daysRecorded(String count) {
    return '$count days recorded';
  }

  @override
  String get lastDays => 'Latest days';

  @override
  String get absencesAndLate => 'Absences and late days';

  @override
  String get myProgress => 'My progress';

  @override
  String get noChildrenLinked => 'No children linked yet';

  @override
  String get noChildrenLinkedSub =>
      'Ask the center to link your children to your account.';

  @override
  String get yourChildren => 'Your children';

  @override
  String get messageATeacher => 'Message a teacher';

  @override
  String get assignments => 'Assignments';

  @override
  String get chooseTeacher => 'Choose a teacher';

  @override
  String get noTeachersToMessage =>
      'No teacher of this section can receive messages yet.';

  @override
  String get whichChild => 'Which child is this about?';

  @override
  String get newMessage => 'New message';

  @override
  String get noConversationsParentSub =>
      'Tap “New message” to write to one of your child\'s teachers.';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get dashboardAdminSub =>
      'Attendance, results and content across the whole center.';

  @override
  String get dashboardTeacherSub =>
      'Attendance and results for the sections you teach.';

  @override
  String get attendanceRateLabel => 'Attendance rate';

  @override
  String get averageScoreLabel => 'Average score';

  @override
  String get gradedResultsLabel => 'Results marked';

  @override
  String get publishedContentLabel => 'Published content';

  @override
  String get attendanceByStatus => 'Attendance by status';

  @override
  String get attendanceByDay => 'Attendance by day';

  @override
  String get averageBySection => 'Average score by section';

  @override
  String get scoreBands => 'Score bands';

  @override
  String get resultsByType => 'Results by type';

  @override
  String get band0 => 'Below 50';

  @override
  String get band50 => '50–64';

  @override
  String get band65 => '65–79';

  @override
  String get band80 => '80–100';

  @override
  String get charts => 'Charts';

  @override
  String get filters => 'Filters';

  @override
  String get clear => 'Clear';

  @override
  String get apply => 'Apply';

  @override
  String get periodLabel => 'Period';

  @override
  String get period30 => 'Last 30 days';

  @override
  String get period90 => 'Last 90 days';

  @override
  String get periodAll => 'All time';

  @override
  String get onlyBelowPass => 'Only results below 50%';

  @override
  String get onlyAbsences => 'Only absences and late days';

  @override
  String get exportTitle => 'Export';

  @override
  String get exportFileName => 'File name';

  @override
  String exportSaved(String path) {
    return 'Saved to $path';
  }

  @override
  String get exportFailedTitle => 'Export failed';

  @override
  String get exportCancelled => 'Export cancelled.';

  @override
  String get student => 'Student';

  @override
  String get assessment => 'Assessment';

  @override
  String get dateLabel => 'Date';

  @override
  String rowsShown(String shown, String total) {
    return '$shown of $total';
  }

  @override
  String get nothingToChart => 'Nothing to chart yet';

  @override
  String get nothingToChartSub =>
      'Charts fill in as attendance is taken and assessments are marked.';

  @override
  String get noRowsMatch => 'Nothing matches these filters.';

  @override
  String get dashboardSearchHint => 'Search a student or an assessment';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get enterFileName => 'Enter a file name';

  @override
  String get focusOverdue => 'Overdue — finish it first';

  @override
  String get focusNext => 'Your next task';

  @override
  String get focusNew => 'New for you';

  @override
  String get allCaughtUp => 'You\'re all caught up';

  @override
  String get allCaughtUpSub =>
      'No exams or quizzes waiting. A good moment to review a lesson.';

  @override
  String get dueToday => 'Due today';

  @override
  String get dueTomorrow => 'Due tomorrow';

  @override
  String dueInDays(String n) {
    return 'Due in $n days';
  }

  @override
  String overdueByDays(String n) {
    return '$n days overdue';
  }

  @override
  String get todayLabel => 'Today';

  @override
  String get notRecordedToday => 'Not recorded yet';

  @override
  String get dayStreak => 'day streak';

  @override
  String get latestResult => 'Latest result';

  @override
  String aboveAverage(String n) {
    return '$n pts above your average';
  }

  @override
  String belowAverage(String n) {
    return '$n pts below your average';
  }

  @override
  String get onYourAverage => 'Right on your average';

  @override
  String assessmentsDone(String done, String total) {
    return '$done of $total exams & quizzes done';
  }

  @override
  String get atAGlance => 'At a glance';

  @override
  String get noResultYetShort => 'Your first result will show here.';

  @override
  String get roleUser => 'Member';

  @override
  String get roleAdminBadge => 'Admin';

  @override
  String get heroTitle => 'Everything you need to learn, in one place.';

  @override
  String get heroSubtitle =>
      'Watch the lessons, then take the quiz before the time runs out.';

  @override
  String get createYourAccount => 'Create your account';

  @override
  String get registerSubtitle =>
      'A minute to sign up, then everything is open to you.';

  @override
  String get register => 'Create account';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get noAccount => 'New here?';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get errPasswordsDiffer => 'The two passwords are not the same.';

  @override
  String get phoneHint => 'Optional';

  @override
  String welcomeName(String name) {
    return 'Welcome, $name';
  }

  @override
  String get signInAsAdminHint => 'The admin account signs in here too.';

  @override
  String get registerHint =>
      'Your account is a member account. The center keeps one admin.';

  @override
  String get quizzes => 'Quizzes';

  @override
  String get quizzesAdminSub =>
      'Write the questions, set the timer and the window when it is open.';

  @override
  String get quizzesUserSub =>
      'Take a quiz while it is open. The timer starts when you do.';

  @override
  String get newQuiz => 'New quiz';

  @override
  String get editQuiz => 'Edit quiz';

  @override
  String get quizTitleHint => 'Unit 3 — revision';

  @override
  String get availabilityWindow => 'When it is open';

  @override
  String get availabilityHint =>
      'Leave both empty to keep it open with no end date.';

  @override
  String get opensAt => 'Opens';

  @override
  String get closesAt => 'Closes';

  @override
  String get notSet => 'Not set';

  @override
  String get clearDate => 'Clear';

  @override
  String get errWindowBackwards =>
      'The closing time has to come after the opening time.';

  @override
  String get errNoQuestions => 'Add at least one question.';

  @override
  String get quizSaved => 'Quiz saved';

  @override
  String get deleteQuizBody =>
      'The quiz and every attempt on it are deleted. This cannot be undone.';

  @override
  String get noQuizzesTitle => 'No quizzes yet';

  @override
  String get noQuizzesAdminSub =>
      'Write your first one — questions, a timer, and when it is open.';

  @override
  String get noQuizzesUserSub =>
      'Nothing is open for you right now. Come back later.';

  @override
  String get attempts => 'Attempts';

  @override
  String get attemptsSub => 'Who has taken this quiz, and how they did.';

  @override
  String get noAttemptsYet => 'Nobody has taken this quiz yet';

  @override
  String get noAttemptsYetSub =>
      'Results appear here the moment somebody submits.';

  @override
  String attemptsCount(String count) {
    return '$count attempts';
  }

  @override
  String get autoSubmitted => 'Time ran out';

  @override
  String get takenOn => 'Taken';

  @override
  String get startQuiz => 'Start the quiz';

  @override
  String quizRulesTimed(String count, String minutes) {
    return '$count questions · $minutes minutes. The timer keeps running once you start, and the quiz is submitted for you when it reaches zero.';
  }

  @override
  String quizRulesUntimed(String count) {
    return '$count questions, no time limit. Take as long as you need.';
  }

  @override
  String get timeLeft => 'Time left';

  @override
  String quizNotOpenYet(String date) {
    return 'Opens $date';
  }

  @override
  String get quizClosed => 'Closed';

  @override
  String quizClosesOn(String date) {
    return 'Closes $date';
  }

  @override
  String get quizOpenNow => 'Open now';

  @override
  String get quizWindowClosedBody => 'This quiz is not open right now.';

  @override
  String get yourScore => 'Your score';

  @override
  String correctOfTotal(String correct, String total) {
    return '$correct of $total correct';
  }

  @override
  String get yourAnswer => 'Your answer';

  @override
  String get correctAnswer => 'Correct answer';

  @override
  String get noAnswer => 'Left blank';

  @override
  String get takeAgain => 'Take it again';

  @override
  String get alreadyTakenBody =>
      'You have already taken this quiz. Here is how you did.';

  @override
  String get backToQuizzes => 'Back to quizzes';

  @override
  String get answered => 'Answered';

  @override
  String get videosAdminSub =>
      'Upload a lesson and it appears for every member.';

  @override
  String get videosUserSub => 'Every lesson the center has published.';

  @override
  String get addVideo => 'Add a video';

  @override
  String get videoLoading => 'Loading lesson';

  @override
  String get importDriveLessons => 'Add Drive lessons';

  @override
  String driveLessonsAdded(int count) {
    return '$count lessons added from Google Drive';
  }

  @override
  String get editVideo => 'Edit video';

  @override
  String get chooseVideoFile => 'Choose a video file';

  @override
  String get videoSaved => 'Video saved';

  @override
  String get deleteVideoBody =>
      'The video and its file are deleted. This cannot be undone.';

  @override
  String get noVideosTitle => 'No videos yet';

  @override
  String get noVideosAdminSub =>
      'Upload the first lesson — members see it straight away.';

  @override
  String get noVideosUserSub =>
      'Lessons appear here as soon as they are published.';

  @override
  String get watchNow => 'Watch';

  @override
  String get uploadingVideo => 'Uploading the video…';

  @override
  String get uploadCancel => 'Cancel the upload';

  @override
  String get noFileChosen => 'No file chosen';

  @override
  String megabytes(String size) {
    return '$size MB';
  }

  @override
  String get videoStillUploading => 'Wait for the upload to finish.';

  @override
  String get members => 'Members';

  @override
  String get membersSub => 'Everybody who has registered.';

  @override
  String get noMembersYet => 'No members yet';

  @override
  String get noMembersYetSub =>
      'They appear here the moment somebody registers.';

  @override
  String get totalMembers => 'Members';

  @override
  String get totalQuizzes => 'Quizzes';

  @override
  String get totalVideos => 'Videos';

  @override
  String get totalAttempts => 'Attempts';

  @override
  String get dashboardAsecSub => 'Your center at a glance.';

  @override
  String memberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get editProfile => 'Edit profile';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get publish => 'Publish';

  @override
  String get errKeychain =>
      'This Mac would not let the app save your session to the keychain. The app has to be signed with an Apple Development team — see SETUP.md.';

  @override
  String get failStorageUnavailable =>
      'Cloud Storage is not ready for this project. Turn Storage on in the Firebase console (Build > Storage), then deploy storage.rules.';

  @override
  String get startedAt => 'Started';

  @override
  String get finishedAt => 'Finished';

  @override
  String get timeTaken => 'Time taken';

  @override
  String get answerSheet => 'Answer sheet';

  @override
  String blanksCount(String count) {
    return '$count left blank';
  }

  @override
  String minutesSeconds(String m, String s) {
    return '$m min $s s';
  }

  @override
  String get theirAnswer => 'Their answer';

  @override
  String get openAttempt => 'See the answers';

  @override
  String attemptOf(String name, String quiz) {
    return '$name — $quiz';
  }

  @override
  String questionNumber(String n) {
    return 'Question $n';
  }

  @override
  String pointsEarned(String earned, String total) {
    return '$earned / $total pts';
  }

  @override
  String get attemptsByDay => 'Attempts by day';

  @override
  String get averageByQuiz => 'Average score by quiz';

  @override
  String get topMembers => 'Top members';

  @override
  String get latestAttempts => 'Latest attempts';

  @override
  String get member => 'Member';

  @override
  String get quizLabel => 'Quiz';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get allQuizzesAvg => 'Across every quiz';

  @override
  String get nothingToChartAsec =>
      'Charts fill in as members take the quizzes.';

  @override
  String get seeAllAttempts => 'Open the quiz to see them all';

  @override
  String get resultsAdminSub =>
      'Every attempt, by every member, across every quiz.';

  @override
  String get searchMember => 'Search a member';

  @override
  String get allQuizzes => 'All quizzes';

  @override
  String get membersWhoTook => 'Members who took';

  @override
  String get passRate => 'Pass rate';

  @override
  String get noAttemptsMatch => 'No attempt matches this search';

  @override
  String get noAttemptsMatchSub => 'Clear the search, or pick another quiz.';

  @override
  String get cvs => 'The Best';

  @override
  String get myCv => 'My CV';

  @override
  String get cvDirectorySub => 'Every member who has published a CV.';

  @override
  String get cvAdminSub => 'Every CV in the centre, with its review state.';

  @override
  String get createCv => 'Create your CV';

  @override
  String get editCv => 'Edit your CV';

  @override
  String get cvSaved => 'CV saved';

  @override
  String get cvNotAllowedTitle => 'The CV form is not open for you yet';

  @override
  String get cvNotAllowedSub =>
      'Ask the admin to switch it on for your account.';

  @override
  String get allowCv => 'CV';

  @override
  String get allowCvHint => 'Lets this member write a CV';

  @override
  String get cvPersonal => 'Personal information';

  @override
  String get cvProfession => 'Profession';

  @override
  String get cvSkillsSection => 'Skills and languages';

  @override
  String get cvLinks => 'Links';

  @override
  String get cvPhoto => 'Photo';

  @override
  String get cvLocation => 'Governorate';

  @override
  String get militaryStatus => 'Military status';

  @override
  String get graduationYear => 'Graduation year';

  @override
  String get cvSpecialization => 'Specialization';

  @override
  String get jobRole => 'Role';

  @override
  String get proSkills => 'Professional skills';

  @override
  String get softSkillsLabel => 'Soft skills';

  @override
  String get languagesLabel => 'Languages';

  @override
  String get bioLabel => 'About you';

  @override
  String get bioHint =>
      'Two or three lines. What you do, and what you are looking for.';

  @override
  String get facebookLabel => 'Facebook';

  @override
  String get linkedinLabel => 'LinkedIn';

  @override
  String get driveLabel => 'CV file';

  @override
  String get cvFileHint => 'Upload the CV itself — PDF or Word, up to 10 MB.';

  @override
  String get uploadCvFile => 'Upload CV file';

  @override
  String get noCvFile => 'No file uploaded yet';

  @override
  String get removeFile => 'Remove the file';

  @override
  String get downloadCv => 'Download CV';

  @override
  String get cvSummary => 'Profile';

  @override
  String get cvEducation => 'Education and status';

  @override
  String get portfolioLabel => 'Portfolio';

  @override
  String get choosePhoto => 'Choose a photo';

  @override
  String get pickRoleFirst => 'Pick a role first — its skills appear here.';

  @override
  String selectedCount(String count) {
    return '$count selected';
  }

  @override
  String get cvIncomplete => 'Fill in every field marked with * before saving.';

  @override
  String get pickSome => 'Tap to choose';

  @override
  String get noneChosen => 'Nothing chosen yet';

  @override
  String get cvPending => 'Pending';

  @override
  String get cvReviewed => 'Reviewed';

  @override
  String get cvShortlisted => 'Shortlisted';

  @override
  String get cvRejected => 'Rejected';

  @override
  String get reviewState => 'Review';

  @override
  String get noCvsTitle => 'No CVs yet';

  @override
  String get noCvsSubUser => 'CVs appear here as members publish them.';

  @override
  String get noCvsSubAdmin =>
      'Allow a member to write one from the Members page.';

  @override
  String get searchCv => 'Search by name, role or skill';

  @override
  String get deleteCvBody =>
      'The CV and its photo are deleted. This cannot be undone.';

  @override
  String get contactDetails => 'Contact';

  @override
  String cvUpdatedOn(String date) {
    return 'Updated $date';
  }

  @override
  String get yourCvIsLive => 'Your CV is visible to the other members.';

  @override
  String get enterPhone => 'Enter a phone number';

  @override
  String get cvAllowed => 'Allowed';

  @override
  String get cvNotAllowed => 'Not allowed';

  @override
  String get joinedLabel => 'Joined';

  @override
  String get cvColumn => 'CV form';

  @override
  String get searchMembers => 'Search a member by name, email or phone';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountHint =>
      'Permanently remove your account and profile.';

  @override
  String get deleteAccountQuestion => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'Your profile and CV are deleted and you are signed out. This cannot be undone.';

  @override
  String get deleteAccountPasswordBody => 'Enter your password to confirm.';

  @override
  String get deleteAccountFailed => 'Could not delete the account';

  @override
  String kpiNewThisWeek(int count) {
    return '+$count this week';
  }

  @override
  String kpiNewThisMonth(int count) {
    return '+$count this month';
  }

  @override
  String kpiOpenNow(int count) {
    return '$count open now';
  }

  @override
  String get kpiCvAccess => 'CV access';

  @override
  String get kpiDrafts => 'Drafts';

  @override
  String get kpiLibrarySize => 'Library';

  @override
  String get kpiUpcoming => 'Upcoming';

  @override
  String get kpiTimedOut => 'Timed out';

  @override
  String get videoLinkTitle => 'Video link';

  @override
  String get videoLinkCaption =>
      'Paste a direct .mp4 link or a Google Drive link (shared as “Anyone with the link”) — no upload needed.';

  @override
  String get videoLinkLabel => 'Link';

  @override
  String get videoLinkInvalid => 'Enter a full link that starts with https://';

  @override
  String get videoOrUpload => 'Or upload a file';

  @override
  String get playerSpeed => 'Speed';

  @override
  String get playerLoop => 'Loop';

  @override
  String get playerRestart => 'Restart';

  @override
  String get playerMute => 'Mute';

  @override
  String get playerFullScreen => 'Full screen';

  @override
  String playerResumedAt(String time) {
    return 'Resumed at $time';
  }

  @override
  String get playerStartOver => 'Start over';

  @override
  String get playerDuration => 'Duration';

  @override
  String get playerShortcuts =>
      'Space: play / pause · ← →: 10 s · ↑ ↓: volume · F: full screen · M: mute';

  @override
  String get agoJustNow => 'just now';

  @override
  String agoMinutes(int count) {
    return '$count min ago';
  }

  @override
  String agoHours(int count) {
    return '$count hours ago';
  }

  @override
  String agoDays(int count) {
    return '$count days ago';
  }

  @override
  String agoWeeks(int count) {
    return '$count weeks ago';
  }

  @override
  String agoMonths(int count) {
    return '$count months ago';
  }

  @override
  String agoYears(int count) {
    return '$count years ago';
  }

  @override
  String get nowPlaying => 'NOW PLAYING';

  @override
  String get videoNewTag => 'NEW';

  @override
  String get autoplay => 'Autoplay';

  @override
  String get filterAll => 'All';

  @override
  String get filterRecent => 'Recently added';

  @override
  String get filterContinue => 'Continue watching';

  @override
  String get filterWatched => 'Watched';

  @override
  String get noLessonsMatch => 'No lessons found';

  @override
  String get noLessonsMatchSub => 'Try another word or filter.';

  @override
  String get searchVideos => 'Search videos';

  @override
  String lessonNumber(int n) {
    return 'Lesson $n';
  }

  @override
  String finishLessonFirst(int n) {
    return 'Finish lesson $n first';
  }

  @override
  String get watchedBadge => 'Watched';

  @override
  String get finishThisLessonFirst =>
      'Finish this lesson first to unlock the next one.';

  @override
  String get noSkipAhead =>
      'You can\'t skip ahead — watch the lesson to unlock the rest.';

  @override
  String get lessonCompleted => 'Completed';

  @override
  String courseProgress(int watched, int total) {
    return '$watched of $total lessons watched';
  }

  @override
  String get courseComplete => 'Course complete — every lesson watched!';

  @override
  String get permVideos => 'Videos';

  @override
  String get permQuizzes => 'Quizzes';

  @override
  String get permResults => 'Results';

  @override
  String get permMembers => 'Members';

  @override
  String get permCvs => 'CVs';

  @override
  String get permWebsite => 'Website';

  @override
  String get ctlGroupSections => 'Member menu';

  @override
  String get ctlGroupVideos => 'Video lessons';

  @override
  String get ctlGroupGeneral => 'Whole app';

  @override
  String get ctlGroupDashboard => 'Admin dashboard';

  @override
  String get ctlGroupCalculators => 'Calculators';

  @override
  String get ctlCalcHint =>
      'On: every member can open it. Off: hidden from all members (admins still see it).';

  @override
  String get ctlCalcEngHint =>
      'Off (default): only the members you unlocked on the Members page can open it. On: every member can.';

  @override
  String get controlCentre => 'Control centre';

  @override
  String get controlCentreHint =>
      'Turn parts of the app on or off for everybody. Changes apply instantly.';

  @override
  String get ctlTurnAllOn => 'Turn all on';

  @override
  String get ctlSectionVideos => 'Videos';

  @override
  String get ctlSectionVideosHint => 'Members see the Videos page.';

  @override
  String get ctlSectionQuizzes => 'Quizzes';

  @override
  String get ctlSectionQuizzesHint => 'Members see the Quizzes page.';

  @override
  String get ctlSectionCvDirectory => 'CV directory';

  @override
  String get ctlSectionCvDirectoryHint => 'Members can browse everyone\'s CVs.';

  @override
  String get ctlSectionMyCv => 'My CV';

  @override
  String get ctlSectionMyCvHint => 'Members allowed a CV see the CV form.';

  @override
  String get ctlVideoSequential => 'Unlock lessons in order';

  @override
  String get ctlVideoSequentialHint =>
      'A lesson opens only after the previous one is watched.';

  @override
  String get ctlVideoBlockSkip => 'Block skipping ahead';

  @override
  String get ctlVideoBlockSkipHint =>
      'Members can\'t jump past what they\'ve watched.';

  @override
  String get ctlVideoAutoplay => 'Autoplay next lesson';

  @override
  String get ctlVideoAutoplayHint => 'The next lesson starts when one ends.';

  @override
  String get ctlVideoUpNext => 'Up next list';

  @override
  String get ctlVideoUpNextHint => 'Show the other lessons beside the player.';

  @override
  String get ctlVideoOptionsBar => 'Player options bar';

  @override
  String get ctlVideoOptionsBarHint =>
      'Skip, loop, restart, volume and speed under the video.';

  @override
  String get ctlVideoSpeed => 'Playback speed';

  @override
  String get ctlVideoSpeedHint => 'Members can watch at 0.5x – 2x.';

  @override
  String get ctlVideoResume => 'Resume where you stopped';

  @override
  String get ctlVideoResumeHint =>
      'Reopening a lesson jumps to the last position.';

  @override
  String get ctlVideoSearch => 'Search and filters';

  @override
  String get ctlVideoSearchHint =>
      'Search box and filter chips on the Videos page.';

  @override
  String get ctlVideoCourseProgress => 'Course progress bar';

  @override
  String get ctlVideoCourseProgressHint =>
      '\"3 of 10 lessons watched\" at the top.';

  @override
  String get ctlAnimations => 'Animations';

  @override
  String get ctlAnimationsHint => 'Page transitions and entrance animations.';

  @override
  String get ctlRegistration => 'New sign-ups';

  @override
  String get ctlRegistrationHint => 'Show \"Register\" on the sign-in screen.';

  @override
  String get ctlScreenProtection => 'Block screenshots';

  @override
  String get ctlScreenProtectionHint =>
      'On: screenshots and screen recordings of lesson videos come out black (Android, iOS, macOS, Windows). Off: allowed.';

  @override
  String get ctlScreenshotException =>
      'Allow screenshots for amrmesbah33@gmail.com';

  @override
  String get ctlScreenshotExceptionHint =>
      'On: this account can take screenshots and screen recordings even while they are blocked for everyone else. Off: blocked like everyone.';

  @override
  String get shotAllowedTitle => 'Screenshots are allowed';

  @override
  String get shotAllowedBody =>
      'Warning: \"Block screenshots\" is off, so every member can take screenshots and record the screen right now. Turn it back on when you are done.';

  @override
  String get shotAllowedBlock => 'Block now';

  @override
  String get shotAllowedKeep => 'Keep allowed';

  @override
  String get ctlDashboardCharts => 'Dashboard charts';

  @override
  String get ctlDashboardChartsHint => 'The four charts under the numbers.';

  @override
  String get ctlDashboardTable => 'Latest attempts table';

  @override
  String get ctlDashboardTableHint =>
      'The table at the bottom of the dashboard.';

  @override
  String get adminsTitle => 'Admins';

  @override
  String get adminsHint => 'Create admins and choose what each one can manage.';

  @override
  String get addAdmin => 'Add admin';

  @override
  String get createAdmin => 'Create admin';

  @override
  String get noAdminsYet => 'No other admins yet.';

  @override
  String get editPermissions => 'Edit permissions';

  @override
  String get removeAdmin => 'Remove admin';

  @override
  String get removeAdminQuestion => 'Remove this admin?';

  @override
  String get noPermissions => 'No permissions — can only open Settings.';

  @override
  String get permissionsTitle => 'Permissions';

  @override
  String get adminCreated => 'Admin created. They can sign in now.';

  @override
  String get permissionsSaved => 'Permissions saved';

  @override
  String get adminFormInvalid => 'Enter a name and a valid email.';

  @override
  String get adminPasswordShort => 'The password needs at least 6 characters.';

  @override
  String get adminEmailInUse => 'This email already has an account.';

  @override
  String removeAdminBody(String name) {
    return '$name will no longer be able to use the admin console. Their login can be deleted from the Firebase console.';
  }

  @override
  String get videoCategoriesTitle => 'Categories';

  @override
  String get videoCategoryGeneral => 'General';

  @override
  String get allCategories => 'All categories';

  @override
  String get videoCategory => 'Category';

  @override
  String get videoCategoryHint =>
      'Videos with the same category are grouped together (e.g. GENERAL NOTES).';

  @override
  String videoCount(int count) {
    return '$count videos';
  }

  @override
  String get securityBlockedTitle => 'This device is not safe for ASEC';

  @override
  String get securityBlockedBody =>
      'To protect the lessons, ASEC does not run while any of the following is on. Turn it off, then tap Check again.';

  @override
  String get securityCheckAgain => 'Check again';

  @override
  String get integrityDeveloperOptions =>
      'Developer options are on (Settings → System → Developer options)';

  @override
  String get integrityUsbDebugging => 'USB debugging is on';

  @override
  String get integrityDebugger => 'A debugger is attached to the app';

  @override
  String get integrityDebuggable =>
      'This copy of the app has been modified — install it from the official source';

  @override
  String get integrityRoot => 'The device is rooted';

  @override
  String get integrityJailbreak => 'The device is jailbroken';

  @override
  String get integrityHooking => 'Hacking / hooking tools are running';

  @override
  String get certificateQuizzes => 'Certificate quizzes';

  @override
  String get certificateQuiz => 'Certificate quiz';

  @override
  String get certificateQuizzesAdminSub =>
      'One final exam per course. Members who score 70% or more get an ASEC certificate.';

  @override
  String get certificateQuizzesUserSub =>
      'Finish every lesson of a course, then pass its final exam with 70% to earn your ASEC certificate.';

  @override
  String get newCertificateQuiz => 'New certificate quiz';

  @override
  String get noCertificateQuizzesTitle => 'No certificate quizzes yet';

  @override
  String get noCertificateQuizzesAdminSub =>
      'Create one final exam for each course.';

  @override
  String get noCoursesTitle => 'No courses yet';

  @override
  String get noCoursesUserSub => 'Courses and their final exams appear here.';

  @override
  String get courseLabel => 'Course';

  @override
  String get courseCaption =>
      'Members unlock this exam after watching every lesson of the course. Pass mark: 70%.';

  @override
  String get chooseCourse => 'Choose a course';

  @override
  String get errChooseCourse => 'Choose the course this exam belongs to.';

  @override
  String certLocked(int watched, int total) {
    return 'Watch all lessons first · $watched/$total';
  }

  @override
  String get certReady => 'Ready — start the final exam';

  @override
  String certFailed(String percent) {
    return 'Last try $percent% · you need 70% — try again';
  }

  @override
  String certPassed(String percent) {
    return 'Passed with $percent% · view your certificate';
  }

  @override
  String get certNoExam => 'Final exam coming soon';

  @override
  String get certLockedSnack =>
      'Finish every lesson in this course to unlock its exam.';

  @override
  String get passedTitle => 'Congratulations, you passed!';

  @override
  String get failedTitle => 'Not passed yet';

  @override
  String get failedBody =>
      'You need 70% to pass. Review the lessons and try again.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get viewCertificate => 'View certificate';

  @override
  String lastTry(String percent) {
    return 'Your last try: $percent% — you need 70% to pass.';
  }

  @override
  String get certificateTitle => 'Your certificate';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get passMark => 'Pass mark 70%';

  @override
  String get certificateBadge => 'Certificate';

  @override
  String get unitConverter => 'Unit converter';

  @override
  String get unitConverterSub =>
      'Main engineering units — works without internet.';

  @override
  String get unitFrom => 'From';

  @override
  String get unitTo => 'To';

  @override
  String get unitValue => 'Enter a value';

  @override
  String get swapUnits => 'Swap units';

  @override
  String get allConversions => 'All conversions';

  @override
  String get openUnitConverter => 'Unit converter';

  @override
  String copiedValue(String value) {
    return 'Copied $value';
  }

  @override
  String get engineeringCalc => 'Engineering calculators';

  @override
  String get engineeringCalcShort => 'Calculators';

  @override
  String get engineeringCalcSub =>
      'HVAC, fire fighting, plumbing and medical gas — quick design checks.';

  @override
  String get ductCalc => 'Duct calculator';

  @override
  String get ductCalcShort => 'Ducts';

  @override
  String get pipeCalc => 'Pipe sizer';

  @override
  String get pipeCalcShort => 'Pipes';

  @override
  String get plumbingFireCalc => 'Plumbing';

  @override
  String get plumbingFireCalcShort => 'Plumbing';

  @override
  String get fireCalc => 'Fire fighting';

  @override
  String get fireCalcShort => 'Fire';

  @override
  String get calcInputs => 'Inputs';

  @override
  String get calcResults => 'Results';

  @override
  String get calcFormula => 'Method';

  @override
  String get calcReset => 'Reset';

  @override
  String get calcTapHint =>
      'Tap a result to change its unit · long-press to copy';

  @override
  String get calcFillAll => 'Fill in every field to see the results.';

  @override
  String get calcDisclaimer =>
      'Simplified design estimate. Check it against the governing code and a detailed calculation before issuing drawings.';

  @override
  String get calcExportPdf => 'Export PDF';

  @override
  String get calcExportExcel => 'Export Excel';

  @override
  String get calcItem => 'Item';

  @override
  String get calcValue => 'Value';

  @override
  String get calcUnit => 'Unit';

  @override
  String get calcDate => 'Date';

  @override
  String get calcFileName => 'File name';

  @override
  String calcSaved(String name) {
    return 'Saved: $name';
  }

  @override
  String get offlineTitle => 'You\'re offline';

  @override
  String get offlineBody =>
      'The tools that don\'t need the internet still work here. The rest of the app comes back as soon as you\'re online.';

  @override
  String get offlineRetry => 'Retry';

  @override
  String get moreTab => 'More';

  @override
  String get certificateShort => 'Certificate';

  @override
  String get memberAccess => 'Access';

  @override
  String get editAccess => 'Edit access';

  @override
  String get accessCourses => 'Courses';

  @override
  String get accessAllCourses => 'All courses';

  @override
  String get accessCoursesCaption =>
      'Choose the courses this member can watch. \"All courses\" also includes any course added later.';

  @override
  String get accessPlatforms => 'Video platforms';

  @override
  String get accessPlatformsCaption =>
      'The member can sign in on any device. Videos, video quizzes and certificates open only on the checked platforms; everything else opens everywhere.';

  @override
  String get accessAllPlatforms => 'All devices';

  @override
  String get accessPeriod => 'Access period';

  @override
  String get accessPermanent => 'Permanent';

  @override
  String get accessDates => 'From – to';

  @override
  String get accessFrom => 'From';

  @override
  String get accessUntil => 'Until';

  @override
  String get accessPause => 'Pause access';

  @override
  String get accessResume => 'Resume access';

  @override
  String get accessPauseCaption =>
      'Freezes the member\'s access now. When you resume, the paused days are added back to the end date.';

  @override
  String accessPausedSince(String date) {
    return 'Paused since $date';
  }

  @override
  String get accessPaused => 'Paused';

  @override
  String accessUntilShort(String date) {
    return 'until $date';
  }

  @override
  String accessCoursesCount(int count) {
    return '$count courses';
  }

  @override
  String get accessSaved => 'Access saved';

  @override
  String get accessPickPlatform => 'Choose at least one device.';

  @override
  String get accessPickCourse => 'Choose at least one course, or All courses.';

  @override
  String get accessDatesInvalid => 'The end date must be after the start date.';

  @override
  String get accessExpiredShort => 'Ended';

  @override
  String get blockedTitlePaused => 'Your access is paused';

  @override
  String get blockedBodyPaused =>
      'ASEC has paused your access for now. Contact ASEC to resume it — you won\'t lose the paused days.';

  @override
  String get blockedTitleExpired => 'Your access has ended';

  @override
  String blockedBodyExpired(String date) {
    return 'Your access ended on $date. Contact ASEC to renew it.';
  }

  @override
  String get blockedTitleNotStarted => 'Your access hasn\'t started yet';

  @override
  String blockedBodyNotStarted(String date) {
    return 'Your access starts on $date.';
  }

  @override
  String get blockedTitlePlatform => 'Not available on this device';

  @override
  String blockedBodyPlatform(String platforms) {
    return 'Your account can be used on: $platforms.';
  }

  @override
  String get tbMember => 'Member';

  @override
  String get tbThisDevice => 'This device';

  @override
  String get tbAllowedOn => 'Allowed on';

  @override
  String get tbStatus => 'Status';

  @override
  String get tbStarts => 'Starts';

  @override
  String get tbEnds => 'Ends';

  @override
  String get tbWrongDevice => 'Wrong device';

  @override
  String get tbNotStarted => 'Not started';

  @override
  String get downloads => 'Downloads';

  @override
  String get downloadsSub =>
      'Lessons saved inside ASEC to watch without internet. They stay in the app only.';

  @override
  String get downloadVideo => 'Download for offline';

  @override
  String get downloadStarted => 'Downloading — you\'ll find it in Downloads';

  @override
  String get downloadCancel => 'Cancel download';

  @override
  String get downloadFailed => 'Download failed — tap to try again';

  @override
  String get downloadDone => 'Downloaded — tap to remove';

  @override
  String downloadRemoveQuestion(String title) {
    return 'Remove “$title” from downloads?';
  }

  @override
  String get downloadRemoveBody =>
      'The lesson stays in Videos; it just won\'t play without internet any more.';

  @override
  String get downloadRemove => 'Remove';

  @override
  String get downloadsEmptyTitle => 'No downloads yet';

  @override
  String get downloadsEmptySub =>
      'Tap the download icon on a lesson in Videos to watch it without internet.';

  @override
  String downloadsStorage(String size) {
    return '$size used on this device';
  }

  @override
  String get downloadsRemoveAll => 'Remove all';

  @override
  String get downloadsRemoveAllQuestion => 'Remove all downloads?';

  @override
  String get updateTitle => 'New version available';

  @override
  String get updateMessage =>
      'A new version of ASEC is ready on Google Play with improvements and fixes.';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredMessage =>
      'This version is no longer supported. Please update from Google Play to keep using ASEC.';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateLater => 'Later';

  @override
  String get updateWhatsNew => 'What\'s new';

  @override
  String updateCurrentVersion(String version) {
    return 'Your version: $version';
  }

  @override
  String get patchReadyTitle => 'Update ready';

  @override
  String get patchReadyMessage =>
      'Improvements were downloaded in the background. Close and reopen the app to apply them.';

  @override
  String get patchRestart => 'Close & reopen';

  @override
  String get calcColumn => 'Eng. calculators';

  @override
  String get calcAllowed => 'Unlocked';

  @override
  String get calcNotAllowed => 'Locked';

  @override
  String get settingsMySpace => 'My space';

  @override
  String get settingsMySpaceHint =>
      'Your CV, certificates, saved lessons and tools.';

  @override
  String homeGreeting(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get homeSub => 'Pick up where you left off.';

  @override
  String get homeContinue => 'Continue watching';

  @override
  String get homeStart => 'Start your first lesson';

  @override
  String get homeStartSub => 'Your courses are ready. Open one to begin.';

  @override
  String get homeAllDone => 'Every lesson watched — well done!';

  @override
  String get homeProgress => 'Your progress';

  @override
  String homeLessonsLeft(int count) {
    return '$count lessons to go';
  }

  @override
  String get homeQuickAccess => 'Quick access';

  @override
  String get homeCourses => 'Your courses';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeVideosHint => 'Courses & lessons';

  @override
  String get homeConverterHint => 'Works offline';

  @override
  String get homeQuizzesHint => 'Test what you learned';

  @override
  String get homeCvsHint => 'Find engineers';

  @override
  String get homeCertificateHint => 'Earn your certificate';

  @override
  String get homeCalcHint => 'HVAC, fire, plumbing';

  @override
  String get homeResume => 'Resume';

  @override
  String homeLessonOf(int n, int total) {
    return 'Lesson $n of $total';
  }

  @override
  String get unitConverterShort => 'Converter';

  @override
  String get sectionQuizLabel => 'Section';

  @override
  String get sectionQuizCaption =>
      'Optional. Link this quiz to a course section: members find it at the end of that section and can start it after watching all its lessons.';

  @override
  String get sectionNone => 'None — a general quiz';

  @override
  String get sectionQuizzesTitle => 'Section quiz';

  @override
  String get addSectionQuiz => 'Add quiz';

  @override
  String get sectionQuizLocked =>
      'Watch every lesson of this section to unlock its quiz.';

  @override
  String get accessDevice => 'Login device';

  @override
  String get accessDeviceCaption =>
      'Members can sign in on any number of devices. The device below was locked to the account before; you can remove it or block it.';

  @override
  String get accessDeviceNone =>
      'No device locked — the member can sign in on any device.';

  @override
  String get accessDeviceUnknown => 'A device';

  @override
  String accessDeviceSince(String date) {
    return 'Since $date';
  }

  @override
  String get accessDeviceRemove => 'Remove device';

  @override
  String get accessDeviceRemoveQuestion => 'Remove this device?';

  @override
  String accessDeviceRemoveBody(String device) {
    return 'The member is shut out of $device now. The next device they sign in on becomes their device.';
  }

  @override
  String get accessDeviceRemoved =>
      'Device removed. The member can sign in on the new device now.';

  @override
  String get blockedTitleOtherDevice =>
      'This account is used on another device';

  @override
  String get blockedBodyOtherDevice =>
      'Your account works on one device only. To use this device instead, ask the admin to remove the old one, then sign out and sign in again here.';

  @override
  String get blockedTitleDeviceRemoved => 'This device was removed';

  @override
  String get blockedBodyDeviceRemoved =>
      'The admin removed this device from your account. To use it again, sign out and sign in.';

  @override
  String get tbAccountDevice => 'Account device';

  @override
  String get engEngagement => 'Engagement';

  @override
  String get engEngagementSub =>
      'Notifications, tips & tricks, the members\' Library and their stars.';

  @override
  String get engNotifications => 'Notifications';

  @override
  String get engNotificationsSub => 'Messages from the ASEC team.';

  @override
  String get engNotificationsEmpty => 'No notifications yet';

  @override
  String get engNotificationsEmptySub =>
      'New messages from the admin appear here.';

  @override
  String get engSendNotification => 'Send notification';

  @override
  String get engSend => 'Send';

  @override
  String get engNotifSent => 'Notification sent';

  @override
  String get engNotifTitleHint => 'Notification title';

  @override
  String get engNotifBodyHint => 'Write the message members will read';

  @override
  String get engNotifAdminSub =>
      'Sent to every member — it appears under the bell in their app bar, with the number not read yet.';

  @override
  String get engTipsTricks => 'Tips & tricks';

  @override
  String get engTipsAdminSub =>
      'Tips pop up over the members\' home page when they open the app. A member can save a tip; the number shows how many saved it.';

  @override
  String get engAddTip => 'Add tip';

  @override
  String get engTipAdded => 'Tip added';

  @override
  String get engTipTitleHint => 'Tip title';

  @override
  String get engTipBodyHint => 'Write the tip';

  @override
  String get engTipSavedToast =>
      'Saved — find it under the bookmark icon at the top';

  @override
  String get engTipTapToClose => 'Tap anywhere to close';

  @override
  String engTipSavedCount(int count) {
    return 'Saved by $count';
  }

  @override
  String get engTipActive => 'Shown to members';

  @override
  String get engTipsEmpty => 'No tips yet';

  @override
  String get engSavedTips => 'Saved tips';

  @override
  String get engSavedTipsSub => 'The tips you saved.';

  @override
  String get engSavedTipsEmpty => 'Nothing saved yet';

  @override
  String get engTipUnsave => 'Remove from saved';

  @override
  String get engLibrary => 'Library';

  @override
  String get engLibraryFiles => 'Files';

  @override
  String get engLibraryFilesHint => 'Documents from ASEC';

  @override
  String get engLibraryBest => 'The best';

  @override
  String get engLibraryBestHint => 'The best CVs in the app';

  @override
  String get engLibraryCertificate => 'Certificate';

  @override
  String get engLibrarySub => 'Files the ASEC team shares with you.';

  @override
  String get engLibraryEmpty => 'No files yet';

  @override
  String get engLibraryEmptySub => 'Files added by the admin appear here.';

  @override
  String get engLibraryAdminSub =>
      'Files in the members\' Library (home page → Library → Files).';

  @override
  String get engLeaderboardSub =>
      'Members ranked by the stars they earned watching courses.';

  @override
  String get engLeaderboardEmpty => 'No stars yet';

  @override
  String get engYou => 'You';

  @override
  String get engMember => 'Member';

  @override
  String get engStarsTab => 'Stars';

  @override
  String get engStarsAdminSub =>
      'Each member\'s stars per course — 1 star for every 20% watched, 5 at most per course. Tap a member to see their courses.';

  @override
  String get engStarsHint =>
      '1 star for every 20% you watch — 5 stars per course';

  @override
  String engStarsCount(int count) {
    return '$count stars';
  }

  @override
  String get engFilesTab => 'Files';

  @override
  String get engNewFolder => 'New folder';

  @override
  String get engFolderName => 'Folder name';

  @override
  String get engFolderCreated => 'Folder created';

  @override
  String get engRename => 'Rename';

  @override
  String get engCourseFilesEmpty => 'No files in this course yet';

  @override
  String get engCourseFilesEmptyAdmin =>
      'Create a folder, then upload files into it.';

  @override
  String get engFolderEmpty => 'This folder is empty';

  @override
  String get engAllFolders => 'All folders';

  @override
  String engFileCount(int count) {
    return '$count files';
  }

  @override
  String get engDeleteFolderBody =>
      'The folder and every file in it will be deleted.';

  @override
  String get engDeleteBody => 'This cannot be undone.';

  @override
  String get engFileUploaded => 'File uploaded';

  @override
  String get engFileOpenFailed => 'Could not open the file';

  @override
  String get engFieldRequired => 'Required';

  @override
  String get engCourseSequential => 'Watch in order';

  @override
  String get engCourseSequentialHint =>
      'A video opens only after the one before it is watched';

  @override
  String get engVideoDefault => 'Default';

  @override
  String get engVideoCustom => 'Custom';

  @override
  String get engMakeDefault => 'Make default (every member)';

  @override
  String get engMakeCustom => 'Make custom';

  @override
  String get engRulesMissing =>
      'Not allowed by Firebase. Deploy the new rules: firebase deploy --only firestore:rules,storage';

  @override
  String get engChooseFolder => 'Upload into which folder?';

  @override
  String get engChooseFolderSub =>
      'Pick a folder, or create a new one — then choose the file.';

  @override
  String get engNoFoldersYet => 'No folders yet — create the first one:';

  @override
  String get engOtherFiles => 'Other files';

  @override
  String get engPartners => 'Our partners';

  @override
  String get engPartnersSub => 'Companies that work with ASEC';

  @override
  String get engPartnersAdminSub =>
      'Partner logos — they turn in a 3D ring around the ASEC logo on the members\' home page (and show on the website). Only published ones appear.';

  @override
  String get engPartnerAdd => 'Add partner';

  @override
  String get engPartnerName => 'Company name';

  @override
  String get engPartnerAdded => 'Partner added';

  @override
  String get engPartnersEmpty => 'No partners yet — add the first logo';

  @override
  String get updCardTitle => 'App update';

  @override
  String get updCardHint =>
      'Ask Android users to update the app. Use the build number — the part after + in pubspec (1.0.1+9 → 9).';

  @override
  String get updLatestBuild => 'Latest build — optional update';

  @override
  String get updLatestBuildHint =>
      'Builds below this see a \"New version\" message they can close.';

  @override
  String get updMinBuild => 'Minimum build — forced update';

  @override
  String get updMinBuildHint =>
      'Builds below this must update. The message can\'t be closed.';

  @override
  String get updNotesEn => 'What\'s new (English)';

  @override
  String get updNotesAr => 'What\'s new (Arabic)';

  @override
  String get updWarning =>
      'Raise these numbers only after the new version is live on Google Play — otherwise users will be asked to update to a version they can\'t download yet.';

  @override
  String updStatusForced(String build) {
    return 'Forced update is on: builds below $build must update';
  }

  @override
  String get updStatusOff => 'No forced update';

  @override
  String updThisApp(String version) {
    return 'This app: $version';
  }

  @override
  String get updStopForcing => 'Stop forcing';

  @override
  String get updSaved => 'Update settings saved';

  @override
  String get updUseThisVersion => 'Use this version';

  @override
  String get updBuildToUse => 'Build number to update to';

  @override
  String get updBuildToUseHint =>
      'Filled from this app. Change it if your new Android build has a different number.';

  @override
  String get updForceQuestion => 'Should users be forced to update?';

  @override
  String get updOptional => 'Optional';

  @override
  String get updForced => 'Forced';

  @override
  String updOptionalSet(String build) {
    return 'Optional update set: builds below $build will be asked to update';
  }

  @override
  String get updEnterBuild => 'Enter the build number';

  @override
  String get permEngagement => 'Engagement';

  @override
  String get permViewOnly => 'View only';

  @override
  String get permDashboardCharts => 'Charts';

  @override
  String get permDashboardTable => 'Latest attempts table';

  @override
  String get permVideosAdd => 'Add / upload videos and course files';

  @override
  String get permVideosEdit => 'Edit videos and course files';

  @override
  String get permVideosDelete => 'Delete videos and course files';

  @override
  String get permVideosPublish => 'Publish / hide videos';

  @override
  String get permVideosAccess =>
      'Course access (default / custom, watch in order)';

  @override
  String get permQuizzesCreate => 'Create quizzes';

  @override
  String get permQuizzesEdit => 'Edit quizzes';

  @override
  String get permQuizzesDelete => 'Delete quizzes';

  @override
  String get permQuizzesOpen => 'Open / close quizzes';

  @override
  String get permQuizzesCertificates => 'Certificate quizzes';

  @override
  String get permMembersBlock => 'Activate / block members';

  @override
  String get permMembersAccess =>
      'Edit access (courses, period, pause, calculators)';

  @override
  String get permMembersDevice => 'Reset device';

  @override
  String get permCvsReview => 'Review CVs (status)';

  @override
  String get permCvsDelete => 'Delete CVs';

  @override
  String get permCvsGrant => 'Give CV rights';

  @override
  String get permEngNotifications => 'Notifications';

  @override
  String get permEngTips => 'Tips & tricks';

  @override
  String get permEngLibrary => 'Library';

  @override
  String get permEngStars => 'Stars';

  @override
  String get permEngPartners => 'Partners';

  @override
  String get permWebContent => 'Pages, articles and content';

  @override
  String get permWebInbox => 'Inbox';

  @override
  String get permWebSettings => 'Site settings and control centre';

  @override
  String get blockedTitleDeviceBlocked => 'This device is blocked';

  @override
  String get blockedBodyDeviceBlocked =>
      'The admin blocked this device. The app can\'t be used on it. Contact the admin if you think this is a mistake.';

  @override
  String get accessDeviceBlock => 'Block device';

  @override
  String get accessDeviceBlockQuestion => 'Block this device?';

  @override
  String accessDeviceBlockBody(String device) {
    return '$device will be blocked: anyone who signs in on it will see \"This device is blocked\". The member can still use the app on another device.';
  }

  @override
  String get accessDeviceBlocked => 'Device blocked.';

  @override
  String get accessDeviceUnblock => 'Unblock';

  @override
  String get accessDeviceUnblocked => 'Device unblocked.';

  @override
  String get videoLockTitle => 'Videos are on another device';

  @override
  String videoLockBody(String platform, String device) {
    return 'On $platform, your videos play only on $device. The rest of the app works here as usual. To watch on this device instead, ask the admin to remove that device.';
  }

  @override
  String get accessVideoDevices => 'Video devices';

  @override
  String get accessVideoDevicesCaption => 'The member can sign in on any device, but videos play on one device per platform. The first device that opens Videos on a platform takes it. Remove a device to let the member pick another.';

  @override
  String get accessVideoDeviceEmpty => 'Not chosen yet — the first device that opens Videos takes it.';

  @override
  String accessVideoDeviceRemoveBody(String device, String platform) {
    return 'Videos stop playing on $device. The next $platform device that opens Videos takes its place.';
  }

  @override
  String get accessVideoDeviceRemoved => 'Device removed. The member can open videos on a new device now.';

  @override
  String get accessBlockedDevices => 'Blocked devices';

  @override
  String get captureAlertsTitle => 'Screen capture alerts';

  @override
  String get captureAlertsCaption =>
      'Members who took a screenshot or recorded the screen inside the app. Detected on iPhone / iPad and Android 14+.';

  @override
  String get captureNone => 'No screenshots or recordings so far.';

  @override
  String get captureClear => 'Clear all';

  @override
  String get captureClearQuestion => 'Clear all alerts?';

  @override
  String get captureClearBody =>
      'Every screenshot and recording alert will be deleted.';

  @override
  String captureShowAll(int count) {
    return 'Show all ($count)';
  }

  @override
  String get captureShowLess => 'Show less';

  @override
  String get captureScreenshot => 'Screenshot';

  @override
  String get captureRecording => 'Screen recording';

  @override
  String get capturePage => 'Page';

  @override
  String get captureCourse => 'Course';

  @override
  String get captureLesson => 'Lesson / quiz';

  @override
  String get courseLocked => 'Locked';

  @override
  String get courseLockedSnack =>
      'This course isn\'t open for you yet. Ask the admin to give it to you.';

  @override
  String get courseSubtitleEdit => 'Subtitle';

  @override
  String get courseSubtitle => 'Course subtitle';

  @override
  String get courseSubtitleHint => 'A short line shown under the course title';

  @override
  String accessCoursePickPlatform(String course) {
    return 'Pick at least one platform for $course';
  }

  @override
  String get accessCoursePlatforms => 'Opens on';

  @override
  String get certPreview => 'Preview certificate';

  @override
  String get certPreviewNote =>
      'A sample — this is how a member\'s certificate looks.';

  @override
  String get certButtonLocked => 'Certificate · finish the course to earn it';

  @override
  String get certIssued => 'Certificate issued · view it';

  @override
  String get certIssueTitle => 'Certificates';

  @override
  String get certIssueCaption =>
      'Give this member a course\'s certificate without the final exam. It shows up for them at once.';

  @override
  String get certIssue => 'Issue';

  @override
  String get certRevoke => 'Take back';

  @override
  String get certRevoked => 'Certificate taken back';

  @override
  String get certIssuedToast => 'Certificate issued';

  @override
  String get libraryProjects => 'Projects';

  @override
  String get libraryProjectsHint => 'Our projects from the website';

  @override
  String get webTab => 'Website';
}
