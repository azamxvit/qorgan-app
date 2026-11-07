import 'package:flutter/foundation.dart';

import '../../../data/repositories/protection_repository.dart';
import '../../../domain/models/message_verdict.dart';

class SmsCheckResult {
  const SmsCheckResult({required this.text, required this.verdict});
  final String text;
  final MessageVerdict verdict;
}

class SmsViewModel extends ChangeNotifier {
  SmsViewModel({required this._repository});
  final ProtectionRepository _repository;
  var _text = '';
  SmsCheckResult? _result;
  String? _error;
  bool _busy = false;
  bool _disposed = false;
  int _generation = 0;

  String get text => _text;
  SmsCheckResult? get result => _result;
  MessageVerdict? get verdict => _result?.verdict;
  String? get error => _error;
  bool get busy => _busy;
  bool get canSubmit => !_disposed && !_busy && _text.trim().isNotEmpty;

  void setText(String value) {
    if (_disposed || value == _text) return;
    _generation++;
    _text = value;
    _result = null;
    _error = null;
    _busy = false;
    notifyListeners();
  }

  void clear() => setText('');

  Future<SmsCheckResult?> submit() async {
    if (!canSubmit) return null;
    final snapshot = _text;
    final generation = ++_generation;
    _busy = true;
    _error = null;
    _result = null;
    notifyListeners();
    try {
      final verdict = await _repository.inspect(snapshot);
      if (_disposed || generation != _generation) return null;
      return _result = SmsCheckResult(text: snapshot, verdict: verdict);
    } catch (_) {
      if (!_disposed && generation == _generation) {
        _error = 'Не удалось проверить текст. Попробуйте ещё раз.';
      }
      return null;
    } finally {
      if (!_disposed && generation == _generation) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
