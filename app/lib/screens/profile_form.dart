import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../lessons.dart';
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

/// Tanlangan maktab / выбранная школа.
class SchoolValue {
  String region, district, number, name;
  SchoolKind kind;
  SchoolValue({this.region = '', this.district = '', this.kind = SchoolKind.school, this.number = '', this.name = ''});

  factory SchoolValue.of(String region, String district, String label) {
    final (k, n, t) = parseSchool(label);
    return SchoolValue(region: region, district: district, kind: label.isEmpty ? SchoolKind.school : k, number: n, name: t);
  }

  String get label => schoolLabel(kind, number: number, name: name);
  bool get complete => region.isNotEmpty && district.isNotEmpty && label.isNotEmpty;
}

/// Viloyat → tuman → maktab raqami ("-maktab" o‘zi qo‘shiladi).
/// Область → район → номер школы ("-maktab" добавляется сам).
class SchoolPicker extends StatefulWidget {
  final SchoolValue value;
  final VoidCallback onChanged;
  const SchoolPicker({super.key, required this.value, required this.onChanged});

  @override
  State<SchoolPicker> createState() => _SchoolPickerState();
}

class _SchoolPickerState extends State<SchoolPicker> {
  late final _number = TextEditingController(text: widget.value.number);
  late final _name = TextEditingController(text: widget.value.name);

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    super.dispose();
  }

  SchoolValue get v => widget.value;

  void _changed() {
    setState(() {});
    widget.onChanged();
  }

  Future<void> _pickRegion() async {
    final s = AppScope.read(context);
    final r = await pickFromList(context,
        title: s.t('region'), items: [for (final r in kRegions) (r.id, s.tr(r.name))], selected: v.region);
    if (r == null || r == v.region) return;
    v.region = r;
    v.district = '';
    _changed();
  }

  Future<void> _pickDistrict() async {
    final s = AppScope.read(context);
    final reg = regionById(v.region);
    if (reg == null) {
      await _pickRegion();
      return;
    }
    final d = await pickFromList(context,
        title: s.t('district'), items: [for (final d in reg.districts) (d, d)], selected: v.district);
    if (d == null) return;
    v.district = d;
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final reg = regionById(v.region);
    final suffix = v.kind == SchoolKind.idum ? '-IDUM' : '-maktab';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _SelectTile(
        key: const ValueKey('school-region'),
        icon: Icons.map_rounded,
        label: s.t('region'),
        value: reg == null ? '' : s.tr(reg.name),
        hint: s.t('region_hint'),
        onTap: _pickRegion,
      ),
      const SizedBox(height: S.x3),
      _SelectTile(
        key: const ValueKey('school-district'),
        icon: Icons.location_city_rounded,
        label: s.t('district'),
        value: v.district,
        hint: s.t(reg == null ? 'region_first' : 'district_hint'),
        onTap: _pickDistrict,
        enabled: reg != null,
      ),
      const SizedBox(height: S.x4),
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(s.t('school'), style: AppType.footnote.copyWith(color: c.text2, fontWeight: w7)),
      ),
      Wrap(spacing: S.x2, runSpacing: S.x2, children: [
        for (final k in SchoolKind.values)
          Pressable(
            key: ValueKey('kind-${k.name}'),
            onTap: () {
              v.kind = k;
              _changed();
            },
            scale: 0.95,
            child: AnimatedContainer(
              duration: Motion.of(context, Motion.fast),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: R.all(R.pill),
                gradient: v.kind == k ? c.accentGradient : null,
                color: v.kind == k ? null : (c.isDark ? c.surfaceAlt : kWhite),
                border: Border.all(color: v.kind == k ? const Color(0x00000000) : c.hairlineStrong),
              ),
              child: Text(s.tr(kSchoolKinds[k]!),
                  style: AppType.subhead.copyWith(color: v.kind == k ? kWhite : c.text, fontWeight: w7)),
            ),
          ),
      ]),
      AnimatedSize(
        duration: Motion.of(context, Motion.base),
        curve: Motion.curve,
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: v.kind == SchoolKind.president ? 0 : S.x3),
          child: kindHasNumber(v.kind)
              ? AppTextField(
                  key: const ValueKey('school-number'),
                  controller: _number,
                  hint: s.t('school_number'),
                  icon: Icons.tag_rounded,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  suffixText: suffix,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.done,
                  onChanged: (x) {
                    v.number = x;
                    _changed();
                  },
                )
              : kindHasName(v.kind)
                  ? AppTextField(
                      key: const ValueKey('school-name'),
                      controller: _name,
                      hint: s.t(v.kind == SchoolKind.lyceum ? 'lyceum_hint' : 'private_hint'),
                      icon: Icons.apartment_rounded,
                      maxLength: 40,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (x) {
                        v.name = x;
                        _changed();
                      },
                    )
                  : const SizedBox(width: double.infinity),
        ),
      ),
      if (v.complete) ...[
        const SizedBox(height: S.x3),
        Container(
          key: const ValueKey('school-summary'),
          padding: const EdgeInsets.symmetric(horizontal: S.x3 + 2, vertical: S.x3),
          decoration: BoxDecoration(color: c.accentSoft, borderRadius: R.all(R.md - 2)),
          child: Row(children: [
            Icon(Icons.check_circle_rounded, size: 18, color: c.accentText),
            const SizedBox(width: S.x2),
            Expanded(
              child: Text('${v.label} · ${v.district}',
                  style: AppType.subhead.copyWith(color: c.accentText, fontWeight: w8)),
            ),
          ]),
        ),
      ],
    ]);
  }
}

class _SelectTile extends StatelessWidget {
  final IconData icon;
  final String label, value, hint;
  final VoidCallback onTap;
  final bool enabled;
  const _SelectTile(
      {super.key, required this.icon, required this.label, required this.value, required this.hint, required this.onTap,
      this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(label, style: AppType.footnote.copyWith(color: c.text2, fontWeight: w7)),
      ),
      Pressable(
        onTap: onTap,
        scale: 0.98,
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: c.isDark ? c.surfaceAlt : kWhite,
              borderRadius: R.all(R.md - 2),
              border: Border.all(color: c.hairlineStrong),
              boxShadow: c.isDark ? null : Shadows.soft(c),
            ),
            child: Row(children: [
              Icon(icon, size: 20, color: value.isEmpty ? c.text3 : c.accent),
              const SizedBox(width: S.x3),
              Expanded(
                child: Text(value.isEmpty ? hint : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.bodyStrong.copyWith(color: value.isEmpty ? c.text3 : c.text)),
              ),
              Icon(Icons.unfold_more_rounded, size: 20, color: c.text3),
            ]),
          ),
        ),
      ),
    ]);
  }
}

/// Qidiruvli ro‘yxatdan tanlash / выбор из списка с поиском.
Future<String?> pickFromList(BuildContext context,
    {required String title, required List<(String, String)> items, String selected = ''}) {
  return showAppSheet<String>(context, builder: (_) => _ListSheet(title: title, items: items, selected: selected));
}

class _ListSheet extends StatefulWidget {
  final String title, selected;
  final List<(String, String)> items;
  const _ListSheet({required this.title, required this.items, required this.selected});

  @override
  State<_ListSheet> createState() => _ListSheetState();
}

class _ListSheetState extends State<_ListSheet> {
  String q = '';

  String _norm(String x) => x.toLowerCase().replaceAll(RegExp('[‘’ʻʼ\'`]'), '');

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final list = [for (final it in widget.items) if (q.isEmpty || _norm(it.$2).contains(_norm(q))) it];
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.78),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.title, textAlign: TextAlign.center, style: AppType.title3.copyWith(color: c.text)),
        const SizedBox(height: S.x3),
        if (widget.items.length > 8) ...[
          AppTextField(
            key: const ValueKey('list-search'),
            hint: s.t('search'),
            icon: Icons.search_rounded,
            onChanged: (x) => setState(() => q = x),
          ),
          const SizedBox(height: S.x3),
        ],
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: c.hairline, indent: 16, endIndent: 16),
            itemBuilder: (_, k) {
              final (id, label) = list[k];
              final on = id == widget.selected;
              return Pressable(
                key: ValueKey('pick-$id'),
                onTap: () => Navigator.of(context).pop(id),
                scale: 0.99,
                child: Container(
                  color: const Color(0x00000000),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    Expanded(
                      child: Text(label,
                          style: AppType.bodyStrong.copyWith(color: on ? c.accentText : c.text, fontWeight: on ? w8 : w6)),
                    ),
                    if (on) Icon(Icons.check_rounded, color: c.accentText, size: 20),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// Ism va maktab maydonlari / поля имени и школы.
class ProfileFields extends StatelessWidget {
  final TextEditingController name;
  final SchoolValue school;
  final VoidCallback onSchool;
  final bool showSchool;
  const ProfileFields(
      {super.key, required this.name, required this.school, required this.onSchool, this.showSchool = true});

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
      if (showSchool) ...[
        const SizedBox(height: S.x4),
        SchoolPicker(value: school, onChanged: onSchool),
      ],
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
  late SchoolValue _school;
  Uint8List? _photo;
  String _error = '';
  int _tick = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    _photo = s.myPhoto;
    _name.text = s.displayName;
    _school = SchoolValue.of(s.region, s.district, s.school);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = AppScope.read(context);
    FocusManager.instance.primaryFocus?.unfocus();
    String err = '';
    if (_name.text.trim().isEmpty) {
      err = s.t('err_profile');
    } else if (!_school.complete) {
      err = s.t('err_school');
    } else if (_photo == null && !s.online) {
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
    if (s.online) {
      await s.updateProfile(name: _name.text, school: _school.label, city: _school.district, region: _school.region);
    } else {
      await s.saveLocalProfile(
          name: _name.text, school: _school.label, city: _school.district, region: _school.region, photo: _photo);
    }
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
                        Text(s.t(s.online ? 'setup_sub_online' : 'setup_sub'), textAlign: TextAlign.center, style: AppType.callout.copyWith(color: c.text2)),
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
                          if (!s.online) ...[
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
                          ],
                          ProfileFields(name: _name, school: _school, onSchool: () => setState(() {})),
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
