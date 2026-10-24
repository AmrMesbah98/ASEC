/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_form_page.dart
/// Purpose: Declares `CvFormPage` — the member writes their own CV.
/// Author: ASEC team
/// Created: 20/9/2026
///
/// Four cards, in the order a CV is written: who you are, what you do, what
/// you can do, where to find you. On a wide window the first two sit beside
/// the last two; below 1000pt they stack.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/1-custom_dropdown.dart';
import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/cv/c1_cv/domain/constants/cv_options.dart';
import 'package:asec/features/cv/c1_cv/domain/entities/cv_profile.dart';
import 'package:asec/features/cv/c1_cv/presentation/controller/cv_form_cubit.dart';
import 'package:asec/features/cv/c1_cv/presentation/ui/widgets/multi_select_field.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

class CvFormPage extends StatelessWidget {
  const CvFormPage({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    // The admin's switch decides whether this screen is a form at all.
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

class _CvFormView extends StatelessWidget {
  const _CvFormView();

  static const double _splitWidth = 1000;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return BlocConsumer<CvFormCubit, CvFormState>(
      listenWhen: (CvFormState a, CvFormState b) => a.status != b.status,
      listener: (BuildContext context, CvFormState state) {
        if (state.status == CvFormStatus.saved) {
          AppMessenger.of(context)
              .show(AppMessage(content: Text(FormatHelper.capitalize(s.cvSaved))));
        }
      },
      builder: (BuildContext context, CvFormState state) {
        if (state.status == CvFormStatus.loading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const AppLoading(),
          );
        }

        final CvFormCubit cubit = context.read<CvFormCubit>();
        final bool split = MediaQuery.sizeOf(context).width >= _splitWidth;

        final Widget left = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _PhotoCard(state: state),
            SizedBox(height: 16.h),
            _PersonalCard(state: state),
          ],
        );
        final Widget right = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _ProfessionCard(state: state),
            SizedBox(height: 16.h),
            _SkillsCard(state: state),
            SizedBox(height: 16.h),
            _CvFileCard(state: state),
            SizedBox(height: 16.h),
            _LinksCard(state: state),
          ],
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'asec_fab_cv',
            onPressed: state.isBusy ? null : cubit.save,
            backgroundColor: AppColors.primary,
            icon: state.status == CvFormStatus.saving
                ? SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.textButton),
                    ),
                  )
                : AppIcon(Icons.check_rounded, color: AppColors.textButton),
            label: Text(
              FormatHelper.capitalize(s.save),
              style:
                  StyleText.fontSize14Weight600.copyWith(color: AppColors.textButton),
            ),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              AppPadding.h,
              16.h,
              AppPadding.h,
              96.h,
            ),
            children: <Widget>[
              if (!state.isNew) ...<Widget>[
                InfoBanner(
                  icon: Icons.check_circle_rounded,
                  color: AppColors.green,
                  message: s.yourCvIsLive,
                ),
                SizedBox(height: 14.h),
              ],
              if (state.showErrors && !state.cv.isComplete) ...<Widget>[
                InfoBanner.error(s.cvIncomplete),
                SizedBox(height: 14.h),
              ],
              if (state.failure != null) ...<Widget>[
                InfoBanner.error(state.failure!.message(context)),
                SizedBox(height: 14.h),
              ],
              if (split)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: left),
                    SizedBox(width: 16.w),
                    Expanded(child: right),
                  ],
                )
              else ...<Widget>[
                left,
                SizedBox(height: 16.h),
                right,
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Photo ────────────────────────────────────────────────────────────────────

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.state});

  final CvFormState state;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final CvFormCubit cubit = context.read<CvFormCubit>();
    final bool uploading = state.status == CvFormStatus.uploading &&
        state.uploading == CvUploadKind.photo;

    return AppCard(
      title: s.cvPhoto,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 104.r,
            height: 104.r,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.chip,
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: state.cv.hasPhoto
                ? Image.network(state.cv.photoUrl, fit: BoxFit.cover)
                : Center(
                    child: AppIcon(
                      Icons.person_outline_rounded,
                      size: 44.sp,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          SizedBox(height: 12.h),
          if (uploading) ...<Widget>[
            ClipRRect(
              borderRadius: AppRadius.buttonR,
              child: LinearProgressIndicator(
                value: state.progress == 0 ? null : state.progress,
                minHeight: 5.h,
                backgroundColor: AppColors.chip,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            SizedBox(height: 10.h),
            AppButton(
              label: s.uploadCancel,
              icon: Icons.close_rounded,
              kind: AppButtonKind.danger,
              dense: true,
              onPressed: cubit.cancelUpload,
            ),
          ] else
            AppButton(
              label: state.cv.hasPhoto ? s.replace : s.choosePhoto,
              icon: Icons.photo_rounded,
              kind: AppButtonKind.subtle,
              dense: true,
              onPressed: state.isBusy ? null : cubit.pickPhoto,
            ),
        ],
      ),
    );
  }
}

// ── Personal ─────────────────────────────────────────────────────────────────

class _PersonalCard extends StatefulWidget {
  const _PersonalCard({required this.state});

  final CvFormState state;

  @override
  State<_PersonalCard> createState() => _PersonalCardState();
}

class _PersonalCardState extends State<_PersonalCard> {
  late final TextEditingController _name =
      TextEditingController(text: widget.state.cv.fullName);
  late final TextEditingController _email =
      TextEditingController(text: widget.state.cv.email);
  late final TextEditingController _phone =
      TextEditingController(text: widget.state.cv.phone);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final CvFormCubit cubit = context.read<CvFormCubit>();
    final CvProfile cv = widget.state.cv;
    final bool errors = widget.state.showErrors;

    return AppCard(
      title: s.cvPersonal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CustomTextField(
            controller: _name,
            label: s.fullName,
            required: true,
            prefixIcon: const AppIcon(Icons.person_outline_rounded),
            errorText: errors && cv.fullName.trim().isEmpty ? s.enterName : null,
            onChanged: cubit.setFullName,
          ),
          SizedBox(height: 12.h),
          CustomTextField(
            controller: _email,
            label: s.email,
            required: true,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const AppIcon(Icons.alternate_email_rounded),
            errorText: errors && cv.email.trim().isEmpty ? s.enterEmail : null,
            onChanged: cubit.setEmail,
          ),
          SizedBox(height: 12.h),
          CustomTextField(
            controller: _phone,
            label: s.phone,
            required: true,
            keyboardType: TextInputType.phone,
            prefixIcon: const AppIcon(Icons.phone_iphone_rounded),
            errorText: errors && cv.phone.trim().isEmpty ? s.enterPhone : null,
            onChanged: cubit.setPhone,
          ),
          SizedBox(height: 12.h),
          CustomDropdown<String>(
            label: s.cvLocation,
            required: true,
            value: cv.location.isEmpty ? null : cv.location,
            hint: s.pickSome,
            errorText: errors && cv.location.isEmpty ? s.pickSome : null,
            onChanged: cubit.setLocation,
            items: <DropdownItem<String>>[
              for (final String v in CvOptions.governorates)
                DropdownItem<String>(value: v, label: v),
            ],
          ),
          SizedBox(height: 12.h),
          CustomDropdown<String>(
            label: s.militaryStatus,
            required: true,
            value: cv.militaryStatus.isEmpty ? null : cv.militaryStatus,
            hint: s.pickSome,
            errorText: errors && cv.militaryStatus.isEmpty ? s.pickSome : null,
            onChanged: cubit.setMilitaryStatus,
            items: <DropdownItem<String>>[
              for (final String v in CvOptions.militaryStatus)
                DropdownItem<String>(value: v, label: v),
            ],
          ),
          SizedBox(height: 12.h),
          CustomDropdown<String>(
            label: s.graduationYear,
            required: true,
            value: cv.graduationYear.isEmpty ? null : cv.graduationYear,
            hint: s.pickSome,
            errorText: errors && cv.graduationYear.isEmpty ? s.pickSome : null,
            onChanged: cubit.setGraduationYear,
            items: <DropdownItem<String>>[
              for (final String v in CvOptions.graduationYears())
                DropdownItem<String>(value: v, label: v),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Profession ───────────────────────────────────────────────────────────────

class _ProfessionCard extends StatefulWidget {
  const _ProfessionCard({required this.state});

  final CvFormState state;

  @override
  State<_ProfessionCard> createState() => _ProfessionCardState();
}

class _ProfessionCardState extends State<_ProfessionCard> {
  late final TextEditingController _bio =
      TextEditingController(text: widget.state.cv.bio);

  @override
  void dispose() {
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final CvFormCubit cubit = context.read<CvFormCubit>();
    final CvProfile cv = widget.state.cv;
    final bool errors = widget.state.showErrors;

    return AppCard(
      title: s.cvProfession,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CustomDropdown<String>(
            label: s.cvSpecialization,
            required: true,
            value: cv.specialization.isEmpty ? null : cv.specialization,
            hint: s.pickSome,
            errorText: errors && cv.specialization.isEmpty ? s.pickSome : null,
            onChanged: cubit.setSpecialization,
            items: <DropdownItem<String>>[
              for (final String v in CvOptions.specializations)
                DropdownItem<String>(value: v, label: v),
            ],
          ),
          SizedBox(height: 12.h),
          CustomDropdown<String>(
            label: s.jobRole,
            required: true,
            value: cv.role.isEmpty ? null : cv.role,
            hint: s.pickSome,
            errorText: errors && cv.role.isEmpty ? s.pickSome : null,
            onChanged: cubit.setRole,
            items: <DropdownItem<String>>[
              for (final String v in CvOptions.roles)
                DropdownItem<String>(value: v, label: v),
            ],
          ),
          SizedBox(height: 12.h),
          CustomTextField(
            controller: _bio,
            label: s.bioLabel,
            hint: s.bioHint,
            maxLines: 4,
            onChanged: cubit.setBio,
          ),
        ],
      ),
    );
  }
}

// ── Skills ───────────────────────────────────────────────────────────────────

class _SkillsCard extends StatelessWidget {
  const _SkillsCard({required this.state});

  final CvFormState state;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final CvFormCubit cubit = context.read<CvFormCubit>();

    return AppCard(
      title: s.cvSkillsSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The professional skills come from the ROLE, so this list is empty
          // until a role is picked — and says so.
          MultiSelectField(
            label: s.proSkills,
            icon: Icons.bolt_rounded,
            options: state.availableProSkills,
            selected: state.cv.proSkills,
            emptyHint: s.pickRoleFirst,
            onChanged: cubit.setProSkills,
          ),
          SizedBox(height: 14.h),
          MultiSelectField(
            label: s.softSkillsLabel,
            icon: Icons.groups_2_rounded,
            options: CvOptions.softSkills,
            selected: state.cv.softSkills,
            onChanged: cubit.setSoftSkills,
          ),
          SizedBox(height: 14.h),
          MultiSelectField(
            label: s.languagesLabel,
            icon: Icons.translate_rounded,
            options: CvOptions.languages,
            selected: state.cv.languages,
            onChanged: cubit.setLanguages,
          ),
        ],
      ),
    );
  }
}

// ── Links ────────────────────────────────────────────────────────────────────

class _LinksCard extends StatefulWidget {
  const _LinksCard({required this.state});

  final CvFormState state;

  @override
  State<_LinksCard> createState() => _LinksCardState();
}

class _LinksCardState extends State<_LinksCard> {
  late final TextEditingController _facebook =
      TextEditingController(text: widget.state.cv.facebookLink);
  late final TextEditingController _linkedin =
      TextEditingController(text: widget.state.cv.linkedinLink);
  late final TextEditingController _portfolio =
      TextEditingController(text: widget.state.cv.portfolioLink);

  @override
  void dispose() {
    _facebook.dispose();
    _linkedin.dispose();
    _portfolio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final CvFormCubit cubit = context.read<CvFormCubit>();

    return AppCard(
      title: s.cvLinks,
      // All four are optional: a CV with none of them is still a CV.
      caption: s.phoneHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CustomTextField(
            controller: _linkedin,
            label: s.linkedinLabel,
            hint: 'https://linkedin.com/in/…',
            keyboardType: TextInputType.url,
            prefixIcon: const AppIcon(Icons.open_in_new_rounded),
            onChanged: cubit.setLinkedin,
          ),
          SizedBox(height: 12.h),
          CustomTextField(
            controller: _portfolio,
            label: s.portfolioLabel,
            hint: 'https://…',
            keyboardType: TextInputType.url,
            prefixIcon: const AppIcon(Icons.insights_rounded),
            onChanged: cubit.setPortfolio,
          ),
          SizedBox(height: 12.h),
          CustomTextField(
            controller: _facebook,
            label: s.facebookLabel,
            hint: 'https://facebook.com/…',
            keyboardType: TextInputType.url,
            prefixIcon: const AppIcon(Icons.chat_bubble_outline_rounded),
            onChanged: cubit.setFacebook,
          ),
        ],
      ),
    );
  }
}

// ── The CV file ──────────────────────────────────────────────────────────────

/// An UPLOAD, not a text field for a link.
///
/// The old form asked for a Google Drive URL. That put the most important part
/// of a CV outside the app: the link rots when the owner tidies their Drive,
/// it asks the reader to trust a third-party page, and nothing here can tell
/// whether it still resolves. The file now lives in this project's own
/// Storage, under the owner's uid, and the directory can hand it straight to
/// whoever is reading the CV.
class _CvFileCard extends StatelessWidget {
  const _CvFileCard({required this.state});

  final CvFormState state;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final CvFormCubit cubit = context.read<CvFormCubit>();
    final CvProfile cv = state.cv;
    final bool uploading = state.status == CvFormStatus.uploading &&
        state.uploading == CvUploadKind.file;

    return AppCard(
      title: s.driveLabel,
      caption: s.cvFileHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (state.fileTooLarge) ...<Widget>[
            InfoBanner.error(s.fileTooLarge(CvFormCubit.maxCvFileMb)),
            SizedBox(height: 12.h),
          ],

          // The dropzone-looking row: what is there now, or that nothing is.
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.chip,
              borderRadius: AppRadius.buttonR,
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 38.r,
                  height: 38.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: AppRadius.buttonR,
                  ),
                  child: AppIcon(
                    cv.hasCvFile
                        ? Icons.picture_as_pdf_rounded
                        : Icons.upload_file_rounded,
                    size: 20.sp,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        FormatHelper.capitalize(cv.hasCvFile
                            ? (cv.cvFileName.isEmpty
                                ? s.driveLabel
                                : cv.cvFileName)
                            : s.noCvFile),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StyleText.fontSize13Weight600,
                      ),
                      if (cv.hasCvFile && cv.cvFileSizeLabel.isNotEmpty)
                        Text(
                          FormatHelper.capitalize(cv.cvFileSizeLabel),
                          style: StyleText.fontSize11Weight400
                              .copyWith(color: AppColors.secondaryText),
                        ),
                    ],
                  ),
                ),
                if (cv.hasCvFile && !state.isBusy)
                  IconButton(
                    tooltip: s.removeFile,
                    onPressed: cubit.removeCvFile,
                    icon: AppIcon(
                      Icons.delete_outline_rounded,
                      size: 18.sp,
                      color: AppColors.red,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          if (uploading) ...<Widget>[
            ClipRRect(
              borderRadius: AppRadius.buttonR,
              child: LinearProgressIndicator(
                value: state.progress == 0 ? null : state.progress,
                minHeight: 5.h,
                backgroundColor: AppColors.chip,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            SizedBox(height: 10.h),
            AppButton(
              label: s.uploadCancel,
              icon: Icons.close_rounded,
              kind: AppButtonKind.danger,
              dense: true,
              onPressed: cubit.cancelUpload,
            ),
          ] else
            AppButton(
              label: cv.hasCvFile ? s.replace : s.uploadCvFile,
              icon: Icons.upload_rounded,
              kind: cv.hasCvFile ? AppButtonKind.subtle : AppButtonKind.filled,
              dense: true,
              onPressed: state.isBusy ? null : cubit.pickCvFile,
            ),
        ],
      ),
    );
  }
}
