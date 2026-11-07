import type { Metadata } from "next";

// Route source: qorgan-web/src/app/privacy/page.tsx.
// Mobile-app policy only. Keep both Markdown policies and this copy aligned.
export const metadata: Metadata = {
  title: "Qorğan — Политика конфиденциальности / Privacy Policy",
  description:
    "Политика конфиденциальности мобильного приложения Qorğan: SMS на устройстве, хранение, загрузка списка адресов и добровольные обращения.",
  alternates: { canonical: "https://qorgan-web.vercel.app/privacy" },
};

const contactEmail = "omirtayazamatt@gmail.com";
const linkClass =
  "break-words text-mint underline decoration-mint/50 underline-offset-4 hover:decoration-mint focus-visible:rounded-sm focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-mint";

const policies = [
  {
    lang: "ru",
    title: "Политика конфиденциальности Qorğan",
    date: "Дата: 7 ноября 2026 года.",
    contact:
      "Разработчик: Azamat. Конфиденциальность, поддержка и удаление добровольно присланных данных:",
    sections: [
      {
        id: "ru-1",
        title: "1. Область действия",
        paragraphs: [
          "Эта политика относится к мобильному приложению Qorğan для Android — проверке SMS на признаки фишинга на устройстве пользователя. Она не описывает другие сервисы сайта Qorğan. Для использования приложения не нужны учётная запись или регистрация. В мобильном приложении нет рекламы и SDK аналитики; оно не отправляет автоматические отчёты о сбоях разработчику.",
          "Qorğan выдаёт предупреждения о возможном риске. Оно не блокирует ссылки и не удаляет сообщения из вашего приложения SMS. Оценка может быть ошибочной, а отсутствие предупреждения не подтверждает подлинность сообщения.",
        ],
      },
      {
        id: "ru-2",
        title: "2. Доступ к новым SMS и работа в фоне",
        paragraphs: [
          "Фоновая проверка включается по вашему выбору. Перед запросом разрешения приложение объясняет доступ к новым SMS; вы можете отказаться и пользоваться ручной проверкой. Для предупреждений нужны разрешения на приём новых SMS и уведомления, после чего вы отдельно включаете защиту.",
          "При включённой защите Qorğan получает текст новых входящих SMS, сведения об отправителе, которые передаёт Android, и время получения. Эти данные используются для локальной проверки и показа результата, в том числе когда экран приложения не открыт. Приложение не загружает старую переписку из системного SMS-приложения, не отправляет SMS и не требует стать SMS-приложением по умолчанию. Работа фоновых предупреждений зависит от разрешений и ограничений Android.",
        ],
      },
      {
        id: "ru-3",
        title: "3. Локальная обработка и история",
        paragraphs: [
          "Текст, отправитель и ссылки проверяются локальными правилами и локальным списком фишинговых адресов. Для вынесения оценки Qorğan не отправляет SMS, отправителя или ссылки из проверяемого сообщения на сервер.",
          "В хранилище приложения на телефоне сохраняются до 100 последних принятых SMS: текст, отправитель, время получения, оценка, балл и признаки, состояние предупреждения и ваша отметка об ошибке или мошенничестве, если вы её сделали. Для связи записи с уведомлением используется локальный ключ сообщения. При добавлении новых записей более старые удаляются сверх этого предела. Это ограничение по количеству записей, а не срок в днях: оставшиеся записи хранятся до вытеснения, очистки истории или удаления данных приложения.",
          "Настройки защиты и первого запуска, локальный список адресов и время его последнего успешного обновления также сохраняются на устройстве. Отметка об ошибке сама по себе не отправляет сообщение разработчику и не изменяет автоматически правило проверки.",
        ],
      },
      {
        id: "ru-4",
        title: "4. Ручная проверка и буфер обмена",
        paragraphs: [
          "Текст, который вы вводите или вставляете для ручной проверки, и её результат хранятся в памяти приложения. Черновик может сохраняться при переходах между экранами до его очистки или завершения процесса приложения. Ручная проверка не добавляет этот текст в историю принятых SMS и не загружает его на сервер. Вставка из буфера обмена выполняется по вашему действию.",
          "Буфер обмена и используемая клавиатура управляются Android и выбранными вами приложениями. Если вы копируете текст или используете синхронизацию буфера обмена, дополнительные копии могут обрабатываться этими средствами по их правилам.",
        ],
      },
      {
        id: "ru-5",
        title: "5. Загрузка публичного списка адресов",
        paragraphs: [
          "При запуске на переднем плане Qorğan может загрузить публичный список фишинговых адресов по HTTPS с постоянного адреса: https://malware-filter.gitlab.io/malware-filter/phishing-filter-hosts.txt. После успешного обновления приложение ждёт не менее 12 часов до следующего обновления; неудачная попытка может повториться при следующем запуске. Фоновый обработчик SMS использует локальный список и не делает сетевой запрос для каждого сообщения.",
          "Запрос GET не содержит текста SMS, отправителя, оценки, ссылки из проверяемого сообщения или добавленного приложением идентификатора устройства. При этом инфраструктура GitLab, обслуживающая список, видит сетевой IP-адрес и технические сведения запроса. HTTPS не скрывает IP от принимающей стороны. Qorğan не запрашивает местоположение устройства и не определяет его по IP.",
          "Согласно [политике GitLab, раздел «GitLab Pages Data»](https://about.gitlab.com/privacy/), журналы доступа содержат IP, время и посещённую страницу; хранятся 7 дней с последовательным удалением старых записей. Среди целей указано предотвращение мошенничества и злоупотреблений. Это опубликованные сведения, проверенные 7 ноября 2026 года, а не независимый аудит. Указанный срок не является гарантией для иных систем издателя списка или других получателей данных.",
          "Эта загрузка может происходить независимо от того, включена ли фоновая проверка SMS. Выключение защиты само по себе не выключает загрузку списка при запуске. При отсутствии сети используются доступные локальные правила и список.",
        ],
      },
      {
        id: "ru-6",
        title: "6. Исправления, копирование отчёта и поддержка",
        paragraphs: [
          "Отчёт об отмеченных сообщениях формируется локально. Если вы решите скопировать такой отчёт, он содержит полный текст отмеченных SMS, отправителей, время получения, результаты проверки, баллы и признаки, ваши отметки и дату отчёта. Копирование в буфер обмена не является автоматической отправкой разработчику.",
          "Перед вставкой отчёта в письмо, мессенджер или другой внешний сервис просмотрите и удалите личные данные, номера счетов, телефоны, пароли, коды подтверждения и сведения других людей. Отчёт не обезличен автоматически. Вы сами выбираете, передавать ли его, кому и через какой сервис; правила этого сервиса применяются к передаваемой копии.",
          "Если вы добровольно пишете на omirtayazamatt@gmail.com, разработчик получает ваш адрес электронной почты, содержание обращения, технические сведения письма и выбранные вами вложения. Эти данные нужны для ответа и разбора описанной проблемы. Автоматической загрузки SMS или отчётов в поддержку нет. Письма и вложения могут оставаться в почтовом ящике до удаления; фиксированный срок хранения таких обращений не установлен. Чтобы запросить удаление добровольно присланных данных, напишите на тот же адрес и укажите, какое обращение нужно найти, без повторной отправки чувствительного SMS.",
        ],
      },
      {
        id: "ru-7",
        title: "7. Управление данными и удаление",
        paragraphs: [
          "Вы можете выключить защиту в Qorğan и отозвать SMS-разрешение в настройках Android. Это ограничивает дальнейший доступ, но само по себе не удаляет уже сохранённую историю.",
          "Действие «Очистить историю» в настройках удаляет сохранённые копии сообщений и связанные с ними отметки из Qorğan. Исходные SMS в вашем приложении сообщений остаются. Пока защита включена, новые входящие SMS могут снова создавать записи, в том числе во время очистки.",
          "Удаление Qorğan или очистка его данных средствами Android удаляет локальные данные приложения обычным способом операционной системы. Это не удаляет исходные SMS, текст в буфере обмена, уже отправленные письма или копии у выбранных вами получателей. Для удаления данных, которые вы добровольно прислали разработчику, используйте контакт выше. Разработчик может работать с доступными ему копиями, но не управляет чужими почтовыми ящиками, внешними публикациями и инфраструктурными журналами GitLab; ограничения по конкретному запросу будут разъяснены в ответе.",
        ],
      },
      {
        id: "ru-8",
        title: "8. Защита хранения и резервное копирование",
        paragraphs: [
          "Локальные записи находятся в хранилище приложения, доступ к которому ограничивается средствами Android. Отдельное шифрование базы данных приложением не заявляется. Блокировка устройства и его системные настройки помогают защищать доступ к вашим данным.",
          "В конфигурации Android резервное копирование приложения отключено. Это мера снижения риска, а не гарантия для всех устройств: поведение восстановления, переноса между устройствами и средств производителя может отличаться. Qorğan не предоставляет собственную облачную синхронизацию SMS. Мы не гарантируем, что все способы переноса устройства исключают данные приложения.",
        ],
      },
      {
        id: "ru-9",
        title: "9. Контакт и изменения",
        paragraphs: [
          "По вопросам этой политики и удаления добровольно присланных данных обращайтесь к Azamat: omirtayazamatt@gmail.com. Политика может обновляться при изменении обработки данных; актуальная редакция обозначается датой в начале страницы. Существенные изменения доступа к SMS должны отражаться и в объяснении внутри приложения.",
        ],
      },
    ],
  },
  {
    lang: "en",
    title: "Qorğan Privacy Policy",
    date: "Date: 7 November 2026.",
    contact:
      "Developer: Azamat. Privacy, support and deletion of voluntarily submitted data:",
    sections: [
      {
        id: "en-1",
        title: "1. Scope",
        paragraphs: [
          "This policy covers the Qorğan Android mobile app, which checks SMS for phishing signals on the user's device. It does not describe other services on the Qorğan website. No account or registration is required. The mobile app has no ads or analytics SDKs and does not send automatic crash reports to the developer.",
          "Qorğan gives warnings about possible risk. It does not block links or delete messages from your SMS app. An assessment can be wrong, and the absence of a warning does not establish that a message is authentic.",
        ],
      },
      {
        id: "en-2",
        title: "2. New SMS access and background use",
        paragraphs: [
          "Background checking is your choice. Before requesting permission, the app explains its access to new SMS; you can decline and use manual checking. Alerts require incoming SMS and notification permissions, followed by your separate action to enable protection.",
          "While protection is enabled, Qorğan receives new incoming SMS text, sender information supplied by Android and the time of receipt. It uses these data for local assessment and displaying results, including when the app's screen is not open. It does not load the existing inbox from the system SMS app, send SMS or require becoming the default SMS app. Background alerts depend on permissions and Android restrictions.",
        ],
      },
      {
        id: "en-3",
        title: "3. Local processing and history",
        paragraphs: [
          "Text, sender information and links are checked using local rules and an on-device phishing-host list. Qorğan does not send an SMS, its sender or links from the message to a server to make the assessment.",
          "The app's storage on your phone keeps up to 100 recent received SMS records: text, sender, receipt time, assessment, score and signals, notification state and any correction or fraud label you have saved. A local message key associates a record with its notification. Older records beyond this limit are removed when new ones are added. This is a record-count limit, not a period in days: remaining records stay until displaced, history is cleared or app data are removed.",
          "Protection and onboarding preferences, the local host list and its last successful update time are also stored on the device. Marking an assessment as wrong does not itself send the message to the developer or automatically change the detection rule.",
        ],
      },
      {
        id: "en-4",
        title: "4. Manual checks and clipboard",
        paragraphs: [
          "Text you enter or paste for a manual check, and its result, are held in app memory. A draft may remain while moving between screens until you clear it or the app process exits. A manual check does not add that text to received-message history or upload it to a server. Pasting from the clipboard is triggered by your action.",
          "The clipboard and your chosen keyboard are controlled by Android and the apps you use. If you copy text or use clipboard synchronization, those facilities may handle additional copies under their own rules.",
        ],
      },
      {
        id: "en-5",
        title: "5. Public host-list download",
        paragraphs: [
          "When launched in the foreground, Qorğan may download a public phishing-host list over HTTPS from this constant address: https://malware-filter.gitlab.io/malware-filter/phishing-filter-hosts.txt. After a successful update, the app waits at least 12 hours before another update; a failed attempt may be retried on a later launch. The background SMS handler uses the local list and does not make a network request for each message.",
          "The GET request contains no SMS text, sender, assessment, link from the message being checked or app-added device identifier. However, GitLab infrastructure serving the list sees the network IP address and technical request information. HTTPS does not hide the IP from the receiving infrastructure. Qorğan does not request device location or infer it from IP.",
          "According to [GitLab's policy, “GitLab Pages Data”](https://about.gitlab.com/privacy/), access logs contain IP, access time and visited page, retained for seven days with rolling deletion. Listed purposes include fraud and abuse prevention. This is published information checked on 7 November 2026, not an independent audit. That retention period is not a guarantee for other systems operated by the list publisher or other data recipients.",
          "This download may occur whether or not background SMS checking is enabled. Turning protection off does not itself disable list downloads on app launch. Available local rules and the list can be used without a network connection.",
        ],
      },
      {
        id: "en-6",
        title: "6. Corrections, copied reports and support",
        paragraphs: [
          "A report about marked messages is generated locally. If you choose to copy such a report, it contains the full text of marked SMS, senders, receipt times, assessments, scores and signals, your labels and the report date. Copying to the clipboard is not automatic delivery to the developer.",
          "Before pasting a report into email, a messenger or another external service, review and remove personal information, account numbers, phone numbers, passwords, verification codes and other people's details. The report is not automatically anonymized. You decide whether to send it, to whom and through which service; that service's rules apply to the transferred copy.",
          "If you voluntarily email omirtayazamatt@gmail.com, the developer receives your email address, request content, email technical information and any attachments you select. These data are used to respond and investigate the problem you describe. There is no automatic SMS or report upload to support. Emails and attachments may remain in the mailbox until deleted; no fixed retention period has been established for these requests. To request deletion of data you voluntarily sent, email the same address and identify the request to locate, without resending the sensitive SMS.",
        ],
      },
      {
        id: "en-7",
        title: "7. Your controls and deletion",
        paragraphs: [
          "You can turn protection off in Qorğan and revoke SMS permission in Android settings. This limits further access but does not itself delete existing history.",
          "The clear-history action in settings removes saved message copies and their associated labels from Qorğan. Original SMS remain in your messaging app. While protection is on, new incoming SMS may create new records, including during a history-clear operation.",
          "Uninstalling Qorğan or clearing its data through Android removes local app data through the operating system's normal process. This does not delete original SMS, clipboard text, emails already sent or copies held by recipients you chose. Use the contact above to request deletion of data voluntarily sent to the developer. The developer can act on copies under their control, but does not control other people's mailboxes, external publications or GitLab infrastructure logs; limitations relevant to a specific request will be explained in the response.",
        ],
      },
      {
        id: "en-8",
        title: "8. Storage protection and backups",
        paragraphs: [
          "Local records are in app storage with access restricted by Android. We do not claim separate app-level database encryption. Your device lock and system settings help protect access to your data.",
          "App backup is disabled in the Android configuration. This is a risk-reduction measure, not a guarantee across all devices: restore, device-to-device transfer and manufacturer tools can behave differently. Qorğan does not provide its own cloud SMS synchronization. We cannot guarantee that every device-transfer method excludes app data.",
        ],
      },
      {
        id: "en-9",
        title: "9. Contact and changes",
        paragraphs: [
          "For questions about this policy or deletion of voluntarily submitted data, contact Azamat at omirtayazamatt@gmail.com. This policy may change when data handling changes; the current revision is identified by the date at the top. Material changes in SMS access must also be reflected in the in-app explanation.",
        ],
      },
    ],
  },
] as const;

function PolicyParagraph({ text }: { text: string }) {
  // Render the single fixed provider citation without a Markdown dependency.
  const citation =
    /\[([^\]]+)\]\((https:\/\/about\.gitlab\.com\/privacy\/)\)/.exec(text);
  if (!citation) return <p>{text}</p>;
  return (
    <p>
      {text.slice(0, citation.index)}
      <a href={citation[2]} className={linkClass}>
        {citation[1]}
      </a>
      {text.slice(citation.index + citation[0].length)}
    </p>
  );
}

export default function PrivacyPage() {
  return (
    <main className="min-h-svh bg-canvas px-5 py-10 text-ink sm:px-8 sm:py-16">
      <div className="mx-auto max-w-3xl">
        <header className="mb-12 border-b border-chip pb-6">
          <p className="font-mono text-sm tracking-wide text-muted">
            Qorğan · Android
          </p>
          <h1 className="mt-4 text-3xl font-semibold tracking-tight sm:text-4xl">
            Политика конфиденциальности
            <span
              lang="en"
              className="mt-2 block text-xl font-normal text-muted"
            >
              Privacy Policy
            </span>
          </h1>
          <nav
            aria-label="Язык / Language"
            className="mt-6 flex flex-wrap gap-x-6 gap-y-3"
          >
            <a href="#ru" lang="ru" className={linkClass}>
              Русский
            </a>
            <a href="#en" lang="en" className={linkClass}>
              English
            </a>
          </nav>
        </header>
        <div className="space-y-16">
          {policies.map((policy) => (
            <article
              key={policy.lang}
              id={policy.lang}
              lang={policy.lang}
              aria-labelledby={`${policy.lang}-title`}
              className="scroll-mt-8"
            >
              <h2
                id={`${policy.lang}-title`}
                className="text-2xl font-semibold tracking-tight"
              >
                {policy.title}
              </h2>
              <p className="mt-3 text-sm text-muted">
                <time dateTime="2026-11-07">{policy.date}</time>
              </p>
              <p className="mt-5 leading-7 text-muted">
                {policy.contact}{" "}
                <a href={`mailto:${contactEmail}`} className={linkClass}>
                  {contactEmail}
                </a>
                .
              </p>
              <div className="mt-8 space-y-9">
                {policy.sections.map((section) => (
                  <section key={section.id} aria-labelledby={section.id}>
                    <h3 id={section.id} className="text-lg font-semibold">
                      {section.title}
                    </h3>
                    <div className="mt-3 space-y-4 break-words text-base leading-7 text-muted">
                      {section.paragraphs.map((paragraph) => (
                        <PolicyParagraph key={paragraph} text={paragraph} />
                      ))}
                    </div>
                  </section>
                ))}
              </div>
            </article>
          ))}
        </div>
      </div>
    </main>
  );
}
