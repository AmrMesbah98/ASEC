/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_form_page.dart
/// Purpose: Declares `CvFormPage` — the member writes their own CV.
/// Author: ASEC team
/// Created: 20/9/2026
/// Updated: 16/11/2026 - The screen is ENGX's Create CV screen
///          (create_cv_screen.dart), in ASEC's colours:
///            header card — photo (tap to change) + name and role preview
///            Personal information | Education       (side by side ≥ 1100)
///            Skills               | Links (optional)
///            About you (500 characters, counter)
///            Save CV / Save Changes
///          Fields two per row from 700 wide. Dropdowns and the multi-pick
///          dialogs (skills, soft skills, languages) work like ENGX's;
///          Save with something missing shows "Incomplete information" and
///          marks every such field.
///          Kept from ASEC: only members the admin allowed get the form
///          (everyone else sees "not allowed"), and the CV waits for the
///          admin's approval — the banner at the top says where it stands.

import 'package:flutter/material.dart';
import 'package:asec/core/custom/116-app_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/114-app_messenger.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/cv/c1_cv/domain/constants/cv_options.dart';
import 'package:asec/features/cv/c1_cv/domain/entities/cv_profile.dart';
import 'package:asec/features/cv/c1_cv/domain/enums/cv_status.dart';
import 'package:asec/features/cv/c1_cv/presentation/controller/cv_form_cubit.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/generated/l10n.dart';

/// English or Arabic, by the app's language.
String _t(BuildContext context, String en, String ar) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

class CvFormPage extends StatelessWidget {
  const CvFormPage({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    // The admin's switch decides whether this screen is a form at all. It is
    // OFF for every member until the admin turns it on.
    if (!user.mayWriteCv) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: AppEmptyView(
          title: s.cvNotAllowedTitle,
          subtitle: s.cvNotAllowedSub,
        ),
      );
    }

    return BlocProvider<CvFormCubit>(
      create: (_) => CvFormCubit(user: user)..load(),
      child: const _CvFormView(),
    );
  }
}

class _CvFormView extends StatefulWidget {
  const _CvFormView();

  @override
  State<_CvFormView> createState() => _CvFormViewState();
}

class _CvFormViewState extends State<_CvFormView> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _facebook = TextEditingController();
  final TextEditingController _linkedin = TextEditingController();
  final TextEditingController _cvLink = TextEditingController();
  final TextEditingController _portfolio = TextEditingController();
  final TextEditingController _bio = TextEditingController();

  /// The text boxes are filled once, when the CV has loaded.
  bool _filled = false;

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _name, _email, _phone, _facebook, _linkedin, _cvLink, _portfolio, _bio,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(CvProfile cv) {
    _name.text = cv.fullName;
    _email.text = cv.email;
    _phone.text = cv.phone;
    _facebook.text = cv.facebookLink;
    _linkedin.text = cv.linkedinLink;
    _cvLink.text = cv.cvFileUrl;
    _portfolio.text = cv.portfolioLink;
    _bio.text = cv.bio;
    _filled = true;
  }

  double get _pageWidth => MediaQuery.sizeOf(context).width;

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final bool ok = await context.read<CvFormCubit>().pickPhoto();
    if (!ok && mounted) {
      _say(_t(context, 'Image size must be less than 5MB',
          'يجب أن يكون حجم الصورة أقل من 5 ميجابايت'));
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final bool ok = await context.read<CvFormCubit>().save();
    if (!ok && mounted) _showIncompleteDialog();
  }

  void _say(String text) =>
      AppMessenger.of(context).show(AppMessage(content: Text(text)));

  void _showIncompleteDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        icon: AppIcon(Icons.error_outline, color: AppColors.red, size: 48.sp),
        title: Text(
          _t(context, 'Incomplete Information', 'بيانات غير مكتملة'),
          textAlign: TextAlign.center,
          style: StyleText.fontSize18Weight600.copyWith(color: AppColors.text),
        ),
        content: Text(
          _t(
            context,
            'Please fill all required fields correctly before saving your CV.',
            'من فضلك املأ كل الحقول المطلوبة بشكل صحيح قبل حفظ السيرة الذاتية.',
          ),
          textAlign: TextAlign.center,
          style: StyleText.fontSize14Weight400
              .copyWith(color: AppColors.secondaryText, height: 1.4),
        ),
        actions: <Widget>[
          Center(
            child: AppButton(
              label: _t(context, 'OK', 'حسنًا'),
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
        ],
      ),
    );
  }

  /// ENGX's multi-pick dialog: a checkbox list, Cancel / Done.
  Future<void> _pickMany({
    required String title,
    required List<String> options,
    required List<String> selected,
    required ValueChanged<List<String>> onDone,
  }) async {
    final List<String> temp = List<String>.from(selected);
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialog) => AlertDialog(
          backgroundColor: AppColors.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(
            title,
            style: StyleText.fontSize18Weight600.copyWith(color: AppColors.text),
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final String option in options)
                    CheckboxListTile(
                      title: Text(
                        option,
                        style: StyleText.fontSize14Weight400
                            .copyWith(color: AppColors.text),
                      ),
                      value: temp.contains(option),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.r)),
                      onChanged: (bool? value) => setDialog(() {
                        if (value == true) {
                          temp.add(option);
                        } else {
                          temp.remove(option);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: Text(
                _t(context, 'Cancel', 'إلغاء'),
                style: StyleText.fontSize14Weight500
                    .copyWith(color: AppColors.secondaryText),
              ),
            ),
            AppButton(
              label: _t(context, 'Done', 'تم'),
              dense: true,
              onPressed: () {
                // Keep the order of the list, not the order of the taps.
                onDone(<String>[
                  for (final String o in options)
                    if (temp.contains(o)) o,
                ]);
                Navigator.maybePop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CvFormCubit, CvFormState>(
      listenWhen: (CvFormState a, CvFormState b) => a.status != b.status,
      listener: (BuildContext context, CvFormState state) {
        if (state.status == CvFormStatus.saved) {
          _say(_t(
            context,
            'CV saved successfully. It shows to members once the admin approves it.',
            'تم حفظ السيرة الذاتية. ستظهر للأعضاء بعد موافقة الإدارة.',
          ));
          // ENGX goes back home after saving.
          if (Navigator.of(context).canPop()) Navigator.of(context).maybePop();
        } else if (state.status == CvFormStatus.failure && state.failure != null) {
          _say(state.failure!.message(context));
        }
      },
      builder: (BuildContext context, CvFormState state) {
        if (state.status == CvFormStatus.loading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const AppLoading(),
          );
        }
        if (!_filled) _fill(state.cv);

        final CvFormCubit cubit = context.read<CvFormCubit>();
        final CvProfile cv = state.cv;
        final bool submitted = state.showErrors;
        final String required = _t(context, 'This field is required.', 'هذا الحقل مطلوب.');

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (!state.isNew) ...<Widget>[
                  _StatusBanner(status: cv.status),
                  SizedBox(height: 12.h),
                ],

                // ── Header: photo + name / role preview ──
                _card(
                  child: Row(
                    children: <Widget>[
                      _Avatar(
                        url: cv.photoUrl,
                        uploading: state.uploading == CvUploadKind.photo &&
                            state.status == CvFormStatus.uploading,
                        onTap: state.isBusy ? null : _pickPhoto,
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              cv.fullName.trim().isEmpty
                                  ? (state.isNew
                                      ? _t(context, 'Create your CV', 'أنشئ سيرتك الذاتية')
                                      : _t(context, 'Edit your CV', 'عدّل سيرتك الذاتية'))
                                  : cv.fullName.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: StyleText.fontSize16Weight700
                                  .copyWith(color: AppColors.text),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              cv.role.isNotEmpty
                                  ? cv.role
                                  : _t(
                                      context,
                                      'Add a photo and fill in your details.',
                                      'أضف صورة واملأ بياناتك.',
                                    ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: StyleText.fontSize12Weight500.copyWith(
                                color: AppColors.secondaryText,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                _sectionsRow(<Widget>[
                  // ── Personal information ──
                  _section(_t(context, 'Personal information', 'البيانات الشخصية'), <Widget>[
                    _TextBox(
                      label: _t(context, 'Full Name', 'الاسم بالكامل'),
                      hint: _t(context, 'Enter your full name', 'اكتب اسمك بالكامل'),
                      controller: _name,
                      error: submitted && cv.fullName.trim().isEmpty ? required : null,
                      onChanged: cubit.setFullName,
                    ),
                    _TextBox(
                      label: _t(context, 'Email', 'البريد الإلكتروني'),
                      hint: _t(context, 'Enter your email', 'اكتب بريدك الإلكتروني'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      error: !submitted
                          ? null
                          : cv.email.trim().isEmpty
                              ? required
                              : !CvValidators.emailOk(cv.email)
                                  ? _t(context, 'Please enter a valid email address.',
                                      'من فضلك اكتب بريدًا إلكترونيًا صحيحًا.')
                                  : null,
                      onChanged: cubit.setEmail,
                    ),
                    _TextBox(
                      label: _t(context, 'Phone number', 'رقم الهاتف'),
                      hint: '01xxxxxxxxx',
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      digitsOnly: true,
                      error: !submitted
                          ? null
                          : cv.phone.trim().isEmpty
                              ? required
                              : !CvValidators.phoneOk(cv.phone)
                                  ? _t(context, 'Phone number must be at least 10 digits.',
                                      'رقم الهاتف لا يقل عن 10 أرقام.')
                                  : null,
                      onChanged: cubit.setPhone,
                    ),
                    _Dropdown(
                      label: _t(context, 'Location', 'المحافظة'),
                      hint: _t(context, 'Select governorate', 'اختر المحافظة'),
                      value: cv.location,
                      items: CvOptions.governorates,
                      error: submitted && cv.location.isEmpty ? required : null,
                      onChanged: cubit.setLocation,
                    ),
                    _Dropdown(
                      label: _t(context, 'Military status', 'الموقف من التجنيد'),
                      hint: _t(context, 'Select military status', 'اختر الموقف من التجنيد'),
                      value: cv.militaryStatus,
                      items: CvOptions.militaryStatus,
                      error: submitted && cv.militaryStatus.isEmpty ? required : null,
                      onChanged: cubit.setMilitaryStatus,
                    ),
                  ]),

                  // ── Education ──
                  _section(_t(context, 'Education', 'التعليم'), <Widget>[
                    _Dropdown(
                      label: _t(context, 'Graduation year', 'سنة التخرج'),
                      hint: _t(context, 'Select graduation year', 'اختر سنة التخرج'),
                      value: cv.graduationYear,
                      items: CvOptions.graduationYears(),
                      error: submitted && cv.graduationYear.isEmpty ? required : null,
                      onChanged: cubit.setGraduationYear,
                    ),
                    _Dropdown(
                      label: _t(context, 'Specialization', 'التخصص'),
                      hint: _t(context, 'Select specialization', 'اختر التخصص'),
                      value: cv.specialization,
                      items: CvOptions.specializations,
                      error: submitted && cv.specialization.isEmpty ? required : null,
                      onChanged: cubit.setSpecialization,
                    ),
                    _Dropdown(
                      label: _t(context, 'Role', 'الوظيفة'),
                      hint: _t(context, 'Select role', 'اختر الوظيفة'),
                      value: cv.role,
                      items: CvOptions.roles,
                      error: submitted && cv.role.isEmpty ? required : null,
                      onChanged: cubit.setRole,
                    ),
                    _SelectBox(
                      label: _t(context, 'Languages', 'اللغات'),
                      hint: _t(context, 'Select languages', 'اختر اللغات'),
                      values: cv.languages,
                      error: submitted && cv.languages.isEmpty
                          ? _t(context, 'Please select at least one language.',
                              'اختر لغة واحدة على الأقل.')
                          : null,
                      onTap: () => _pickMany(
                        title: _t(context, 'Select Languages', 'اختر اللغات'),
                        options: CvOptions.languages,
                        selected: cv.languages,
                        onDone: cubit.setLanguages,
                      ),
                    ),
                  ]),
                ]),

                _sectionsRow(<Widget>[
                  // ── Skills ──
                  _section(_t(context, 'Skills', 'المهارات'), <Widget>[
                    _SelectBox(
                      label: _t(context, 'Professional skills', 'المهارات المهنية'),
                      hint: _t(context, 'Select skills', 'اختر المهارات'),
                      values: cv.proSkills,
                      error: submitted && cv.proSkills.isEmpty
                          ? _t(context, 'Please select at least one skill.',
                              'اختر مهارة واحدة على الأقل.')
                          : null,
                      onTap: () {
                        if (state.availableProSkills.isEmpty) {
                          _say(_t(context, 'Please select Specialization and Role first',
                              'اختر التخصص والوظيفة أولًا'));
                          return;
                        }
                        _pickMany(
                          title: _t(context, 'Select Pro Skills', 'اختر المهارات المهنية'),
                          options: state.availableProSkills,
                          selected: cv.proSkills,
                          onDone: cubit.setProSkills,
                        );
                      },
                    ),
                    _SelectBox(
                      label: _t(context, 'Soft skills', 'المهارات الشخصية'),
                      hint: _t(context, 'Select soft skills', 'اختر المهارات الشخصية'),
                      values: cv.softSkills,
                      error: submitted && cv.softSkills.isEmpty
                          ? _t(context, 'Please select at least one soft skill.',
                              'اختر مهارة شخصية واحدة على الأقل.')
                          : null,
                      onTap: () => _pickMany(
                        title: _t(context, 'Select Soft Skills', 'اختر المهارات الشخصية'),
                        options: CvOptions.softSkills,
                        selected: cv.softSkills,
                        onDone: cubit.setSoftSkills,
                      ),
                    ),
                  ]),

                  // ── Links (optional) ──
                  _section(
                    _t(context, 'Links', 'الروابط'),
                    <Widget>[
                      _TextBox(
                        label: 'LinkedIn',
                        hint: 'linkedin.com/in/…',
                        controller: _linkedin,
                        keyboardType: TextInputType.url,
                        error: _urlError(submitted, cv.linkedinLink),
                        onChanged: cubit.setLinkedin,
                      ),
                      _TextBox(
                        label: 'Facebook',
                        hint: 'facebook.com/…',
                        controller: _facebook,
                        keyboardType: TextInputType.url,
                        error: _urlError(submitted, cv.facebookLink),
                        onChanged: cubit.setFacebook,
                      ),
                      _TextBox(
                        label: _t(context, 'CV file link', 'رابط ملف السيرة الذاتية'),
                        hint: _t(context, 'Google Drive or cloud link to your CV',
                            'رابط Google Drive أو أي رابط سحابي لسيرتك الذاتية'),
                        controller: _cvLink,
                        keyboardType: TextInputType.url,
                        error: _urlError(submitted, cv.cvFileUrl),
                        onChanged: cubit.setCvLink,
                      ),
                      _TextBox(
                        label: _t(context, 'Portfolio', 'معرض الأعمال'),
                        hint: _t(context, 'Portfolio or website link', 'رابط معرض الأعمال أو الموقع'),
                        controller: _portfolio,
                        keyboardType: TextInputType.url,
                        error: _urlError(submitted, cv.portfolioLink),
                        onChanged: cubit.setPortfolio,
                      ),
                    ],
                    optional: true,
                  ),
                ]),

                // ── About you ──
                _section(_t(context, 'About you', 'نبذة عنك'), <Widget>[
                  _BioBox(
                    controller: _bio,
                    hint: _t(
                      context,
                      'A short overview of your experience and what makes you stand out.',
                      'نبذة قصيرة عن خبرتك وما يميزك.',
                    ),
                    error: submitted && cv.bio.trim().isEmpty ? required : null,
                    onChanged: cubit.setBio,
                  ),
                ]),
                SizedBox(height: 8.h),

                AppButton(
                  label: state.status == CvFormStatus.saving
                      ? _t(context, 'Saving…', 'جارٍ الحفظ…')
                      : state.isNew
                          ? _t(context, 'Save CV', 'حفظ السيرة الذاتية')
                          : _t(context, 'Save Changes', 'حفظ التعديلات'),
                  icon: Icons.check_rounded,
                  expand: true,
                  loading: state.status == CvFormStatus.saving,
                  onPressed: state.isBusy ? null : _save,
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _urlError(bool submitted, String value) =>
      submitted && !CvValidators.urlOk(value)
          ? _t(context, 'Please enter a valid URL.', 'من فضلك اكتب رابطًا صحيحًا.')
          : null;

  // ── Layout (ENGX's) ──────────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: child,
      );

  /// Two sections side by side on a wide window (same height), stacked on a
  /// phone.
  Widget _sectionsRow(List<Widget> sections) {
    if (_pageWidth < 1100) return Column(children: sections);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < sections.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: sections[i]),
          ],
        ],
      ),
    );
  }

  /// Fields two per row from 700 wide, one per row on a phone.
  Widget _fieldGrid(List<Widget> fields) {
    final bool two = _pageWidth >= 700 && fields.length > 1;
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < fields.length; i += two ? 2 : 1) {
      if (i > 0) rows.add(SizedBox(height: 14.h));
      if (!two) {
        rows.add(fields[i]);
      } else {
        rows.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: fields[i]),
            const SizedBox(width: 14),
            Expanded(
              child: i + 1 < fields.length ? fields[i + 1] : const SizedBox.shrink(),
            ),
          ],
        ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }

  Widget _section(String title, List<Widget> fields, {bool optional = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  title,
                  style: StyleText.fontSize15Weight600.copyWith(color: AppColors.text),
                ),
                if (optional) ...<Widget>[
                  SizedBox(width: 6.w),
                  Text(
                    _t(context, 'Optional', 'اختياري'),
                    style: StyleText.fontSize12Weight400
                        .copyWith(color: AppColors.secondaryText),
                  ),
                ],
              ],
            ),
            SizedBox(height: 16.h),
            _fieldGrid(fields),
          ],
        ),
      ),
    );
  }
}

// ── Pieces ───────────────────────────────────────────────────────────────────

const double _fieldHeight = 48;
const double _fieldRadius = 10;

/// The label above every field.
class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 6.h),
        child: Text(
          text,
          style: StyleText.fontSize14Weight600.copyWith(color: AppColors.text),
        ),
      );
}

/// The red line under a field.
class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.text);

  final String? text;

  @override
  Widget build(BuildContext context) => text == null
      ? const SizedBox.shrink()
      : Padding(
          padding: EdgeInsetsDirectional.only(top: 4.h, start: 4.w),
          child: Text(
            text!,
            style: StyleText.fontSize11Weight600.copyWith(color: AppColors.red),
          ),
        );
}

BoxDecoration _boxDecoration(bool error) => BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(_fieldRadius),
      border: Border.all(
        color: error ? AppColors.red.withOpacity(0.5) : Colors.transparent,
      ),
    );

class _TextBox extends StatelessWidget {
  const _TextBox({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.error,
    this.keyboardType,
    this.digitsOnly = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? error;
  final TextInputType? keyboardType;
  final bool digitsOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Label(label),
        Container(
          height: _fieldHeight,
          alignment: Alignment.center,
          decoration: _boxDecoration(error != null),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: digitsOnly
                ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
                : null,
            onChanged: onChanged,
            style: StyleText.fontSize14Weight400.copyWith(color: AppColors.text),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: StyleText.fontSize13Weight400
                  .copyWith(color: AppColors.secondaryText),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 14.w),
            ),
          ),
        ),
        _ErrorLine(error),
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.error,
  });

  final String label;
  final String hint;

  /// '' = nothing picked.
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Label(label),
        Container(
          height: _fieldHeight,
          alignment: Alignment.center,
          decoration: _boxDecoration(error != null),
          padding: EdgeInsetsDirectional.only(start: 14.w, end: 10.w),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : null,
              isExpanded: true,
              dropdownColor: AppColors.card,
              menuMaxHeight: 250.h,
              borderRadius: BorderRadius.circular(_fieldRadius),
              hint: Text(
                hint,
                style: StyleText.fontSize13Weight400
                    .copyWith(color: AppColors.secondaryText),
              ),
              icon: AppIcon(Icons.keyboard_arrow_down, color: AppColors.secondaryText),
              style: StyleText.fontSize14Weight400.copyWith(color: AppColors.text),
              items: <DropdownMenuItem<String>>[
                for (final String item in items)
                  DropdownMenuItem<String>(value: item, child: Text(item)),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
        _ErrorLine(error),
      ],
    );
  }
}

/// ENGX's "select" box: looks like the dropdowns, the picks show as chips
/// inside it, a tap opens the checkbox dialog.
class _SelectBox extends StatelessWidget {
  const _SelectBox({
    required this.label,
    required this.hint,
    required this.values,
    required this.onTap,
    this.error,
  });

  final String label;
  final String hint;
  final List<String> values;
  final VoidCallback onTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Label(label),
        Material(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(_fieldRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(_fieldRadius),
            onTap: onTap,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: _fieldHeight),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_fieldRadius),
                border: Border.all(
                  color: error != null
                      ? AppColors.red.withOpacity(0.5)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: values.isEmpty
                        ? Text(
                            hint,
                            style: StyleText.fontSize13Weight400
                                .copyWith(color: AppColors.secondaryText),
                          )
                        : Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: <Widget>[
                              for (final String v in values)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    v,
                                    style: StyleText.fontSize12Weight500
                                        .copyWith(color: AppColors.text),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  AppIcon(Icons.keyboard_arrow_down, color: AppColors.secondaryText),
                ],
              ),
            ),
          ),
        ),
        _ErrorLine(error),
      ],
    );
  }
}

/// "About you": 5 lines, 500 characters, the count under it.
class _BioBox extends StatelessWidget {
  const _BioBox({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.error,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final String? error;

  static const int max = 500;

  @override
  Widget build(BuildContext context) {
    final int length = controller.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          decoration: _boxDecoration(error != null),
          child: TextField(
            controller: controller,
            maxLines: 5,
            maxLength: max,
            onChanged: onChanged,
            style: StyleText.fontSize14Weight400.copyWith(color: AppColors.text),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: StyleText.fontSize13Weight400
                  .copyWith(color: AppColors.secondaryText),
              border: InputBorder.none,
              counterText: '',
              isDense: true,
              contentPadding: EdgeInsets.all(14.r),
            ),
          ),
        ),
        Row(
          children: <Widget>[
            Expanded(child: _ErrorLine(error)),
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(
                '$length/$max',
                style: StyleText.fontSize11Weight400.copyWith(
                  color: length >= max ? AppColors.red : AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The round photo with the camera badge; a spinner on the badge while it
/// uploads.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.uploading, required this.onTap});

  final String url;
  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double size = 72.r;
    final Widget placeholder = Center(
      child: AppIcon(Icons.person, size: 34.r, color: AppColors.secondaryText),
    );
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              width: size,
              height: size,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: AppColors.background),
              child: ClipOval(
                child: url.isEmpty
                    ? placeholder
                    : AppNetworkImage(
                        url,
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                        errorBuilder: (_, __, ___) => placeholder,
                      ),
              ),
            ),
            PositionedDirectional(
              bottom: -2,
              end: -2,
              child: Container(
                width: 26.r,
                height: 26.r,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: AppColors.text),
                child: uploading
                    ? SizedBox(
                        width: 12.r,
                        height: 12.r,
                        child: CircularProgressIndicator(
                          color: AppColors.card,
                          strokeWidth: 2,
                        ),
                      )
                    : AppIcon(Icons.camera_alt, size: 13.r, color: AppColors.card),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the member's CV stands with the admin.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final CvStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case CvStatus.approved:
        return InfoBanner(
          icon: Icons.check_circle_rounded,
          color: AppColors.green,
          message: _t(context, 'Your CV is approved and visible to members.',
              'تمت الموافقة على سيرتك الذاتية وهي ظاهرة للأعضاء.'),
        );
      case CvStatus.rejected:
        return InfoBanner(
          icon: Icons.cancel_rounded,
          color: AppColors.red,
          message: _t(context, 'Your CV was rejected by the admin.',
              'تم رفض سيرتك الذاتية من الإدارة.'),
        );
      case CvStatus.pending:
        return InfoBanner(
          icon: Icons.hourglass_top_rounded,
          color: AppColors.statusPending,
          message: _t(context, 'Your CV is waiting for the admin\'s approval.',
              'سيرتك الذاتية في انتظار موافقة الإدارة.'),
        );
    }
  }
}
