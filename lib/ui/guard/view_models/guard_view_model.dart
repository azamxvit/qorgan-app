import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/protection_repository.dart';
import '../../../data/services/incoming_message_service.dart';
import '../../../data/services/message_store.dart';
import '../../../domain/models/message_verdict.dart';

class GuardViewModel extends ChangeNotifier {
  GuardViewModel({required this._repository, required this._incomingMessages}) {
    _incomingMessages.listen(_onIncoming);
  }
  final ProtectionRepository _repository;
  final IncomingMessageService _incomingMessages;
  MessageVerdict? _verdict;
  String? _message;
  String? _sender;
  ProtectionAccess _access = const ProtectionAccess();
  bool _busy = false;
  bool _loaded = false;
  bool _statusKnown = false;
  bool _disposed = false;
  bool _refreshRequested = false;
  String? _error;
  String? _statusError;
  String? _historyError;
  List<StoredMessage> _messages = [];
  List<StoredMessage> get messages => List.unmodifiable(_messages);
  int get checkedCount => _messages.length;
  int get suspiciousCount => _messages.where((m) => m.verdict.block).length;
  bool get armed => _repository.armed;
  bool get active => _statusKnown && armed && _access.ready;
  bool get received => _verdict != null;
  bool get busy => _busy;
  bool get loaded => _loaded;
  bool get statusKnown => _statusKnown;
  ProtectionAccess get access => _access;
  String? get error => _error ?? _statusError ?? _historyError;
  String? get statusError => _statusError;
  String? get historyError => _historyError;
  String? get message => _message;
  String? get sender => _sender;
  MessageVerdict? get verdict => _verdict;
  bool get blocked => _verdict?.block ?? false;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void _begin({bool checkingStatus = false}) {
    _busy = true;
    _error = null;
    if (checkingStatus) _statusKnown = false;
    _changed();
  }

  Future<void> _finish() async {
    _busy = false;
    _changed();
    if (_refreshRequested && !_disposed) {
      _refreshRequested = false;
      await refresh();
    }
  }

  Future<void> _readStatus(
    Future<ProtectionAccess> Function() readAccess,
  ) async {
    try {
      await _repository.initialize();
      _access = await readAccess();
      _statusKnown = true;
      _statusError = null;
    } catch (_) {
      _statusKnown = false;
      _statusError = 'Не удалось проверить состояние защиты. Попробуйте снова.';
    } finally {
      _loaded = true;
    }
  }

  Future<void> _readHistory() async {
    try {
      _messages = await _incomingMessages.recent();
      final latest = _messages.firstOrNull;
      _verdict = latest?.verdict;
      _message = latest?.message.body;
      _sender = latest?.message.sender;
      _historyError = null;
    } catch (_) {
      _historyError = 'Не удалось загрузить сообщения. Попробуйте снова.';
    }
  }

  Future<void> refresh() async {
    if (_busy) {
      _refreshRequested = true;
      return;
    }
    _begin(checkingStatus: true);
    try {
      await _readStatus(_incomingMessages.status);
      // History failure cannot disable protection; a status failure cannot hide
      // messages that are still readable.
      await _readHistory();
    } finally {
      await _finish();
    }
  }

  Future<ProtectionAccess> _requestCapability(
    Future<ProtectionAccess> Function() request,
    bool Function(ProtectionAccess) granted,
    String deniedMessage,
  ) async {
    if (_busy) return _access;
    _begin(checkingStatus: true);
    try {
      await _readStatus(request);
      if (_statusKnown && !granted(_access)) _error = deniedMessage;
      return _access;
    } finally {
      await _finish();
    }
  }

  Future<ProtectionAccess> requestSmsAccess() => _requestCapability(
    _incomingMessages.requestSmsAccess,
    (access) => access.sms,
    'Доступ к новым SMS не предоставлен. Разрешите его в настройках Android или проверяйте текст вручную.',
  );

  Future<ProtectionAccess> requestNotificationAccess() => _requestCapability(
    _incomingMessages.requestNotificationAccess,
    (access) => access.notifications,
    'Предупреждения недоступны. Разрешите уведомления Qorgan в настройках Android.',
  );

  Future<bool> enable() => _enable();

  Future<bool> _enable({bool requestAccess = false}) async {
    if (_busy) return false;
    _begin(checkingStatus: true);
    try {
      await _readStatus(
        requestAccess
            ? _incomingMessages.requestAccess
            : _incomingMessages.status,
      );
      if (!_statusKnown) return false;
      if (!_access.ready) {
        _error = 'Для фоновых предупреждений разрешите приём SMS и уведомления в настройках.';
        return false;
      }
      await _repository.setArmed(true);
      return true;
    } catch (_) {
      _error =
          'Не удалось изменить состояние защиты. Настройка не подтверждена.';
      return false;
    } finally {
      await _finish();
    }
  }

  Future<bool> disable() async {
    if (_busy) return false;
    _begin();
    try {
      await _repository.initialize();
      await _repository.setArmed(false);
      return true;
    } catch (_) {
      _error =
          'Не удалось изменить состояние защиты. Настройка не подтверждена.';
      return false;
    } finally {
      await _finish();
    }
  }

  /// Compatibility for earlier callers; setup uses separate explicit steps.
  Future<void> toggle() async {
    if (armed) {
      await disable();
    } else {
      await _enable(requestAccess: true);
    }
  }

  Future<bool> clearHistory() async {
    if (_busy) return false;
    _begin();
    try {
      await _incomingMessages.clearHistory();
      await _readHistory();
      return _historyError == null;
    } catch (_) {
      _historyError = 'Не удалось очистить историю. Попробуйте снова.';
      return false;
    } finally {
      await _finish();
    }
  }

  Future<void> openSettings() => _incomingMessages.openSettings();

  void _onIncoming(String text) {
    // The persisted verdict includes sender and blocklist signals. A refresh
    // requested during another operation queues a second read.
    unawaited(refresh());
  }

  @override
  void dispose() {
    _disposed = true;
    _incomingMessages.dispose();
    super.dispose();
  }
}
