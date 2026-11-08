import 'package:flutter/material.dart';

import '../app_lock.dart';
import '../lessons.dart';
import '../progress.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'cards.dart' show CardsScreen;
import 'certificate.dart' show openCertificates;
import 'profile_form.dart';
import 'reminder.dart' show ReminderScreen;

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

  Future<void> _pickTheme() async {
    final s = AppScope.read(context);
    await showAppSheet<void>(context, builder: (ctx) {
      final c = AppScope.of(ctx).c;
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(s.t('appearance'), textAlign: TextAlign.center, style: AppType.title3.copyWith(color: c.text)),
        const SizedBox(height: S.x4),
        Segmented<String>(
          values: const ['system', 'light', 'dark'],
          labels: [s.t('system'), s.t('light'), s.t('dark')],
          icons: const [Icons.brightness_auto_rounded, Icons.light_mode_rounded, Icons.dark_mode_rounded],
          value: AppScope.of(ctx).theme,
          onChanged: s.setTheme,
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c, st = s.st;
    final place = [s.school, s.city].where((x) => x.trim().isNotEmpty).join(' · ');
    void push(Widget w) => Navigator.of(context).push(AppRoute<void>(builder: (_) => w));

    final head = Column(children: [
      PhotoPicker(
        bytes: s.myPhoto,
        url: s.myPhoto == null && s.online ? s.photoUrl(s.username) : null,
        name: s.displayName,
        size: 92,
        onPicked: (b) async {
          final ok = await s.updatePhoto(b);
          if (ok) s.toast(s.t('photo_saved'), icon: Icons.check_circle_rounded);
        },
      ),
      const SizedBox(height: S.x3),
      Text(s.displayName.isEmpty ? s.t('profile') : s.displayName,
          textAlign: TextAlign.center, style: AppType.title2.copyWith(color: c.text)),
      if (place.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(place, textAlign: TextAlign.center, style: AppType.subhead.copyWith(color: c.text2)),
      ],
      const SizedBox(height: S.x2),
      TextButton(
        key: const ValueKey('edit-profile'),
        onPressed: _edit,
        child: Text(s.t('edit_profile'), style: AppType.callout.copyWith(color: c.accentText, fontWeight: w6)),
      ),
    ]);

    Widget stat(String value, String label) => Expanded(
          child: Column(children: [
            Text(value, style: AppType.title2.copyWith(color: c.text)),
            const SizedBox(height: 2),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(color: c.text2)),
          ]),
        );
    final stats = Container(
      padding: const EdgeInsets.symmetric(vertical: S.x4),
      decoration: BoxDecoration(color: c.surface, borderRadius: R.all(R.lg)),
      child: Row(children: [
        stat('${levelOf(st.xpTotal)}', s.t('level')),
        stat('${st.xp}', 'XP'),
        stat('${st.streak}', s.t('streak')),
        stat('${st.done.length}', s.t('lessons')),
      ]),
    );

    final reminder = s.reminderMinutes >= 0
        ? '${(s.reminderMinutes ~/ 60).toString().padLeft(2, '0')}:${(s.reminderMinutes % 60).toString().padLeft(2, '0')}'
        : s.t('off');
    final learning = GroupList([
      GroupRow(
          icon: Icons.military_tech_rounded,
          color: const Color(0xFF5856D6),
          title: s.t('league'),
          value: s.leagueName,
          onTap: () => s.go('ranking')),
      GroupRow(
          key: const ValueKey('row-shop'),
          icon: Icons.redeem_rounded,
          color: const Color(0xFFFF9500),
          title: s.t('shop_title'),
          value: '${st.xp} XP',
          onTap: () => s.go('shop')),
      GroupRow(
          key: const ValueKey('cards-tile'),
          icon: Icons.bookmarks_rounded,
          color: const Color(0xFF0A6CFF),
          title: s.t('my_cards'),
          value: '${s.savedCards.length}',
          onTap: () => push(const CardsScreen())),
      GroupRow(
          key: const ValueKey('row-certs'),
          icon: Icons.workspace_premium_rounded,
          color: const Color(0xFFFFB800),
          title: s.t('my_certs'),
          value: '${s.certs.length}',
          onTap: () => openCertificates(context)),
      GroupRow(
          key: const ValueKey('row-play'),
          icon: Icons.terminal_rounded,
          color: const Color(0xFF1C1C1E),
          title: s.t('play'),
          onTap: () => s.go('play')),
      GroupRow(
          key: const ValueKey('reminder-tile'),
          icon: Icons.notifications_rounded,
          color: const Color(0xFFFF3B30),
          title: s.t('reminder_title_short'),
          value: reminder,
          onTap: () => push(const ReminderScreen(asSheet: true))),
      if (AppLock.supported && !s.isStaff)
        GroupRow(
            key: const ValueKey('row-applock'),
            icon: Icons.shield_moon_rounded,
            color: const Color(0xFF5856D6),
            title: s.t('lock_name'),
            onTap: () => Navigator.of(context).push(AppRoute<void>(builder: (_) => const PageShell(child: AppLockScreen())))),
    ]);

    final settings = GroupList([
      GroupRow(
          icon: Icons.contrast_rounded,
          color: const Color(0xFF8E8E93),
          title: s.t('appearance'),
          value: s.t(s.theme),
          onTap: _pickTheme),
      GroupRow(
          key: const ValueKey('row-lang'),
          icon: Icons.translate_rounded,
          color: const Color(0xFF34C759),
          title: s.t('language'),
          value: s.lang == 'uz' ? 'O‘zbekcha' : 'Русский',
          onTap: s.toggleLang),
    ]);

    final account = GroupList([
      if (s.online)
        GroupRow(
            icon: Icons.logout_rounded, color: const Color(0xFFFF3B30), title: s.t('logout'), onTap: s.logout)
      else ...[
        GroupRow(icon: Icons.login_rounded, color: const Color(0xFF0A6CFF), title: s.t('login_btn'), onTap: s.logout),
        GroupRow(
            icon: Icons.restart_alt_rounded, color: const Color(0xFFFF3B30), title: s.t('reset'), onTap: _confirmReset),
      ],
    ]);

    return TabPage(
      children: [
        head,
        if (!s.isStaff) ...[stats, learning],
        settings,
        account,
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
  late final TextEditingController _name;
  late final SchoolValue _school;
  bool _busy = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    _name = TextEditingController(text: s.displayName);
    _school = SchoolValue.of(s.region, s.district, s.school);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = AppScope.read(context);
    if (_name.text.trim().isEmpty) {
      setState(() => _error = s.t('err_profile'));
      return;
    }
    if (s.isStudent && !_school.complete) {
      setState(() => _error = s.t('err_school'));
      return;
    }
    setState(() => _busy = true);
    if (s.isStudent) {
      await s.updateProfile(name: _name.text, school: _school.label, city: _school.district, region: _school.region);
    } else {
      await s.updateProfile(name: _name.text);
    }
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
      Flexible(
        child: SingleChildScrollView(
          child: ProfileFields(
              name: _name, school: _school, onSchool: () => setState(() {}), showSchool: s.isStudent),
        ),
      ),
      if (_error.isNotEmpty) ...[const SizedBox(height: S.x3), ErrorBox(_error)],
      const SizedBox(height: S.x4),
      AppButton(s.t('save'),
          key: const ValueKey('profile-save'), onPressed: _busy ? null : _save, loading: _busy, expand: true),
    ]);
  }
}
