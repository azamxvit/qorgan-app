/// Messages the rule is measured against.
///
/// These are written by hand to match the shape of Kazakhstani SMS; they are
/// NOT collected user data. Treat the numbers they produce as a floor, not as
/// field accuracy, and replace these entries with messages gathered from real
/// phones with consent before trusting the rule in production.
///
/// Add every false alarm and every missed phishing message reported by a user
/// here first, then change the rule until this file passes again.
class CorpusSms {
  const CorpusSms(this.sender, this.body, {required this.phishing});

  /// Sender as Android reports it: an alphanumeric name, a short code, or a
  /// full phone number.
  final String sender;
  final String body;

  /// What a careful human would say about this message.
  final bool phishing;
}

/// Legitimate traffic. A warning on any of these costs user trust.
const legitimateSms = <CorpusSms>[
  CorpusSms(
    'KASPI',
    'Kaspi.kz: код 8123 для входа. Никому его не сообщайте.',
    phishing: false,
  ),
  CorpusSms(
    'KASPI',
    'Kaspi Gold: Пополнение 25 000 ₸. Доступно 132 400 ₸.',
    phishing: false,
  ),
  CorpusSms(
    'KASPI',
    'Kaspi.kz: Платеж 4 500 ₸ за Beeline проведен.',
    phishing: false,
  ),
  CorpusSms('HALYK', 'Halyk: Ваш код подтверждения 4455', phishing: false),
  CorpusSms(
    'HALYK',
    'Halyk Bank: Поступление 20 000 ₸. Доступно 145 300 ₸.',
    phishing: false,
  ),
  CorpusSms(
    'HALYK',
    'Halyk: по карте *1234 операция 12 000 ₸ в MAGNUM',
    phishing: false,
  ),
  CorpusSms(
    'HALYK',
    'Halyk: Напоминаем, платеж по кредиту 45 000 ₸ до 10 числа',
    phishing: false,
  ),
  CorpusSms(
    'Homebank',
    'Homebank: вход выполнен. Если это не вы, позвоните 7111.',
    phishing: false,
  ),
  CorpusSms(
    'JUSAN',
    'Jusan: Подтвердите вход в приложение, код 1122',
    phishing: false,
  ),
  CorpusSms(
    'BCC',
    'BCC: Поступление 50 000 KZT. Подробнее https://bcc.kz/app',
    phishing: false,
  ),
  CorpusSms(
    'FORTE',
    'Forte: срочно обновите приложение до 1 декабря',
    phishing: false,
  ),
  CorpusSms(
    'KASPI',
    'Kaspi.kz: Ваш кредит одобрен. Подробнее в приложении.',
    phishing: false,
  ),
  CorpusSms(
    'KASPI',
    'Kaspi.kz: Счет на оплату 8 900 ₸ от Казахтелеком',
    phishing: false,
  ),
  CorpusSms(
    'KASPI',
    'Kaspi Магазин: заказ доставлен. Спасибо за покупку!',
    phishing: false,
  ),
  CorpusSms(
    '1414',
    'Код подтверждения: 391045. Не сообщайте его никому.',
    phishing: false,
  ),
  CorpusSms('1402', 'Пароль для входа: 55102', phishing: false),
  CorpusSms('Yandex', 'Ваш код для входа: 442119', phishing: false),
  CorpusSms(
    'Beeline',
    'Beeline: на вашем номере осталось 100 минут',
    phishing: false,
  ),
  CorpusSms(
    'Kcell',
    'Kcell: пакет интернета 10 ГБ активирован',
    phishing: false,
  ),
  CorpusSms(
    'eGov',
    'eGov: Ваша заявка принята. Номер 7781234',
    phishing: false,
  ),
  CorpusSms('Wolt', 'Курьер заберет заказ через 15 минут', phishing: false),
  CorpusSms('Glovo', 'Оплатите заказ в приложении', phishing: false),
  CorpusSms(
    'OLX',
    'Ваше объявление опубликовано: https://olx.kz/item/123',
    phishing: false,
  ),
  CorpusSms(
    'Magnum',
    'Magnum Club: вам начислено 500 бонусов. Поздравляем!',
    phishing: false,
  ),
  CorpusSms(
    'AirAstana',
    'Рейс KC 123 задержан на 40 минут. Извините за неудобства.',
    phishing: false,
  ),
];

/// Phishing and social engineering. A miss here is the reason the app exists.
const phishingSms = <CorpusSms>[
  CorpusSms(
    '+7 701 123 45 67',
    'Halyk Bank: по вашей карте замечена подозрительная операция. Перезвоните.',
    phishing: true,
  ),
  CorpusSms(
    '+7 707 888 99 00',
    'Kaspi: Ваш счет заблокирован. Сообщите код из SMS для разблокировки.',
    phishing: true,
  ),
  CorpusSms(
    'KASPI-INFO',
    'KASPI: Счёт заблокируют через 15 минут. Срочно подтвердите код: '
        'http://kaspi-secure.xyz/login',
    phishing: true,
  ),
  CorpusSms(
    '+7 701 222 33 44',
    'Вам перевод 150 000 тг, получите на halyk-bonus.ru',
    phishing: true,
  ),
  CorpusSms(
    'Bank',
    'Ваша карта заблокирована. Перейдите https://bit.ly/3xKz9',
    phishing: true,
  ),
  CorpusSms(
    '+7 705 555 66 77',
    'Сіздің картаңыз бұғатталды. Жедел растау кодын жіберіңіз',
    phishing: true,
  ),
  CorpusSms(
    'Info',
    'Поздравляем! Вы выиграли iPhone 17. Оплатите доставку 2990 тг на '
        'kaspi-pay.top',
    phishing: true,
  ),
  CorpusSms(
    'Info',
    'Поздравляем! Вы выиграли приз. Оплатите доставку 2990 тг',
    phishing: true,
  ),
  CorpusSms(
    '+7 701 999 88 77',
    'Мама, это я, срочно переведи 50 000 на этот номер',
    phishing: true,
  ),
  CorpusSms(
    'Egov',
    'Вам начислена выплата 42500 тг. Срочно получите: egov-kz.site',
    phishing: true,
  ),
  CorpusSms(
    '+7 701 333 44 55',
    'Ваш номер выбран для компенсации. Введите код из SMS на forte-bonus.ru',
    phishing: true,
  ),
  CorpusSms(
    'Kaspi',
    'KАSPI: подтвердите код по ссылке http://kaspi-kz.secure-login.xyz',
    phishing: true,
  ),
  CorpusSms(
    '+7 706 111 22 33',
    'Здравствуйте! Я из службы безопасности банка. Назовите код из сообщения.',
    phishing: true,
  ),
  CorpusSms(
    '+7 702 444 55 66',
    'Ваш аккаунт Kaspi будет удален. Подтвердите данные: kaspi.kz.verify.ru',
    phishing: true,
  ),
];

const smsCorpus = [...legitimateSms, ...phishingSms];

/// The two messages other tests reference by name. They used to live in
/// `AppCopy` and therefore shipped inside the app; sample text belongs here.
const corpusPhishingSample =
    'KASPI: Счёт заблокируют через 15 минут. Срочно подтвердите код: '
    'http://kaspi-secure.xyz/login';
const corpusOrdinarySample =
    'Halyk Bank: Поступление 20 000 ₸. Доступно 145 300 ₸.';
