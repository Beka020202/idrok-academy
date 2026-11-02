// Admin paneli: ustoz kodlari va sovg‘a buyurtmalari.
// Панель администратора: коды учителей и заказы призов.
import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'profile_form.dart';
import 'ranking.dart' show asStr;
import 'shop.dart' show OrderRow;

/// Ustoz kodlari / коды учителей.
class AdminCodesTab extends StatefulWidget {
  const AdminCodesTab({super.key});

  @override
  State<AdminCodesTab> createState() => _AdminCodesTabState();
}

class _AdminCodesTabState extends State<AdminCodesTab> {
  final SchoolValue _school = SchoolValue();
  final _note = TextEditingController();
  List<Map<String, dynamic>>? _rows;
  bool _loading = false;
  bool _error = false;
  String _formError = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = AppScope.read(context);
    setState(() => _loading = true);
    final rows = await s.fetchRows('/api/admin/codes');
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = rows == null;
      if (rows != null) _rows = rows;
    });
  }

  Future<void> _create() async {
    final s = AppScope.read(context);
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_school.complete) {
      setState(() => _formError = s.t('err_school'));
      return;
    }
    setState(() => _formError = '');
    final res = await s.post('/api/admin/codes', {
      'region': _school.region,
      'district': _school.district,
      'school': _school.label,
      'note': _note.text.trim(),
    });
    if (res == null || !mounted) return;
    final code = '${res['code']}';
    _note.clear();
    _load();
    await showCodeSheet(context, code, '${_school.label} · ${_school.district}');
  }

  Future<void> _revoke(String code) async {
    final s = AppScope.read(context);
    final res = await s.post('/api/admin/codes/revoke', {'code': code});
    if (res != null) _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final rows = _rows;
    return TabPage(
      title: s.t('codes_tab'),
      subtitle: s.t('codes_sub'),
      onRefresh: _load,
      children: [
        AppCard(
          padding: const EdgeInsets.all(S.x5),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const IconTile(Icons.key_rounded, size: 40, vivid: true),
              const SizedBox(width: S.x3),
              Expanded(child: Text(s.t('code_new'), style: AppType.title3.copyWith(color: c.text))),
            ]),
            const SizedBox(height: S.x2),
            Text(s.t('code_steps'), style: AppType.footnote.copyWith(color: c.text2)),
            const SizedBox(height: S.x4),
            SchoolPicker(value: _school, onChanged: () => setState(() {})),
            const SizedBox(height: S.x4),
            AppTextField(
              key: const ValueKey('code-note'),
              controller: _note,
              label: s.t('code_note'),
              hint: s.t('code_note_hint'),
              icon: Icons.person_rounded,
              maxLength: 80,
            ),
            if (_formError.isNotEmpty) ...[const SizedBox(height: S.x3), ErrorBox(_formError)],
            const SizedBox(height: S.x4),
            AppButton(s.t('code_make'),
                key: const ValueKey('code-make'),
                onPressed: s.busy ? null : _create,
                loading: s.busy,
                expand: true,
                icon: Icons.add_rounded),
          ]),
        ),
        SectionHeader(s.t('code_list'),
            trailing: _loading ? CupertinoActivityIndicator(color: c.text2, radius: 8) : null),
        if (_error && rows == null)
          EmptyState(icon: Icons.cloud_off_rounded, title: s.t('err_conn'), error: true, actionLabel: s.t('retry'), onAction: _load)
        else if (rows == null)
          const SkeletonRows(count: 3)
        else if (rows.isEmpty)
          EmptyState(icon: Icons.key_off_rounded, title: s.t('code_empty'))
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: S.x4, vertical: S.x2),
            child: Column(children: [
              for (var k = 0; k < rows.length; k++) ...[
                if (k > 0) Divider(height: 1, color: c.hairline),
                _CodeRow(r: rows[k], onRevoke: () => _revoke(asStr(rows[k]['code']))),
              ],
            ]),
          ),
      ],
    );
  }
}

class _CodeRow extends StatelessWidget {
  final Map<String, dynamic> r;
  final VoidCallback onRevoke;
  const _CodeRow({required this.r, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final used = asStr(r['used_by']).isNotEmpty;
    final code = asStr(r['code']);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: S.x3),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Pressable(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                s.toast(s.t('copied'), icon: Icons.copy_rounded);
              },
              child: Text(code, style: AppType.monoStrong.copyWith(color: used ? c.text3 : c.accentText)),
            ),
            const SizedBox(height: 2),
            Text('${asStr(r['school'])} · ${asStr(r['district'])}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(color: c.text2)),
            if (asStr(r['note']).isNotEmpty)
              Text(asStr(r['note']),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(color: c.text3)),
          ]),
        ),
        const SizedBox(width: S.x2),
        if (used)
          AppPill(asStr(r['used_by']), icon: Icons.check_rounded, tone: Tone.yellow, small: true)
        else
          AppIconButton(Icons.delete_outline_rounded, tooltip: s.t('code_revoke'), color: c.danger, onPressed: onRevoke),
      ]),
    );
  }
}

/// Yangi kodni ko‘rsatish / показать новый код.
Future<void> showCodeSheet(BuildContext context, String code, String school) {
  final s = AppScope.read(context);
  return showAppSheet<void>(context, builder: (ctx) {
    final c = AppScope.of(ctx).c;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Center(child: IconTile(Icons.verified_user_rounded, size: 60, circle: true, vivid: true)),
      const SizedBox(height: S.x4),
      Text(s.t('code_ready'), textAlign: TextAlign.center, style: AppType.title3.copyWith(color: c.text)),
      const SizedBox(height: S.x2),
      Text(school, textAlign: TextAlign.center, style: AppType.subhead.copyWith(color: c.text2)),
      const SizedBox(height: S.x4),
      Container(
        padding: const EdgeInsets.symmetric(vertical: S.x4),
        decoration: BoxDecoration(color: c.accentSoft, borderRadius: R.all(R.lg)),
        child: SelectableText(code,
            key: const ValueKey('code-value'),
            textAlign: TextAlign.center,
            style: AppType.monoStrong.copyWith(fontSize: 26, color: c.accentText, letterSpacing: 2)),
      ),
      const SizedBox(height: S.x3),
      Text(s.t('code_once'), textAlign: TextAlign.center, style: AppType.footnote.copyWith(color: c.text2)),
      const SizedBox(height: S.x5),
      AppButton(s.t('copy'), icon: Icons.copy_rounded, expand: true, onPressed: () {
        Clipboard.setData(ClipboardData(text: code));
        s.toast(s.t('copied'), icon: Icons.copy_rounded);
      }),
      const SizedBox(height: S.x2),
      AppButton(s.t('ok'), kind: BtnKind.secondary, expand: true, onPressed: () => Navigator.of(ctx).pop()),
    ]);
  });
}

/// Sovg‘a buyurtmalari (sovg‘alarni admin o‘zi topshiradi).
/// Заказы призов (призы вручает сам админ).
class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  List<ShopOrder>? _orders;
  bool _error = false;
  String _filter = 'new';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final s = AppScope.read(context);
    try {
      final o = await s.teacherOrders();
      if (mounted) setState(() => _orders = o);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _set(ShopOrder o, String status) async {
    final s = AppScope.read(context);
    final ok = await s.setOrderStatus(o.id, status);
    if (ok && mounted) {
      s.toast(s.t(status == 'delivered' ? 'st_delivered' : 'st_cancelled'), icon: Icons.check_circle_rounded);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final all = _orders;
    final list = all == null ? null : [for (final o in all) if (_filter == 'all' || o.status == _filter) o];
    final newN = all?.where((o) => o.status == 'new').length ?? 0;
    return TabPage(
      title: s.t('orders_tab'),
      subtitle: s.t('orders_sub'),
      onRefresh: _load,
      children: [
        Segmented<String>(
          values: const ['new', 'delivered', 'all'],
          labels: ['${s.t('st_new')}${newN > 0 ? ' · $newN' : ''}', s.t('st_delivered'), s.t('all')],
          value: _filter,
          onChanged: (v) => setState(() => _filter = v),
        ),
        if (_error && all == null)
          EmptyState(icon: Icons.cloud_off_rounded, title: s.t('err_conn'), error: true, actionLabel: s.t('retry'), onAction: _load)
        else if (list == null)
          const SkeletonRows(count: 4)
        else if (list.isEmpty)
          EmptyState(icon: Icons.redeem_rounded, title: s.t('no_orders'))
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: S.x4, vertical: S.x2),
            child: Column(children: [
              for (var k = 0; k < list.length; k++) ...[
                if (k > 0) Divider(height: 1, color: c.hairline),
                OrderRow(order: list[k], teacher: true, onStatus: (st) => _set(list[k], st)),
              ],
            ]),
          ),
      ],
    );
  }
}
