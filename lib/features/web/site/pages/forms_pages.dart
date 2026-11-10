/// تواصل معنا · طلب خدمة · طلب وظيفة — the three public forms. Each writes
/// one document to Firestore; the panel's Inbox shows it.
///
/// Fields are the same as the WPForms / Elementor forms on asecbim.com.
///
/// LANGUAGE: labels follow the site's language; the choices of a list are
/// always SAVED in Arabic (`L.ar`), so the panel's Inbox reads the same
/// whichever language the visitor used.
library;

import 'package:flutter/material.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/web/core/builtin_en.dart';
import 'package:asec/features/web/core/doc.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/features/web/core/widgets.dart';
import 'package:asec/features/web/data/site_repo.dart';
import 'package:asec/features/web/site/site_shell.dart';
import 'package:asec/features/web/site/widgets/cards.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

// ── A tiny form kit ──────────────────────────────────────────────────────

/// Thrown from `onSubmit` to show a specific message instead of the generic one.
class FormMessage implements Exception {
  const FormMessage(this.text);

  final String text;
}

String? _required(String? v) =>
    (v == null || v.trim().isEmpty) ? const L('هذا الحقل مطلوب', 'This field is required').t : null;

String? _email(String? v) {
  if (_required(v) != null) return _required(v);
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim()) ? null
      : const L('بريد إلكتروني غير صحيح', 'Invalid e-mail address').t;
}

class _Labeled extends StatelessWidget {
  const _Labeled(this.label, this.child, {this.isRequired = true});

  final String label;
  final Widget child;
  final bool isRequired;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text.rich(TextSpan(children: <InlineSpan>[
            TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: WebColors.red)),
          ])),
          const SizedBox(height: 6),
          child,
        ],
      );
}

class _Text extends StatelessWidget {
  const _Text(this.label, this.c,
      {this.hint = '', this.isRequired = true, this.lines = 1, this.email = false, this.phone = false});

  final String label;
  final TextEditingController c;
  final String hint;
  final bool isRequired;
  final int lines;
  final bool email;
  final bool phone;

  @override
  Widget build(BuildContext context) => _Labeled(
        label,
        TextFormField(
          controller: c,
          maxLines: lines,
          maxLength: lines > 1 ? 3000 : 200,
          buildCounter: (_, {required int currentLength, required bool isFocused, int? maxLength}) => null,
          keyboardType: email
              ? TextInputType.emailAddress
              : (phone ? TextInputType.phone : (lines > 1 ? TextInputType.multiline : TextInputType.text)),
          textDirection: (email || phone) ? TextDirection.ltr : null,
          decoration: InputDecoration(hintText: hint.isEmpty ? label : hint),
          validator: email ? _email : (isRequired ? _required : null),
        ),
        isRequired: isRequired,
      );
}

/// A drop-down. Shows `o.t`, saves `o.ar`.
class _Select extends StatelessWidget {
  const _Select(this.label, this.options, this.value, this.onChanged);

  final String label;
  final List<L> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => _Labeled(
        label,
        DropdownButtonFormField<String>(
          initialValue: value,
          icon: const AppIcon(Icons.keyboard_arrow_down_rounded),
          items: <DropdownMenuItem<String>>[
            for (final L o in options) DropdownMenuItem<String>(value: o.ar, child: Text(FormatHelper.capitalize(o.t))),
          ],
          onChanged: onChanged,
          validator: (String? v) => v == null ? const L('اختر من القائمة', 'Choose from the list').t : null,
          decoration: const InputDecoration(),
        ),
      );
}

/// Several choices. Shows `o.t`, saves `o.ar`.
class _Checks extends StatelessWidget {
  const _Checks(this.label, this.options, this.selected, this.onChanged);

  final String label;
  final List<L> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) => _Labeled(
        label,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final L o in options)
              FilterChip(
                label: Text(FormatHelper.capitalize(o.t)),
                selected: selected.contains(o.ar),
                onSelected: (bool on) {
                  final Set<String> next = Set<String>.of(selected);
                  on ? next.add(o.ar) : next.remove(o.ar);
                  onChanged(next);
                },
              ),
          ],
        ),
      );
}

class _DateField extends StatelessWidget {
  const _DateField(this.label, this.value, this.onChanged);

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => _Labeled(
        label,
        FormField<DateTime>(
          validator: (_) => value == null ? const L('اختر التاريخ', 'Pick a date').t : null,
          builder: (FormFieldState<DateTime> st) => InkWell(
            onTap: () async {
              final DateTime? d = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime(1970),
                lastDate: DateTime(DateTime.now().year + 5),
              );
              if (d != null) {
                onChanged(d);
                st.didChange(d);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                errorText: st.errorText,
                suffixIcon: const AppIcon(Icons.calendar_month_rounded),
              ),
              child: Text(FormatHelper.capitalize(value == null ? const L('اختر', 'Pick').t : '${value!.year}/${value!.month}/${value!.day}')),
            ),
          ),
        ),
      );
}

/// Two fields side by side on wide screens, stacked on phones.
class _Row extends StatelessWidget {
  const _Row(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      GridOf(cols: context.isMobile ? 1 : children.length, gap: 16, children: children);
}

/// The frame every form sits in: header, card, send button, thank-you.
class _FormPage extends StatefulWidget {
  const _FormPage({
    required this.title,
    required this.intro,
    required this.enabledKey,
    required this.fields,
    required this.onSubmit,
    this.side,
  });

  final String title;
  final String intro;
  final String enabledKey;
  final Widget Function(BuildContext context, VoidCallback refresh) fields;
  final Future<void> Function() onSubmit;
  final Widget? side;

  @override
  State<_FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<_FormPage> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  bool _sending = false;
  bool _sent = false;
  String? _error;

  Future<void> _send() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.onSubmit();
      setState(() => _sent = true);
    } on FormMessage catch (e) {
      setState(() => _error = e.text);
    } catch (e) {
      setState(() => _error = const L('تعذر الإرسال، حاول مرة أخرى.', 'Could not send. Please try again.').t);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WithSettings(
      builder: (BuildContext context, Doc s) {
        final bool open = s.b(widget.enabledKey);
        final Widget card = Card(
          child: Padding(
            padding: EdgeInsets.all(context.isMobile ? 18 : 32),
            child: !open
                ? EmptyNote(const L('هذا النموذج مغلق حاليًا', 'This form is currently closed').t,
                    icon: Icons.lock_outline_rounded)
                : _sent
                    ? Column(
                        children: <Widget>[
                          const AppIcon(Icons.check_circle_rounded, color: WebColors.success, size: 64),
                          const SizedBox(height: 12),
                          Text(FormatHelper.capitalize(const L('تم الإرسال بنجاح', 'Sent successfully').t),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(FormatHelper.capitalize(const L('شكرًا لك، سنتواصل معك قريبًا.', 'Thank you — we will get back to you soon.').t),
                              style: TextStyle(color: WebColors.muted)),
                          const SizedBox(height: 18),
                          OutlinedButton(
                            onPressed: () => setState(() => _sent = false),
                            child: Text(FormatHelper.capitalize(const L('إرسال طلب آخر', 'Send another').t)),
                          ),
                        ],
                      )
                    : Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            widget.fields(context, () => setState(() {})),
                            const SizedBox(height: 24),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(FormatHelper.capitalize(_error!), style: const TextStyle(color: WebColors.red)),
                              ),
                            ElevatedButton(
                              onPressed: _sending ? null : _send,
                              child: _sending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(FormatHelper.capitalize(const L('ارسال الطلب', 'Submit').t)),
                            ),
                          ],
                        ),
                      ),
          ),
        );
        return SitePage(
          cta: false,
          children: <Widget>[
            PageHeader(widget.title),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 44),
              child: Contained(
                maxWidth: widget.side == null ? 900 : 1200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (widget.intro.isNotEmpty) ...<Widget>[
                      Text(FormatHelper.capitalize(widget.intro),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, height: 1.9, color: WebColors.muted)),
                      const SizedBox(height: 28),
                    ],
                    if (widget.side == null || context.isMobile) ...<Widget>[
                      if (widget.side != null) ...<Widget>[widget.side!, const SizedBox(height: 24)],
                      card,
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(width: 360, child: widget.side),
                          const SizedBox(width: 28),
                          Expanded(child: card),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Text(
                        FormatHelper.capitalize(const L('يجب عليك قبل ارسال الطلب قراءة سياسة الخصوصية الخاصة بموقعنا الالكتروني',
                                'Please read our privacy policy before submitting.')
                            .t),
                        textAlign: TextAlign.center, style: TextStyle(color: WebColors.muted, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── تواصل معنا ───────────────────────────────────────────────────────────

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _message = TextEditingController();

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[_name, _phone, _email, _subject, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _info(IconData icon, String title, List<String> lines, {String Function(String)? link}) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                backgroundColor: WebColors.red.withValues(alpha: 0.1),
                child: AppIcon(icon, color: WebColors.red),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(FormatHelper.capitalize(title), style: const TextStyle(fontWeight: FontWeight.w800)),
                    for (final String l in lines)
                      InkWell(
                        onTap: link == null ? null : () => openLink(link(l)),
                        child: Text(FormatHelper.capitalize(l), style: TextStyle(color: WebColors.muted, height: 1.8)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => WithSettings(builder: _build);

  Widget _build(BuildContext context, Doc s) {
    return _FormPage(
      title: const L('تواصل معنا', 'Contact Us').t,
      intro: s.txt('contact_title',
          const L('تواصل مع أسيك للإستشارات الهندسية', 'Get in touch with ASEC Engineering Consultants')),
      enabledKey: 'accept_messages',
      side: Column(
        children: <Widget>[
          _info(Icons.location_on_rounded, const L('المكتب الرئيسي', 'Head office').t, <String>[s.s('address')]),
          const SizedBox(height: 12),
          _info(Icons.email_rounded, const L('ارسل لنا عبر البريد الإلكتروني', 'E-mail us').t, s.l('emails'),
              link: (String e) => 'mailto:$e'),
          const SizedBox(height: 12),
          _info(Icons.phone_rounded, const L('تحدث معانا', 'Call us').t, sitePhones(s.raw('phone')), link: telLink),
          const SizedBox(height: 16),
          SocialIcons(settings: s),
        ],
      ),
      fields: (BuildContext c, VoidCallback refresh) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(FormatHelper.capitalize(const L('أرسل لنا رسالة', 'Send us a message').t),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          _Row(<Widget>[
            _Text(const L('اسم', 'Name').t, _name),
            _Text(const L('هاتف', 'Phone').t, _phone, phone: true),
          ]),
          const SizedBox(height: 16),
          _Row(<Widget>[
            _Text(const L('بريد إلكتروني', 'E-mail').t, _email, email: true),
            _Text(const L('موضوع', 'Subject').t, _subject),
          ]),
          const SizedBox(height: 16),
          _Text(const L('رسالة', 'Message').t, _message, lines: 6),
        ],
      ),
      onSubmit: () async {
        await SiteRepo.submit(Coll.messages, <String, dynamic>{
          'name': _name.text.trim(),
          'phone': _phone.text.trim(),
          'email': _email.text.trim(),
          'subject': _subject.text.trim(),
          'message': _message.text.trim(),
        });
        for (final TextEditingController c in <TextEditingController>[_name, _phone, _email, _subject, _message]) {
          c.clear();
        }
      },
    );
  }
}

// ── طلب خدمة ─────────────────────────────────────────────────────────────

class ServiceRequestPage extends StatefulWidget {
  const ServiceRequestPage({super.key});

  @override
  State<ServiceRequestPage> createState() => _ServiceRequestPageState();
}

class _ServiceRequestPageState extends State<ServiceRequestPage> {
  final Map<String, TextEditingController> _c = <String, TextEditingController>{
    for (final String k in <String>[
      'client_name', 'company', 'phone', 'project_name', 'email', 'floors', 'land_area', 'location', 'files_link',
    ])
      k: TextEditingController(),
  };
  String? _type;
  Set<String> _services = <String>{};

  @override
  void dispose() {
    for (final TextEditingController c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormPage(
      title: const L('نموذج طلب خدمة', 'Service Request Form').t,
      intro: const L(
              'النموذج يحتوي على عدة حقول يجب ملؤها بالمعلومات المطلوبة. اضغط "ارسال الطلب" بعد ملء الحقول لإرسال الطلب.',
              'Fill in the fields below, then press "Submit" to send your request.')
          .t,
      enabledKey: 'accept_service_requests',
      fields: (BuildContext c, VoidCallback refresh) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Row(<Widget>[
            _Text(const L('اسم العميل', 'Client name').t, _c['client_name']!, hint: const L('اسمك', 'Your name').t),
            _Text(const L('اسم الشركة', 'Company name').t, _c['company']!),
          ]),
          const SizedBox(height: 16),
          _Row(<Widget>[
            _Text(const L('رقم الهاتف', 'Phone number').t, _c['phone']!, phone: true),
            _Text(const L('اسم المشروع', 'Project name').t, _c['project_name']!),
          ]),
          const SizedBox(height: 16),
          _Row(<Widget>[
            _Select(
                const L('نوع المشروع', 'Project type').t,
                const <L>[
                  L('طبي', 'Medical'),
                  L('سكني', 'Residential'),
                  L('تجاري', 'Commercial'),
                  L('اداري', 'Administrative'),
                  L('صناعي', 'Industrial'),
                ],
                _type,
                (String? v) => setState(() => _type = v)),
            _Text(const L('البريد الالكتروني', 'E-mail').t, _c['email']!, email: true),
          ]),
          const SizedBox(height: 26),
          Text(FormatHelper.capitalize(const L('بيانات عامة عن المشروع', 'Project overview').t),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          _Row(<Widget>[
            _Text(const L('عدد الطوابق', 'Number of floors').t, _c['floors']!,
                hint: const L('ضع هنا عدد الطوابق', 'Enter the number of floors').t),
            _Text(const L('مساحة الأرض', 'Land area').t, _c['land_area']!,
                hint: const L('ضع هنا مساحة الأرض', 'Enter the land area').t),
          ]),
          const SizedBox(height: 16),
          _Checks(
              const L('نوع الخدمة المطلوبة', 'Services required').t,
              const <L>[
                L('تصميم', 'Design'),
                L('شوب دروينج', 'Shop drawings'),
                L('اشراف على التنفيذ', 'Site supervision'),
              ],
              _services,
              (Set<String> v) => setState(() => _services = v)),
          const SizedBox(height: 16),
          _Row(<Widget>[
            _Text(const L('مكان المشروع', 'Project location').t, _c['location']!,
                hint: const L('ضع هنا مكان المشروع', 'Enter the project location').t),
            _Text(const L('رجاء وضع رابط ملفات المشروع', 'Link to the project files').t, _c['files_link']!,
                hint: 'https://'),
          ]),
        ],
      ),
      onSubmit: () async {
        if (_services.isEmpty) {
          throw FormMessage(const L('اختر نوع الخدمة المطلوبة', 'Choose the service you need').t);
        }
        final Map<String, dynamic> data = <String, dynamic>{
          for (final MapEntry<String, TextEditingController> e in _c.entries) e.key: e.value.text.trim(),
          'project_type': _type ?? '',
          'services': _services.toList(),
        };
        await SiteRepo.submit(Coll.serviceRequests, data);
        // AND BY E-MAIL to info@: a `mail` document, sent by the Firebase
        // "Trigger Email" extension. A failure here never fails the form —
        // the request is already saved in the inbox.
        try {
          await SiteRepo.mailServiceRequest(data);
        } catch (_) {}
      },
    );
  }
}

// ── طلب وظيفة ────────────────────────────────────────────────────────────

class JobRequestPage extends StatefulWidget {
  const JobRequestPage({super.key});

  @override
  State<JobRequestPage> createState() => _JobRequestPageState();
}

class _JobRequestPageState extends State<JobRequestPage> {
  final Map<String, TextEditingController> _c = <String, TextEditingController>{
    for (final String k in <String>[
      'name', 'university', 'faculty', 'residence', 'email', 'phone', 'skills', 'company', 'projects_link',
    ])
      k: TextEditingController(),
  };
  DateTime? _graduation;
  DateTime? _from;
  DateTime? _to;
  String? _grade;
  String? _type;
  String? _level;
  String? _role;

  @override
  void dispose() {
    for (final TextEditingController c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _d(DateTime? d) => d == null ? '' : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return _FormPage(
      title: const L('نموذج طلب وظيفة', 'Job Application Form').t,
      intro: const L(
              'النموذج يحتوي على عدة حقول يجب ملؤها بالمعلومات المطلوبة. اضغط "ارسال الطلب" بعد ملء الحقول لإرسال طلب الحصول على وظيفة.',
              'Fill in the fields below, then press "Submit" to send your application.')
          .t,
      enabledKey: 'accept_job_applications',
      fields: (BuildContext c, VoidCallback refresh) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Row(<Widget>[
            _Text(const L('الاسم', 'Name').t, _c['name']!, hint: const L('اسمك', 'Your name').t),
            _Text(const L('الجامعة', 'University').t, _c['university']!),
          ]),
          const SizedBox(height: 16),
          _Row(<Widget>[
            _Text(const L('الكلية', 'Faculty').t, _c['faculty']!),
            _DateField(const L('سنة التخرج', 'Graduation date').t, _graduation,
                (DateTime d) => setState(() => _graduation = d)),
          ]),
          const SizedBox(height: 16),
          _Row(<Widget>[
            _Select(
                const L('التقدير العام', 'Overall grade').t,
                const <L>[
                  L('امتياز', 'Excellent'),
                  L('جيد جدا', 'Very good'),
                  L('جيد', 'Good'),
                  L('مقبول', 'Pass'),
                ],
                _grade,
                (String? v) => setState(() => _grade = v)),
            _Text(const L('محل الاقامة', 'Place of residence').t, _c['residence']!),
          ]),
          const SizedBox(height: 16),
          _Row(<Widget>[
            _Text(const L('البريد الالكتروني', 'E-mail').t, _c['email']!, email: true),
            _Text(const L('رقم الهاتف', 'Phone number').t, _c['phone']!, phone: true),
          ]),
          const SizedBox(height: 16),
          _Row(<Widget>[
            _Select(const L('نوع الطلب', 'Application type').t,
                const <L>[L('وظيفة', 'Job'), L('معايشة', 'Training placement')], _type,
                (String? v) => setState(() => _type = v)),
            _Select(const L('مستوى', 'Level').t,
                const <L>[L('مبتدئ', 'Beginner'), L('متوسط', 'Intermediate'), L('متقدم', 'Advanced')], _level,
                (String? v) => setState(() => _level = v)),
          ]),
          const SizedBox(height: 16),
          _Text(const L('ابرز المهارات', 'Key skills').t, _c['skills']!,
              hint: const L('مثال ( اتوكاد- ريفت- تصميم .....الخ )', 'e.g. AutoCAD, Revit, design…').t),
          const SizedBox(height: 26),
          Text(FormatHelper.capitalize(const L('الخبرة السابقة', 'Previous experience').t),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          _Row(<Widget>[
            _Select(
                const L('الخبرة السابقة', 'Previous role').t,
                const <L>[
                  L('مهندس تصميم', 'Design engineer'),
                  L('مهندس تنفيذ', 'Site engineer'),
                  L('مهندس مكتب فني', 'Technical office engineer'),
                  L('مهندس متدرب', 'Trainee engineer'),
                ],
                _role,
                (String? v) => setState(() => _role = v)),
            _Text(const L('إسم الشركة', 'Company name').t, _c['company']!),
          ]),
          const SizedBox(height: 16),
          _Row(<Widget>[
            _DateField(const L('من', 'From').t, _from, (DateTime d) => setState(() => _from = d)),
            _DateField(const L('إلي', 'To').t, _to, (DateTime d) => setState(() => _to = d)),
          ]),
          const SizedBox(height: 16),
          _Text(const L('ابرز المشاريع التي شاركت فيها', 'Main projects you worked on').t, _c['projects_link']!,
              hint: const L('ضع رابط البرتفويلو الخاص بك', 'Link to your portfolio').t),
        ],
      ),
      onSubmit: () => SiteRepo.submit(Coll.jobApplications, <String, dynamic>{
        for (final MapEntry<String, TextEditingController> e in _c.entries) e.key: e.value.text.trim(),
        'graduation_date': _d(_graduation),
        'grade': _grade ?? '',
        'request_type': _type ?? '',
        'skill_level': _level ?? '',
        'experience_role': _role ?? '',
        'from': _d(_from),
        'to': _d(_to),
      }),
    );
  }
}
