/// /admin/admins — super admin only. Lists the admins created in the ASEC
/// app and switches the `website` permission that opens this panel.
///
/// "Add admin" creates a new login (name, email, password) with the
/// permissions ticked — the same as the app's Settings → Admins → Add admin
/// (AdminsRepository.createAdmin: the account is made on a secondary
/// Firebase app, so the super admin stays signed in).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
import 'package:asec/features/settings/se1_settings/data/admins_repository.dart';
import 'package:asec/features/web/admin/admin_session.dart';
import 'package:asec/features/web/admin/widgets.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/features/web/core/widgets.dart';
import 'package:asec/features/web/data/site_repo.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

class AdminsPage extends StatelessWidget {
  const AdminsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPageFrame(
      title: const L('المشرفون', 'Admins').t,
      icon: Icons.admin_panel_settings_outlined,
      subtitle: const L('أضف مشرفًا جديدًا (بريد وكلمة مرور) واختر ما يديره. مفتاح "الموقع" يفتح له لوحة الموقع.',
              'Add a new admin (email and password) and pick what they manage. "Website" opens this panel to them.')
          .t,
      actions: <Widget>[
        FilledButton.icon(
          onPressed: () async {
            final bool? ok = await showDialog<bool>(context: context, builder: (_) => const _NewAdminDialog());
            if (ok == true && context.mounted) {
              AppMessenger.of(context).show(AppMessage(
                content: Text(FormatHelper.capitalize(const L('تم إنشاء المشرف', 'Admin created').t)),
                backgroundColor: WebColors.success,
              ));
            }
          },
          icon: const AppIcon(Icons.person_add_alt_1_rounded, color: WebColors.white, size: 20),
          label: Text(FormatHelper.capitalize(const L('إضافة مشرف', 'Add admin').t)),
        ),
      ],
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: SiteRepo.db.collection(Coll.users).where('role', isEqualTo: 'admin').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snap) {
          if (snap.hasError) return ErrorNote(snap.error);
          if (!snap.hasData) return const Loading();
          final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snap.data!.docs
              .where((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                  '${d.data()['email'] ?? ''}'.toLowerCase() != kSuperAdminEmail)
              .toList();
          return Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const CircleAvatar(backgroundColor: WebColors.red, child: AppIcon(Icons.shield_rounded, color: Colors.white)),
                  title: Text(FormatHelper.capitalize(kSuperAdminEmail), style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(FormatHelper.capitalize(const L('المشرف الرئيسي — كل الصلاحيات', 'Super admin — everything').t)),
                ),
                if (docs.isEmpty)
                  EmptyNote(const L('لا يوجد مشرفون آخرون بعد', 'No other admins yet').t)
                else
                  for (final QueryDocumentSnapshot<Map<String, dynamic>> d in docs) ...<Widget>[
                    const Divider(),
                    _AdminRow(id: d.id, data: d.data()),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdminRow extends StatelessWidget {
  const _AdminRow({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final List<String> perms = data['permissions'] is List
        ? (data['permissions'] as List<dynamic>).map((dynamic e) => '$e').toList()
        : <String>[];
    final bool web = perms.contains(kWebsitePermission);
    final bool active = data['active'] == true;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: WebColors.navy.withValues(alpha: 0.1),
        child: AppIcon(Icons.person_outline_rounded, color: WebColors.navy),
      ),
      title: Text(FormatHelper.capitalize('${data['full_name'] ?? '—'}'), style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(FormatHelper.capitalize('${data['email'] ?? ''}  ·  ${perms.join(', ')}${active ? '' : '  ·  ${const L('موقوف', 'switched off').t}'}')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(FormatHelper.capitalize(const L('الموقع', 'Website').t), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Switch(
            value: web,
            onChanged: (bool v) {
              // The tab and all its actions ('website.content', …).
              final List<String> next = <String>[
                ...perms.where((String p) =>
                    p != kWebsitePermission && !p.startsWith('$kWebsitePermission.')),
                if (v) ...AdminPerms.fullTab(AdminPermission.website),
              ];
              guarded(
                context,
                () => SiteRepo.db.collection(Coll.users).doc(id).update(<String, dynamic>{
                  'permissions': next,
                  'updated_at': FieldValue.serverTimestamp(),
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Add admin ───────────────────────────────────────────────────────────────

const Map<AdminPermission, L> _permLabels = <AdminPermission, L>{
  AdminPermission.dashboard: L('لوحة المعلومات', 'Dashboard'),
  AdminPermission.videos: L('الفيديوهات', 'Videos'),
  AdminPermission.quizzes: L('الاختبارات', 'Quizzes'),
  AdminPermission.results: L('النتائج', 'Results'),
  AdminPermission.members: L('الأعضاء', 'Members'),
  AdminPermission.cvs: L('السير الذاتية', 'CVs'),
  AdminPermission.engagement: L('التفاعل', 'Engagement'),
  AdminPermission.website: L('الموقع الإلكتروني', 'Website'),
};

class _NewAdminDialog extends StatefulWidget {
  const _NewAdminDialog();

  @override
  State<_NewAdminDialog> createState() => _NewAdminDialogState();
}

class _NewAdminDialogState extends State<_NewAdminDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final Set<AdminPermission> _perms = <AdminPermission>{AdminPermission.website};
  bool _busy = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String email = _email.text.trim();
    if (_name.text.trim().isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = const L('اكتب الاسم وبريدًا صحيحًا.', 'Enter a name and a valid email.').t);
      return;
    }
    if (_password.text.length < 6) {
      setState(() => _error = const L('كلمة المرور 6 أحرف على الأقل.', 'The password needs at least 6 characters.').t);
      return;
    }
    if (_perms.isEmpty) {
      setState(() => _error = const L('اختر صلاحية واحدة على الأقل.', 'Pick at least one permission.').t);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AdminsRepository().createAdmin(
        fullName: _name.text,
        email: email,
        password: _password.text,
        // Every action of each ticked tab; fine-tune them in the app
        // (Settings → Admins → Edit permissions).
        permissionKeys: <String>{
          AdminPerms.v2Marker,
          for (final AdminPermission p in _perms) ...AdminPerms.fullTab(p),
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _busy = false;
        _error = e.code == 'email-already-in-use'
            ? const L('هذا البريد مستخدم لحساب آخر.', 'That email already has an account.').t
            : (e.message ?? e.code);
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = describeError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppLang.direction,
      child: AlertDialog(
        title: Row(
          children: <Widget>[
            const AppIcon(Icons.person_add_alt_1_rounded, color: WebColors.red),
            const SizedBox(width: 10),
            Text(FormatHelper.capitalize(const L('إضافة مشرف', 'Add admin').t)),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _name,
                  enabled: !_busy,
                  decoration: InputDecoration(labelText: const L('الاسم', 'Full name').t),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(labelText: const L('البريد الإلكتروني', 'Email').t),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: _hide,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: const L('كلمة المرور', 'Password').t,
                    helperText: const L('أرسلها له ليدخل بها التطبيق والموقع.', 'Send it to them to sign in.').t,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _hide = !_hide),
                      icon: AppIcon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(FormatHelper.capitalize(const L('يستطيع إدارة', 'May manage').t),
                    style: TextStyle(fontWeight: FontWeight.w800, color: WebColors.navy)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final AdminPermission p in AdminPermission.values)
                      FilterChip(
                        selected: _perms.contains(p),
                        showCheckmark: false,
                        avatar: AppIcon(p.icon, size: 18,
                            color: _perms.contains(p) ? WebColors.white : WebColors.ink),
                        label: Text(FormatHelper.capitalize(_permLabels[p]?.t ?? p.key)),
                        labelStyle: TextStyle(
                          color: _perms.contains(p) ? WebColors.white : WebColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                        selectedColor: WebColors.red,
                        onSelected: _busy
                            ? null
                            : (bool on) => setState(() => on ? _perms.add(p) : _perms.remove(p)),
                      ),
                  ],
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 14),
                  Text(FormatHelper.capitalize(_error!), style: const TextStyle(color: WebColors.red, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: Text(FormatHelper.capitalize(const L('إلغاء', 'Cancel').t)),
          ),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: WebColors.white))
                : Text(FormatHelper.capitalize(const L('إنشاء المشرف', 'Create admin').t)),
          ),
        ],
      ),
    );
  }
}
