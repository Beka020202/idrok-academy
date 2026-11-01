import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart' show AppLogo;
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

// Avtomatik testlar uchun 1×1 rasm / картинка 1×1 для автотестов.
final Uint8List _kTestPhoto = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');

/// Rasm tanlash (kamera yoki galereya) / выбор фото (камера или галерея).
Future<Uint8List?> pickProfilePhoto(BuildContext context) async {
  final s = AppScope.read(context);
  if (s.testMode) return _kTestPhoto;
  final c = s.c;
  final src = await showAppSheet<ImageSource>(context, builder: (ctx) {
    Widget row(IconData icon, String label, ImageSource v) => Padding(
          padding: const EdgeInsets.only(bottom: S.x2),
          child: AppCard(
            kind: CardKind.inset,
            radius: R.lg,
            padding: const EdgeInsets.all(S.x4),
            onTap: () => Navigator.of(ctx).pop(v),
            child: Row(children: [
              IconTile(icon, size: 40),
              const SizedBox(width: S.x3),
              Expanded(child: Text(label, style: AppType.headline.copyWith(color: c.text))),
              Icon(Icons.chevron_right_rounded, color: c.text3),
            ]),
          ),
        );
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(s.t('photo_pick'), textAlign: TextAlign.center, style: AppType.title3.copyWith(color: c.text)),
      const SizedBox(height: S.x2),
      Text(s.t('photo_hint'), textAlign: TextAlign.center, style: AppType.footnote.copyWith(color: c.text2)),
      const SizedBox(height: S.x4),
      row(Icons.photo_camera_rounded, s.t('photo_camera'), ImageSource.camera),
      row(Icons.photo_library_rounded, s.t('photo_gallery'), ImageSource.gallery),
    ]);
  });
  if (src == null) return null;
  try {
    final x = await ImagePicker().pickImage(
      source: src,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 82,
      preferredCameraDevice: CameraDevice.front,
    );
    if (x == null) return null;
    final bytes = await x.readAsBytes();
    if (bytes.length > 1000000) {
      s.toast(s.t('photo_big'), icon: Icons.photo_rounded);
      return null;
    }
    return bytes;
  } catch (_) {
    s.toast(s.t('photo_fail'), icon: Icons.photo_rounded);
    return null;
  }
}

/// Doiraviy rasm tanlagich / круглый выбор фото.
class PhotoPicker extends StatelessWidget {
  final Uint8List? bytes;
  final String? url;
  final String name;
  final double size;
  final ValueChanged<Uint8List> onPicked;
  const PhotoPicker({super.key, this.bytes, this.url, this.name = '', this.size = 112, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final empty = (bytes == null || bytes!.isEmpty) && (url == null || url!.isEmpty);
    return Pressable(
      key: const ValueKey('photo-pick'),
      semanticLabel: s.t('photo_pick'),
      scale: 0.95,
      onTap: () async {
        final b = await pickProfilePhoto(context);
        if (b != null) onPicked(b);
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(clipBehavior: Clip.none, children: [
          if (empty)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.accentSoft,
                border: Border.all(color: c.accent, width: 2),
              ),
              child: Icon(Icons.add_a_photo_rounded, size: size * 0.34, color: c.accentText),
            )
          else
            AppAvatar(bytes: bytes, url: url, headers: s.authHeaders, name: name, size: size, ring: true),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: c.accentGradient,
                border: Border.all(color: c.bg, width: 3),
              ),
              child: Icon(empty ? Icons.add_rounded : Icons.edit_rounded, size: size * 0.16, color: kWhite),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Ism, maktab, shahar maydonlari / поля имени, школы, города.
class ProfileFields extends StatelessWidget {
  final TextEditingController name, school, city;
  final VoidCallback? onDone;
  const ProfileFields({super.key, required this.name, required this.school, required this.city, this.onDone});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppTextField(
        key: const ValueKey('f-name'),
        controller: name,
        label: s.t('full_name'),
        icon: Icons.badge_rounded,
        maxLength: 40,
        textCapitalization: TextCapitalization.words,
        autocorrect: false,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: S.x4),
      AppTextField(
        key: const ValueKey('f-school'),
        controller: school,
        label: s.t('school'),
        hint: s.t('school_hint'),
        icon: Icons.school_rounded,
        maxLength: 60,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: S.x4),
      AppTextField(
        key: const ValueKey('f-city'),
        controller: city,
        label: s.t('city'),
        hint: s.t('city_hint'),
        icon: Icons.location_on_rounded,
        maxLength: 60,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: onDone == null ? null : (_) => onDone!(),
      ),
    ]);
  }
}

/// Oflayn rejimda profilni to‘ldirish / заполнение профиля в офлайн-режиме.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _name = TextEditingController();
  final _school = TextEditingController();
  final _city = TextEditingController();
  Uint8List? _photo;
  String _error = '';
  int _tick = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    _photo = s.myPhoto;
    _school.text = s.localSchool;
    _city.text = s.localCity;
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
    FocusManager.instance.primaryFocus?.unfocus();
    String err = '';
    if (_name.text.trim().isEmpty || _school.text.trim().isEmpty || _city.text.trim().isEmpty) {
      err = s.t('err_profile');
    } else if (_photo == null) {
      err = s.t('err_photo');
    }
    if (err.isNotEmpty) {
      setState(() {
        _error = err;
        _tick++;
      });
      return;
    }
    setState(() => _saving = true);
    await s.saveLocalProfile(name: _name.text, school: _school.text, city: _city.text, photo: _photo);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
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
                    Row(children: [
                      AppIconButton(Icons.arrow_back_rounded, tooltip: s.t('back'), onPressed: s.logout),
                      const Spacer(),
                      Pressable(
                        onTap: s.toggleLang,
                        child: AppPill(s.lang.toUpperCase(), icon: Icons.translate_rounded),
                      ),
                    ]),
                    const SizedBox(height: S.x4),
                    const Appear(child: Center(child: AppLogo(size: 64))),
                    const SizedBox(height: S.x4),
                    Appear(
                      index: 1,
                      child: Column(children: [
                        Text(s.t('setup_title'), textAlign: TextAlign.center, style: AppType.title1.copyWith(color: c.text)),
                        const SizedBox(height: S.x2),
                        Text(s.t('setup_sub'), textAlign: TextAlign.center, style: AppType.callout.copyWith(color: c.text2)),
                      ]),
                    ),
                    const SizedBox(height: S.x6),
                    Appear(
                      index: 2,
                      child: AppCard(
                        kind: CardKind.glass,
                        radius: R.xxl,
                        padding: const EdgeInsets.all(S.x5),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Center(
                            child: PhotoPicker(
                              bytes: _photo,
                              name: _name.text,
                              onPicked: (b) => setState(() => _photo = b),
                            ),
                          ),
                          const SizedBox(height: S.x2),
                          Text(s.t('photo_need'),
                              textAlign: TextAlign.center, style: AppType.footnote.copyWith(color: c.text2)),
                          const SizedBox(height: S.x5),
                          ProfileFields(name: _name, school: _school, city: _city, onDone: _save),
                          if (_error.isNotEmpty) ...[
                            const SizedBox(height: S.x4),
                            ErrorBox(_error, tick: _tick),
                          ],
                          const SizedBox(height: S.x5),
                          AppButton(s.t('continue'),
                              key: const ValueKey('setup-save'),
                              onPressed: _saving ? null : _save,
                              loading: _saving,
                              expand: true,
                              icon: Icons.arrow_forward_rounded),
                        ]),
                      ),
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

/// Xato qutisi / блок ошибки.
class ErrorBox extends StatelessWidget {
  final String text;
  final int tick;
  const ErrorBox(this.text, {super.key, this.tick = 0});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Shake(
      trigger: tick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: S.x3 + 2, vertical: S.x3),
        decoration: BoxDecoration(color: c.dangerSoft, borderRadius: R.all(R.md - 2)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.error_rounded, size: 18, color: c.danger),
          const SizedBox(width: S.x2),
          Expanded(child: Text(text, style: AppType.subhead.copyWith(color: c.danger))),
        ]),
      ),
    );
  }
}
