import 'package:flutter/material.dart';

import '../api.dart';
import '../state.dart';
import '../widgets.dart';

/// Natijani matnga aylantirish / вывод результата запуска.
String formatRun(AppState s, RunResult r) {
  var out = r.out;
  switch (r.err) {
    case null:
      break;
    case 'timeout':
      out += '\n⚠ ${s.t('timeout')}';
    case 'conn':
      out += '\n⚠ ${s.t('run_conn')}';
    case 'busy':
      out += '\n⚠ ${s.t('run_busy')}';
    default:
      out += '\n⚠ ${s.t('error')}: ${r.err}';
  }
  return out.trim();
}

/// 3. Python maydoni / песочница Python.
class PlayTab extends StatefulWidget {
  const PlayTab({super.key});

  @override
  State<PlayTab> createState() => _PlayTabState();
}

class _PlayTabState extends State<PlayTab> {
  late final TextEditingController _inputs;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    _inputs = TextEditingController(text: s.playInputs);
    s.warmUp();
  }

  @override
  void dispose() {
    _inputs.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final s = AppScope.read(context);
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _running = true);
    final r = await s.run(s.playCode, inputs: s.playInputs.split('\n'));
    if (!mounted) return;
    s.playOut = formatRun(s, r);
    setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return TabPage(
      title: s.t('play_title'),
      subtitle: s.t('play_text'),
      children: [
        CodeEditor(initial: s.playCode, onChanged: (v) => s.playCode = v, minLines: 9, label: 'main.py'),
        AppTextField(
          controller: _inputs,
          label: s.t('inputs'),
          icon: Icons.keyboard_rounded,
          onChanged: (v) => s.playInputs = v,
          minLines: 1,
          maxLines: 4,
        ),
        AppButton(
          _running ? s.t('running') : s.t('run'),
          onPressed: _run,
          loading: _running,
          expand: true,
          icon: Icons.play_arrow_rounded,
        ),
        Console(
          s.playOut.isEmpty ? s.t('empty_out') : s.playOut,
          label: s.t('output'),
          placeholder: s.playOut.isEmpty,
        ),
      ],
    );
  }
}
