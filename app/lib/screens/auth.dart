import 'package:flutter/material.dart';

import '../config.dart';
import '../main.dart' show AppLogo;
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

/// Kirish / ro‘yxatdan o‘tish / вход и регистрация.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  late final TextEditingController _server;
  bool _register = false;
  bool _showPass = false;
  bool _showServer = false;
  String _error = '';
  int _errorTick = 0;
  late final String _tip;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    _error = s.bootError;
    _server = TextEditingController(text: s.server);
    _tip = s.pick('tips');
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _name.dispose();
    _server.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = AppScope.read(context);
    FocusManager.instance.primaryFocus?.unfocus();
    final err = await s.auth(
      register: _register,
      username: _user.text,
      password: _pass.text,
      name: _name.text,
      serverUrl: _server.text,
    );
    if (!mounted) return;
    setState(() {
      _error = err ?? '';
      if (err != null) _errorTick++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final reg = _register;

    final form = AppCard(
      kind: CardKind.glass,
      radius: R.xxl,
      padding: const EdgeInsets.all(S.x5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Segmented<bool>(
          values: const [false, true],
          labels: [s.t('login_btn'), s.t('register_btn')],
          value: reg,
          onChanged: (v) => setState(() {
            _register = v;
            _error = '';
          }),
        ),
        const SizedBox(height: S.x5),
        AppTextField(
          controller: _user,
          label: s.t('username'),
          icon: Icons.person_rounded,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: S.x4),
        AppTextField(
          controller: _pass,
          label: s.t('password'),
          icon: Icons.lock_rounded,
          obscure: !_showPass,
          textInputAction: reg ? TextInputAction.next : TextInputAction.done,
          onSubmitted: reg ? null : (_) => _submit(),
          suffix: IconButton(
            tooltip: s.t('password'),
            icon: Icon(_showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: c.text3, size: 20),
            onPressed: () => setState(() => _showPass = !_showPass),
          ),
        ),
        AnimatedSize(
          duration: Motion.of(context, Motion.base),
          curve: Motion.curve,
          alignment: Alignment.topCenter,
          child: reg
              ? Padding(
                  padding: const EdgeInsets.only(top: S.x4),
                  child: AppTextField(
                    controller: _name,
                    label: s.t('name'),
                    icon: Icons.badge_rounded,
                    maxLength: 30,
                    textCapitalization: TextCapitalization.words,
                    autocorrect: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        AnimatedSize(
          duration: Motion.of(context, Motion.base),
          curve: Motion.curve,
          alignment: Alignment.topCenter,
          child: _showServer
              ? Padding(
                  padding: const EdgeInsets.only(top: S.x4),
                  child: AppTextField(
                    controller: _server,
                    label: s.t('server'),
                    icon: Icons.dns_rounded,
                    keyboardType: TextInputType.url,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        AnimatedSize(
          duration: Motion.of(context, Motion.base),
          curve: Motion.curve,
          alignment: Alignment.topCenter,
          child: _error.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: S.x4),
                  child: Shake(
                    trigger: _errorTick,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: S.x3 + 2, vertical: S.x3),
                      decoration: BoxDecoration(color: c.dangerSoft, borderRadius: R.all(R.md - 2)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.error_rounded, size: 18, color: c.danger),
                        const SizedBox(width: S.x2),
                        Expanded(child: Text(_error, style: AppType.subhead.copyWith(color: c.danger))),
                      ]),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: S.x5),
        AppButton(
          reg ? s.t('register_btn') : s.t('login_btn'),
          onPressed: _submit,
          loading: s.busy,
          expand: true,
          icon: Icons.arrow_forward_rounded,
        ),
      ]),
    );

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: c.bg,
        body: AppBackground(
          strong: true,
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(S.page, S.x3, S.page, S.x8),
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      _LangChip(),
                      const SizedBox(width: S.x2),
                      AppIconButton(
                        s.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        tooltip: s.isDark ? s.t('light') : s.t('dark'),
                        onPressed: s.toggleTheme,
                      ),
                    ]),
                    const SizedBox(height: S.x6),
                    const Appear(child: Center(child: AppLogo(size: 92))),
                    const SizedBox(height: S.x5),
                    Appear(
                      index: 1,
                      child: Column(children: [
                        Text(kAppName, textAlign: TextAlign.center, style: AppType.largeTitle.copyWith(color: c.text)),
                        const SizedBox(height: S.x2),
                        Text(s.t('login_sub'),
                            textAlign: TextAlign.center, style: AppType.callout.copyWith(color: c.text2)),
                      ]),
                    ),
                    const SizedBox(height: S.x4),
                    Appear(
                      index: 2,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                          decoration: BoxDecoration(
                            color: c.isDark ? const Color(0x0FFFFFFF) : const Color(0x99FFFFFF),
                            borderRadius: R.all(R.pill),
                            border: Border.all(color: c.hairline),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const AppAvatar('🤖', size: 28),
                            const SizedBox(width: S.x2),
                            Flexible(
                              child: Text(_tip,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppType.footnote.copyWith(color: c.text2)),
                            ),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: S.x6),
                    Appear(index: 3, child: form),
                    const SizedBox(height: S.x3),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showServer = !_showServer),
                        icon: Icon(Icons.dns_rounded, size: 16, color: c.text2),
                        label: Text(s.t('server'), style: AppType.footnote.copyWith(color: c.text2)),
                      ),
                    ),
                    const SizedBox(height: S.x2),
                    Row(children: [
                      Expanded(child: Divider(color: c.hairline)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: S.x3),
                        child: Text(s.t('or'), style: AppType.caption.copyWith(color: c.text3)),
                      ),
                      Expanded(child: Divider(color: c.hairline)),
                    ]),
                    const SizedBox(height: S.x4),
                    AppButton(
                      s.t('offline'),
                      onPressed: s.busy ? null : s.goOffline,
                      kind: BtnKind.secondary,
                      icon: Icons.wifi_off_rounded,
                      expand: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Til almashtirish tabletkasi / переключатель языка.
class _LangChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    return Pressable(
      onTap: s.toggleLang,
      scale: 0.93,
      semanticLabel: s.t('language'),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: S.x4),
        decoration: BoxDecoration(
          color: c.isDark ? c.surfaceAlt : c.surface,
          borderRadius: R.all(R.pill),
          border: Border.all(color: c.hairline),
          boxShadow: Shadows.soft(c),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.translate_rounded, size: 17, color: c.text2),
          const SizedBox(width: 6),
          Text(s.lang.toUpperCase(), style: AppType.footnote.copyWith(color: c.text, fontWeight: w8)),
        ]),
      ),
    );
  }
}
