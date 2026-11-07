import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../messages/manual_sms_result_page.dart';
import '../view_models/sms_view_model.dart';

class SmsScreen extends StatefulWidget {
  const SmsScreen({required this.viewModel, this.active = true, super.key});
  final SmsViewModel viewModel;
  final bool active;
  @override
  State<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends State<SmsScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.viewModel.text,
  );
  bool _openingResult = false;
  bool _pasting = false;
  int _navigationGeneration = 0;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_syncDraft);
  }

  @override
  void didUpdateWidget(covariant SmsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel ||
        (oldWidget.active && !widget.active)) {
      _navigationGeneration++;
      _openingResult = false;
    }
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_syncDraft);
      widget.viewModel.addListener(_syncDraft);
      _syncDraft();
    }
  }

  void _syncDraft() {
    final text = widget.viewModel.text;
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  void dispose() {
    _navigationGeneration++;
    widget.viewModel.removeListener(_syncDraft);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    setState(() => _pasting = true);
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      if (data?.text?.trim().isNotEmpty ?? false) {
        widget.viewModel.setText(data!.text!);
      } else {
        _notice('В буфере обмена нет текста');
      }
    } catch (_) {
      if (mounted) {
        _notice('Не удалось вставить текст. Используйте системную вставку.');
      }
    } finally {
      if (mounted) setState(() => _pasting = false);
    }
  }

  void _notice(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _submit() async {
    if (_openingResult || !widget.active) return;
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    final generation = ++_navigationGeneration;
    final model = widget.viewModel;
    FocusScope.of(context).unfocus();
    setState(() => _openingResult = true);
    try {
      final result = await model.submit();
      if (!mounted ||
          result == null ||
          !widget.active ||
          generation != _navigationGeneration ||
          !identical(widget.viewModel, model) ||
          !route.isCurrent) {
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => ManualSmsResultPage(result: result)),
      );
    } finally {
      if (mounted && generation == _navigationGeneration) {
        setState(() => _openingResult = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) => ListView(
      key: const PageStorageKey('manual-sms-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Text(
          'Проверить SMS',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text(
          'Вставьте или введите сообщение. Проверка выполняется на телефоне.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 22),
        TextField(
          key: const ValueKey('sms-draft'),
          controller: _controller,
          minLines: 4,
          maxLines: 7,
          onChanged: widget.viewModel.setText,
          style: const TextStyle(color: QorganColors.ink),
          decoration: const InputDecoration(
            labelText: 'Текст SMS',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              onPressed: _pasting ? null : _paste,
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              label: const Text('Вставить текст'),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            ),
            TextButton(
              onPressed: widget.viewModel.text.isEmpty
                  ? null
                  : widget.viewModel.clear,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: const Text('Очистить'),
            ),
          ],
        ),
        if (widget.viewModel.error != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              widget.viewModel.error!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: widget.viewModel.canSubmit && !_openingResult
              ? _submit
              : null,
          child: Text(widget.viewModel.busy ? 'Проверяем…' : 'Проверить'),
        ),
        const SizedBox(height: 14),
        Text(
          'Результат этой проверки не сохраняется в историю',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
