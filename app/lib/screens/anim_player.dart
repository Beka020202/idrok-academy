// Dars animatsiyalarini ko‘rsatish (qadamma-qadam yoki avtomatik).
// Показ анимаций уроков (по шагам или автоматически).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../lessons.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class AnimPlayer extends StatefulWidget {
  final AnimScene scene;
  const AnimPlayer({super.key, required this.scene});

  @override
  State<AnimPlayer> createState() => _AnimPlayerState();
}

class _AnimPlayerState extends State<AnimPlayer> {
  int f = 0;
  Timer? _timer;

  List<AnimFrame> get frames => widget.scene.frames;
  AnimFrame get frame => frames[f.clamp(0, frames.length - 1).toInt()];
  bool get playing => _timer != null;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnimPlayer old) {
    super.didUpdateWidget(old);
    if (f >= frames.length) f = frames.isEmpty ? 0 : frames.length - 1;
  }

  void _go(int to) {
    final v = to.clamp(0, frames.length - 1).toInt();
    if (v == f) return;
    HapticFeedback.selectionClick();
    setState(() => f = v);
  }

  void _toggle() {
    if (playing) {
      _timer!.cancel();
      setState(() => _timer = null);
      return;
    }
    if (f >= frames.length - 1) f = 0;
    setState(() {
      _timer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
        if (!mounted) return;
        if (f >= frames.length - 1) {
          _timer?.cancel();
          setState(() => _timer = null);
        } else {
          setState(() => f++);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final sc = widget.scene;
    final Widget stage = switch (sc.kind) {
      'trace' => _TraceStage(scene: sc, frame: frame),
      'render' => _RenderStage(scene: sc, frame: frame),
      'box' => _BoxStage(scene: sc, frame: frame),
      'flex' => _FlexStage(scene: sc, frame: frame),
      'learn' => _LearnStage(scene: sc, frame: frame),
      'chat' => _ChatStage(scene: sc, frame: frame),
      'grid' => _GridStage(scene: sc, frame: frame),
      _ => const SizedBox.shrink(),
    };
    final last = frames.length - 1;
    final kindLabel = switch (sc.kind) {
      'trace' => sc.lang == 'js' ? 'JavaScript' : 'Python',
      'render' => sc.lang == 'css' ? 'CSS' : 'HTML',
      'box' => 'CSS · box',
      'flex' => 'Flexbox',
      'learn' || 'grid' => 'AI',
      'chat' => 'Chat',
      _ => '',
    };
    return GestureDetector(
      key: const ValueKey('anim-player'),
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -250) _go(f + 1);
        if (v > 250) _go(f - 1);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: R.all(R.xxl),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: c.isDark ? const [Color(0xFF1C1F2B), Color(0xFF15171F)] : const [Color(0xFFFFFFFF), Color(0xFFF6F8FC)],
          ),
          border: Border.all(color: c.isDark ? const Color(0x1AFFFFFF) : const Color(0x0F0A1226)),
          boxShadow: [
            BoxShadow(color: c.accent.withAlpha(c.isDark ? 0x22 : 0x18), blurRadius: 30, offset: const Offset(0, 14)),
            ...Shadows.card(c),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Sarlavha qatori / строка заголовка
          Padding(
            padding: const EdgeInsets.fromLTRB(S.x4, S.x3, S.x3, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: c.accentSoft, borderRadius: R.all(R.pill)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_awesome_rounded, size: 12, color: c.accentText),
                  const SizedBox(width: 4),
                  Text(kindLabel.toUpperCase(), style: AppType.overline.copyWith(color: c.accentText, fontSize: 10)),
                ]),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: Motion.of(context, Motion.fast),
                child: Text('${f + 1} / ${frames.length}',
                    key: ValueKey('n$f'),
                    style: AppType.caption.copyWith(color: c.text2, fontFeatures: const [FontFeature.tabularFigures()])),
              ),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(S.x3, S.x3, S.x3, S.x3), child: stage),
          // Izoh / пояснение
          Container(
            margin: const EdgeInsets.fromLTRB(S.x3, 0, S.x3, S.x2),
            padding: const EdgeInsets.fromLTRB(S.x3, S.x3, S.x4, S.x3),
            decoration: BoxDecoration(
              color: c.isDark ? const Color(0x14FFFFFF) : const Color(0xFFF1F5FF),
              borderRadius: R.all(R.lg),
              border: Border.all(color: c.accent.withAlpha(0x22)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedContainer(
                duration: Motion.of(context, Motion.base),
                curve: Motion.pop,
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: c.accentGradient),
                child: Text('${f + 1}', style: AppType.caption.copyWith(color: kWhite, fontSize: 11)),
              ),
              const SizedBox(width: S.x3),
              Expanded(
                child: AnimatedSize(
                  duration: Motion.of(context, Motion.base),
                  curve: Motion.curve,
                  alignment: Alignment.topLeft,
                  child: AnimatedSwitcher(
                    duration: Motion.of(context, Motion.base),
                    switchInCurve: Motion.curve,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                          position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(a), child: child),
                    ),
                    layoutBuilder: (cur, prev) => Stack(alignment: Alignment.topLeft, children: [...prev, if (cur != null) cur]),
                    child: Text(s.tr(frame.say),
                        key: ValueKey(f), style: AppType.subhead.copyWith(color: c.text, fontWeight: w6, height: 1.45)),
                  ),
                ),
              ),
            ]),
          ),
          // Jarayon / прогресс
          Padding(
            padding: const EdgeInsets.fromLTRB(S.x4, S.x2, S.x4, 0),
            child: Row(children: [
              for (var k = 0; k < frames.length; k++) ...[
                if (k > 0) const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _go(k),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: AnimatedContainer(
                        duration: Motion.of(context, Motion.base),
                        curve: Motion.curve,
                        height: k == f ? 5 : 4,
                        decoration: BoxDecoration(
                          gradient: k <= f ? c.accentGradient : null,
                          color: k <= f ? null : (c.isDark ? const Color(0x1FFFFFFF) : const Color(0x140A1226)),
                          borderRadius: R.all(R.pill),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ]),
          ),
          // Boshqaruv / управление
          Padding(
            padding: const EdgeInsets.fromLTRB(S.x3, S.x1, S.x3, S.x3),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _RoundBtn(
                key: const ValueKey('anim-prev'),
                icon: Icons.chevron_left_rounded,
                tooltip: s.t('back'),
                onTap: f > 0 ? () => _go(f - 1) : null,
              ),
              const SizedBox(width: S.x5),
              _RoundBtn(
                key: const ValueKey('anim-play'),
                icon: playing ? Icons.pause_rounded : (f >= last ? Icons.replay_rounded : Icons.play_arrow_rounded),
                tooltip: s.t('anim_play'),
                big: true,
                onTap: _toggle,
              ),
              const SizedBox(width: S.x5),
              _RoundBtn(
                key: const ValueKey('anim-next'),
                icon: Icons.chevron_right_rounded,
                tooltip: s.t('next'),
                onTap: f < last ? () => _go(f + 1) : null,
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// iOS uslubidagi dumaloq tugma / круглая кнопка в стиле iOS.
class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool big;
  const _RoundBtn({super.key, required this.icon, required this.tooltip, this.onTap, this.big = false});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final size = big ? 52.0 : 40.0;
    final on = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        scale: 0.9,
        semanticLabel: tooltip,
        child: AnimatedOpacity(
          duration: Motion.of(context, Motion.fast),
          opacity: on ? 1 : 0.35,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: big ? c.accentGradient : null,
              color: big ? null : (c.isDark ? const Color(0x1AFFFFFF) : const Color(0xFFEFF2F8)),
              boxShadow: big ? Shadows.glow(c.accent, c, strength: 0.7) : null,
            ),
            child: AnimatedSwitcher(
              duration: Motion.of(context, Motion.fast),
              transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
              child: Icon(icon, key: ValueKey(icon), size: big ? 28 : 24, color: big ? kWhite : c.text),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================ KOD PANELI / ПАНЕЛЬ КОДА
class _CodePanel extends StatelessWidget {
  final List<String> code;
  final int line;
  final String label;
  final double fontSize;
  const _CodePanel({required this.code, required this.line, required this.label, this.fontSize = 12.5});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Container(
      decoration: BoxDecoration(color: c.codeBg, borderRadius: R.all(R.md)),
      padding: const EdgeInsets.symmetric(vertical: S.x2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(S.x3, 0, S.x3, 6),
            child: Text(label, style: AppType.caption.copyWith(color: c.codeMuted)),
          ),
        for (var k = 0; k < code.length; k++)
          AnimatedContainer(
            duration: Motion.of(context, Motion.base),
            curve: Motion.curve,
            color: k == line ? const Color(0x332F80FF) : const Color(0x00000000),
            padding: const EdgeInsets.symmetric(horizontal: S.x2, vertical: 2),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 16,
                child: AnimatedOpacity(
                  duration: Motion.of(context, Motion.fast),
                  opacity: k == line ? 1 : 0,
                  child: const Icon(Icons.play_arrow_rounded, size: 14, color: kSky),
                ),
              ),
              SizedBox(
                width: 18,
                child: Text('${k + 1}', style: AppType.mono.copyWith(fontSize: fontSize - 1.5, color: c.codeMuted)),
              ),
              Expanded(
                child: Text(code[k],
                    style: AppType.mono.copyWith(
                        fontSize: fontSize, height: 1.45, color: k == line ? kWhite : c.codeFg, fontWeight: k == line ? w7 : w4)),
              ),
            ]),
          ),
      ]),
    );
  }
}

// ============================================================ TRACE
class _TraceStage extends StatelessWidget {
  final AnimScene scene;
  final AnimFrame frame;
  const _TraceStage({required this.scene, required this.frame});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final file = scene.lang == 'js' ? 'script.js' : 'main.py';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _CodePanel(code: scene.code, line: frame.line, label: file),
      const SizedBox(height: S.x3),
      Row(children: [
        Icon(Icons.memory_rounded, size: 16, color: c.text2),
        const SizedBox(width: 6),
        Text(s.t('anim_memory'), style: AppType.caption.copyWith(color: c.text2)),
      ]),
      const SizedBox(height: S.x2),
      if (frame.vars.isEmpty && frame.arr == null)
        Text('—', style: AppType.subhead.copyWith(color: c.text3))
      else
        Wrap(spacing: S.x2, runSpacing: S.x2, children: [
          for (final e in frame.vars.entries) _VarBox(name: e.key, value: e.value, hot: e.key == frame.hot),
        ]),
      if (frame.arr != null) ...[
        const SizedBox(height: S.x3),
        _ArrayRow(name: frame.arrName, items: frame.arr!, hot: frame.arrHot),
      ],
      const SizedBox(height: S.x3),
      Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.all(S.x3),
        decoration: BoxDecoration(color: const Color(0xFF05070D), borderRadius: R.all(R.md)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.t('output'), style: AppType.caption.copyWith(color: const Color(0x99FFFFFF))),
          const SizedBox(height: 4),
          for (var k = math.max(0, frame.out.length - 4); k < frame.out.length; k++)
            TweenAnimationBuilder<double>(
              key: ValueKey('o$k-${frame.out[k]}'),
              tween: Tween(begin: 0, end: 1),
              duration: Motion.of(context, Motion.base),
              builder: (_, v, child) => Opacity(opacity: v, child: child),
              child: Text(frame.out[k], style: AppType.mono.copyWith(color: const Color(0xFF7CF6B0), fontSize: 13)),
            ),
        ]),
      ),
    ]);
  }
}

class _VarBox extends StatelessWidget {
  final String name, value;
  final bool hot;
  const _VarBox({required this.name, required this.value, required this.hot});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(name, style: AppType.mono.copyWith(fontSize: 12, color: c.text2, fontWeight: w7)),
      const SizedBox(height: 3),
      AnimatedContainer(
        duration: Motion.of(context, Motion.base),
        constraints: const BoxConstraints(minWidth: 56),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: hot ? c.accentSoft : (c.isDark ? c.surfaceAlt : const Color(0xFFF2F5FA)),
          borderRadius: R.all(R.sm),
          border: Border.all(color: hot ? c.accent : c.hairlineStrong, width: hot ? 2 : 1),
          boxShadow: hot ? Shadows.glow(c.accent, c, strength: 0.35) : null,
        ),
        child: AnimatedSwitcher(
          duration: Motion.of(context, Motion.base),
          transitionBuilder: (child, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: child)),
          child: Text(value,
              key: ValueKey(value),
              textAlign: TextAlign.center,
              style: AppType.monoStrong.copyWith(color: c.text, fontSize: 15)),
        ),
      ),
    ]);
  }
}

class _ArrayRow extends StatelessWidget {
  final String name;
  final List<String> items;
  final int hot;
  const _ArrayRow({required this.name, required this.items, required this.hot});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name, style: AppType.mono.copyWith(fontSize: 12, color: c.text2, fontWeight: w7)),
      const SizedBox(height: 4),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (var k = 0; k < items.length; k++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Column(children: [
                AnimatedContainer(
                  duration: Motion.of(context, Motion.base),
                  width: 66,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: k == hot ? c.accent : (c.isDark ? c.surfaceAlt : const Color(0xFFF2F5FA)),
                    borderRadius: R.all(R.sm),
                    border: Border.all(color: k == hot ? c.accent : c.hairlineStrong),
                  ),
                  child: Text(items[k],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.mono.copyWith(fontSize: 12, color: k == hot ? kWhite : c.text, fontWeight: w7)),
                ),
                const SizedBox(height: 3),
                Text('$k', style: AppType.caption.copyWith(color: k == hot ? c.accentText : c.text3)),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

// ============================================================ RENDER (HTML / CSS)
class _RenderStage extends StatelessWidget {
  final AnimScene scene;
  final AnimFrame frame;
  const _RenderStage({required this.scene, required this.frame});

  Map<String, String> _styleFor(RenderEl el) {
    final styles = frame.extra['styles'];
    final out = <String, String>{};
    if (styles is Map) {
      for (final key in ['all', el.style['class'] ?? '\u0000', '#${el.style['id'] ?? '\u0000'}']) {
        final v = styles[key];
        if (v is Map) out.addAll({for (final e in v.entries) '${e.key}': '${e.value}'});
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final shown = scene.els.take(frame.reveal).toList();
    final phone = Container(
      width: 150,
      height: 250,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: const Color(0xFF0A1226), borderRadius: BorderRadius.circular(26)),
      child: Container(
        decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(21)),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 5, bottom: 6),
              width: 44,
              height: 10,
              decoration: BoxDecoration(color: const Color(0xFF0A1226), borderRadius: R.all(R.pill)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              physics: const NeverScrollableScrollPhysics(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final el in shown)
                  TweenAnimationBuilder<double>(
                    key: ValueKey('${el.tag}-${el.line}'),
                    tween: Tween(begin: 0, end: 1),
                    duration: Motion.of(context, Motion.slow),
                    curve: Motion.curve,
                    builder: (_, v, child) =>
                        Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 8 * (1 - v)), child: child)),
                    child: Padding(padding: const EdgeInsets.only(bottom: 6), child: _Element(el: el, style: _styleFor(el))),
                  ),
              ]),
            ),
          ),
        ]),
      ),
    );
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: _CodePanel(
            code: scene.code, line: frame.line, label: scene.lang == 'css' ? 'style.css' : 'index.html', fontSize: 11),
      ),
      const SizedBox(width: S.x3),
      Column(children: [
        phone,
        const SizedBox(height: 4),
        Icon(Icons.phone_iphone_rounded, size: 14, color: c.text3),
      ]),
    ]);
  }
}

class _Element extends StatelessWidget {
  final RenderEl el;
  final Map<String, String> style;
  const _Element({required this.el, required this.style});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF111111);
    Color? hex(String? v) => v == null ? null : hexColor(v);
    final color = hex(style['color']);
    final size = double.tryParse(style['size'] ?? '');
    final bold = style['bold'] == '1';
    final align = style['align'] == 'center' ? TextAlign.center : TextAlign.left;
    TextStyle base(double sz, FontWeight w) => TextStyle(
        fontFamily: kBody, fontSize: size != null ? size / 2 : sz, fontWeight: bold ? w8 : w, color: color ?? ink, height: 1.25);
    final Widget out = switch (el.tag) {
      'h1' => Text(el.text, textAlign: align, style: base(19, w8)),
      'h2' => Text(el.text, textAlign: align, style: base(15, w8)),
      'h3' => Text(el.text, textAlign: align, style: base(12.5, w8)),
      'p' => Text(el.text, textAlign: align, style: base(10.5, w4)),
      'a' => Text(el.text,
          style: base(10.5, w6).copyWith(color: const Color(0xFF0A6CFF), decoration: TextDecoration.underline)),
      'li' => Text('•  ${el.text}', style: base(10.5, w4)),
      'oli' => Text(el.text, style: base(10.5, w4)),
      'img' => Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(colors: [Color(0xFFBDE6FF), Color(0xFF7FB2FF)]),
          ),
          child: const Icon(Icons.pets_rounded, color: kWhite, size: 30),
        ),
      'header' => Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: const Color(0xFF0A6CFF), borderRadius: BorderRadius.circular(6)),
          child: Text(el.text, style: base(10.5, w8).copyWith(color: kWhite)),
        ),
      'main' => Container(
          height: 80,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: const Color(0xFFEFF5FF), borderRadius: BorderRadius.circular(6)),
          child: Text(el.text, style: base(10, w6)),
        ),
      'footer' => Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: const Color(0xFFE6E9EF), borderRadius: BorderRadius.circular(6)),
          child: Text(el.text, style: base(9, w4).copyWith(color: const Color(0xFF666666))),
        ),
      'input' => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB8C2D3)), borderRadius: BorderRadius.circular(6)),
          child: Text(el.text, style: base(10, w4).copyWith(color: const Color(0xFF9AA4B5))),
        ),
      'button' => Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF0A6CFF), borderRadius: BorderRadius.circular(20)),
            child: Text(el.text, style: base(10, w7).copyWith(color: kWhite)),
          ),
        ),
      'th' || 'tr' => Container(
          decoration: BoxDecoration(
            color: el.tag == 'th' ? const Color(0xFF0A6CFF) : const Color(0xFFF4F7FC),
            border: Border.all(color: const Color(0xFFD5DCE6), width: 0.6),
          ),
          child: Row(children: [
            for (final cell in el.text.split('|'))
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(cell.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: base(9.5, el.tag == 'th' ? w8 : w4).copyWith(color: el.tag == 'th' ? kWhite : (color ?? ink))),
                ),
              ),
          ]),
        ),
      'strong' => Text(el.text, style: base(10.5, w8)),
      'em' => Text(el.text, style: base(10.5, w4).copyWith(fontStyle: FontStyle.italic)),
      'mark' => Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            color: const Color(0xFFFFE45C),
            child: Text(el.text, style: base(10.5, w6)),
          ),
        ),
      'hr' => Container(height: 1.5, margin: const EdgeInsets.symmetric(vertical: 3), color: const Color(0xFFCDD5E1)),
      'check' || 'radio' => Row(children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: el.tag == 'radio' ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: el.tag == 'radio' ? null : BorderRadius.circular(3),
              color: el.text.startsWith('*') ? const Color(0xFF0A6CFF) : kWhite,
              border: Border.all(color: const Color(0xFF0A6CFF), width: 1.4),
            ),
            child: el.text.startsWith('*') ? const Icon(Icons.check_rounded, size: 9, color: kWhite) : null,
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(el.text.replaceFirst('*', ''), style: base(10, w4))),
        ]),
      'select' => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB8C2D3)), borderRadius: BorderRadius.circular(6)),
          child: Row(children: [
            Expanded(child: Text(el.text, style: base(10, w6))),
            const Icon(Icons.expand_more_rounded, size: 14, color: Color(0xFF5B6475)),
          ]),
        ),
      'label' => Text(el.text, style: base(9, w7).copyWith(color: color ?? const Color(0xFF5B6475))),
      _ => AnimatedContainer(
          duration: Motion.of(context, Motion.base),
          curve: Motion.curve,
          width: style['w'] == null ? null : 128 * ((double.tryParse(style['w']!) ?? 100) / 100),
          padding: EdgeInsets.all(double.tryParse(style['pad'] ?? '') ?? 8),
          transform: Matrix4.diagonal3Values(double.tryParse(style['scale'] ?? '') ?? 1, double.tryParse(style['scale'] ?? '') ?? 1, 1),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: hex(style['bg']) ?? const Color(0x00000000),
            borderRadius: BorderRadius.circular((double.tryParse(style['radius'] ?? '') ?? 0) / 2),
            border: style['border'] != null
                ? Border.all(color: hex(style['border'])!, width: 2)
                : style['bg'] == null
                    ? Border.all(color: const Color(0xFFD5DCE6))
                    : null,
            boxShadow: style['shadow'] == '1'
                ? const [BoxShadow(color: Color(0x400A1226), blurRadius: 12, offset: Offset(0, 6))]
                : null,
          ),
          child: Text(el.text, textAlign: align, style: base(11, w6)),
        ),
    };
    return AnimatedDefaultTextStyle(
      duration: Motion.of(context, Motion.base),
      style: const TextStyle(),
      child: out,
    );
  }
}

// ============================================================ BOX MODEL
class _BoxStage extends StatelessWidget {
  final AnimScene scene;
  final AnimFrame frame;
  const _BoxStage({required this.scene, required this.frame});

  @override
  Widget build(BuildContext context) {
    final layer = (frame.extra['layer'] as int?) ?? 0;
    final d = Motion.of(context, Motion.slow);
    Widget label(String t, Color col) => Text(t, style: AppType.caption.copyWith(color: col, fontSize: 10));
    return Column(children: [
      _CodePanel(code: scene.code, line: frame.line, label: 'style.css', fontSize: 11.5),
      const SizedBox(height: S.x3),
      SizedBox(
        height: 210,
        child: Center(
          child: AnimatedContainer(
            duration: d,
            curve: Motion.curve,
            padding: EdgeInsets.all(layer >= 3 ? 22 : 0),
            decoration: BoxDecoration(
              color: layer >= 3 ? const Color(0xFFFFF1D6) : const Color(0x00FFF1D6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(clipBehavior: Clip.none, children: [
              AnimatedContainer(
                duration: d,
                curve: Motion.curve,
                decoration: BoxDecoration(
                  border: Border.all(color: layer >= 2 ? const Color(0xFF0A6CFF) : const Color(0x000A6CFF), width: layer >= 2 ? 5 : 0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedContainer(
                  duration: d,
                  curve: Motion.curve,
                  padding: EdgeInsets.all(layer >= 1 ? 20 : 0),
                  color: layer >= 1 ? const Color(0xFFBFE3FF) : const Color(0x00BFE3FF),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    color: kWhite,
                    child: Text('Matn', style: AppType.headline.copyWith(color: const Color(0xFF111111))),
                  ),
                ),
              ),
              if (layer >= 1) Positioned(left: 8, top: 2, child: label('padding', const Color(0xFF0058E6))),
              if (layer >= 2) Positioned(right: 8, bottom: -16, child: label('border', const Color(0xFF0A6CFF))),
              if (layer >= 3) Positioned(left: -2, top: -20, child: label('margin', const Color(0xFFB7791F))),
            ]),
          ),
        ),
      ),
    ]);
  }
}

// ============================================================ FLEX
class _FlexStage extends StatelessWidget {
  final AnimScene scene;
  final AnimFrame frame;
  const _FlexStage({required this.scene, required this.frame});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final mode = '${frame.extra['mode'] ?? 'block'}';
    const colors = [Color(0xFF0A6CFF), Color(0xFF3FA9FF), Color(0xFF0A1226)];
    return Column(children: [
      _CodePanel(code: scene.code, line: frame.line, label: 'style.css', fontSize: 11.5),
      const SizedBox(height: S.x3),
      Container(
        height: 172,
        decoration: BoxDecoration(
          color: c.isDark ? c.surfaceAlt : const Color(0xFFF2F5FA),
          borderRadius: R.all(R.md),
          border: Border.all(color: c.hairline),
        ),
        child: LayoutBuilder(builder: (_, box) {
          const sz = 46.0;
          final w = box.maxWidth;
          return Stack(children: [
            for (var k = 0; k < 3; k++)
              AnimatedPositioned(
                duration: Motion.of(context, Motion.slow),
                curve: Motion.curve,
                left: switch (mode) {
                  'row' => 10 + k * (sz + 4),
                  'center' => (w - (3 * sz + 8)) / 2 + k * (sz + 4),
                  'gap' => (w - (3 * sz + 24)) / 2 + k * (sz + 12),
                  _ => 10,
                },
                top: mode == 'block' ? 10 + k * (sz + 6) : (172 - sz) / 2,
                child: Container(
                  width: mode == 'block' ? w - 20 : sz,
                  height: sz,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: colors[k], borderRadius: R.all(R.sm)),
                  child: Text('${k + 1}', style: AppType.headline.copyWith(color: kWhite)),
                ),
              ),
          ]);
        }),
      ),
    ]);
  }
}

// ============================================================ AI: LEARN
class _LearnStage extends StatelessWidget {
  final AnimScene scene;
  final AnimFrame frame;
  const _LearnStage({required this.scene, required this.frame});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final p = (frame.extra['line'] as num?)?.toDouble() ?? -1;
    final t = p < 0 ? 0.0 : ((p - 0.15) / 0.35).clamp(0.0, 1.0).toDouble();
    final angle = (30 + (-45 - 30) * t) * math.pi / 180;
    return AspectRatio(
      aspectRatio: 1.3,
      child: Container(
        decoration: BoxDecoration(
          color: c.isDark ? c.surfaceAlt : const Color(0xFFF7FAFF),
          borderRadius: R.all(R.md),
          border: Border.all(color: c.hairline),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: angle),
          duration: Motion.of(context, const Duration(milliseconds: 900)),
          curve: Motion.curve,
          builder: (_, a, __) => CustomPaint(
            painter: _LearnPainter(scene.points, p < 0 ? null : a, frame.extra['new'] == 1, c.isDark),
          ),
        ),
      ),
    );
  }
}

class _LearnPainter extends CustomPainter {
  final List<(double, double, int)> pts;
  final double? angle;
  final bool showNew;
  final bool dark;
  _LearnPainter(this.pts, this.angle, this.showNew, this.dark);

  // Chiziqning qaysi tomonida / с какой стороны линии
  int side(double x, double y, double a) {
    final nx = -math.sin(a), ny = math.cos(a);
    return ((x - 0.5) * nx + ((1 - y) - 0.5) * ny) > 0 ? 0 : 1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    Offset at(double x, double y) => Offset(16 + x * (size.width - 32), 12 + (1 - y) * (size.height - 24));
    final axis = Paint()
      ..color = dark ? const Color(0x33FFFFFF) : const Color(0x22000000)
      ..strokeWidth = 1;
    canvas.drawLine(at(0, 0), at(1, 0), axis);
    canvas.drawLine(at(0, 0), at(0, 1), axis);
    final a = angle;
    if (a != null) {
      final dx = math.cos(a), dy = math.sin(a);
      final p1 = at(0.5 - dx, 0.5 + dy * -1 + 0), p2 = at(0.5 + dx, 0.5 + dy);
      final q1 = at(0.5 - dx, 0.5 - dy);
      canvas.drawLine(q1, p2, Paint()
        ..color = const Color(0xFF0A6CFF)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round);
      p1.toString();
    }
    for (final (x, y, cls) in pts) {
      final o = at(x, y);
      final wrong = a != null && side(x, y, -a) != cls;
      canvas.drawCircle(o, 9, Paint()..color = cls == 0 ? const Color(0xFF3FA9FF) : const Color(0xFF0A1226));
      if (wrong) {
        canvas.drawCircle(o, 12, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFFD93A44));
      }
      final tp = TextPainter(
        text: TextSpan(text: cls == 0 ? '🐱' : '🐶', style: const TextStyle(fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    }
    if (showNew) {
      final o = at(0.8, 0.74);
      canvas.drawCircle(o, 13, Paint()..color = const Color(0xFFFFD45E));
      final tp = TextPainter(
          text: const TextSpan(text: '❓', style: TextStyle(fontSize: 13)), textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_LearnPainter o) => o.angle != angle || o.showNew != showNew || o.dark != dark;
}

// ============================================================ AI: CHAT
class _ChatStage extends StatelessWidget {
  final AnimScene scene;
  final AnimFrame frame;
  const _ChatStage({required this.scene, required this.frame});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final shown = scene.chat.take(frame.reveal).toList();
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(S.x3),
      decoration: BoxDecoration(
        color: c.isDark ? c.surfaceAlt : const Color(0xFFF2F5FA),
        borderRadius: R.all(R.md),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: S.x8),
            child: Icon(Icons.forum_rounded, size: 44, color: c.text3),
          ),
        for (var k = 0; k < shown.length; k++)
          TweenAnimationBuilder<double>(
            key: ValueKey('b$k'),
            tween: Tween(begin: 0, end: 1),
            duration: Motion.of(context, Motion.slow),
            curve: Motion.curve,
            builder: (_, v, child) =>
                Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child)),
            child: Align(
              alignment: shown[k].$1 ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: S.x2),
                child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  if (!shown[k].$1) ...[
                    const IconTile(Icons.smart_toy_rounded, size: 26, circle: true, vivid: true),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 260),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: shown[k].$1 ? c.accentGradient : null,
                        color: shown[k].$1 ? null : (c.isDark ? c.elevated : kWhite),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(shown[k].$1 ? 16 : 4),
                          bottomRight: Radius.circular(shown[k].$1 ? 4 : 16),
                        ),
                        boxShadow: Shadows.soft(c),
                      ),
                      child: Text(s.tr(shown[k].$2),
                          style: AppType.subhead.copyWith(color: shown[k].$1 ? kWhite : c.text, fontWeight: w6)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

// ============================================================ AI: GRID
class _GridStage extends StatelessWidget {
  final AnimScene scene;
  final AnimFrame frame;
  const _GridStage({required this.scene, required this.frame});

  Widget _grid(BuildContext context, List<int> px, double cell, {Color on = const Color(0xFF0A1226), bool glow = false}) {
    final c = colorsOf(context);
    return AnimatedContainer(
      duration: Motion.of(context, Motion.base),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: glow ? c.accent : c.hairlineStrong, width: glow ? 2.5 : 1),
        boxShadow: glow ? Shadows.glow(c.accent, c, strength: 0.4) : null,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (var r = 0; r < 5; r++)
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (var k = 0; k < 3; k++)
              Container(
                width: cell,
                height: cell,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: px[r * 3 + k] == 1 ? on : const Color(0xFFEFF3F9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final digits = kDigits.keys.toList();
    final cmp = frame.extra['cmp'] as int?;
    final win = frame.extra['win'] == 1;
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Column(children: [
        _grid(context, scene.grids.first, 16, on: c.accent),
        const SizedBox(height: 6),
        Text('?', style: AppType.title2.copyWith(color: c.text)),
      ]),
      const SizedBox(width: S.x4),
      Expanded(
        child: Wrap(spacing: S.x2, runSpacing: S.x2, alignment: WrapAlignment.center, children: [
          for (var k = 0; k < digits.length; k++)
            Column(mainAxisSize: MainAxisSize.min, children: [
              _grid(context, scene.grids[k + 1], 9, glow: cmp == digits[k]),
              const SizedBox(height: 3),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${digits[k]}', style: AppType.headline.copyWith(color: c.text)),
                if (win && cmp == digits[k]) Icon(Icons.check_circle_rounded, size: 16, color: c.yellow),
              ]),
              if (cmp == digits[k] && frame.extra['diff'] != null)
                Text('Δ ${frame.extra['diff']}', style: AppType.caption.copyWith(color: c.accentText)),
            ]),
        ]),
      ),
    ]);
  }
}
