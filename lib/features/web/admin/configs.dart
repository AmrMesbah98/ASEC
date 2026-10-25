/// What every content section of the panel edits. Adding a field to the site
/// = add a FieldSpec here and read it on the page.
library;

import 'package:flutter/material.dart';

import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/data/site_repo.dart';
import 'package:asec/features/web/admin/fields.dart';

class CollectionConfig {
  const CollectionConfig({
    required this.coll,
    required this.title,
    required this.icon,
    required this.specs,
    this.titleKey = 'title',
    this.subtitleKey,
    this.imageKey,
    this.sort = SortBy.order,
    this.publicPath,
  });

  final String coll;
  final L title;
  final IconData icon;
  final List<FieldSpec> specs;
  final String titleKey;
  final String? subtitleKey;
  final String? imageKey;
  final SortBy sort;

  /// Builds the public URL of an item, for the "open on site" button.
  final String Function(String id, Map<String, dynamic> data)? publicPath;

  /// Every field empty — including the English twins.
  Map<String, dynamic> blank() => blankValues(specs);
}

const FieldSpec _published = FieldSpec('published', L('منشور على الموقع', 'Published on the site'), FieldType.boolean);
const FieldSpec _order = FieldSpec('order', L('الترتيب', 'Order'), FieldType.number,
    hint: L('الأصغر يظهر أولًا', 'Smaller shows first'));

final CollectionConfig servicesConfig = CollectionConfig(
  coll: Coll.services,
  title: const L('الخدمات', 'Services'),
  icon: Icons.design_services_rounded,
  subtitleKey: 'tagline',
  imageKey: 'image_url',
  publicPath: (String id, Map<String, dynamic> d) => '/services/${d['slug'] ?? id}',
  specs: const <FieldSpec>[
    FieldSpec('title', L('العنوان', 'Title'), FieldType.text, isRequired: true),
    FieldSpec('slug', L('الرابط المختصر', 'Slug (URL)'), FieldType.text,
        rtl: false, isRequired: true, hint: L('مثال: integrated-design → /services/integrated-design', 'e.g. integrated-design')),
    FieldSpec('tagline', L('الجملة التعريفية', 'Tagline'), FieldType.text),
    FieldSpec('image_url', L('الصورة', 'Image'), FieldType.image),
    FieldSpec('body', L('النص', 'Body'), FieldType.multiline),
    FieldSpec('points', L('اهم النقاط', 'Key points'), FieldType.stringList),
    _order,
    _published,
  ],
);

final CollectionConfig featuresConfig = CollectionConfig(
  coll: Coll.features,
  title: const L('مميزات العمل معنا', 'Why us'),
  icon: Icons.star_outline_rounded,
  imageKey: 'icon_url',
  specs: const <FieldSpec>[
    FieldSpec('title', L('العنوان', 'Title'), FieldType.text, isRequired: true),
    FieldSpec('icon_url', L('الأيقونة', 'Icon'), FieldType.image),
    _order,
    _published,
  ],
);

final CollectionConfig projectsConfig = CollectionConfig(
  coll: Coll.projects,
  title: const L('الأعمال', 'Projects'),
  icon: Icons.apartment_rounded,
  subtitleKey: 'client',
  imageKey: 'cover',
  publicPath: (String id, _) => '/projects/$id',
  specs: const <FieldSpec>[
    FieldSpec('title', L('اسم المشروع', 'Project name'), FieldType.text, isRequired: true),
    FieldSpec('category', L('القسم', 'Category'), FieldType.select, options: <String, L>{
      'medical': L('طبي', 'Medical'),
      'residential': L('سكني', 'Residential'),
      'commercial': L('تجاري', 'Commercial'),
      'industrial': L('صناعي', 'Industrial'),
    }),
    FieldSpec('cover', L('صورة الغلاف', 'Cover image'), FieldType.image),
    FieldSpec.section(L('بيانات المشروع', 'Details')),
    FieldSpec('client', L('اسم العميل', 'Client'), FieldType.text),
    FieldSpec('location', L('الموقع', 'Location'), FieldType.text),
    FieldSpec('area', L('المساحة', 'Area'), FieldType.text),
    FieldSpec('date', L('التاريخ', 'Date'), FieldType.text, hint: L('مثال: فبراير 2022', 'e.g. February 2022')),
    FieldSpec('team', L('فريق العمل المشارك فيه', 'Team'), FieldType.stringList),
    FieldSpec('description', L('الوصف', 'Description'), FieldType.multiline),
    FieldSpec('role', L('دورنا في المشروع', 'Our role'), FieldType.stringList),
    FieldSpec('download_url', L('رابط تحميل ملفات المشروع', 'Files download link'), FieldType.url),
    FieldSpec.section(L('الصور', 'Images')),
    FieldSpec('gallery', L('معرض الصور', 'Gallery'), FieldType.imageList),
    FieldSpec.section(L('العرض', 'Display')),
    FieldSpec('featured', L('يظهر في الرئيسية', 'Show on home page'), FieldType.boolean),
    _order,
    _published,
  ],
);

final CollectionConfig articlesConfig = CollectionConfig(
  coll: Coll.articles,
  title: const L('المقالات', 'Articles'),
  icon: Icons.article_outlined,
  subtitleKey: 'category',
  imageKey: 'cover',
  sort: SortBy.newest,
  publicPath: (String id, _) => '/articles/$id',
  specs: const <FieldSpec>[
    FieldSpec('title', L('العنوان', 'Title'), FieldType.text, isRequired: true),
    FieldSpec('category', L('التصنيف', 'Category'), FieldType.text,
        hint: L('مثال: معلومات هندسية عامة', 'e.g. General engineering')),
    FieldSpec('published_at', L('تاريخ النشر', 'Publish date'), FieldType.date),
    FieldSpec('cover', L('صورة المقال', 'Cover image'), FieldType.image),
    FieldSpec('excerpt', L('مقتطف', 'Excerpt'), FieldType.multiline),
    FieldSpec('body_html', L('المحتوى', 'Content'), FieldType.html),
    _published,
  ],
);

final CollectionConfig partnersConfig = CollectionConfig(
  coll: Coll.partners,
  title: const L('شركاء النجاح', 'Partners'),
  icon: Icons.handshake_outlined,
  titleKey: 'name',
  imageKey: 'logo_url',
  specs: const <FieldSpec>[
    FieldSpec('name', L('اسم الشركة', 'Company'), FieldType.text, isRequired: true),
    FieldSpec('logo_url', L('الشعار', 'Logo'), FieldType.image),
    _order,
    _published,
  ],
);

final CollectionConfig testimonialsConfig = CollectionConfig(
  coll: Coll.testimonials,
  title: const L('أراء العملاء', 'Testimonials'),
  icon: Icons.format_quote_rounded,
  titleKey: 'name',
  subtitleKey: 'role',
  specs: const <FieldSpec>[
    FieldSpec('name', L('الاسم', 'Name'), FieldType.text, isRequired: true),
    FieldSpec('role', L('الوظيفة / الشركة', 'Role / company'), FieldType.text),
    FieldSpec('quote', L('الرأي', 'Quote'), FieldType.multiline, isRequired: true),
    _order,
    _published,
  ],
);

/// `site_settings/main` — texts, contact and images. The on/off switches
/// live on the Control page.
const List<FieldSpec> siteSettingsSpecs = <FieldSpec>[
  FieldSpec.section(L('عام', 'General')),
  FieldSpec('site_name', L('اسم الموقع', 'Site name'), FieldType.text),
  FieldSpec('footer_text', L('نص حقوق النشر', 'Copyright line'), FieldType.text, rtl: false),
  FieldSpec.section(L('الواجهة الرئيسية', 'Hero')),
  FieldSpec('hero_video_url', L('رابط الفيديو (mp4)', 'Video URL (mp4)'), FieldType.url),
  FieldSpec('hero_poster_url', L('صورة قبل تشغيل الفيديو', 'Poster image'), FieldType.image),
  FieldSpec('hero_button_text', L('نص الزر', 'Button text'), FieldType.text),
  FieldSpec('map_image_url', L('صورة الخريطة', 'Map image'), FieldType.image),
  FieldSpec('counters', L('العدادات', 'Counters'), FieldType.pairs),
  FieldSpec.section(L('عناوين الأقسام', 'Section titles')),
  FieldSpec('services_title', L('عنوان الخدمات', 'Services title'), FieldType.text),
  FieldSpec('services_intro', L('مقدمة الخدمات', 'Services intro'), FieldType.multiline),
  FieldSpec('features_title', L('عنوان المميزات', 'Why-us title'), FieldType.text),
  FieldSpec('features_intro', L('مقدمة المميزات', 'Why-us intro'), FieldType.multiline),
  FieldSpec('projects_title', L('عنوان الأعمال', 'Projects title'), FieldType.text),
  FieldSpec('projects_intro', L('مقدمة الأعمال', 'Projects intro'), FieldType.multiline),
  FieldSpec('partners_title', L('عنوان الشركاء', 'Partners title'), FieldType.text),
  FieldSpec('partners_intro', L('مقدمة الشركاء', 'Partners intro'), FieldType.multiline),
  FieldSpec('blog_title', L('عنوان المدونة', 'Blog title'), FieldType.text),
  FieldSpec('blog_intro', L('مقدمة المدونة', 'Blog intro'), FieldType.multiline),
  FieldSpec('testimonials_title', L('عنوان آراء العملاء', 'Testimonials title'), FieldType.text),
  FieldSpec('testimonials_intro', L('مقدمة آراء العملاء', 'Testimonials intro'), FieldType.multiline),
  FieldSpec('cta_title', L('عنوان الدعوة (أسفل الصفحات)', 'Call-to-action title'), FieldType.text),
  FieldSpec('cta_text', L('نص الدعوة', 'Call-to-action text'), FieldType.multiline),
  FieldSpec.section(L('المدير التنفيذي', 'CEO')),
  FieldSpec('ceo_label', L('المسمى', 'Label'), FieldType.text),
  FieldSpec('ceo_name', L('الاسم', 'Name'), FieldType.text),
  FieldSpec('ceo_photo_url', L('الصورة', 'Photo'), FieldType.image),
  FieldSpec('ceo_bio', L('الكلمة', 'Message'), FieldType.multiline),
  FieldSpec.section(L('من نحن', 'About')),
  FieldSpec('about_title', L('العنوان', 'Title'), FieldType.text),
  FieldSpec('about_subtitle', L('العنوان الفرعي', 'Subtitle'), FieldType.text),
  FieldSpec('about_heading', L('العنوان الداخلي', 'Heading'), FieldType.text),
  FieldSpec('about_text', L('النص', 'Text'), FieldType.multiline),
  FieldSpec('team', L('يتكون فريقنا من', 'Our team'), FieldType.stringList),
  FieldSpec.section(L('التواصل', 'Contact')),
  FieldSpec('contact_title', L('عنوان صفحة التواصل', 'Contact page title'), FieldType.text),
  FieldSpec('address', L('العنوان', 'Address'), FieldType.text),
  FieldSpec('emails', L('البريد الإلكتروني', 'E-mails'), FieldType.stringList, rtl: false),
  FieldSpec('phone', L('الهاتف', 'Phone'), FieldType.text, rtl: false),
  FieldSpec('whatsapp', L('واتساب (بدون +)', 'WhatsApp (no +)'), FieldType.text, rtl: false),
  FieldSpec('facebook_url', L('فيسبوك', 'Facebook'), FieldType.url),
  FieldSpec('linkedin_url', L('لينكدإن', 'LinkedIn'), FieldType.url),
  FieldSpec('youtube_url', L('يوتيوب', 'YouTube'), FieldType.url),
  FieldSpec('instagram_url', L('إنستجرام', 'Instagram'), FieldType.url),
  FieldSpec('telegram_url', L('تليجرام', 'Telegram'), FieldType.url),
  FieldSpec.section(L('التحميلات', 'Downloads')),
  FieldSpec('windows_download_url', L('رابط تحميل نسخة ويندوز', 'Windows download link'), FieldType.url,
      hint: L('اتركه فارغًا لاستخدام آخر إصدار على GitHub تلقائيًا', 'Leave empty to use the latest GitHub release automatically')),
  FieldSpec.section(L('صفحات أخرى', 'Other pages')),
  FieldSpec('requests_text', L('نص صفحة تقديم طلب', 'Requests page text'), FieldType.multiline),
  FieldSpec('maintenance_text', L('رسالة الصيانة', 'Maintenance message'), FieldType.text),
  FieldSpec('privacy_html', L('سياسة الخصوصية', 'Privacy policy'), FieldType.html),
];
