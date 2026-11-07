import 'package:flutter/material.dart';

import '../core/light_components.dart';
import '../sms/view_models/sms_view_model.dart';
import 'sms_result_content.dart';

class ManualSmsResultPage extends StatelessWidget {
  const ManualSmsResultPage({required this.result, super.key});
  final SmsCheckResult result;

  @override
  Widget build(BuildContext context) => PhonePage(
    header: SmsHeader(
      onBack: () => Navigator.of(context).pop(),
      onMenu: () {},
      onProfile: () {},
    ),
    children: [
      Text(
        'Результат проверки',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 20),
      SmsResultContent(
        text: result.text,
        verdict: result.verdict,
        manual: true,
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('Изменить текст'),
      ),
    ],
  );
}
