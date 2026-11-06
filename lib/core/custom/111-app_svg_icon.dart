/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: 111-app_svg_icon.dart
/// Purpose: `AppIcon` — the app's drop-in replacement for Flutter's `Icon`.
///          It draws the matching SVG from `assets/icons_assets/` (tinted
///          with the icon colour, no background) and only falls back to the
///          Material glyph when no SVG has been mapped for that icon.
/// Author: Manger Plus team
/// Created: 18/9/2026
///
/// TO SWAP AN ICON: change its path in [AppSvgIcons._map]. To give a new
/// Material icon an SVG, add a line there — every screen picks it up.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSvgIcons {
  AppSvgIcons._();

  static const String _main = 'assets/icons_assets/main_icons_assets/';
  static const String _crm = 'assets/icons_assets/crm_icons_assets/';
  static const String _form = 'assets/icons_assets/form_builder_assets/';
  static const String _home = 'assets/icons_assets/home_assets/';
  static const String _msg = 'assets/icons_assets/messaging_assets/';
  static const String _roles = 'assets/icons_assets/roles_assets/';
  static const String _settings = 'assets/icons_assets/settings_assets/';
  static const String _web = 'assets/icons_assets/web_assets/';
  static const String _tools = 'assets/icons_assets/tools_assets/';

  static final Map<IconData, String> _map = <IconData, String>{
    // Checks & status
    Icons.check_rounded: '${_crm}check_box_filed.svg',
    Icons.check_circle_rounded: '${_crm}check_box_filed.svg',
    Icons.done_all_rounded: '${_form}select_all_group_check.svg',
    Icons.verified_user_rounded: '${_main}approval_badge_check.svg',
    Icons.close_rounded: '${_msg}vectors_close.svg',
    Icons.cancel_rounded: '${_msg}vectors_close.svg',
    Icons.remove_circle_outline: '${_main}cancel_minus_circle.svg',
    Icons.error_outline_rounded: '${_main}warning_triangle_red.svg',
    Icons.info_outline_rounded: '${_crm}how-it-work.svg',
    Icons.pending_actions_rounded: '${_home}hourglass_pending.svg',
    Icons.radio_button_unchecked_rounded: '${_form}radio_circle_empty.svg',
    Icons.rule_rounded: '${_main}bullet_list.svg',
    // Navigation
    Icons.chevron_right_rounded: '${_main}chevron_right.svg',
    Icons.chevron_left_rounded: '${_main}chevron_left.svg',
    Icons.keyboard_arrow_down_rounded: '${_main}chevron_down.svg',
    Icons.arrow_back_rounded: '${_main}mobile_arrow_back.svg',
    Icons.arrow_forward_rounded: '${_main}vectors_arrowForward.svg',
    Icons.open_in_new_rounded: '${_main}export_arrow.svg',
    Icons.home_rounded: '${_roles}home.svg',
    Icons.home_outlined: '${_roles}home.svg',
    Icons.settings_rounded: '${_roles}settings_gear.svg',
    Icons.settings_outlined: '${_roles}settings_gear.svg',
    Icons.logout_rounded: '${_main}logout_door_arrow.svg',
    // 03/11/2026: Settings → Account / profile card.
    Icons.delete_forever_rounded: '${_settings}delete_account_trash.svg',
    Icons.calendar_today_rounded: '${_settings}calendar_since.svg',
    Icons.power_settings_new_rounded: '${_home}logout_arrow.svg',
    Icons.search: '${_main}search_magnifier_alt.svg',
    Icons.filter_alt_outlined: '${_main}filter_sliders.svg',
    // Actions
    Icons.add_rounded: '${_main}plus.svg',
    Icons.edit_outlined: '${_main}assets_edit.svg',
    Icons.edit_rounded: '${_main}assets_edit.svg',
    Icons.edit_note_rounded: '${_main}edit_pencil_square.svg',
    Icons.delete_outline_rounded: '${_crm}trush.svg',
    Icons.delete_sweep_outlined: '${_form}delete_trash_red.svg',
    Icons.send_rounded: '${_msg}vectors_send.svg',
    Icons.cloud_upload_outlined: '${_main}cloud_upload.svg',
    // People
    Icons.person_outline_rounded: '${_main}person_outline.svg',
    Icons.person_rounded: '${_main}person_outline.svg',
    Icons.groups_2_rounded: '${_main}users_group_three.svg',
    Icons.groups_2_outlined: '${_main}users_group_three.svg',
    Icons.family_restroom_rounded: '${_msg}people.svg',
    Icons.family_restroom_outlined: '${_msg}people.svg',
    Icons.co_present_outlined: '${_settings}bio_person_spotlight.svg',
    Icons.co_present_rounded: '${_settings}bio_person_spotlight.svg',
    Icons.admin_panel_settings_outlined: '${_roles}roles_people_gear.svg',
    Icons.school_rounded: '${_main}graduation_cap.svg',
    Icons.school_outlined: '${_main}graduation_cap.svg',
    Icons.backpack_rounded: '${_settings}academic_history_graduation.svg',
    Icons.backpack_outlined: '${_settings}academic_history_graduation.svg',
    // Time
    Icons.event_rounded: '${_main}images_Calendar.svg',
    Icons.event_outlined: '${_main}images_Calendar.svg',
    Icons.schedule_rounded: '${_main}clock_circle.svg',
    Icons.timer_outlined: '${_roles}time_tracking_dashed_clock.svg',
    Icons.fact_check_outlined: '${_main}calendar_attendance_marks.svg',
    Icons.fact_check_rounded: '${_main}calendar_attendance_marks.svg',
    // Content & media
    Icons.video_library_rounded: '${_main}knowledgeVideo.svg',
    Icons.video_library_outlined: '${_main}knowledgeVideo.svg',
    Icons.play_circle_fill_rounded: '${_main}knowledgeVideo.svg',
    Icons.play_circle_outline_rounded: '${_msg}play.svg',
    Icons.play_circle_outline: '${_msg}play.svg',
    Icons.play_arrow_rounded: '${_msg}play.svg',
    Icons.pause_circle_outline: '${_msg}pause.svg',
    Icons.pause_circle_filled_rounded: '${_msg}pause.svg',
    Icons.picture_as_pdf_rounded: '${_main}assets_pdf.svg',
    Icons.picture_as_pdf_outlined: '${_main}assets_pdf.svg',
    Icons.photo_rounded: '${_main}image_photo_rounded.svg',
    Icons.image_outlined: '${_main}image_photo_rounded.svg',
    Icons.broken_image_outlined: '${_main}image_placeholder_large.svg',
    Icons.assignment_outlined: '${_form}summary_document_list.svg',
    Icons.assignment_rounded: '${_form}summary_document_list.svg',
    Icons.quiz_outlined: '${_main}approval_badge_check.svg',
    Icons.bolt_rounded: '${_main}approval_badge_check.svg',
    Icons.format_quote_rounded: '${_home}quotation_marks.svg',
    // Insights & grades
    Icons.insights_rounded: '${_home}analytics_charts.svg',
    Icons.insights_outlined: '${_home}analytics_charts.svg',
    Icons.grade_rounded: '${_msg}vectors_star.svg',
    Icons.grade_outlined: '${_msg}vectors_star.svg',
    Icons.star_outline_rounded: '${_msg}vectors_star.svg',
    // Messages & contact
    Icons.chat_bubble_outline_rounded: '${_main}chat_bubble_dots.svg',
    Icons.chat_bubble_rounded: '${_main}chat_bubble_dots.svg',
    Icons.alternate_email_rounded: '${_main}email_envelope.svg',
    Icons.phone_iphone_rounded: '${_main}phone_number.svg',
    // Settings
    Icons.translate_rounded: '${_settings}language_translate_bubbles.svg',
    Icons.light_mode_rounded: '${_home}picker_light_mode.svg',
    Icons.dark_mode_rounded: '${_home}picker_dark_mode.svg',
    Icons.vibration_rounded: '${_settings}haptic_vibration_phone.svg',
    Icons.lock_outline_rounded: '${_home}user_access_lock.svg',
    Icons.desktop_mac_rounded: '${_main}employee_desk_computer.svg',
    // Website (lib/features/web) — the site and its control panel
    Icons.add: '${_main}plus.svg',
    Icons.add_photo_alternate_outlined: '${_form}image_add.svg',
    Icons.animation_rounded: '${_web}animation.svg',
    Icons.apartment_rounded: '${_main}company.svg',
    Icons.article_outlined: '${_msg}vectors_document.svg',
    Icons.bar_chart_rounded: '${_msg}poll_bars.svg',
    Icons.business_center_rounded: '${_main}Case.svg',
    Icons.work_outline_rounded: '${_main}Case.svg',
    Icons.calendar_month_rounded: '${_main}images_Calendar.svg',
    Icons.camera_alt_rounded: '${_main}images_Camera.svg',
    Icons.chat_outlined: '${_main}chat_bubble_dots.svg',
    Icons.chat_rounded: '${_main}chat_bubble_dots.svg',
    Icons.cloud_download_outlined: '${_form}cloud_download.svg',
    Icons.code: '${_web}code.svg',
    Icons.construction_rounded: '${_web}wrench_construction.svg',
    Icons.design_services_outlined: '${_crm}services.svg',
    Icons.design_services_rounded: '${_crm}services.svg',
    Icons.download_rounded: '${_form}download_arrow.svg',
    Icons.upload_rounded: '${_form}upload_arrow.svg',
    Icons.email_rounded: '${_main}email_envelope.svg',
    Icons.mail_outline_rounded: '${_main}email_envelope.svg',
    Icons.inbox_outlined: '${_main}mail-inbox-app.svg',
    Icons.facebook_rounded: '${_web}facebook.svg',
    Icons.fast_forward_rounded: '${_web}fast_forward.svg',
    Icons.handshake_outlined: '${_web}handshake.svg',
    Icons.history_rounded: '${_crm}history.svg',
    Icons.language_rounded: '${_web}globe.svg',
    Icons.public_rounded: '${_web}globe.svg',
    Icons.location_on_rounded: '${_form}location_pin.svg',
    Icons.lock_rounded: '${_home}user_access_lock.svg',
    Icons.menu_rounded: '${_roles}menu_lines_bold.svg',
    Icons.numbers_rounded: '${_crm}hash.svg',
    Icons.pause_rounded: '${_web}pause.svg',
    Icons.person: '${_main}person_outline.svg',
    Icons.person_add_alt_1_rounded: '${_main}details_User Plus.svg',
    Icons.phone_rounded: '${_main}phone_number.svg',
    Icons.playlist_play_rounded: '${_web}playlist_play.svg',
    Icons.reply_rounded: '${_web}reply.svg',
    Icons.save_rounded: '${_main}assets_save.svg',
    Icons.search_rounded: '${_main}search_magnifier_alt.svg',
    Icons.shield_rounded: '${_web}shield.svg',
    Icons.space_dashboard_outlined: '${_web}dashboard_tiles.svg',
    Icons.speed_rounded: '${_web}speed_gauge.svg',
    Icons.stacked_line_chart_rounded: '${_crm}chart-line-solid.svg',
    Icons.table_rows_rounded: '${_main}list_lines.svg',
    Icons.toggle_on_outlined: '${_web}toggle_on.svg',
    Icons.tune_rounded: '${_main}filter_sliders.svg',
    Icons.visibility: '${_web}eye.svg',
    Icons.visibility_outlined: '${_web}eye.svg',
    Icons.visibility_off_outlined: '${_web}eye_off.svg',
    Icons.volume_off_rounded: '${_web}volume_off.svg',
    Icons.volume_up_rounded: '${_web}volume_up.svg',
    // Website video player (site/widgets/hero_video.dart) — solid, like a
    // browser's own player bar.
    Icons.play_arrow: '${_web}player_play.svg',
    Icons.pause: '${_web}player_pause.svg',
    Icons.volume_up: '${_web}player_volume_up.svg',
    Icons.volume_off: '${_web}player_volume_off.svg',
    Icons.fullscreen: '${_web}player_fullscreen.svg',
    Icons.fullscreen_exit: '${_web}player_fullscreen_exit.svg',
    Icons.more_vert: '${_web}player_more.svg',
    Icons.replay: '${_web}player_replay.svg',
    Icons.check: '${_web}player_check.svg',
    Icons.keyboard_arrow_up_rounded: '${_web}chevron_up.svg',
    // The calculators — drawings of what each one sizes (CalcIcons).
    CalcIcons.calculators: '${_tools}calc_group.svg',
    CalcIcons.units: '${_tools}calc_units.svg',
    CalcIcons.duct: '${_tools}calc_duct.svg',
    CalcIcons.pipe: '${_tools}calc_pipe.svg',
    CalcIcons.hvac: '${_tools}calc_hvac.svg',
    CalcIcons.plumbing: '${_tools}calc_plumbing.svg',
    CalcIcons.fire: '${_tools}calc_fire.svg',
  };

  /// The SVG mapped to [icon], or null to keep the Material glyph.
  static String? assetFor(IconData? icon) => icon == null ? null : _map[icon];
}

/// THE CALCULATORS' ICONS. Each is its own SVG drawing (a duct, a pipe
/// elbow, a fan, a tap, an FM-200 cylinder …) in
/// `assets/icons_assets/tools_assets/` — not a Material glyph. They are
/// IconData only so they fit `ShellSection.icon`; ALWAYS draw them with
/// `AppIcon`, which swaps in the SVG (a plain `Icon` would draw nothing).
abstract final class CalcIcons {
  static const String _font = 'AsecCalcIcons';
  static const IconData calculators = IconData(0xf0001, fontFamily: _font);
  static const IconData units = IconData(0xf0002, fontFamily: _font);
  static const IconData duct = IconData(0xf0003, fontFamily: _font);
  static const IconData pipe = IconData(0xf0004, fontFamily: _font);
  static const IconData hvac = IconData(0xf0005, fontFamily: _font);
  static const IconData plumbing = IconData(0xf0006, fontFamily: _font);
  static const IconData fire = IconData(0xf0007, fontFamily: _font);
}

/// Same constructor as `Icon`, so `Icon(...)` -> `AppIcon(...)` is a rename.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final IconData? icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final IconThemeData theme = IconTheme.of(context);
    final double box = size ?? theme.size ?? 24;
    Color? ink = color ?? theme.color;
    if (color == null && ink != null && theme.opacity != null && theme.opacity! < 1) {
      ink = ink.withOpacity(ink.opacity * theme.opacity!);
    }

    final String? asset = AppSvgIcons.assetFor(icon);
    if (asset == null) {
      return Icon(icon, size: box, color: ink, semanticLabel: semanticLabel);
    }

    // Material glyphs leave ~2px of air inside their 24px box; the SVGs are
    // drawn edge to edge, so they are inset to the same visual weight.
    final double glyph = box * 0.84;
    return SizedBox(
      width: box,
      height: box,
      child: Center(
        child: SvgPicture.asset(
          asset,
          width: glyph,
          height: glyph,
          semanticsLabel: semanticLabel,
          colorFilter:
              ink == null ? null : ColorFilter.mode(ink, BlendMode.srcIn),
        ),
      ),
    );
  }
}
