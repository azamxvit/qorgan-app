import '../../domain/models/message_verdict.dart';

abstract final class AppCopy {
  static const name = 'Qorğan';
  static const tagline = 'Проверка SMS на телефоне. Предупреждения о фишинге.';
  static const guardTitle = 'Фоновая защита';
  static const guardBody =
      'Qorgan проверяет входящие SMS и предупреждает о подозрительных сообщениях, даже когда приложение закрыто. SMS остаётся в вашем приложении сообщений.';
  static const armed = 'Защита включена — предупреждения готовы';
  static const disarmed = 'Автоматическая защита не активна';
  static const waiting = 'Входящих сообщений пока нет.';
  static const blocked = 'Подозрительное сообщение';
  static const smsTitle = 'Проверка SMS';
  static const smsBody =
      'Вставьте текст сообщения. Решение считается на устройстве.';
  static const allow = 'Можно пропустить';
  static const noSignals = 'Признаков социальной инженерии нет.';

  static const signalText = {
    MessageSignal.bank: 'Есть название банка.',
    MessageSignal.urgency: 'Есть срочность.',
    MessageSignal.pressure: 'Есть давление.',
    MessageSignal.secret: 'Просят код или пароль.',
    MessageSignal.unofficialLink: 'Ссылка не на официальный сайт банка.',
    MessageSignal.impersonation:
        'Пишут от имени банка, но с обычного номера телефона.',
    MessageSignal.prize: 'Обещают выигрыш или компенсацию.',
    MessageSignal.payment: 'Просят оплатить или перевести деньги.',
    MessageSignal.blockedHost:
        'Ссылка ведёт на адрес, уже известный как фишинговый.',
  };
}
