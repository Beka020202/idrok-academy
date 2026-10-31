// ============================================================================
//  Idrok Academy — komponentlar kutubxonasi / библиотека компонентов
//  Barcha ekranlar faqat shu komponentlardan foydalanadi (uslub takrorlanmaydi).
//  Все экраны используют только эти компоненты (стили не дублируются).
// ============================================================================

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config.dart';
import 'lessons.dart';
import 'progress.dart';
import 'state.dart';
import 'theme.dart';

AppColors colorsOf(BuildContext context) => AppScope.of(context).c;

// ============================================================ FON / ФОН
/// Ilova foni: yumshoq to‘q sariq va sariq yorug‘lik dog‘lari (shisha uchun chuqurlik).
/// Фон: мягкие пятна оранжевого и жёлтого света (дают глубину стеклу).
class AppBackground extends StatelessWidget {
  final Widget child;
  final bool strong;
  const AppBackground({super.key, required this.child, this.strong = false});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return ColoredBox(
      color: c.bg,
      child: Stack(children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _GlowPainter(c.glowA, c.glowB, strong ? 1.25 : 1.0)),
          ),
        ),
        child,
      ]),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final Color a, b;
  final double k;
  _GlowPainter(this.a, this.b, this.k);

  void _blob(Canvas canvas, Offset center, double r, Color col) {
    final rect = Rect.fromCircle(center: center, radius: r);
    final paint = Paint()..shader = RadialGradient(colors: [col, col.withAlpha(0)]).createShader(rect);
    canvas.drawCircle(center, r, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    _blob(canvas, Offset(w * 0.95, -size.height * 0.04), w * 0.9 * k, a);
    _blob(canvas, Offset(-w * 0.2, size.height * 0.34), w * 0.75 * k, b);
    _blob(canvas, Offset(w * 1.05, size.height * 0.9), w * 0.6, a.withAlpha(0x10));
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.a != a || old.b != b || old.k != k;
}

// ============================================================ BOSISH / НАЖАТИЕ
/// Bosilganda yengil kichrayadi (iOS kabi, to‘lqinsiz).
/// При нажатии слегка уменьшается (как в iOS, без «волны»).
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;
  final String? semanticLabel;
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.97, this.haptic = true, this.semanticLabel});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: enabled
            ? () {
                if (widget.haptic) HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: Motion.of(context, _down ? Motion.press : Motion.base),
          curve: _down ? Curves.easeOut : Motion.pop,
          child: widget.child,
        ),
      ),
    );
  }
}

// ============================================================ TUGMALAR / КНОПКИ
enum BtnKind { primary, success, dark, secondary, ghost, danger }

/// Asosiy tugma: holatlari — oddiy, bosilgan, fokus, o‘chirilgan, yuklanmoqda.
/// Кнопка: состояния — обычное, нажатое, фокус, неактивное, загрузка.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final BtnKind kind;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final double height;

  const AppButton(
    this.label, {
    super.key,
    this.onPressed,
    this.kind = BtnKind.primary,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.height = 54,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _down = false;
  bool _focus = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  void _fire() {
    if (widget.onPressed == null || widget.loading) return;
    HapticFeedback.lightImpact();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final enabled = widget.onPressed != null && !widget.loading;
    final big = widget.height >= 50;
    final radius = BorderRadius.circular(big ? 18 : 14);

    Gradient? grad;
    Color? fill;
    Color fg;
    Border? border;
    List<BoxShadow>? shadow;
    var sheen = false;
    switch (widget.kind) {
      case BtnKind.primary:
        grad = c.accentGradient;
        fg = kWhite;
        shadow = Shadows.glow(c.accent, c, strength: _down ? 0.5 : 1);
        sheen = true;
      case BtnKind.success:
        grad = c.yellowGradient;
        fg = kWhite;
        shadow = Shadows.glow(c.yellow, c, strength: _down ? 0.45 : 0.85);
        sheen = true;
      case BtnKind.dark:
        grad = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B2B2E), Color(0xFF0F0F10)],
        );
        fg = kWhite;
        border = Border.all(color: const Color(0x1FFFFFFF));
        shadow = Shadows.soft(c);
        sheen = true;
      case BtnKind.secondary:
        fill = c.isDark ? const Color(0x14FFFFFF) : const Color(0xCCFFFFFF);
        fg = c.text;
        border = Border.all(color: c.hairlineStrong);
        shadow = c.isDark ? null : Shadows.soft(c);
      case BtnKind.ghost:
        fill = const Color(0x00000000);
        fg = c.accentText;
      case BtnKind.danger:
        fill = c.dangerSoft;
        fg = c.danger;
        border = Border.all(color: c.danger.withAlpha(0x38));
    }
    if (!enabled && !widget.loading) shadow = null;
    if (_focus) {
      shadow = [...?shadow, BoxShadow(color: c.accent.withAlpha(0x66), spreadRadius: 3)];
    }

    final style = AppType.button.copyWith(
      color: fg,
      fontSize: big ? 16 : 14.5,
      shadows: fg == kWhite && widget.kind != BtnKind.dark ? kTextShadow : null,
    );
    // Kenglik cheklangan bo‘lsa matn qisqaradi (…), aks holda o‘z o‘lchamida.
    // При ограниченной ширине текст сокращается (…), иначе — по содержимому.
    final label = LayoutBuilder(
      key: const ValueKey('label'),
      builder: (context, box) {
        final text = Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[Icon(widget.icon, size: big ? 20 : 18, color: fg), const SizedBox(width: 8)],
            box.hasBoundedWidth ? Flexible(child: text) : text,
          ],
        );
      },
    );

    final box = AnimatedContainer(
      duration: Motion.of(context, Motion.fast),
      curve: Motion.curve,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: grad,
        color: grad == null ? fill : null,
        borderRadius: radius,
        border: border,
        boxShadow: shadow,
      ),
      child: Stack(alignment: Alignment.center, children: [
        if (sheen)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _down ? 1 : 0,
              duration: Motion.of(context, Motion.press),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: sheen || c.isDark ? const Color(0x1F000000) : const Color(0x0D000000),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: big ? 22 : 16),
          child: AnimatedSwitcher(
            duration: Motion.of(context, Motion.fast),
            child: widget.loading
                ? CupertinoActivityIndicator(key: const ValueKey('spin'), color: fg, radius: 10)
                : label,
          ),
        ),
      ]),
    );

    final result = FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (v) => setState(() => _focus = v),
      mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          _fire();
          return null;
        }),
      },
      child: Semantics(
        button: true,
        enabled: enabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _set(true) : null,
          onTapUp: enabled ? (_) => _set(false) : null,
          onTapCancel: enabled ? () => _set(false) : null,
          onTap: enabled ? _fire : null,
          child: AnimatedScale(
            scale: _down ? 0.965 : 1,
            duration: Motion.of(context, _down ? Motion.press : Motion.base),
            curve: _down ? Curves.easeOut : Motion.pop,
            child: AnimatedOpacity(
              opacity: enabled || widget.loading ? 1 : 0.4,
              duration: Motion.of(context, Motion.fast),
              child: box,
            ),
          ),
        ),
      ),
    );
    return widget.expand ? SizedBox(width: double.infinity, child: result) : result;
  }
}

/// Dumaloq ikonka-tugma / круглая кнопка-иконка.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? color;
  const AppIconButton(this.icon, {super.key, this.onPressed, this.tooltip, this.size = 42, this.color});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final w = Pressable(
      onTap: onPressed,
      scale: 0.9,
      semanticLabel: tooltip,
      child: AnimatedOpacity(
        opacity: onPressed == null ? 0.4 : 1,
        duration: Motion.of(context, Motion.fast),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.isDark ? c.surfaceAlt : c.surface,
            border: Border.all(color: c.hairline),
            boxShadow: Shadows.soft(c),
          ),
          child: Icon(icon, size: size * 0.47, color: color ?? c.text),
        ),
      ),
    );
    return tooltip == null ? w : Tooltip(message: tooltip!, child: w);
  }
}

// ============================================================ SIRTLAR / ПОВЕРХНОСТИ
enum CardKind { solid, inset, glass, tinted }

/// Karta. Ko‘pincha "solid" — toza sirt; shisha faqat kerakli joyda.
/// Карточка. Чаще «solid» — чистая поверхность; стекло — только где уместно.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final CardKind kind;
  final Color? tint;
  final Color? borderColor;
  final Gradient? gradient;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(S.x5),
    this.radius = R.xl,
    this.kind = CardKind.solid,
    this.tint,
    this.borderColor,
    this.gradient,
    this.shadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    Widget body;
    if (kind == CardKind.glass) {
      body = Glass(radius: radius, padding: padding, child: child);
    } else {
      Color? color;
      Border? border;
      List<BoxShadow>? sh;
      switch (kind) {
        case CardKind.solid:
          color = c.surface;
          border = Border.all(color: borderColor ?? c.hairline);
          sh = Shadows.card(c);
        case CardKind.inset:
          color = c.surfaceAlt;
          border = borderColor == null ? null : Border.all(color: borderColor!);
        case CardKind.tinted:
          color = tint ?? c.accentSoft;
          border = Border.all(color: borderColor ?? (tint ?? c.accent).withAlpha(0x30));
        case CardKind.glass:
          break;
      }
      body = AnimatedContainer(
        duration: Motion.of(context, Motion.base),
        curve: Motion.curve,
        padding: padding,
        decoration: BoxDecoration(
          color: gradient == null ? color : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          border: border,
          boxShadow: shadow ?? sh,
        ),
        child: child,
      );
      if (c.isDark && kind == CardKind.solid && gradient == null) {
        // Yuqori chetdagi nozik yorug‘lik / тонкий блик по верхней кромке.
        body = Stack(children: [
          body,
          Positioned(
            top: 0,
            left: radius,
            right: radius,
            child: IgnorePointer(
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0x00FFFFFF), Color(0x24FFFFFF), Color(0x00FFFFFF)]),
                ),
              ),
            ),
          ),
        ]);
      }
    }
    return onTap == null ? body : Pressable(onTap: onTap, scale: 0.98, child: body);
  }
}

/// Shisha material: orqa fonni xiralashtiradi / стекло: размывает фон под собой.
class Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final Color? color;
  final List<BoxShadow>? shadow;
  const Glass({super.key, required this.child, this.radius = R.xl, this.padding, this.blur = 24, this.color, this.shadow});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: r, boxShadow: shadow ?? Shadows.card(c)),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color ?? c.glass,
              borderRadius: r,
              border: Border.all(color: c.glassEdge),
            ),
            child: Stack(children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [c.isDark ? const Color(0x12FFFFFF) : const Color(0x80FFFFFF), const Color(0x00FFFFFF)],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(padding: padding ?? EdgeInsets.zero, child: child),
            ]),
          ),
        ),
      ),
    );
  }
}

// ============================================================ KICHIK ELEMENTLAR / МЕЛКИЕ ЭЛЕМЕНТЫ
enum Tone { neutral, accent, yellow, onColor, danger }

/// Tabletka (belgi) / «таблетка»-метка.
class AppPill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? iconColor;
  final Tone tone;
  final bool small;
  const AppPill(this.text, {super.key, this.icon, this.iconColor, this.tone = Tone.neutral, this.small = false});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final (bg, fg, bd) = switch (tone) {
      Tone.neutral => (c.isDark ? c.surfaceAlt : c.surface, c.text, c.hairline),
      Tone.accent => (c.accentSoft, c.accentText, const Color(0x00000000)),
      Tone.yellow => (c.yellowSoft, c.yellowText, const Color(0x00000000)),
      Tone.onColor => (const Color(0x2EFFFFFF), kWhite, const Color(0x40FFFFFF)),
      Tone.danger => (c.dangerSoft, c.danger, const Color(0x00000000)),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 9 : 11, vertical: small ? 4 : 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: R.all(R.pill),
        border: Border.all(color: bd),
        boxShadow: tone == Tone.neutral && !c.isDark ? Shadows.soft(c) : null,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: small ? 13 : 16, color: iconColor ?? fg),
          SizedBox(width: small ? 3 : 4),
        ],
        Text(
          text,
          maxLines: 1,
          style: (small ? AppType.caption : AppType.footnote.copyWith(fontWeight: w8)).copyWith(color: fg),
        ),
      ]),
    );
  }
}

/// Jarayon chizig‘i (silliq) / индикатор прогресса (плавный).
class AppProgress extends StatelessWidget {
  final double value;
  final double height;
  final Gradient? gradient;
  final Color? color;
  final Color? track;
  const AppProgress(this.value, {super.key, this.height = 8, this.gradient, this.color, this.track});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: R.all(R.pill),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(fit: StackFit.expand, children: [
          ColoredBox(color: track ?? (c.isDark ? const Color(0x1AFFFFFF) : const Color(0x12000000))),
          TweenAnimationBuilder<double>(
            tween: Tween(end: v),
            duration: Motion.of(context, Motion.slow),
            curve: Motion.curve,
            builder: (_, x, __) => FractionallySizedBox(
              widthFactor: x,
              heightFactor: 1,
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: R.all(R.pill),
                  color: gradient == null ? (color ?? c.accent) : null,
                  gradient: gradient,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Doiraviy jarayon / круговой прогресс.
class AppRing extends StatelessWidget {
  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Color track;
  final Widget? child;
  const AppRing(this.value,
      {super.key, this.size = 84, this.stroke = 8, required this.color, required this.track, this.child});

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween(end: v),
      duration: Motion.of(context, Motion.slow * 2),
      curve: Motion.curve,
      builder: (_, x, ch) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _RingPainter(x, stroke, color, track), child: Center(child: ch)),
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v, stroke;
  final Color color, track;
  _RingPainter(this.v, this.stroke, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = track);
    if (v > 0) canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * v, false, base..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.color != color || o.track != track || o.stroke != stroke;
}

/// Avatar (emoji) / аватар.
class AppAvatar extends StatelessWidget {
  final String emoji;
  final double size;
  final bool ring;
  const AppAvatar(this.emoji, {super.key, this.size = 44, this.ring = false});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final inner = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.isDark ? c.elevated : c.surfaceAlt,
        border: Border.all(color: ring ? c.bg : c.hairline, width: ring ? size * 0.045 : 1),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.46, height: 1.15)),
    );
    if (!ring) return SizedBox(width: size, height: size, child: inner);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: c.accentGradient),
      child: inner,
    );
  }
}

/// Ikonka plitkasi / плитка с иконкой.
class IconTile extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final Color? bg;
  final bool vivid;
  final bool circle;
  const IconTile(this.icon, {super.key, this.size = 44, this.color, this.bg, this.vivid = false, this.circle = false});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size * 0.32),
        gradient: vivid ? c.accentGradient : null,
        color: vivid ? null : (bg ?? c.accentSoft),
        boxShadow: vivid ? Shadows.glow(c.accent, c, strength: 0.5) : null,
      ),
      child: Icon(icon, size: size * 0.5, color: vivid ? kWhite : (color ?? c.accentText)),
    );
  }
}

/// Bo‘lim sarlavhasi / заголовок раздела.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: S.x1),
      child: Row(children: [
        Expanded(child: Text(title, style: AppType.title3.copyWith(color: c.text))),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// Katta sarlavha (iOS) / большой заголовок (iOS).
class LargeTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const LargeTitle(this.title, {super.key, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppType.largeTitle.copyWith(color: c.text)),
          if (subtitle != null) ...[
            const SizedBox(height: S.x1),
            Text(subtitle!, style: AppType.callout.copyWith(color: c.text2, fontWeight: w6)),
          ],
        ]),
      ),
      if (trailing != null) ...[const SizedBox(width: S.x3), trailing!],
    ]);
  }
}

/// iOS uslubidagi segmentli tanlov / сегментированный переключатель в стиле iOS.
class Segmented<T> extends StatelessWidget {
  final List<T> values;
  final List<String> labels;
  final List<IconData>? icons;
  final T value;
  final ValueChanged<T> onChanged;
  const Segmented({super.key, required this.values, required this.labels, this.icons, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final n = values.length;
    final idx = math.max(0, values.indexOf(value));
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.isDark ? c.surfaceAlt : const Color(0xFFEAE6E0),
        borderRadius: R.all(R.sm + 1),
      ),
      child: Stack(children: [
        AnimatedAlign(
          alignment: Alignment(n == 1 ? 0 : -1 + 2 * idx / (n - 1), 0),
          duration: Motion.of(context, Motion.base),
          curve: Motion.curve,
          child: FractionallySizedBox(
            widthFactor: 1 / n,
            heightFactor: 1,
            child: Container(
              decoration: BoxDecoration(
                color: c.isDark ? c.elevated : kWhite,
                borderRadius: R.all(R.sm - 2),
                border: c.isDark ? Border.all(color: c.hairline) : null,
                boxShadow: Shadows.soft(c),
              ),
            ),
          ),
        ),
        Row(children: [
          for (var i = 0; i < n; i++)
            Expanded(
              child: Semantics(
                selected: i == idx,
                button: true,
                label: labels[i],
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (values[i] == value) return;
                    HapticFeedback.selectionClick();
                    onChanged(values[i]);
                  },
                  child: Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (icons != null) ...[
                        Icon(icons![i], size: 16, color: i == idx ? c.text : c.text2),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.footnote
                              .copyWith(color: i == idx ? c.text : c.text2, fontWeight: i == idx ? w8 : w6),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ]),
    );
  }
}

// ============================================================ MAYDONLAR / ПОЛЯ ВВОДА
/// Matn maydoni: yorliq tepasida, fokusda yumshoq porlash.
/// Поле ввода: подпись сверху, при фокусе — мягкое свечение.
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? icon;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int minLines;
  final int maxLines;
  final bool autocorrect;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.icon,
    this.obscure = false,
    this.suffix,
    this.onSubmitted,
    this.onChanged,
    this.textInputAction,
    this.keyboardType,
    this.maxLength,
    this.minLines = 1,
    this.maxLines = 1,
    this.autocorrect = false,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted && _focus.hasFocus != _focused) setState(() => _focused = _focus.hasFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      if (widget.label != null)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(widget.label!, style: AppType.footnote.copyWith(color: c.text2, fontWeight: w7)),
        ),
      AnimatedContainer(
        duration: Motion.of(context, Motion.fast),
        curve: Motion.curve,
        decoration: BoxDecoration(
          color: c.isDark ? c.surfaceAlt : kWhite,
          borderRadius: R.all(R.md - 2),
          border: Border.all(color: _focused ? c.accent : c.hairlineStrong, width: _focused ? 1.5 : 1),
          boxShadow: _focused
              ? [BoxShadow(color: c.accent.withAlpha(0x2E), spreadRadius: 4)]
              : (c.isDark ? null : Shadows.soft(c)),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focus,
          obscureText: widget.obscure,
          onSubmitted: widget.onSubmitted,
          onChanged: widget.onChanged,
          textInputAction: widget.textInputAction,
          keyboardType: widget.keyboardType,
          maxLength: widget.maxLength,
          minLines: widget.obscure ? 1 : widget.minLines,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          autocorrect: widget.autocorrect,
          enableSuggestions: widget.autocorrect,
          textCapitalization: widget.textCapitalization,
          style: AppType.bodyStrong.copyWith(color: c.text),
          cursorColor: c.accent,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppType.bodyStrong.copyWith(color: c.text3),
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.symmetric(horizontal: widget.icon == null ? 16 : 4, vertical: 15),
            prefixIcon: widget.icon == null
                ? null
                : Icon(widget.icon, size: 20, color: _focused ? c.accent : c.text3),
            suffixIcon: widget.suffix,
          ),
        ),
      ),
    ]);
  }
}

// ============================================================ KOD / КОД
Widget _codeDot(Color col) => Container(width: 10, height: 10, decoration: BoxDecoration(color: col, shape: BoxShape.circle));

/// Kod oynasi sarlavhasi / шапка окна кода.
class CodeBar extends StatelessWidget {
  final String label;
  final Widget? trailing;
  const CodeBar(this.label, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: c.codeBar,
      child: Row(children: [
        _codeDot(kOrange),
        const SizedBox(width: 6),
        _codeDot(kYellow),
        const SizedBox(width: 6),
        _codeDot(const Color(0xFF55514B)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.caption.copyWith(color: c.codeMuted, fontFamily: kMono, letterSpacing: 0.4)),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

BoxDecoration _codeShell(AppColors c) => BoxDecoration(
      color: c.codeBg,
      borderRadius: R.all(R.lg),
      border: Border.all(color: c.isDark ? c.hairline : const Color(0x1F000000)),
      boxShadow: Shadows.card(c),
    );

/// Kod muharriri (tahrirlanadigan) / редактор кода.
class CodeEditor extends StatelessWidget {
  final String initial;
  final ValueChanged<String> onChanged;
  final int minLines;
  final bool enabled;
  final String label;
  const CodeEditor(
      {super.key, required this.initial, required this.onChanged, this.minLines = 6, this.enabled = true, this.label = ''});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Container(
      decoration: _codeShell(c),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CodeBar(label),
        CodeField(initial: initial, onChanged: onChanged, minLines: minLines, enabled: enabled),
      ]),
    );
  }
}

/// Faqat o‘qish uchun kod / код только для чтения.
class CodeBlock extends StatelessWidget {
  final String code;
  final String label;
  const CodeBlock(this.code, {super.key, this.label = ''});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Container(
      width: double.infinity,
      decoration: _codeShell(c),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CodeBar(label),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: SelectableText(code, style: AppType.mono.copyWith(color: c.codeFg)),
        ),
      ]),
    );
  }
}

/// Natija oynasi / окно вывода.
class Console extends StatelessWidget {
  final String text;
  final String label;
  final bool placeholder;
  const Console(this.text, {super.key, required this.label, this.placeholder = false});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Container(
      width: double.infinity,
      decoration: _codeShell(c),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CodeBar(label),
        AnimatedSize(
          duration: Motion.of(context, Motion.base),
          curve: Motion.curve,
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: SelectableText(
              text,
              style: AppType.mono.copyWith(color: placeholder ? c.codeMuted : c.codeFg),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Kod yozish maydoni (avtotuzatishsiz) / поле для кода (без автозамены).
class CodeField extends StatefulWidget {
  final String initial;
  final ValueChanged<String> onChanged;
  final int minLines;
  final bool enabled;
  const CodeField({super.key, required this.initial, required this.onChanged, this.minLines = 6, this.enabled = true});

  @override
  State<CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<CodeField> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      minLines: widget.minLines,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      smartQuotesType: SmartQuotesType.disabled,
      smartDashesType: SmartDashesType.disabled,
      inputFormatters: [_TabToSpaces()],
      style: AppType.mono.copyWith(color: c.codeFg),
      cursorColor: kOrange,
      decoration: const InputDecoration(
        border: InputBorder.none,
        isCollapsed: true,
        contentPadding: EdgeInsets.fromLTRB(16, 14, 16, 16),
      ),
    );
  }
}

/// Tab belgisini 4 bo‘sh joyga almashtiradi (Python uchun) / заменяет Tab на 4 пробела.
class _TabToSpaces extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (!newValue.text.contains('\t')) return newValue;
    final before = newValue.selection.baseOffset < 0
        ? newValue.text
        : newValue.text.substring(0, newValue.selection.baseOffset.clamp(0, newValue.text.length).toInt());
    final added = '\t'.allMatches(before).length * 3;
    final text = newValue.text.replaceAll('\t', '    ');
    final off = (newValue.selection.baseOffset < 0 ? text.length : newValue.selection.baseOffset + added)
        .clamp(0, text.length)
        .toInt();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: off));
  }
}

// ============================================================ HOLATLAR / СОСТОЯНИЯ
/// Yuklanish skeleti (yaltiroq) / скелетон загрузки (с бликом).
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  const Skeleton({super.key, this.width, this.height = 14, this.radius = R.xs});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _a.stop();
    } else if (!_a.isAnimating) {
      _a.repeat();
    }
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final base = c.isDark ? const Color(0xFF1E1E21) : const Color(0xFFECE8E2);
    final hi = c.isDark ? const Color(0xFF2A2A2E) : const Color(0xFFF7F5F1);
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) {
        final t = _a.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: R.all(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-2.0 + 4 * t, 0),
              end: Alignment(-1.0 + 4 * t, 0),
              colors: [base, hi, base],
            ),
          ),
        );
      },
    );
  }
}

/// Ro‘yxat uchun skelet qatorlari / строки-скелетоны для списка.
class SkeletonRows extends StatelessWidget {
  final int count;
  const SkeletonRows({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: S.x4, vertical: S.x2),
      child: Column(children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              const Skeleton(width: 40, height: 40, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Skeleton(width: 120.0 + (i % 3) * 30, height: 14),
                  const SizedBox(height: 8),
                  const Skeleton(width: 90, height: 10),
                ]),
              ),
              const Skeleton(width: 54, height: 16),
            ]),
          ),
      ]),
    );
  }
}

/// Bo‘sh / xato holati / пустое состояние или ошибка.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool error;
  const EmptyState(
      {super.key, required this.icon, required this.title, this.message, this.actionLabel, this.onAction, this.error = false});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: S.x6, vertical: S.x8),
      child: Column(children: [
        IconTile(icon, size: 64, circle: true, bg: error ? c.dangerSoft : c.accentSoft, color: error ? c.danger : c.accentText),
        const SizedBox(height: S.x4),
        Text(title, textAlign: TextAlign.center, style: AppType.headline.copyWith(color: c.text)),
        if (message != null) ...[
          const SizedBox(height: S.x1 + 2),
          Text(message!, textAlign: TextAlign.center, style: AppType.subhead.copyWith(color: c.text2, fontWeight: w6)),
        ],
        if (actionLabel != null) ...[
          const SizedBox(height: S.x5),
          AppButton(actionLabel!, onPressed: onAction, kind: BtnKind.secondary, height: 44, icon: Icons.refresh_rounded),
        ],
      ]),
    );
  }
}

/// Statistika plitkasi / плитка статистики.
class StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const StatTile({super.key, required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return AppCard(
      padding: const EdgeInsets.all(S.x4 - 2),
      radius: R.lg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconTile(icon, size: 32),
        const SizedBox(height: S.x3),
        Text(value, maxLines: 1, style: AppType.number.copyWith(color: c.text)),
        const SizedBox(height: 2),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(color: c.text2)),
      ]),
    );
  }
}

// ============================================================ HARAKAT / ДВИЖЕНИЕ
/// Xato javobda yengil silkinish / лёгкое покачивание при ошибке.
class Shake extends StatefulWidget {
  final int trigger;
  final Widget child;
  const Shake({super.key, required this.trigger, required this.child});

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !Motion.reduced(context)) _a.forward(from: 0);
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (_, child) {
        final t = _a.value;
        final dx = math.sin(t * math.pi * 6) * 7 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

/// Sekin "nafas oluvchi" porlash (joriy dars) / медленное «дыхание» (текущий урок).
class Breathing extends StatefulWidget {
  final Widget Function(double t) builder;
  const Breathing({super.key, required this.builder});

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _a.stop();
      _a.value = 0.5;
    } else if (!_a.isAnimating) {
      _a.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _a,
        builder: (_, __) => widget.builder(Curves.easeInOut.transform(_a.value)),
      );
}

/// Raqamni sanab chiqish / анимированный счётчик.
class CountUp extends StatelessWidget {
  final int value;
  final String prefix;
  final TextStyle style;
  const CountUp(this.value, {super.key, this.prefix = '', required this.style});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.toDouble()),
        duration: Motion.of(context, const Duration(milliseconds: 900)),
        curve: Motion.curve,
        builder: (_, x, __) => Text('$prefix${x.round()}', style: style),
      );
}

/// Paydo bo‘lish: pastdan yengil ko‘tarilib, ochiladi (kartalar uchun).
/// Появление: лёгкий подъём снизу и проявление (для карточек).
class Appear extends StatelessWidget {
  final Widget child;
  final int index;
  const Appear({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return child;
    final delay = (index * 0.08).clamp(0.0, 0.4).toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + (delay * 1000).round()),
      curve: Interval(delay / (0.52 + delay), 1, curve: Motion.curve),
      child: child,
      builder: (_, t, ch) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: ch),
      ),
    );
  }
}

/// Sahifa o‘tishi: yengil ko‘tarilish + paydo bo‘lish.
/// Переход между страницами: лёгкий подъём + проявление.
class AppRoute<T> extends PageRouteBuilder<T> {
  AppRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: Motion.page,
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (context, _, __) => builder(context),
          transitionsBuilder: (context, anim, _, child) {
            if (Motion.reduced(context)) return child;
            final a = CurvedAnimation(parent: anim, curve: Motion.curve, reverseCurve: Curves.easeInCubic);
            return FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(a),
                child: child,
              ),
            );
          },
        );
}

// ============================================================ OYNALAR / ОКНА
/// Pastdan chiquvchi shisha oyna / «стеклянный» лист снизу.
Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  final c = AppScope.read(context).c;
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: c.scrim,
    elevation: 0,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      final cc = AppScope.of(ctx).c;
      return Padding(
        padding: EdgeInsets.fromLTRB(10, 0, 10, 10 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: SafeArea(
          top: false,
          child: Glass(
            radius: 30,
            blur: 30,
            color: cc.isDark ? const Color(0xEB161618) : const Color(0xF2FFFFFF),
            padding: const EdgeInsets.fromLTRB(S.x6, S.x2 + 2, S.x6, S.x6),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(color: cc.hairlineStrong, borderRadius: R.all(R.pill)),
                ),
              ),
              const SizedBox(height: S.x5),
              builder(ctx),
            ]),
          ),
        ),
      );
    },
  );
}

/// Yuqoridan chiquvchi bildirishnoma / уведомление сверху.
class AppToast {
  static OverlayEntry? _current;

  static void show(OverlayState overlay, String text, {IconData icon = Icons.info_rounded}) {
    _current?.remove();
    _current = null;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastView(
        text: text,
        icon: icon,
        onDone: () {
          if (_current == entry) {
            entry.remove();
            _current = null;
          }
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }
}

class _ToastView extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onDone;
  const _ToastView({required this.text, required this.icon, required this.onDone});

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _a.value = 1;
    } else {
      _a.forward();
    }
    _timer = Timer(const Duration(milliseconds: 2600), _hide);
  }

  Future<void> _hide() async {
    _timer?.cancel();
    if (!mounted) return;
    if (Motion.reduced(context)) {
      widget.onDone();
      return;
    }
    await _a.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final curved = CurvedAnimation(parent: _a, curve: Motion.curve, reverseCurve: Curves.easeInCubic);
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: false,
        top: false,
        child: FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, -0.6), end: Offset.zero).animate(curved),
            child: Center(
              child: Material(
                type: MaterialType.transparency,
                child: GestureDetector(
                  onTap: _hide,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Glass(
                      radius: R.pill,
                      blur: 26,
                      color: c.isDark ? const Color(0xD9202023) : const Color(0xE6FFFFFF),
                      padding: const EdgeInsets.fromLTRB(8, 8, 18, 8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconTile(widget.icon, size: 32, circle: true, vivid: true),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(widget.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.callout.copyWith(color: c.text, fontWeight: w7)),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================ SAHIFA KARKASI / КАРКАС СТРАНИЦ
/// Yuqori qator: avatar, nom, daraja, olov va olmos.
/// Верхняя строка: аватар, название, уровень, огонь и кристаллы.
class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    return Row(children: [
      Pressable(
        onTap: () => s.go('profile'),
        scale: 0.92,
        semanticLabel: s.t('profile'),
        child: AppAvatar(s.st.avatar, size: 42, ring: true),
      ),
      const SizedBox(width: S.x3),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(kAppName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.brand.copyWith(color: c.text)),
          const SizedBox(height: 3),
          Text('${s.t('level')} ${levelOf(s.st.xp)}', style: AppType.caption.copyWith(color: c.text2)),
        ]),
      ),
      AppPill('${s.st.streak}', icon: Icons.local_fire_department_rounded, iconColor: c.accent),
      const SizedBox(width: S.x2),
      AppPill('${s.st.gems}', icon: Icons.diamond_rounded, iconColor: c.yellow),
    ]);
  }
}

/// Tab sahifasi: sarlavha qatori + katta sarlavha + bo‘limlar.
/// Страница вкладки: шапка + большой заголовок + секции.
class TabPage extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  const TabPage({super.key, this.title, this.subtitle, this.trailing, required this.children, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final list = ListView(
      padding: EdgeInsets.fromLTRB(S.page, S.x3, S.page, MediaQuery.paddingOf(context).bottom + S.x6),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        const Header(),
        if (title != null) ...[
          const SizedBox(height: S.x7),
          LargeTitle(title!, subtitle: subtitle, trailing: trailing),
        ],
        for (var i = 0; i < children.length; i++) ...[
          SizedBox(height: i == 0 && title == null ? S.x6 : S.x5),
          Appear(index: i, child: children[i]),
        ],
      ],
    );
    if (onRefresh == null) return list;
    return RefreshIndicator.adaptive(onRefresh: onRefresh!, color: c.accent, child: list);
  }
}

/// Suzuvchi shisha menyu / плавающее стеклянное меню.
class FloatingNavBar extends StatelessWidget {
  final List<(String, IconData, String)> items; // (id, ikonka, nom)
  final int index;
  final ValueChanged<int> onTap;
  const FloatingNavBar({super.key, required this.items, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final n = items.length;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, math.max(12, MediaQuery.paddingOf(context).bottom)),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Glass(
            radius: 28,
            blur: 28,
            color: c.isDark ? const Color(0xC2141416) : const Color(0xD9FFFFFF),
            padding: const EdgeInsets.all(6),
            child: SizedBox(
              height: 58,
              child: Stack(children: [
                AnimatedAlign(
                  alignment: Alignment(n == 1 ? 0 : -1 + 2 * index / (n - 1), 0),
                  duration: Motion.of(context, Motion.base),
                  curve: Motion.curve,
                  child: FractionallySizedBox(
                    widthFactor: 1 / n,
                    heightFactor: 1,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(color: c.accentSoft, borderRadius: R.all(22)),
                    ),
                  ),
                ),
                Row(children: [
                  for (var i = 0; i < n; i++)
                    Expanded(
                      child: Semantics(
                        selected: i == index,
                        button: true,
                        label: items[i].$3,
                        child: GestureDetector(
                          key: ValueKey('nav-${items[i].$1}'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (i != index) HapticFeedback.selectionClick();
                            onTap(i);
                          },
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            AnimatedScale(
                              scale: i == index ? 1.08 : 1,
                              duration: Motion.of(context, Motion.base),
                              curve: Motion.pop,
                              child: Icon(items[i].$2, size: 23, color: i == index ? c.accentText : c.text2),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              items[i].$3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.caption.copyWith(
                                fontSize: 10.5,
                                color: i == index ? c.accentText : c.text2,
                                fontWeight: i == index ? w8 : w7,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================ TO‘R VA KURS BELGISI / СЕТКА И ЗНАЧОК КУРСА
/// Bir qatorda n ta teng ustun / сетка из n равных колонок.
Widget gridOf(List<Widget> items, int cols, {double gap = S.x3}) {
  final rows = <Widget>[];
  for (var i = 0; i < items.length; i += cols) {
    final cells = <Widget>[];
    for (var k = 0; k < cols; k++) {
      if (k > 0) cells.add(SizedBox(width: gap));
      cells.add(Expanded(child: i + k < items.length ? items[i + k] : const SizedBox()));
    }
    if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
    rows.add(IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells)));
  }
  return Column(children: rows);
}

/// Kurs rangi (qorong‘i mavzuda qora → oq) / цвет курса (в тёмной теме чёрный → белый).
Color courseColor(Course co, AppColors c) {
  final col = hexColor(co.color);
  return c.isDark && col.computeLuminance() < 0.02 ? const Color(0xFFF2F2F2) : col;
}

/// Kurs belgisi (</>, { }, JS, Py) / значок курса.
class CourseTag extends StatelessWidget {
  final Course course;
  final double size;
  final double fontSize;
  final bool onColorBg;
  const CourseTag(this.course, {super.key, this.size = 46, this.fontSize = 14, this.onColorBg = false});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final col = courseColor(course, c);
    final bg = onColorBg ? const Color(0x33FFFFFF) : col;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        color: bg,
        border: onColorBg ? Border.all(color: const Color(0x40FFFFFF)) : null,
        gradient: onColorBg
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(col, kWhite, 0.18)!, col],
              ),
        boxShadow: onColorBg ? null : Shadows.glow(col, c, strength: 0.35),
      ),
      child: Text(course.tag,
          style: AppType.monoStrong.copyWith(fontSize: fontSize, color: onColorBg ? kWhite : onColor(col))),
    );
  }
}
