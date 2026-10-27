/// /admin/inbox — what visitors sent: contact messages, service requests,
/// job applications. Each item: new → read → done, reply by mail/WhatsApp.
library;

import 'package:flutter/material.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/web/admin/widgets.dart';
import 'package:asec/features/web/core/doc.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/features/web/core/widgets.dart';
import 'package:asec/features/web/data/site_repo.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/network/shared_stream.dart';

class InboxKind {
  const InboxKind(this.coll, this.label, this.icon, this.titleKey, this.fields);

  final String coll;
  final L label;
  final IconData icon;
  final String titleKey;

  /// key → label, in display order.
  final Map<String, L> fields;
}

const List<InboxKind> kInboxKinds = <InboxKind>[
  InboxKind(Coll.messages, L('رسائل التواصل', 'Messages'), Icons.mail_outline_rounded, 'name', <String, L>{
    'name': L('الاسم', 'Name'),
    'phone': L('الهاتف', 'Phone'),
    'email': L('البريد', 'E-mail'),
    'subject': L('الموضوع', 'Subject'),
    'message': L('الرسالة', 'Message'),
  }),
  InboxKind(Coll.serviceRequests, L('طلبات الخدمة', 'Service requests'), Icons.design_services_outlined, 'client_name',
      <String, L>{
        'client_name': L('اسم العميل', 'Client'),
        'company': L('اسم الشركة', 'Company'),
        'phone': L('الهاتف', 'Phone'),
        'email': L('البريد', 'E-mail'),
        'project_name': L('اسم المشروع', 'Project'),
        'project_type': L('نوع المشروع', 'Project type'),
        'services': L('الخدمات المطلوبة', 'Services'),
        'floors': L('عدد الطوابق', 'Floors'),
        'land_area': L('مساحة الأرض', 'Land area'),
        'location': L('مكان المشروع', 'Location'),
        'files_link': L('رابط الملفات', 'Files link'),
      }),
  InboxKind(Coll.jobApplications, L('طلبات التوظيف', 'Job applications'), Icons.work_outline_rounded, 'name', <String, L>{
    'name': L('الاسم', 'Name'),
    'phone': L('الهاتف', 'Phone'),
    'email': L('البريد', 'E-mail'),
    'request_type': L('نوع الطلب', 'Type'),
    'university': L('الجامعة', 'University'),
    'faculty': L('الكلية', 'Faculty'),
    'graduation_date': L('سنة التخرج', 'Graduation'),
    'grade': L('التقدير', 'Grade'),
    'residence': L('محل الإقامة', 'Residence'),
    'skills': L('المهارات', 'Skills'),
    'skill_level': L('المستوى', 'Level'),
    'experience_role': L('الخبرة السابقة', 'Experience'),
    'company': L('الشركة', 'Company'),
    'from': L('من', 'From'),
    'to': L('إلى', 'To'),
    'projects_link': L('رابط المشاريع', 'Portfolio'),
  }),
];

const Map<String, L> kStatuses = <String, L>{
  'new': L('جديد', 'New'),
  'read': L('تمت القراءة', 'Read'),
  'done': L('تم الرد', 'Done'),
};

Color statusColor(String s) => switch (s) {
      'new' => WebColors.red,
      'read' => WebColors.warning,
      _ => WebColors.success,
    };

class InboxPage extends StatelessWidget {
  const InboxPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: kInboxKinds.length,
      initialIndex: initialTab.clamp(0, kInboxKinds.length - 1).toInt(),
      child: AdminPageFrame(
        title: const L('الوارد', 'Inbox').t,
        icon: Icons.inbox_outlined,
        scroll: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: <Widget>[for (final InboxKind k in kInboxKinds) Tab(icon: AppIcon(k.icon), text: k.label.t)],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: <Widget>[for (final InboxKind k in kInboxKinds) _InboxList(kind: k)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InboxList extends StatefulWidget {
  const _InboxList({required this.kind});

  final InboxKind kind;

  @override
  State<_InboxList> createState() => _InboxListState();
}

class _InboxListState extends State<_InboxList> {
  late final Stream<List<Doc>> _stream = shared(() => SiteRepo.all(widget.kind.coll, by: SortBy.newest));
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Doc>>(
      stream: _stream,
      builder: (BuildContext context, AsyncSnapshot<List<Doc>> snap) {
        if (snap.hasError) return ErrorNote(snap.error);
        if (!snap.hasData) return const Loading();
        final List<Doc> items = snap.data!.where((Doc d) => _filter.isEmpty || d.s('status', 'new') == _filter).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: Text(FormatHelper.capitalize('${const L('الكل', 'All').t} (${snap.data!.length})')),
                  selected: _filter.isEmpty,
                  onSelected: (_) => setState(() => _filter = ''),
                ),
                for (final MapEntry<String, L> e in kStatuses.entries)
                  ChoiceChip(
                    label: Text(FormatHelper.capitalize('${e.value.t} (${snap.data!.where((Doc d) => d.s('status', 'new') == e.key).length})')),
                    selected: _filter == e.key,
                    onSelected: (_) => setState(() => _filter = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? EmptyNote(const L('لا يوجد شيء هنا', 'Nothing here').t)
                  : Card(
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (BuildContext c, int i) => InboxTile(kind: widget.kind, doc: items[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class InboxTile extends StatelessWidget {
  const InboxTile({super.key, required this.kind, required this.doc});

  final InboxKind kind;
  final Doc doc;

  @override
  Widget build(BuildContext context) {
    final String status = doc.s('status', 'new');
    final DateTime? at = doc.t('created_at');
    final String sub = <String>[
      doc.s('subject', doc.s('project_name', doc.s('request_type'))),
      doc.s('phone'),
    ].where((String s) => s.isNotEmpty).join('  ·  ');
    return ListTile(
      onTap: () => showInboxItem(context, kind, doc),
      leading: CircleAvatar(
        backgroundColor: statusColor(status).withValues(alpha: 0.12),
        child: AppIcon(kind.icon, color: statusColor(status)),
      ),
      title: Text(FormatHelper.capitalize(doc.s(kind.titleKey, '—')),
          style: TextStyle(fontWeight: status == 'new' ? FontWeight.w800 : FontWeight.w500)),
      subtitle: Text(FormatHelper.capitalize(sub), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: statusColor(status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(FormatHelper.capitalize(kStatuses[status]?.t ?? status), style: TextStyle(color: statusColor(status), fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4),
          Text(FormatHelper.capitalize(at == null ? '' : '${panelDate(at)} ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}'),
              style: TextStyle(fontSize: 11, color: WebColors.muted)),
        ],
      ),
    );
  }
}

Future<void> showInboxItem(BuildContext context, InboxKind kind, Doc doc) async {
  if (doc.s('status', 'new') == 'new') {
    SiteRepo.patch(kind.coll, doc.id, <String, dynamic>{'status': 'read'}).ignore();
  }
  final String email = doc.s('email');
  final String phone = doc.s('phone');
  await showDialog<void>(
    context: context,
    builder: (BuildContext c) => Directionality(
      textDirection: AppLang.direction,
      child: AlertDialog(
        title: Text(FormatHelper.capitalize(doc.s(kind.titleKey, kind.label.t))),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(FormatHelper.capitalize(panelDate(doc.t('created_at'))), style: TextStyle(color: WebColors.muted)),
                  const SizedBox(height: 10),
                  for (final MapEntry<String, L> f in kind.fields.entries)
                    if (doc.data[f.key] != null && '${doc.data[f.key]}'.isNotEmpty && '${doc.data[f.key]}' != '[]')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(FormatHelper.capitalize(f.value.t), style: TextStyle(color: WebColors.muted, fontSize: 12)),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                FormatHelper.capitalize(doc.data[f.key] is List ? doc.l(f.key).join(AppLang.isAr ? '، ' : ', ') : doc.s(f.key)),
                                style: const TextStyle(fontWeight: FontWeight.w600, height: 1.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
        actions: <Widget>[
          if (email.isNotEmpty)
            TextButton.icon(
              onPressed: () => openLink('mailto:$email'),
              icon: const AppIcon(Icons.reply_rounded),
              label: Text(FormatHelper.capitalize(const L('رد بالبريد', 'Reply by e-mail').t)),
            ),
          if (phone.isNotEmpty)
            TextButton.icon(
              onPressed: () => openLink(whatsappLink(phone)),
              icon: const AppIcon(Icons.chat_rounded),
              label: Text(FormatHelper.capitalize('WhatsApp')),
            ),
          PopupMenuButton<String>(
            tooltip: const L('الحالة', 'Status').t,
            onSelected: (String s) async {
              await guarded(c, () => SiteRepo.patch(kind.coll, doc.id, <String, dynamic>{'status': s}));
              if (c.mounted) Navigator.of(c).pop();
            },
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              for (final MapEntry<String, L> e in kStatuses.entries) PopupMenuItem<String>(value: e.key, child: Text(FormatHelper.capitalize(e.value.t))),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(FormatHelper.capitalize(const L('تغيير الحالة', 'Set status').t), style: TextStyle(color: WebColors.navy, fontWeight: FontWeight.w700)),
            ),
          ),
          IconButton(
            tooltip: const L('حذف', 'Delete').t,
            onPressed: () async {
              final bool ok = await confirm(c, const L('حذف؟', 'Delete?').t, const L('سيُحذف نهائيًا.', 'This cannot be undone.').t);
              if (!ok) return;
              await guarded(c, () => SiteRepo.remove(kind.coll, doc.id));
              if (c.mounted) Navigator.of(c).pop();
            },
            icon: const AppIcon(Icons.delete_outline_rounded, color: WebColors.red),
          ),
          TextButton(onPressed: () => Navigator.of(c).pop(), child: Text(FormatHelper.capitalize(const L('إغلاق', 'Close').t))),
        ],
      ),
    ),
  );
}

/// The five newest items across the three inboxes (dashboard).
class LatestInbox extends StatelessWidget {
  const LatestInbox({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          for (final InboxKind k in kInboxKinds)
            StreamBuilder<List<Doc>>(
              stream: SiteRepo.all(k.coll, by: SortBy.newest),
              builder: (BuildContext c, AsyncSnapshot<List<Doc>> s) {
                final List<Doc> d = (s.data ?? const <Doc>[]).take(3).toList();
                if (d.isEmpty) return const SizedBox.shrink();
                return Column(children: <Widget>[for (final Doc x in d) InboxTile(kind: k, doc: x)]);
              },
            ),
        ],
      ),
    );
  }
}
