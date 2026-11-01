import 'package:flutter/material.dart';

import '../lessons.dart';
import '../progress.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'profile_form.dart';

/// Profil / Профиль.
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Future<void> _confirmReset() async {
    final s = AppScope.read(context);
    await showAppSheet<void>(
      context,
      builder: (ctx) {
        final c = AppScope.of(ctx).c;
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: IconTile(Icons.restart_alt_rounded, size: 60, circle: true, bg: c.dangerSoft, color: c.danger)),
          const SizedBox(height: S.x4),
          Text(s.t('reset'), textAlign: TextAlign.center, style: AppType.title2.copyWith(color: c.text)),
          const SizedBox(height: S.x2),
          Text(s.t('reset_q'), textAlign: TextAlign.center, style: AppType.callout.copyWith(color: c.text2)),
          const SizedBox(height: S.x6),
          AppButton(s.t('yes'), kind: BtnKind.danger, expand: true, icon: Icons.delete_outline_rounded, onPressed: () {
            s.resetProgress();
            Navigator.of(ctx).pop();
            s.toast(s.t('reset'), icon: Icons.restart_alt_rounded);
          }),
          const SizedBox(height: S.x3),
          AppButton(s.t('no'), kind: BtnKind.secondary, expand: true, onPressed: () => Navigator.of(ctx).pop()),
        ]);
      },
    );
  }

  Future<void> _edit() async {
    await showAppSheet<void>(context, builder: (_) => const _EditSheet());
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c, st = s.st;
    final place = [s.school, s.city].where((x) => x.trim().isNotEmpty).join(' · ');

    // ---- Profil kartasi / карточка профиля
    final head = AppCard(
      padding: const EdgeInsets.all(S.x5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          PhotoPicker(
            bytes: s.myPhoto,
            url: s.myPhoto == null && s.online ? s.photoUrl(s.username) : null,
            name: s.displayName,
            size: 84,
            onPicked: (b) async {
              final ok = await s.updatePhoto(b);
              if (ok) s.toast(s.t('photo_saved'), icon: Icons.check_circle_rounded);
            },
          ),
          const SizedBox(width: S.x4),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.displayName.isEmpty ? s.t('profile') : s.displayName,
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: AppType.title2.copyWith(color: c.text)),
              if (place.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(place, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppType.footnote.copyWith(color: c.text2)),
              ],
              const SizedBox(height: S.x2),
              Wrap(spacing: S.x2, runSpacing: S.x2, children: [
                s.online
                    ? AppPill(s.t('online'), icon: Icons.cloud_done_rounded, tone: Tone.yellow, small: true)
                    : AppPill(s.t('offline_mode'), icon: Icons.cloud_off_rounded, small: true),
                if (s.online) AppPill('@${s.username}', small: true),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: S.x4),
        AppButton(s.t('edit_profile'),
            key: const ValueKey('edit-profile'), kind: BtnKind.secondary, icon: Icons.edit_rounded, expand: true, onPressed: _edit),
      ]),
    );

    // ---- Liga / лига
    final league = s.isTeacher
        ? null
        : AppCard(
            padding: const EdgeInsets.all(S.x4),
            child: Row(children: [
              LeagueBadge(league: st.league, size: 52),
              const SizedBox(width: S.x3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.leagueName, style: AppType.headline.copyWith(color: c.text)),
                  const SizedBox(height: 2),
                  Text(s.t(st.league == 'master' ? 'league_top' : 'league_hint'),
                      style: AppType.caption.copyWith(color: c.text2)),
                ]),
              ),
            ]),
          );

    // ---- Statistika / статистика
    final acc = (st.stats.accuracy * 100).round();
    final stats = gridOf([
      StatTile(icon: Icons.workspace_premium_rounded, value: '${levelOf(st.xpTotal)}', label: s.t('level')),
      StatTile(icon: Icons.bolt_rounded, value: '${st.xp}', label: s.t('balance')),
      StatTile(icon: Icons.stacked_line_chart_rounded, value: '${st.xpTotal}', label: s.t('total_xp')),
      StatTile(icon: Icons.local_fire_department_rounded, value: '${st.streak}', label: s.t('streak')),
      StatTile(icon: Icons.menu_book_rounded, value: '${st.done.length}', label: s.t('lessons')),
      StatTile(icon: Icons.track_changes_rounded, value: '$acc%', label: s.t('accuracy')),
    ], 3, gap: S.x3);

    // ---- Yutuqlar / достижения
    final badges = [
      (Icons.rocket_launch_rounded, s.t('b1'), st.done.isNotEmpty),
      (Icons.bolt_rounded, s.t('b2'), st.xpTotal >= 100),
      (Icons.local_fire_department_rounded, s.t('b3'), st.streak >= 3),
      (Icons.verified_rounded, s.t('perfect'), st.perfect >= 1),
      (Icons.emoji_events_rounded, s.t('b4'),
          kCourses.any((x) => s.lessonsOf(x).isNotEmpty && s.progressOf(x) == s.lessonsOf(x).length)),
      (Icons.military_tech_rounded, s.t('b5'), st.league == 'advanced' || st.league == 'master'),
    ];
    final badgeGrid = AppCard(
      padding: const EdgeInsets.symmetric(vertical: S.x5, horizontal: S.x3),
      child: gridOf([
        for (final (icon, name, on) in badges)
          Column(children: [
            AnimatedContainer(
              duration: Motion.of(context, Motion.base),
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: on ? c.accentGradient : null,
                color: on ? null : c.surfaceAlt,
                boxShadow: on ? Shadows.glow(c.accent, c, strength: 0.4) : null,
              ),
              child: Icon(icon, size: 26, color: on ? kWhite : c.text3),
            ),
            const SizedBox(height: S.x2),
            Text(name, textAlign: TextAlign.center, maxLines: 2, style: AppType.caption.copyWith(color: on ? c.text : c.text3)),
          ]),
      ], 3, gap: S.x4),
    );

    // ---- Do‘kon / магазин
    final shop = s.isTeacher
        ? null
        : AppCard(
            key: const ValueKey('profile-shop'),
            onTap: () => s.go('shop'),
            padding: const EdgeInsets.all(S.x4),
            child: Row(children: [
              const IconTile(Icons.redeem_rounded, size: 44, vivid: true),
              const SizedBox(width: S.x3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.t('shop_title'), style: AppType.headline.copyWith(color: c.text)),
                  Text(s.t('shop_sub'), maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: AppType.caption.copyWith(color: c.text2)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: c.text3),
            ]),
          );

    // ---- Sozlamalar / настройки
    final settings = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const IconTile(Icons.contrast_rounded, size: 32),
          const SizedBox(width: S.x3),
          Text(s.t('appearance'), style: AppType.headline.copyWith(color: c.text)),
        ]),
        const SizedBox(height: S.x3),
        Segmented<String>(
          values: const ['system', 'light', 'dark'],
          labels: [s.t('system'), s.t('light'), s.t('dark')],
          icons: const [Icons.brightness_auto_rounded, Icons.light_mode_rounded, Icons.dark_mode_rounded],
          value: s.theme,
          onChanged: s.setTheme,
        ),
        Divider(height: S.x8, color: c.hairline),
        Row(children: [
          const IconTile(Icons.translate_rounded, size: 32),
          const SizedBox(width: S.x3),
          Text(s.t('language'), style: AppType.headline.copyWith(color: c.text)),
        ]),
        const SizedBox(height: S.x3),
        Segmented<String>(
          values: const ['uz', 'ru'],
          labels: const ['O‘zbekcha', 'Русский'],
          value: s.lang,
          onChanged: (v) {
            if (v != s.lang) s.toggleLang();
          },
        ),
      ]),
    );

    final Widget bottom = s.online
        ? AppButton(s.t('logout'), onPressed: s.logout, kind: BtnKind.secondary, icon: Icons.logout_rounded, expand: true)
        : Row(children: [
            Expanded(child: AppButton(s.t('login_btn'), onPressed: s.logout, icon: Icons.login_rounded)),
            const SizedBox(width: S.x3),
            Expanded(
              child: AppButton(s.t('reset'), onPressed: _confirmReset, kind: BtnKind.danger, icon: Icons.restart_alt_rounded),
            ),
          ]);

    return TabPage(
      title: s.t('profile'),
      children: [
        head,
        if (league != null) league,
        SectionHeader(s.t('stats')),
        stats,
        if (shop != null) shop,
        SectionHeader(s.t('badges')),
        badgeGrid,
        SectionHeader(s.t('settings')),
        settings,
        bottom,
      ],
    );
  }
}

/// Profilni tahrirlash / редактирование профиля.
class _EditSheet extends StatefulWidget {
  const _EditSheet();

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _name, _school, _city;
  bool _busy = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    _name = TextEditingController(text: s.displayName);
    _school = TextEditingController(text: s.school);
    _city = TextEditingController(text: s.city);
  }

  @override
  void dispose() {
    _name.dispose();
    _school.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = AppScope.read(context);
    if (_name.text.trim().isEmpty || _school.text.trim().isEmpty || _city.text.trim().isEmpty) {
      setState(() => _error = s.t('err_profile'));
      return;
    }
    setState(() => _busy = true);
    await s.updateProfile(name: _name.text, school: _school.text, city: _city.text);
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(s.t('edit_profile'), textAlign: TextAlign.center, style: AppType.title3.copyWith(color: c.text)),
      const SizedBox(height: S.x4),
      ProfileFields(name: _name, school: _school, city: _city, onDone: _save),
      if (_error.isNotEmpty) ...[const SizedBox(height: S.x3), ErrorBox(_error)],
      const SizedBox(height: S.x4),
      AppButton(s.t('save'),
          key: const ValueKey('profile-save'), onPressed: _busy ? null : _save, loading: _busy, expand: true),
    ]);
  }
}
