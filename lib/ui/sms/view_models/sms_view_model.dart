import 'package:flutter/foundation.dart';

import '../../../data/repositories/protection_repository.dart';
import '../../../domain/models/message_verdict.dart';

class SmsViewModel extends ChangeNotifier {
  SmsViewModel({required this._repository});

  final ProtectionRepository _repository;

  var _text = '';

  String get text => _text;
  MessageVerdict get verdict =>
      _text.trim().isEmpty ? MessageVerdict.clear : _repository.inspect(_text);

  void setText(String value) {
    _text = value;
    notifyListeners();
  }
}
