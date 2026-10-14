import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../data/repositories/protection_repository.dart';
import '../data/services/incoming_message_service.dart';
import 'core/copy.dart';
import 'core/theme.dart';
import 'shell/home_shell.dart';

class QorganApp extends StatelessWidget {
  const QorganApp({
    required this.repository,
    required this.incomingMessages,
    super.key,
  });

  final ProtectionRepository repository;
  final IncomingMessageService incomingMessages;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppCopy.name,
      debugShowCheckedModeBanner: false,
      theme: qorganTheme(),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HomeShell(
        repository: repository,
        incomingMessages: incomingMessages,
      ),
    );
  }
}
