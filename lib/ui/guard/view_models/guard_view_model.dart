import 'package:flutter/foundation.dart';

import '../../../data/repositories/protection_repository.dart';
import '../../../data/services/incoming_message_service.dart';
import '../../../domain/models/message_verdict.dart';
import '../../../data/services/message_store.dart';

class GuardViewModel extends ChangeNotifier {
  GuardViewModel({
    required this._repository,
    required this._incomingMessages,
    required this._sample,
  }) {
    _incomingMessages.listen(_onIncoming);
  }
  final ProtectionRepository _repository;
  final IncomingMessageService _incomingMessages;
  final String _sample;
  MessageVerdict? _verdict;
  String? _message;
  String? _sender;
  ProtectionAccess _access = const ProtectionAccess();
  bool _busy = false;
  bool _disposed = false;
  bool _refreshRequested = false;
  String? _error;
  List<StoredMessage> _messages = [];
  List<StoredMessage> get messages => List.unmodifiable(_messages);
  int get checkedCount => _messages.length;
  int get suspiciousCount => _messages.where((m) => m.verdict.block).length;
  bool get armed => _repository.armed;
  bool get active => armed && _access.ready;
  bool get received => _verdict != null;
  bool get busy => _busy;
  ProtectionAccess get access => _access;
  String? get error => _error;
  String? get message => _message;
  String? get sender => _sender;
  MessageVerdict? get verdict => _verdict;
  bool get blocked => _verdict?.block ?? false;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refresh() async {
    if (_busy) {
      _refreshRequested = true;
      return;
    }
    _busy = true;
    _changed();
    try {
      await _repository.initialize();
      _access = await _incomingMessages.status();
      _messages = await _incomingMessages.recent();
      final latest = await _incomingMessages.latest();
      if (latest != null) {
        _verdict = latest.verdict;
        _message = latest.message.body;
        _sender = latest.message.sender;
      }
      _error = null;
    } catch (_) {
      _error = 'Не удалось проверить состояние защиты. Попробуйте снова.';
      _access = const ProtectionAccess();
    } finally {
      _busy = false;
      _changed();
      if (_refreshRequested && !_disposed) {
        _refreshRequested = false;
        await refresh();
      }
    }
  }

  Future<void> toggle() async {
    if (_busy) return;
    _busy = true;
    _error = null;
    _changed();
    try {
      if (armed) {
        await _repository.setArmed(false);
      } else {
        _access = await _incomingMessages.requestAccess();
        if (_access.ready) {
          await _repository.setArmed(true);
        } else {
          _error = 'Для фоновых предупреждений разрешите приём SMS и уведомления в настройках.';
        }
      }
    } catch (_) {
      _error =
          'Не удалось изменить состояние защиты. Настройка не подтверждена.';
    } finally {
      _busy = false;
      _changed();
      if (_refreshRequested && !_disposed) {
        _refreshRequested = false;
        await refresh();
      }
    }
  }

  Future<void> openSettings() => _incomingMessages.openSettings();
  void simulate() => _onIncoming(_sample);
  void _onIncoming(String text) {
    _message = text;
    _sender = null;
    _verdict = _repository.inspect(text);
    _changed();
    refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    _incomingMessages.dispose();
    super.dispose();
  }
}
