/// Module: admin / a2_members
///
///*************************** FILE INFO ****************************///
/// File Name: members_page.dart
/// Purpose: Declares `MembersPage` — every account that has registered, as a
///          table the admin can search, filter and act on.
/// Author: ASEC team
/// Created: 19/9/2026
/// Updated: 20/9/2026 - Rebuilt on ConsolePage + AppDataTable. It was a
///          centred list of cards with two unlabelled switches and no page
///          title; the table is the app's own, the controls are dropdowns
///          that SAY what they do, and the page fills its width.
///
/// TWO POWERS, TWO COLUMNS. `Active` decides whether the account can get past
/// the splash at all; `CV form` decides whether it may write a CV. Both are
/// dropdowns rather than switches, because a switch is only honest when the
/// off state is obvious — here "off" is a policy, and it deserves a word.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/1-custom_dropdown.dart';
import 'package:asec/core/custom/100-custom_data_table.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/8-custom_filter_app.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/features/onboarding/o2_authentication/data/repository/auth_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/base_repository/auth_base_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/admin/a2_members/presentation/ui/pages/member_access_page.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/member_access.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/admin_permission.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final UsersBaseRepository _repository = UsersRepository();
  late final Stream<List<AppUser>> _members = _repository.watchMembers();

  static const String _all = '__all__';
  static const String _activeOnly = 'active';
  static const String _inactiveOnly = 'inactive';
  static const String _cvOnly = 'cv';

  String _filter = _all;
  String _query = '';
  String _sortKey = 'name';
  bool _ascending = true;

  List<AppUser> _visible(List<AppUser> all) {
    final String q = _query.trim().toLowerCase();

    final List<AppUser> rows = all.where((AppUser u) {
      switch (_filter) {
        case _activeOnly:
          if (!u.active) return false;
        case _inactiveOnly:
          if (u.active) return false;
        case _cvOnly:
          if (!u.canCreateCv) return false;
      }
      if (q.isEmpty) return true;
      return u.displayName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.phone.contains(q);
    }).toList();

    int compare(AppUser a, AppUser b) {
      switch (_sortKey) {
        case 'email':
          return a.email.toLowerCase().compareTo(b.email.toLowerCase());
        case 'joined':
          return (a.createdAt ?? DateTime(0))
              .compareTo(b.createdAt ?? DateTime(0));
        case 'name':
        default:
          return a.displayName
              .toLowerCase()
              .compareTo(b.displayName.toLowerCase());
      }
    }

    rows.sort((AppUser a, AppUser b) =>
        _ascending ? compare(a, b) : compare(b, a));
    return rows;
  }

  void _sort(String key) => setState(() {
        if (_sortKey == key) {
          _ascending = !_ascending;
        } else {
          _sortKey = key;
          _ascending = key != 'joined'; // newest first by default
        }
      });

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final AppUser me = SessionController.to.current;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<AppUser>>(
        stream: _members,
        builder: (BuildContext context, AsyncSnapshot<List<AppUser>> snapshot) {
          if (snapshot.hasError) return AppErrorView(message: s.errUnknown, error: snapshot.error, stackTrace: snapshot.stackTrace);
          if (!snapshot.hasData) return const AppLoading();

          final List<AppUser> all = snapshot.data!;
          final List<AppUser> rows = _visible(all);

          return ConsolePage(
            title: s.members,
            subtitle: s.membersSub,
            actions: <Widget>[
              ConsoleSearchField(
                hint: s.searchMembers,
                onChanged: (String value) => setState(() => _query = value),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Counts on the chips, so "how many are switched off" is
                // answered without changing the filter.
                ConsoleFilters(
                  selectedKey: _filter,
                  onSelected: (String key) => setState(() => _filter = key),
                  items: <StatusChipItem>[
                    StatusChipItem(
                      key: _all,
                      label: s.all,
                      count: all.length,
                    ),
                    StatusChipItem(
                      key: _activeOnly,
                      label: s.active,
                      count: all.where((AppUser u) => u.active).length,
                    ),
                    StatusChipItem(
                      key: _inactiveOnly,
                      label: s.inactive,
                      count: all.where((AppUser u) => !u.active).length,
                    ),
                    StatusChipItem(
                      key: _cvOnly,
                      label: s.cvColumn,
                      count: all.where((AppUser u) => u.canCreateCv).length,
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Expanded(
                  child: AppDataTable<AppUser>(
                    rows: rows,
                    showRowNumbers: true,
                    sortKey: _sortKey,
                    sortAscending: _ascending,
                    onSort: _sort,
                    rowHeight: 62.h,
                    emptyState: AppEmptyView(
                      title: all.isEmpty ? s.noMembersYet : s.noRowsMatch,
                      subtitle: all.isEmpty
                          ? s.noMembersYetSub
                          : s.noAttemptsMatchSub,
                      size: 140,
                    ),
                    columns: <AppTableColumn<AppUser>>[
                      AppTableColumn<AppUser>(
                        label: s.name,
                        flex: 3,
                        sortKey: 'name',
                        cell: (BuildContext context, AppUser u) => Row(
                          children: <Widget>[
                            AppAvatar(name: u.displayName, size: 34),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  AppTableCellText(
                                    u.displayName,
                                    emphasis: true,
                                  ),
                                  AppTableCellText(u.email),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppTableColumn<AppUser>(
                        label: s.phone,
                        flex: 2,
                        cell: (BuildContext context, AppUser u) =>
                            AppTableCellText(u.phone.isEmpty ? '—' : u.phone),
                      ),
                      AppTableColumn<AppUser>(
                        label: s.joinedLabel,
                        flex: 2,
                        sortKey: 'joined',
                        cell: (BuildContext context, AppUser u) =>
                            AppTableCellText(AppDates.day(context, u.createdAt)),
                      ),
                      AppTableColumn<AppUser>(
                        label: s.status,
                        fixedWidth: 150.w,
                        cell: (BuildContext context, AppUser u) => _ChoiceCell(
                          value: u.active,
                          trueLabel: s.active,
                          falseLabel: s.inactive,
                          trueColor: AppColors.green,
                          // Members → Activate / block.
                          onChanged: !me.canDo(AdminAction.membersBlock)
                              ? null
                              : (bool value) => _repository.setActive(u.uid, value),
                        ),
                      ),
                      AppTableColumn<AppUser>(
                        label: s.cvColumn,
                        fixedWidth: 160.w,
                        cell: (BuildContext context, AppUser u) => _ChoiceCell(
                          value: u.canCreateCv,
                          trueLabel: s.cvAllowed,
                          falseLabel: s.cvNotAllowed,
                          trueColor: AppColors.primary,
                          // CVs → Give CV rights.
                          onChanged: !me.canDo(AdminAction.cvsGrant)
                              ? null
                              : (bool value) => _repository.setCanCreateCv(u.uid, value),
                        ),
                      ),
                      // The engineering calculators are a paid extra: the
                      // admin unlocks them once the member has bought them.
                      AppTableColumn<AppUser>(
                        label: s.calcColumn,
                        fixedWidth: 170.w,
                        cell: (BuildContext context, AppUser u) => _ChoiceCell(
                          value: u.canUseCalcs,
                          trueLabel: s.calcAllowed,
                          falseLabel: s.calcNotAllowed,
                          trueColor: AppColors.primary,
                          // Members → Edit access.
                          onChanged: !me.canDo(AdminAction.membersAccess)
                              ? null
                              : (bool value) => _repository.setCanUseCalcs(u.uid, value),
                        ),
                      ),
                      // What the member may use: courses · devices · period,
                      // or "Paused". Tap to edit.
                      AppTableColumn<AppUser>(
                        label: s.memberAccess,
                        fixedWidth: 240.w,
                        cell: (BuildContext context, AppUser u) => _AccessCell(
                          member: u,
                          onTap: !(me.canDo(AdminAction.membersAccess) ||
                                  me.canDo(AdminAction.membersDevice))
                              ? () {}
                              : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => MemberAccessPage(member: u),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A yes/no cell as a DROPDOWN, not a switch: the two states are written out,
/// the current one is coloured, and changing it is one deliberate choice
/// rather than a flick that could happen by accident on a trackpad.
class _ChoiceCell extends StatelessWidget {
  const _ChoiceCell({
    required this.value,
    required this.trueLabel,
    required this.falseLabel,
    required this.trueColor,
    required this.onChanged,
  });

  final bool value;
  final String trueLabel;
  final String falseLabel;
  final Color trueColor;

  /// Null = this admin may not change it (shown, not editable).
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    // Same ground and ink as every chip; the word says the state.
    return CustomDropdown<bool>(
      value: value,
      height: 34.h,
      fillColor: AppColors.chip,
      valueStyle: StyleText.fontSize12Weight600.copyWith(color: AppColors.onChip),
      itemStyle: StyleText.fontSize12Weight500,
      enabled: onChanged != null,
      onChanged: (bool? next) {
        if (next != null && next != value) onChanged?.call(next);
      },
      items: <DropdownItem<bool>>[
        DropdownItem<bool>(value: true, label: trueLabel),
        DropdownItem<bool>(value: false, label: falseLabel),
      ],
    );
  }
}

/// "All courses · All devices · Permanent", "2 courses · Android · until 1 Nov",
/// or "Paused" — with a pencil to open the access page.
class _AccessCell extends StatelessWidget {
  const _AccessCell({required this.member, required this.onTap});

  final AppUser member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final DateTime now = DateTime.now();
    final bool expired = member.accessUntil != null && now.isAfter(member.accessUntil!);

    final String courses = member.allCourses
        ? s.accessAllCourses
        : s.accessCoursesCount(member.courses.length);
    // Not set = the default: Android and iPhone / iPad only.
    final String devices = (member.platforms.isEmpty
            ? MemberAccess.defaultPlatforms
            : member.platforms)
        .map(MemberAccess.platformLabel)
        .join(', ');
    final String period = member.isPaused
        ? s.accessPaused
        : expired
            ? s.accessExpiredShort
            : member.accessUntil != null
                ? s.accessUntilShort(AppDates.day(context, member.accessUntil))
                : s.accessPermanent;
    final Color periodColor = member.isPaused
        ? AppColors.statusPending
        : expired
            ? AppColors.red
            : AppColors.secondaryText;

    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  FormatHelper.capitalize('$courses · $devices'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StyleText.fontSize12Weight600.copyWith(color: AppColors.text),
                ),
                Text(
                  FormatHelper.capitalize(period),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StyleText.fontSize11Weight600.copyWith(color: periodColor),
                ),
              ],
            ),
          ),
          Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
        ],
      ),
    );
  }
}
