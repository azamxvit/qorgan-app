import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/copy.dart';
import '../../core/verdict_card.dart';
import '../view_models/sms_view_model.dart';

class SmsScreen extends StatefulWidget {
  const SmsScreen({required this.viewModel, super.key});

  final SmsViewModel viewModel;

  @override
  State<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends State<SmsScreen> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _use(String text) {
    _controller.text = text;
    widget.viewModel.setText(text);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final verdict = widget.viewModel.verdict;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          children: [
            Text(
              AppCopy.smsTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppCopy.smsBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _use(AppCopy.phishingText),
                  child: const Text(AppCopy.phishingSample),
                ),
                OutlinedButton(
                  onPressed: () => _use(AppCopy.ordinaryText),
                  child: const Text(AppCopy.ordinarySample),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              minLines: 4,
              maxLines: 6,
              onChanged: widget.viewModel.setText,
              style: const TextStyle(color: QorganColors.ink),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.viewModel.text.trim().isNotEmpty)
              VerdictCard(
                title: verdict.block ? AppCopy.blocked : AppCopy.allow,
                verdict: verdict,
                blocked: verdict.block,
              ),
          ],
        );
      },
    );
  }
}
