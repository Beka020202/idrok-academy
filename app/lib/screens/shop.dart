import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

/// Narxni chiroyli yozish: 250000 -> 250 000 / красивый формат цены.
String fmtXp(int v) {
  final s = '$v';
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

/// Mahsulot rasmi / изображение товара.
class ShopImage extends StatelessWidget {
  final ShopItem item;
  final double? size; // null — ota o‘lchamini to‘ldiradi / заполняет родителя
  const ShopImage(this.item, {super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular((size ?? 160) * 0.22),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: c.isDark ? const [Color(0xFF1A2236), Color(0xFF0E1424)] : const [Color(0xFFFFFFFF), Color(0xFFE6EEFA)],
        ),
        border: Border.all(color: c.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        item.image,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => Icon(Icons.redeem_rounded, size: (size ?? 120) * 0.4, color: c.accentText),
      ),
    );
  }
}

/// XP do‘koni (haqiqiy sovg‘alar) / магазин XP (реальные призы).
class ShopTab extends StatefulWidget {
  const ShopTab({super.key});

  @override
  State<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<ShopTab> {
  List<ShopOrder>? _orders;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final s = AppScope.read(context);
    if (!s.online) return;
    setState(() => _loading = true);
    try {
      final o = await s.myOrders();
      if (mounted) setState(() => _orders = o);
    } catch (_) {
      // tarmoq xatosi — ro‘yxat ko‘rsatilmaydi / ошибка сети — список не показываем
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(ShopItem item) async {
    HapticFeedback.selectionClick();
    final bought = await showAppSheet<bool>(context, builder: (ctx) => _BuySheet(item: item));
    if (bought == true && mounted) {
      HapticFeedback.heavyImpact();
      await _loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final items = [...s.shopItems]..sort((a, b) => a.price.compareTo(b.price));
    final orders = _orders ?? const <ShopOrder>[];

    return TabPage(
      title: s.t('shop_title'),
      subtitle: s.t('shop_sub'),
      onRefresh: _loadOrders,
      children: [
        _Balance(xp: s.st.xp),
        if (!s.online)
          AppCard(
            kind: CardKind.tinted,
            padding: const EdgeInsets.all(S.x4),
            child: Row(children: [
              Icon(Icons.wifi_off_rounded, color: c.accentText),
              const SizedBox(width: S.x3),
              Expanded(child: Text(s.t('shop_online'), style: AppType.subhead.copyWith(color: c.text))),
            ]),
          ),
        gridOf([for (final it in items) _ItemCard(item: it, onTap: () => _open(it))], 2),
        if (s.online) ...[
          SectionHeader(s.t('my_orders'),
              trailing: _loading ? CupertinoActivityIndicator(color: c.text2, radius: 8) : null),
          if (orders.isEmpty && !_loading)
            AppCard(
              padding: const EdgeInsets.all(S.x4),
              child: Text(s.t('no_orders'), style: AppType.subhead.copyWith(color: c.text2)),
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: S.x4, vertical: S.x2),
              child: Column(children: [
                for (var k = 0; k < orders.length; k++) ...[
                  if (k > 0) Divider(height: 1, color: c.hairline),
                  OrderRow(order: orders[k]),
                ],
              ]),
            ),
        ],
      ],
    );
  }
}

class _Balance extends StatelessWidget {
  final int xp;
  const _Balance({required this.xp});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    return Container(
      padding: const EdgeInsets.all(S.x5),
      decoration: BoxDecoration(
        borderRadius: R.all(R.xxl),
        gradient: c.heroGradient,
        boxShadow: Shadows.glow(c.accent, c, strength: 0.8),
      ),
      child: Row(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x2EFFFFFF),
            border: Border.all(color: const Color(0x40FFFFFF)),
          ),
          child: const Icon(Icons.bolt_rounded, color: kWhite, size: 32, shadows: kTextShadow),
        ),
        const SizedBox(width: S.x4),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.t('balance'), style: AppType.footnote.copyWith(color: const Color(0xD9FFFFFF))),
            CountUp(xp, style: AppType.largeTitle.copyWith(color: kWhite, shadows: kTextShadow)),
          ]),
        ),
        Text('XP', style: AppType.title2.copyWith(color: const Color(0xD9FFFFFF))),
      ]),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ShopItem item;
  final VoidCallback onTap;
  const _ItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final can = s.st.xp >= item.price;
    final share = item.price == 0 ? 1.0 : (s.st.xp / item.price).clamp(0.0, 1.0).toDouble();
    return AppCard(
      key: ValueKey('shop-${item.id}'),
      onTap: onTap,
      padding: const EdgeInsets.all(S.x3),
      radius: R.xl,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AspectRatio(aspectRatio: 1, child: ShopImage(item, size: null)),
        const SizedBox(height: S.x3),
        Text(s.tr(item.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.headline.copyWith(color: c.text)),
        const SizedBox(height: 4),
        Row(children: [
          Icon(Icons.bolt_rounded, size: 16, color: c.yellow),
          const SizedBox(width: 2),
          Expanded(
            child: Text('${fmtXp(item.price)} XP',
                maxLines: 1, style: AppType.subhead.copyWith(color: can ? c.yellowText : c.text2, fontWeight: w8)),
          ),
        ]),
        const SizedBox(height: S.x2),
        AppProgress(share, height: 5, gradient: can ? c.yellowGradient : c.accentGradient),
      ]),
    );
  }
}

class _BuySheet extends StatefulWidget {
  final ShopItem item;
  const _BuySheet({required this.item});

  @override
  State<_BuySheet> createState() => _BuySheetState();
}

class _BuySheetState extends State<_BuySheet> {
  bool _busy = false;

  Future<void> _buy() async {
    final s = AppScope.read(context);
    setState(() => _busy = true);
    final ok = await s.buy(widget.item);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final it = widget.item;
    final can = s.st.xp >= it.price;
    final need = it.price - s.st.xp;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(child: ShopImage(it, size: 220)),
      const SizedBox(height: S.x4),
      Text(s.tr(it.name), textAlign: TextAlign.center, style: AppType.title2.copyWith(color: c.text)),
      const SizedBox(height: S.x2),
      Text(s.tr(it.desc), textAlign: TextAlign.center, style: AppType.subhead.copyWith(color: c.text2)),
      const SizedBox(height: S.x4),
      Center(
        child: AppPill('${fmtXp(it.price)} XP', icon: Icons.bolt_rounded, iconColor: c.yellow, tone: Tone.yellow),
      ),
      const SizedBox(height: S.x3),
      Text(
        can ? s.t('buy_note') : s.t('need_more').replaceAll('{n}', fmtXp(need)),
        textAlign: TextAlign.center,
        style: AppType.footnote.copyWith(color: can ? c.text2 : c.danger),
      ),
      const SizedBox(height: S.x5),
      AppButton(
        s.t('buy'),
        key: const ValueKey('buy-confirm'),
        onPressed: can && !_busy && s.online ? _buy : null,
        loading: _busy,
        expand: true,
        icon: Icons.shopping_bag_rounded,
      ),
      const SizedBox(height: S.x2),
      AppButton(s.t('no'), kind: BtnKind.secondary, expand: true, onPressed: () => Navigator.of(context).pop(false)),
    ]);
  }
}

/// Buyurtma qatori / строка заказа.
class OrderRow extends StatelessWidget {
  final ShopOrder order;
  final bool teacher;
  final void Function(String status)? onStatus;
  const OrderRow({super.key, required this.order, this.teacher = false, this.onStatus});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final it = s.shopItem(order.itemId);
    final d = DateTime.fromMillisecondsSinceEpoch((order.ts * 1000).round());
    final date = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    final (label, tone) = switch (order.status) {
      'delivered' => (s.t('st_delivered'), Tone.yellow),
      'cancelled' => (s.t('st_cancelled'), Tone.danger),
      _ => (s.t('st_new'), Tone.accent),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: S.x3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          if (it != null) ShopImage(it, size: 48) else const IconTile(Icons.redeem_rounded, size: 48),
          const SizedBox(width: S.x3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(it != null ? s.tr(it.name) : order.itemId,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.subhead.copyWith(color: c.text, fontWeight: w8)),
              const SizedBox(height: 2),
              Text(
                teacher
                    ? '${order.name.isEmpty ? order.username : order.name} · ${order.school} · ${order.city}'
                    : '$date · ${fmtXp(order.price)} XP',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppType.caption.copyWith(color: c.text2),
              ),
            ]),
          ),
          const SizedBox(width: S.x2),
          AppPill(label, tone: tone, small: true),
        ]),
        if (teacher && order.status == 'new' && onStatus != null) ...[
          const SizedBox(height: S.x3),
          Row(children: [
            Expanded(
              child: AppButton(s.t('deliver'),
                  height: 40, kind: BtnKind.success, icon: Icons.check_rounded, onPressed: () => onStatus!('delivered')),
            ),
            const SizedBox(width: S.x2),
            Expanded(
              child: AppButton(s.t('cancel_order'),
                  height: 40, kind: BtnKind.secondary, icon: Icons.undo_rounded, onPressed: () => onStatus!('cancelled')),
            ),
          ]),
        ],
      ]),
    );
  }
}
