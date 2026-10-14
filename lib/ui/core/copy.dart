import '../../domain/models/message_verdict.dart';

abstract final class AppCopy {
  static const name = 'Qorğan';
  static const tagline = 'Проверка SMS на телефоне. Предупреждения о фишинге.';
  static const guardLabel = 'Фон';
  static const smsLabel = 'SMS';
  static const guardTitle = 'Фоновая защита';
  static const guardBody =
      'Qorgan проверяет входящие SMS и предупреждает о подозрительных сообщениях, даже когда приложение закрыто. SMS остаётся в вашем приложении сообщений.';
  static const armed = 'Защита включена — предупреждения готовы';
  static const disarmed = 'Автоматическая защита не активна';
  static const simulate = 'Показать пример проверки';
  static const waiting = 'Входящих сообщений пока нет.';
  static const passedWhileOff = 'Пропущено: фон был выключен.';
  static const blocked = 'Подозрительное сообщение';
  static const smsTitle = 'Проверка SMS';
  static const smsBody =
      'Вставьте текст сообщения. Решение считается на устройстве.';
  static const phishingSample = 'Фишинг';
  static const ordinarySample = 'Обычное';
  static const phishingText =
      'KASPI: Счёт заблокируют через 15 минут. Срочно подтвердите код: http://kaspi-secure.xyz/login';
  static const ordinaryText =
      'Halyk Bank: Поступление 20 000 ₸. Доступно 145 300 ₸.';
  static const allow = 'Можно пропустить';
  static const noSignals = 'Признаков социальной инженерии нет.';

  static const signalText = {
    MessageSignal.bank: 'Есть название банка.',
    MessageSignal.urgency: 'Есть срочность.',
    MessageSignal.pressure: 'Есть давление.',
    MessageSignal.secret: 'Просят код или пароль.',
    MessageSignal.unofficialLink: 'Ссылка не на официальный сайт банка.',
  };
}
