/// Module: settings / se1_settings
///
///*************************** FILE INFO ****************************///
/// File Name: admins_card.dart
/// Purpose: Declares `AdminsCard` — super admin only: every admin account,
///          what each may manage, a switch to turn one off, and the form to
///          create a new admin with chosen permissions.
/// Author: ASEC team
/// Created: 25/9/2026

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
import 'package:asec/features/settings/se1_settings/data/admins_repository.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

class AdminsCard extends StatefulWidget {
  const AdminsCard({super.key});

  @override
  State<AdminsCard> createState() => _AdminsCardState();
}

class _AdminsCardState extends State<AdminsCard> {
  final AdminsRepository _repo = AdminsRepository();
  late final Stream<List<AppUser>> _admins = _repo.watchAdmins();

  void _toast(String text) {
    if (!mounted) return;
    AppMessenger.of(context)
      ..hide()
      ..show(AppMessage(content: Text(FormatHelper.capitalize(text))));
  }

  Future<void> _create() async {
    final bool? created = await showDialog<bool>(
      context: context,
      builder: (_) => _AdminFormDialog(repo: _repo),
    );
    if (created == true) _toast(S.of(context).adminCreated);
  }

  Future<void> _editPermissions(AppUser admin) async {
    final Set<String>? perms = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _PermissionsDialog(
        title: admin.displayName,
        // A legacy admin is shown as the v2 list that means the same.
        initial: AdminPerms.upgrade(admin.permissionKeys),
      ),
    );
    if (perms == null) return;
    try {
      await _repo.setPermissions(admin.uid, perms);
      _toast(S.of(context).permissionsSaved);
    } catch (_) {
      _toast(S.of(context).errUnknown);
    }
  }

  Future<void> _remove(AppUser admin) async {
    final S s = S.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(FormatHelper.capitalize(s.removeAdminQuestion)),
        content: Text(FormatHelper.capitalize(s.removeAdminBody(admin.displayName))),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(FormatHelper.capitalize(s.cancel)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(FormatHelper.capitalize(s.delete), style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.remove(admin.uid);
    } catch (_) {
      _toast(s.errUnknown);
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return AppCard(
      title: s.adminsTitle,
      caption: s.adminsHint,
      actions: <Widget>[
        AppButton(
          label: s.addAdmin,
          icon: Icons.person_add_alt_1_rounded,
          dense: true,
          onPressed: _create,
        ),
      ],
      child: StreamBuilder<List<AppUser>>(
        stream: _admins,
        builder: (BuildContext context, AsyncSnapshot<List<AppUser>> snap) {
          if (snap.hasError) {
            return Text(FormatHelper.capitalize(s.errUnknown),
                style: StyleText.fontSize13Weight400
                    .copyWith(color: AppColors.red));
          }
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator.adaptive()),
            );
          }
          final List<AppUser> admins = snap.data!;
          if (admins.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text(
                FormatHelper.capitalize(s.noAdminsYet),
                style: StyleText.fontSize13Weight400
                    .copyWith(color: AppColors.secondaryText),
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final AppUser a in admins)
                _AdminRow(
                  admin: a,
                  onToggle: (bool v) async {
                    try {
                      await _repo.setActive(a.uid, v);
                    } catch (_) {
                      _toast(s.errUnknown);
                    }
                  },
                  onEdit: () => _editPermissions(a),
                  onRemove: () => _remove(a),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminRow extends StatelessWidget {
  const _AdminRow({
    required this.admin,
    required this.onToggle,
    required this.onEdit,
    required this.onRemove,
  });

  final AppUser admin;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppAvatar(name: admin.displayName, size: 40),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      FormatHelper.capitalize(admin.displayName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText.fontSize14Weight600,
                    ),
                    Text(
                      FormatHelper.capitalize(admin.email),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText.fontSize12Weight400
                          .copyWith(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: admin.active,
                activeTrackColor: AppColors.secondaryPrimary,
                onChanged: onToggle,
              ),
              PopupMenuButton<int>(
                icon: AppIcon(Icons.more_vert_rounded, size: 20.sp),
                onSelected: (int v) => v == 0 ? onEdit() : onRemove(),
                itemBuilder: (_) => <PopupMenuEntry<int>>[
                  PopupMenuItem<int>(value: 0, child: Text(FormatHelper.capitalize(s.editPermissions))),
                  PopupMenuItem<int>(
                    value: 1,
                    child: Text(FormatHelper.capitalize(s.removeAdmin),
                        style: TextStyle(color: AppColors.red)),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: <Widget>[
              if (admin.permissions.isEmpty)
                Text(
                  FormatHelper.capitalize(s.noPermissions),
                  style: StyleText.fontSize12Weight400
                      .copyWith(color: AppColors.statusPending),
                ),
              for (final AdminPermission p in admin.permissions)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AppIcon(p.icon, size: 13.sp, color: AppColors.onChip),
                      SizedBox(width: 4.w),
                      Text(
                        FormatHelper.capitalize(p.label(context)),
                        style: StyleText.fontSize11Weight600
                            .copyWith(color: AppColors.onChip),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Each tab with its actions underneath, reused by the create form and the
/// edit dialog. Works on the raw keys ('videos', 'videos.delete', 'v2').
/// Ticking a tab ticks all its actions; unticking it clears them. The tab
/// itself means "may open and view it".
class _PermissionPicker extends StatelessWidget {
  const _PermissionPicker({required this.selected, required this.onChanged});

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  void _toggleTab(AdminPermission p, bool on) {
    final Set<String> next = <String>{...selected}
      ..removeAll(AdminPerms.fullTab(p));
    if (on) next.addAll(AdminPerms.fullTab(p));
    onChanged(next);
  }

  void _toggleAction(AdminAction a, bool on) {
    final Set<String> next = <String>{...selected};
    on ? next.add(a.key) : next.remove(a.key);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final AdminPermission p in AdminPermission.values) ...<Widget>[
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primary,
            value: selected.contains(p.key),
            secondary: AppIcon(p.icon, size: 18.sp, color: AppColors.secondaryText),
            title: Text(FormatHelper.capitalize(p.label(context)), style: StyleText.fontSize14Weight600),
            subtitle: p.actions.isEmpty
                ? Text(
                    FormatHelper.capitalize(s.permViewOnly),
                    style: StyleText.fontSize11Weight400
                        .copyWith(color: AppColors.secondaryText),
                  )
                : null,
            onChanged: (bool? v) => _toggleTab(p, v == true),
          ),
          if (selected.contains(p.key) && p.actions.isNotEmpty)
            // A Material (not a coloured Container) so the checkbox rows'
            // ink paints on this box instead of behind it.
            Padding(
              padding: EdgeInsetsDirectional.only(start: 28.w, bottom: 6.h),
              child: Material(
              color: AppColors.chip,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              clipBehavior: Clip.antiAlias,
              child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final AdminAction a in p.actions)
                    CheckboxListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.primary,
                      value: selected.contains(a.key),
                      title: Text(
                        FormatHelper.capitalize(a.label(context)),
                        style: StyleText.fontSize13Weight500,
                      ),
                      onChanged: (bool? v) => _toggleAction(a, v == true),
                    ),
                ],
              ),
              ),
              ),
            ),
        ],
      ],
    );
  }
}

/// The keys to write: the tabs and actions ticked, plus the 'v2' marker
/// (and no action whose tab is unticked).
Set<String> _toSave(Set<String> selected) => <String>{
      AdminPerms.v2Marker,
      for (final AdminPermission p in AdminPermission.values)
        if (selected.contains(p.key)) ...<String>[
          p.key,
          for (final AdminAction a in p.actions)
            if (selected.contains(a.key)) a.key,
        ],
    };

class _PermissionsDialog extends StatefulWidget {
  const _PermissionsDialog({required this.title, required this.initial});

  final String title;
  final Set<String> initial;

  @override
  State<_PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends State<_PermissionsDialog> {
  late Set<String> _selected = <String>{...widget.initial};

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(FormatHelper.capitalize('${s.editPermissions} · ${widget.title}'),
          style: StyleText.fontSize16Weight600),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: _PermissionPicker(
            selected: _selected,
            onChanged: (Set<String> v) => setState(() => _selected = v),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(FormatHelper.capitalize(s.cancel)),
        ),
        AppButton(
          label: s.save,
          dense: true,
          onPressed: () => Navigator.pop(context, _toSave(_selected)),
        ),
      ],
    );
  }
}

class _AdminFormDialog extends StatefulWidget {
  const _AdminFormDialog({required this.repo});

  final AdminsRepository repo;

  @override
  State<_AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends State<_AdminFormDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  Set<String> _perms = <String>{
    ...AdminPerms.fullTab(AdminPermission.dashboard),
    ...AdminPerms.fullTab(AdminPermission.videos),
    ...AdminPerms.fullTab(AdminPermission.quizzes),
  };
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final S s = S.of(context);
    final String email = _email.text.trim();
    if (_name.text.trim().isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = s.adminFormInvalid);
      return;
    }
    if (_password.text.length < 6) {
      setState(() => _error = s.adminPasswordShort);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repo.createAdmin(
        fullName: _name.text,
        email: email,
        password: _password.text,
        permissionKeys: _toSave(_perms),
      );
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _busy = false;
        _error = e.code == 'email-already-in-use'
            ? s.adminEmailInUse
            : (e.message ?? s.errUnknown);
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(FormatHelper.capitalize(s.addAdmin), style: StyleText.fontSize18Weight600),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CustomTextField(controller: _name, label: s.fullName),
              SizedBox(height: 10.h),
              CustomTextField(
                controller: _email,
                label: s.email,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 10.h),
              CustomTextField(
                controller: _password,
                label: s.password,
                obscureText: true,
              ),
              SizedBox(height: 14.h),
              Text(FormatHelper.capitalize(s.permissionsTitle), style: StyleText.fontSize14Weight600),
              _PermissionPicker(
                selected: _perms,
                onChanged: (Set<String> v) => setState(() => _perms = v),
              ),
              if (_error != null) ...<Widget>[
                SizedBox(height: 8.h),
                Text(
                  FormatHelper.capitalize(_error!),
                  style: StyleText.fontSize12Weight500
                      .copyWith(color: AppColors.red),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text(FormatHelper.capitalize(s.cancel)),
        ),
        AppButton(
          label: s.createAdmin,
          icon: Icons.check_rounded,
          dense: true,
          loading: _busy,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}
