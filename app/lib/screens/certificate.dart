import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../lessons.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

// ============================================================================
//  Sertifikat: ilovadagi ko‘rinish va PDF / сертификат: вид в приложении и PDF
//  Ikkalasi ham bir xil 842×595 (A4 albom) o‘lchamda chiziladi.
//  Оба рисуются в одном размере 842×595 (A4 альбомный).
// ============================================================================

const double _w = 842, _h = 595;
const _blue = Color(0xFF0A6CFF), _sky = Color(0xFF2EA6FF), _navy = Color(0xFF0A1226), _gold = Color(0xFFFFB800);

/// Sertifikat matnlari / тексты сертификата.
class CertText {
  final String name, courseUz, courseRu, school, date, id, link;
  final int score;
  const CertText(
      {required this.name,
      required this.courseUz,
      required this.courseRu,
      required this.school,
      required this.date,
      required this.id,
      required this.link,
      required this.score});

  factory CertText.of(Cert ce, String link) {
    final co = kCourses.where((x) => x.id == ce.course).firstOrNull;
    final d = ce.issued;
    String two(int v) => v.toString().padLeft(2, '0');
    return CertText(
      name: ce.name,
      courseUz: co?.name.uz ?? ce.course,
      courseRu: co?.name.ru ?? ce.course,
      school: ce.school,
      date: '${two(d.day)}.${two(d.month)}.${d.year}',
      id: ce.id,
      link: link.replaceFirst(RegExp(r'^https?://'), ''),
      score: ce.score,
    );
  }

  String get uzLine => '«$courseUz» kursini muvaffaqiyatli tamomlagani va yakuniy imtihondan '
      '$score% natija bilan o‘tgani uchun berildi.';
  String get ruLine => 'успешно окончил(а) курс «$courseRu» и сдал(а) итоговый экзамен с результатом $score%.';
}

// ---------------------------------------------------------------- PDF
/// Shriftlar ilova ichidan / шрифты из приложения.
class CertFonts {
  final pw.Font body, bold, display;
  final Uint8List? logo; // Idrok Academy belgisi / логотип
  const CertFonts(this.body, this.bold, this.display, {this.logo});

  static Future<CertFonts> load() async => CertFonts(
        pw.Font.ttf(await rootBundle.load('assets/fonts/Manrope-600.ttf')),
        pw.Font.ttf(await rootBundle.load('assets/fonts/Manrope-800.ttf')),
        pw.Font.ttf(await rootBundle.load('assets/fonts/Unbounded-800.ttf')),
        logo: (await rootBundle.load(kCertLogo)).buffer.asUint8List(),
      );
}

const String kCertLogo = 'assets/icon/icon.png';

PdfColor _pc(Color c) => PdfColor.fromInt(c.toARGB32());

Future<Uint8List> buildCertificatePdf(CertText t, CertFonts f) {
  final doc = pw.Document(title: 'Idrok Academy — ${t.name}', author: 'Idrok Academy', creator: 'Idrok Academy');
  pw.TextStyle st(double size, {pw.Font? font, Color color = _navy, double spacing = 0}) =>
      pw.TextStyle(font: font ?? f.body, fontSize: size, color: _pc(color), letterSpacing: spacing);
  const grey = Color(0xFF5B6475);
  final logo = f.logo == null ? null : pw.MemoryImage(f.logo!);

  doc.addPage(pw.Page(
    pageFormat: const PdfPageFormat(_w, _h),
    margin: pw.EdgeInsets.zero,
    build: (_) => pw.Stack(children: [
      // fon / фон
      pw.Positioned.fill(child: pw.Container(color: PdfColors.white)),
      pw.Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        child: pw.Container(
          width: 26,
          decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                  begin: pw.Alignment.topCenter, end: pw.Alignment.bottomCenter, colors: [_pc(_sky), _pc(_blue), _pc(_navy)])),
        ),
      ),
      pw.Positioned(
        left: 50,
        top: 24,
        right: 24,
        bottom: 24,
        child: pw.Container(
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(18),
            border: pw.Border.all(color: _pc(const Color(0xFFD6E4FF)), width: 1.4),
          ),
        ),
      ),
      pw.Positioned(
        left: 50,
        top: 24,
        right: 24,
        bottom: 24,
        child: pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(44, 34, 44, 30),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Row(children: [
              if (logo != null) ...[
                pw.ClipRRect(
                  horizontalRadius: 9,
                  verticalRadius: 9,
                  child: pw.Image(logo, width: 38, height: 38),
                ),
                pw.SizedBox(width: 10),
              ],
              pw.Text('IDROK ACADEMY', style: st(13, font: f.display, color: _blue, spacing: 1.5)),
              pw.Spacer(),
              pw.Text('ID: ${t.id}', style: st(11, font: f.bold, color: grey)),
            ]),
            pw.SizedBox(height: 34),
            pw.Text('SERTIFIKAT', style: st(46, font: f.display, color: _navy, spacing: 2)),
            pw.Text('СЕРТИФИКАТ', style: st(14, font: f.bold, color: _blue, spacing: 4)),
            pw.SizedBox(height: 26),
            pw.Text('Ushbu sertifikat egasi · Настоящим подтверждается, что', style: st(12, color: grey)),
            pw.SizedBox(height: 8),
            pw.Text(t.name, style: st(34, font: f.bold, color: _navy)),
            if (t.school.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(t.school, style: st(12, color: grey)),
            ],
            pw.SizedBox(height: 16),
            pw.SizedBox(width: 560, child: pw.Text(t.uzLine, style: st(14, font: f.bold))),
            pw.SizedBox(height: 4),
            pw.SizedBox(width: 560, child: pw.Text(t.ruLine, style: st(11.5, color: grey))),
            pw.Spacer(),
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Sana · Дата', style: st(10, color: grey)),
                pw.Text(t.date, style: st(15, font: f.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Tekshirish · Проверка', style: st(10, color: grey)),
                pw.Text(t.link, style: st(11, font: f.bold, color: _blue)),
              ]),
              pw.Spacer(),
              pw.Container(
                width: 104,
                height: 104,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  gradient: pw.LinearGradient(colors: [_pc(const Color(0xFFFFD54A)), _pc(_gold)]),
                  border: pw.Border.all(color: _pc(const Color(0xFFFFE9A8)), width: 4),
                ),
                child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
                  pw.Text('${t.score}%', style: st(26, font: f.bold, color: kWhite)),
                  pw.Text('IDROK', style: st(9, font: f.display, color: kWhite, spacing: 1.2)),
                ]),
              ),
            ]),
          ]),
        ),
      ),
    ]),
  ));
  return doc.save();
}

// ---------------------------------------------------------------- ilovadagi ko‘rinish / вид в приложении
class CertificateView extends StatelessWidget {
  final CertText t;
  const CertificateView(this.t, {super.key});

  @override
  Widget build(BuildContext context) {
    TextStyle st(double size, {String font = kBody, FontWeight weight = w6, Color color = _navy, double spacing = 0}) =>
        TextStyle(fontFamily: font, fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing, height: 1.2);
    const grey = Color(0xFF5B6475);
    return AspectRatio(
      aspectRatio: _w / _h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: R.all(R.lg),
          boxShadow: const [BoxShadow(color: Color(0x2A0A1E5A), blurRadius: 30, offset: Offset(0, 14))],
        ),
        child: ClipRRect(
          borderRadius: R.all(R.lg),
          child: FittedBox(
            child: SizedBox(
              width: _w,
              height: _h,
              child: Stack(children: [
                const Positioned.fill(child: ColoredBox(color: kWhite)),
                const Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 26,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_sky, _blue, _navy])),
                  ),
                ),
                Positioned(
                  left: 50,
                  top: 24,
                  right: 24,
                  bottom: 24,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(44, 34, 44, 30),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD6E4FF), width: 1.4),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.asset(kCertLogo, width: 38, height: 38),
                        ),
                        const SizedBox(width: 10),
                        Text('IDROK ACADEMY', style: st(13, font: kDisplay, weight: w8, color: _blue, spacing: 1.5)),
                        const Spacer(),
                        Text('ID: ${t.id}', style: st(11, weight: w8, color: grey)),
                      ]),
                      const SizedBox(height: 34),
                      Text('SERTIFIKAT', style: st(46, font: kDisplay, weight: w8, spacing: 2)),
                      Text('СЕРТИФИКАТ', style: st(14, weight: w8, color: _blue, spacing: 4)),
                      const SizedBox(height: 26),
                      Text('Ushbu sertifikat egasi · Настоящим подтверждается, что', style: st(12, color: grey)),
                      const SizedBox(height: 8),
                      Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: st(34, weight: w8)),
                      if (t.school.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(t.school, style: st(12, color: grey)),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(width: 560, child: Text(t.uzLine, style: st(14, weight: w8))),
                      const SizedBox(height: 4),
                      SizedBox(width: 560, child: Text(t.ruLine, style: st(11.5, color: grey))),
                      const Spacer(),
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Sana · Дата', style: st(10, color: grey)),
                          Text(t.date, style: st(15, weight: w8)),
                          const SizedBox(height: 10),
                          Text('Tekshirish · Проверка', style: st(10, color: grey)),
                          Text(t.link, style: st(11, weight: w8, color: _blue)),
                        ]),
                        const Spacer(),
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [Color(0xFFFFD54A), _gold]),
                            border: Border.all(color: const Color(0xFFFFE9A8), width: 4),
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('${t.score}%', style: st(26, weight: w8, color: kWhite)),
                            Text('IDROK', style: st(9, font: kDisplay, weight: w8, color: kWhite, spacing: 1.2)),
                          ]),
                        ),
                      ]),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- sahifalar / страницы
void openCertificate(BuildContext context, Cert ce) {
  Navigator.of(context).push(AppRoute<void>(builder: (_) => PageShell(child: CertificateScreen(cert: ce))));
}

void openCertificates(BuildContext context) {
  Navigator.of(context).push(AppRoute<void>(builder: (_) => const PageShell(child: CertificatesScreen())));
}

class CertificateScreen extends StatefulWidget {
  final Cert cert;
  const CertificateScreen({super.key, required this.cert});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  bool busy = false;

  Future<void> _download() async {
    final s = AppScope.read(context);
    setState(() => busy = true);
    try {
      final t = CertText.of(widget.cert, s.certLink(widget.cert));
      final bytes = await buildCertificatePdf(t, await CertFonts.load());
      await Printing.sharePdf(bytes: bytes, filename: 'Idrok-sertifikat-${widget.cert.id}.pdf');
    } catch (_) {
      s.toast(s.t('error'), icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final ce = widget.cert;
    final link = s.certLink(ce);
    return TabPage(
      title: s.t('certificate'),
      subtitle: s.tr(kCourses.where((x) => x.id == ce.course).firstOrNull?.name ?? Tr.same(ce.course)),
      children: [
        CertificateView(CertText.of(ce, link)),
        AppButton(s.t('cert_download'),
            key: const ValueKey('cert-download'),
            onPressed: busy ? null : _download,
            loading: busy,
            expand: true,
            height: 56,
            icon: Icons.download_rounded),
        GroupList([
          GroupRow(icon: Icons.tag_rounded, color: const Color(0xFF0A6CFF), title: 'ID', value: ce.id),
          GroupRow(
            key: const ValueKey('cert-copy'),
            icon: Icons.link_rounded,
            color: const Color(0xFF34C759),
            title: s.t('cert_copy'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: link));
              s.toast(s.t('copied'), icon: Icons.check_rounded);
            },
          ),
        ]),
        Text(s.t('cert_check_text'), style: AppType.footnote.copyWith(color: c.text2)),
      ],
    );
  }
}

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.c;
    final list = [
      for (final co in kCourses)
        if (s.certs[co.id] != null) (co, s.certs[co.id]!)
    ];
    return TabPage(
      title: s.t('my_certs'),
      children: [
        if (list.isEmpty)
          EmptyState(icon: Icons.workspace_premium_rounded, title: s.t('no_certs'), message: s.t('no_certs_text'))
        else
          GroupList([
            for (final (co, ce) in list)
              GroupRow(
                key: ValueKey('cert-${co.id}'),
                icon: Icons.workspace_premium_rounded,
                color: courseColor(co, c),
                title: s.tr(co.name),
                value: '${ce.score}%',
                onTap: () => openCertificate(context, ce),
              ),
          ]),
      ],
    );
  }
}
