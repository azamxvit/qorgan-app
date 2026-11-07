import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/light_components.dart';

class FeedbackReportPage extends StatefulWidget {
  const FeedbackReportPage({
    required this.header,
    required this.loadReport,
    super.key,
  });

  final SmsHeader header;
  final Future<String> Function() loadReport;

  @override
  State<FeedbackReportPage> createState() => _FeedbackReportPageState();
}

class _FeedbackReportPageState extends State<FeedbackReportPage> {
  String? _report;
  String? _loadError;
  String? _copyError;
  bool _loading = false;
  bool _copying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _report = null;
      _loadError = null;
      _copyError = null;
    });
    try {
      final report = await widget.loadReport();
      if (mounted) setState(() => _report = report);
    } catch (_) {
      if (mounted) {
        setState(
          () => _loadError = 'Не удалось загрузить отчёт. Попробуйте ещё раз.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copy() async {
    final report = _report;
    if (_copying || _loading || report == null || report.isEmpty) return;
    setState(() {
      _copying = true;
      _copyError = null;
    });
    try {
      await Clipboard.setData(ClipboardData(text: report));
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Отчёт скопирован')));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _copyError = 'Не удалось скопировать отчёт. Попробуйте ещё раз.',
        );
      }
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  @override
  Widget build(BuildContext context) => PhonePage(
    header: widget.header,
    children: [
      Semantics(
        header: true,
        child: Text(
          'Отчёт об исправлениях',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Отчёт формируется только на устройстве и включает полный текст SMS, '
        'отправителей, время получения, результаты проверки и ваши отметки. '
        'Перед передачей в другие приложения или людям удалите из копии отчёта '
        'коды, пароли и другие чувствительные сведения. '
        'Qorğan ничего не отправляет автоматически.',
      ),
      const SizedBox(height: 24),
      if (_loading)
        Semantics(liveRegion: true, child: const Text('Загружаем отчёт…'))
      else if (_loadError != null) ...[
        Semantics(liveRegion: true, child: Text(_loadError!)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: _load, child: const Text('Повторить')),
      ] else if (_report?.isEmpty == true) ...[
        Semantics(
          liveRegion: true,
          child: const Text('Нет отметок для отчёта'),
        ),
        const SizedBox(height: 12),
        const Text('Добавьте свою оценку в карточке сохранённого SMS.'),
      ] else if (_report != null) ...[
        SelectableText(
          _report!,
          key: const ValueKey('feedback-report-content'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _copying ? null : _copy,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Скопировать отчёт', textAlign: TextAlign.center),
          ),
        ),
        if (_copyError != null) ...[
          const SizedBox(height: 12),
          Semantics(liveRegion: true, child: Text(_copyError!)),
        ],
      ],
    ],
  );
}
