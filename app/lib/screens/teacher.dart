import 'package:flutter/material.dart';

import '../api.dart';
import '../lessons.dart';
import '../progress.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'ranking.dart' show asInt, asStr, rowAvatar;

/// 5. Ustoz paneli / панель учителя.
class TeacherTab extends StatefulWidget {
  const TeacherTab({super.key});

  @override
  State<TeacherTab> createState() => _TeacherTabState();
}

class _TeacherTabState extends State<TeacherTab> {
  List<Map<String, dynamic>>? _rows;
  String _error = '';
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final s = AppScope.read(context);
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final res = await s.api.call(s.isAdmin ? '/api/admin/students' : '/api/teacher/students');
      final rows = res['rows'];
      _rows = rows is List ? [for (final r in rows) if (r is Map) Map<String, dynamic>.from(r)] : [];
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
    final rows = _rows;

    List<Widget> content;
    if (_error.isNotEmpty) {
      content = [
        EmptyState(icon: Icons.cloud_off_rounded, title: _error, error: true, actionLabel: s.t('retry'), onAction: _load)
      ];
    } else if (rows == null) {
      content = [
        Row(children: const [
          Expanded(child: Skeleton(height: 108, radius: R.lg)),
          SizedBox(width: S.x3),
          Expanded(child: Skeleton(height: 108, radius: R.lg)),
          SizedBox(width: S.x3),
          Expanded(child: Skeleton(height: 108, radius: R.lg)),
        ]),
        const SkeletonRows(count: 4),
      ];
    } else {
      final today = todayStr();
      final now = DateTime.now();
      content = [
        Row(children: [
          Expanded(child: StatTile(icon: Icons.groups_rounded, value: '${rows.length}', label: s.t('students'))),
          const SizedBox(width: S.x3),
          Expanded(
            child: StatTile(
              icon: Icons.menu_book_rounded,
              value: '${rows.fold<int>(0, (a, r) => a + _doneOf(r).length)}',
              label: s.t('lessons'),
            ),
          ),
          const SizedBox(width: S.x3),
          Expanded(
            child: StatTile(
              icon: Icons.today_rounded,
              value: '${rows.where((r) => asStr(r['last_day']) == today).length}',
              label: '${s.t('today')} · ${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}',
            ),
          ),
        ]),
        if (s.isAdmin)
          AppTextField(
            key: const ValueKey('student-search'),
            hint: s.t('search_students'),
            icon: Icons.search_rounded,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        if (rows.isEmpty) EmptyState(icon: Icons.school_rounded, title: s.t('no_students')),
        for (final r in rows)
          if (_query.isEmpty ||
              '${asStr(r['name'])} ${asStr(r['school'])} ${asStr(r['district'])} ${asStr(r['region'])}'
                  .toLowerCase()
                  .contains(_query))
            _StudentCard(r: r),
      ];
    }

    return TabPage(
      title: s.isAdmin ? s.t('students_tab') : s.t('my_school'),
      subtitle: s.isAdmin ? s.t('admin_students_sub') : '${s.school} · ${s.district}',
      trailing: refresh,
      onRefresh: _load,
      children: content,
    );
  }
}

List<String> _doneOf(Map<String, dynamic> r) => r['done'] is List ? [for (final x in r['done'] as List) '$x'] : [];

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> r;
  const _StudentCard({required this.r});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final done = _doneOf(r).toSet();
    final last = asStr(r['last_day']);
    final league = asStr(r['league']);
    return AppCard(
      padding: const EdgeInsets.all(S.x4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          rowAvatar(s, r, size: 50),
          const SizedBox(width: S.x3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(asStr(r['name']),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.headline.copyWith(color: c.text)),
              Text([asStr(r['school']), asStr(r['district'])].where((x) => x.isNotEmpty).join(' · '),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(color: c.text2)),
              Text('@${asStr(r['username'])}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(color: c.text3)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${asInt(r['xp_total'])} XP', style: AppType.headline.copyWith(color: c.accentText, fontWeight: w8)),
            const SizedBox(height: 2),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.local_fire_department_rounded, size: 14, color: c.accent),
              Text(' ${asInt(r['streak'])}   ', style: AppType.caption.copyWith(color: c.text2)),
              Icon(Icons.calendar_view_week_rounded, size: 14, color: c.yellow),
              Text(' +${asInt(r['week_xp'])}', style: AppType.caption.copyWith(color: c.text2)),
            ]),
          ]),
        ]),
        const SizedBox(height: S.x3),
        Row(children: [
          LeagueBadge(league: league, size: 22),
          const SizedBox(width: S.x2),
          Text(league.isEmpty ? s.t('no_league') : s.tr(kLeagueNames[league] ?? kLeagueNames['beginner']!),
              style: AppType.caption.copyWith(color: c.text2)),
        ]),
        const SizedBox(height: S.x4),
        Row(children: [
          for (final co in kCourses) ...[
            if (co != kCourses.first) const SizedBox(width: S.x3),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(co.tag, style: AppType.caption.copyWith(color: c.text2, fontFamily: kMono)),
                const SizedBox(height: 6),
                AppProgress(
                  co.lessonsFor(league).where((l) => done.contains(l.id)).length /
                      (co.lessonsFor(league).isEmpty ? 1 : co.lessonsFor(league).length),
                  height: 6,
                  color: courseColor(co, c),
                ),
              ]),
            ),
          ],
        ]),
        const SizedBox(height: S.x3),
        Row(children: [
          Icon(Icons.schedule_rounded, size: 14, color: c.text3),
          const SizedBox(width: 4),
          Text('${s.t('last_active')}: ${last.isEmpty ? s.t('never') : last}',
              style: AppType.caption.copyWith(color: c.text3)),
        ]),
      ]),
    );
  }
}
