import 'package:flutter/material.dart';

import '../lessons.dart';
import '../progress.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

/// 6. Profil / Профиль.
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final TextEditingController _name;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    _name = TextEditingController(text: s.displayName);
    _focus.addListener(() {
      if (!_focus.hasFocus) s.saveName(_name.text);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _name.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c, st = s.st;

    // ---- Profil kartasi / карточка профиля
    final head = AppCard(
      padding: const EdgeInsets.all(S.x5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          AppAvatar(st.avatar, size: 76, ring: true),
          const SizedBox(width: S.x4),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.displayName.isEmpty ? s.t('profile') : s.displayName,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.title2.copyWith(color: c.text)),
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
        const SizedBox(height: S.x5),
        AppTextField(
          controller: _name,
          focusNode: _focus,
          label: s.t('name'),
          icon: Icons.edit_rounded,
          maxLength: 30,
          autocorrect: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => s.saveName(v),
        ),
      ]),
    );

    // ---- Statistika / статистика
    final stats = gridOf([
      StatTile(icon: Icons.workspace_premium_rounded, value: '${levelOf(st.xp)}', label: s.t('level')),
      StatTile(icon: Icons.bolt_rounded, value: '${st.xp}', label: 'XP'),
      StatTile(icon: Icons.diamond_rounded, value: '${st.gems}', label: s.t('gems')),
      StatTile(icon: Icons.local_fire_department_rounded, value: '${st.streak}', label: s.t('streak')),
      StatTile(icon: Icons.menu_book_rounded, value: '${st.done.length}', label: s.t('lessons')),
      StatTile(icon: Icons.verified_rounded, value: '${st.perfect}', label: s.t('perfect_n')),
    ], 3, gap: S.x3);

    // ---- Avatar do‘koni / магазин аватаров
    final shopItems = [
      for (final e in kAvatars.entries) _ShopItem(emoji: e.key, price: e.value),
    ];

    // ---- Yutuqlar / достижения
    final badges = [
      (Icons.rocket_launch_rounded, s.t('b1'), st.done.isNotEmpty),
      (Icons.bolt_rounded, s.t('b2'), st.xp >= 100),
      (Icons.local_fire_department_rounded, s.t('b3'), st.streak >= 3),
      (Icons.verified_rounded, s.t('perfect'), st.perfect >= 1),
      (Icons.emoji_events_rounded, s.t('b4'), kCourses.any((x) => s.progressOf(x) == x.lessons.length)),
      (Icons.diamond_rounded, '200', st.gems >= 200),
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
            Text(name,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppType.caption.copyWith(color: on ? c.text : c.text3)),
          ]),
      ], 3, gap: S.x4),
    );

    // ---- Sozlamalar / настройки
    final settings = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          IconTile(Icons.contrast_rounded, size: 32),
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
          IconTile(Icons.translate_rounded, size: 32),
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

    return LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth >= 560 ? 5 : 4;
      return TabPage(
        title: s.t('profile'),
        children: [
          head,
          SectionHeader(s.t('stats')),
          stats,
          SectionHeader(s.t('shop'),
              trailing: AppPill('${st.gems}', icon: Icons.diamond_rounded, iconColor: c.yellow, small: true)),
          gridOf(shopItems, cols, gap: S.x3),
          SectionHeader(s.t('badges')),
          badgeGrid,
          SectionHeader(s.t('settings')),
          settings,
          bottom,
        ],
      );
    });
  }
}

/// Avatar do‘koni katakchasi / ячейка магазина аватаров.
class _ShopItem extends StatelessWidget {
  final String emoji;
  final int price;
  const _ShopItem({required this.emoji, required this.price});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c, st = s.st;
    final owned = st.owned.contains(emoji);
    final equipped = st.avatar == emoji;
    final affordable = st.gems >= price;
    final Widget tag;
    if (equipped) {
      tag = Icon(Icons.check_circle_rounded, size: 18, color: c.accent);
    } else if (owned) {
      tag = Text(s.t('equip'), maxLines: 1, style: AppType.caption.copyWith(color: c.text2));
    } else {
      tag = Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.diamond_rounded, size: 12, color: affordable ? c.yellow : c.text3),
        const SizedBox(width: 3),
        Text('$price', style: AppType.caption.copyWith(color: affordable ? c.yellowText : c.text3)),
      ]);
    }
    return Pressable(
      onTap: () => s.pickAvatar(emoji),
      scale: 0.93,
      semanticLabel: emoji,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.base),
        curve: Motion.curve,
        padding: const EdgeInsets.symmetric(vertical: S.x3, horizontal: S.x1),
        decoration: BoxDecoration(
          color: equipped ? c.accentSoft : c.surface,
          borderRadius: R.all(R.lg - 2),
          border: Border.all(color: equipped ? c.accent : c.hairline, width: equipped ? 2 : 1),
          boxShadow: equipped ? Shadows.glow(c.accent, c, strength: 0.3) : Shadows.soft(c),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Opacity(
            opacity: owned || affordable ? 1 : 0.4,
            child: Text(emoji, style: const TextStyle(fontSize: 30, height: 1.2)),
          ),
          const SizedBox(height: S.x1 + 2),
          SizedBox(height: 18, child: Center(child: tag)),
        ]),
      ),
    );
  }
}
