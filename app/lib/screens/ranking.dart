import 'package:flutter/material.dart';

import '../api.dart';
import '../lessons.dart';
import '../progress.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

int asInt(Object? v) => v is num ? v.toInt() : 0;
String asStr(Object? v) => v == null ? '' : '$v';

/// Foydalanuvchi rasmi (server orqali) / фото пользователя (через сервер).
Widget rowAvatar(AppState s, Map<String, dynamic> r, {double size = 40, bool ring = false}) {
  final user = asStr(r['username']);
  final mine = user.toLowerCase() == s.username.toLowerCase();
  return AppAvatar(
    bytes: mine ? s.myPhoto : null,
    url: r['has_photo'] == true ? s.photoUrl(user) : null,
    headers: s.authHeaders,
    name: asStr(r['name']),
    size: size,
    ring: ring,
  );
}

/// 4. Reyting / Рейтинг.
class RankingTab extends StatefulWidget {
  const RankingTab({super.key});

  @override
  State<RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<RankingTab> {
  List<Map<String, dynamic>>? _rows;
  Map<String, dynamic>? _me;
  String _error = '';
  bool _loading = false;
  String _period = 'week';
  String _league = 'beginner';
  String _scope = 'school'; // ustoz uchun / для учителя: school | league

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final s = AppScope.read(context);
    if (!s.online || _loading) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final q = 'period=$_period'
          '${s.isTeacher && _scope == 'school' ? '&scope=school' : ''}'
          '${s.isStaff ? '&league=$_league' : ''}';
      final res = await s.api.call('/api/leaderboard?$q');
      final rows = res['rows'];
      _rows = rows is List ? [for (final r in rows) if (r is Map) Map<String, dynamic>.from(r)] : [];
      final me = res['me'];
      _me = me is Map ? Map<String, dynamic>.from(me) : null;
    } on ApiError {
      _error = s.t('err_conn');
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final refresh = AppIconButton(Icons.refresh_rounded, tooltip: s.t('refresh'), onPressed: _loading ? null : _load);

    List<Widget> content;
    if (!s.online) {
      content = [EmptyState(icon: Icons.wifi_off_rounded, title: s.t('rank_offline'))];
    } else if (_error.isNotEmpty) {
      content = [
        EmptyState(icon: Icons.cloud_off_rounded, title: _error, error: true, actionLabel: s.t('retry'), onAction: _load)
      ];
    } else if (_rows == null) {
      content = [const _PodiumSkeleton(), const SkeletonRows()];
    } else if (_rows!.isEmpty) {
      content = [EmptyState(icon: Icons.flag_rounded, title: s.t('rank_empty'))];
    } else {
      content = [
        _Podium(rows: _rows!),
        _List(rows: _rows!),
        if (_me != null) _List(rows: [_me!], startRank: asInt(_me!['rank'])),
      ];
    }

    final c = s.c;
    final league = s.isStaff ? _league : s.st.league;
    final schoolScope = s.isTeacher && _scope == 'school';
    final header = AppCard(
      padding: const EdgeInsets.all(S.x4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (s.isTeacher) ...[
          Segmented<String>(
            key: const ValueKey('rank-scope'),
            values: const ['school', 'league'],
            labels: [s.t('my_school'), s.t('whole_app')],
            value: _scope,
            onChanged: (v) {
              setState(() {
                _scope = v;
                _rows = null;
              });
              _load();
            },
          ),
          const SizedBox(height: S.x4),
        ],
        Row(children: [
          schoolScope
              ? const IconTile(Icons.school_rounded, size: 48, vivid: true)
              : LeagueBadge(league: league, size: 48),
          const SizedBox(width: S.x3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(schoolScope ? s.school : s.tr(kLeagueNames[league] ?? kLeagueNames['beginner']!),
                  style: AppType.headline.copyWith(color: c.text)),
              const SizedBox(height: 2),
              Text(s.t('rank_rule'), style: AppType.caption.copyWith(color: c.text2)),
            ]),
          ),
        ]),
        if (s.isStaff && !schoolScope) ...[
          const SizedBox(height: S.x4),
          Segmented<String>(
            values: kLeagues,
            labels: [for (final l in kLeagues) s.tr(kLeagueNames[l]!).split(' ').first],
            value: _league,
            onChanged: (v) {
              setState(() {
                _league = v;
                _rows = null;
              });
              _load();
            },
          ),
        ],
        const SizedBox(height: S.x3),
        Segmented<String>(
          key: const ValueKey('period'),
          values: const ['week', 'month'],
          labels: [s.t('period_week'), s.t('period_month')],
          value: _period,
          onChanged: (v) {
            setState(() {
              _period = v;
              _rows = null;
            });
            _load();
          },
        ),
      ]),
    );

    return TabPage(
      title: s.t('ranking'),
      trailing: s.online ? refresh : null,
      onRefresh: s.online ? _load : null,
      children: [if (s.online) header, ...content],
    );
  }
}

// ------------------------------------------------------------ shohsupa / пьедестал
class _Podium extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  const _Podium({required this.rows});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final me = s.username.toLowerCase();
    // (o‘rin, balandlik, gradient) / (место, высота, градиент)
    final places = <(int, double, Gradient?, Color)>[
      (1, 96.0, c.yellowGradient, c.yellow),
      (0, 128.0, c.accentGradient, c.accent),
      (2, 72.0, null, c.text3),
    ];
    final cols = <Widget>[];
    for (final (idx, h, grad, col) in places) {
      if (idx >= rows.length) {
        cols.add(const Expanded(child: SizedBox()));
        continue;
      }
      final r = rows[idx];
      final mine = asStr(r['username']).toLowerCase() == me;
      cols.add(Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (idx == 0) Icon(Icons.workspace_premium_rounded, color: c.yellow, size: 26) else const SizedBox(height: 26),
          const SizedBox(height: 4),
          rowAvatar(s, r, size: idx == 0 ? 60 : 50, ring: idx == 0 || mine),
          const SizedBox(height: S.x2),
          Text(asStr(r['name']),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppType.footnote.copyWith(color: c.text, fontWeight: w8)),
          Text('${asInt(r['xp'])} XP', style: AppType.caption.copyWith(color: c.text2)),
          const SizedBox(height: S.x2),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: h),
            duration: Motion.of(context, const Duration(milliseconds: 700)),
            curve: Motion.curve,
            builder: (_, v, child) => Container(
              height: v,
              width: double.infinity,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: S.x3),
              decoration: BoxDecoration(
                gradient: grad,
                color: grad == null ? c.surfaceAlt : null,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(R.lg), bottom: Radius.circular(R.xs)),
                border: Border.all(color: grad == null ? c.hairline : const Color(0x33FFFFFF)),
                boxShadow: grad == null ? null : Shadows.glow(col, c, strength: 0.4),
              ),
              child: child,
            ),
            child: Text('${idx + 1}',
                style: AppType.title1.copyWith(
                    color: grad == null ? c.text2 : kWhite, shadows: grad == null ? null : kTextShadow)),
          ),
        ]),
      ));
      cols.add(const SizedBox(width: S.x3));
    }
    if (cols.isNotEmpty) cols.removeLast();
    return AppCard(
      padding: const EdgeInsets.fromLTRB(S.x4, S.x4, S.x4, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: cols),
    );
  }
}

class _PodiumSkeleton extends StatelessWidget {
  const _PodiumSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget col(double h) => Expanded(
          child: Column(children: [
            const Skeleton(width: 50, height: 50, radius: 25),
            const SizedBox(height: S.x2),
            const Skeleton(width: 60, height: 12),
            const SizedBox(height: S.x3),
            Skeleton(height: h, radius: R.lg),
          ]),
        );
    return AppCard(
      padding: const EdgeInsets.fromLTRB(S.x4, S.x4, S.x4, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        col(96),
        const SizedBox(width: S.x3),
        col(128),
        const SizedBox(width: S.x3),
        col(72),
      ]),
    );
  }
}

// ------------------------------------------------------------ ro‘yxat / список
class _List extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final int startRank;
  const _List({required this.rows, this.startRank = 1});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final me = s.username.toLowerCase();
    final items = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final mine = asStr(r['username']).toLowerCase() == me;
      if (i > 0) items.add(Divider(height: 1, thickness: 1, indent: 64, color: c.hairline));
      items.add(Container(
        margin: mine ? const EdgeInsets.symmetric(vertical: 4) : EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: mine
            ? BoxDecoration(
                color: c.accentSoft,
                borderRadius: R.all(R.md),
                border: Border.all(color: c.accent.withAlpha(0x59)),
              )
            : null,
        child: Row(children: [
          SizedBox(
            width: 26,
            child: FittedBox(
              child: Text('${startRank + i}',
                  textAlign: TextAlign.center,
                  style: AppType.headline.copyWith(color: startRank + i <= 3 ? c.accentText : c.text3, fontWeight: w8)),
            ),
          ),
          const SizedBox(width: S.x2),
          rowAvatar(s, r, size: 40),
          const SizedBox(width: S.x3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(asStr(r['name']) + (mine ? '  ·  ${s.t('you')}' : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.subhead.copyWith(color: c.text, fontWeight: w8)),
              const SizedBox(height: 2),
              Text(
                [
                  if (asStr(r['school']).isNotEmpty) asStr(r['school']),
                  '${s.t('level')} ${asInt(r['level'])}',
                  '${asInt(r['streak'])} 🔥',
                ].join('  ·  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.caption.copyWith(color: c.text2),
              ),
            ]),
          ),
          const SizedBox(width: S.x2),
          Text('${asInt(r['xp'])} XP', style: AppType.subhead.copyWith(color: c.accentText, fontWeight: w8)),
        ]),
      ));
    }
    return AppCard(padding: const EdgeInsets.symmetric(horizontal: S.x2, vertical: S.x1), child: Column(children: items));
  }
}
