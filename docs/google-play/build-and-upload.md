# Сборка и загрузка первого закрытого теста

Подготовлено 7 ноября 2026 года. Владелец подтвердил: предыдущих загрузок не было. Package ID — `kz.qorgan.qorgan_app`, версия — `1.0.0`, versionCode — `1`. Фоновая защита и `RECEIVE_SMS` сохранены. Загрузка в Play Console этим процессом не выполняется.

## Готовые файлы

В `artifacts/play-release/`:

- `qorgan-1.0.0-1.aab` — подписанный Android App Bundle для Play.
- `qorgan-1.0.0-1.apk` — APK той же версии для установки на тестовый телефон.
- `upload-certificate.pem` — публичный сертификат upload-ключа.
- `verification.json`, `release-manifest.xml` — проверка конкретных артефактов и итоговый manifest.

Иконка магазина 512×512 и feature graphic 1024×500 — в `docs/google-play/assets/`. Скриншоты и видео для Google нужно снять с этой версии; имеющиеся старые превью не являются свидетельством работы фонового приёмника.

## Ключ подписи

Первый upload-ключ уже создан. **Не генерируйте новый для следующего обновления.** Приватные файлы находятся вне репозитория:

- `~/.qorgan/signing/upload-keystore.jks`
- `~/.qorgan/signing/upload.password`

Alias: `upload`. Локальный `android/key.properties` содержит пути и пароли, имеет права `0600` и исключён из Git. Каталог с ключом и паролем нужно сохранить в защищённой резервной копии. Ни пароль, ни JKS нельзя добавлять в документацию, чат или Git. Публичный сертификат раскрывать можно.

SHA-256 сертификата:

```text
91cf5b397c2868cb9e5a81f17ccf4cc16ad68a87d6495451073ab5cc17b74855
```

При первой загрузке используйте Play App Signing: Google управляет ключом подписи распространяемого приложения, локальный ключ служит для загрузки. После установки через Google Play сертификат приложения будет отличаться от upload-сертификата — это ожидаемо.

## Повторить сборку на этом Mac

Установлены Flutter 3.47.5, Temurin Java 17.0.21+9, Android SDK 36, Build Tools 36.0.0, NDK 28.2.13676358. SDK расположен в `~/Library/Android/sdk`, Java — в `~/Library/Java/JavaVirtualMachines/jdk-17.0.21+9/Contents/Home`. Временный SDK больше не используется.

Из корня qorgan-app:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
python3 -m unittest discover -s scripts/tests
python3 scripts/build_play_release.py --apk
```

Скрипт использует публичные параметры `config/play-release.json`, выбирает Java 17 на macOS и собирает обе версии из текущего дерева. Gradle завершает release-сборку ошибкой при отсутствии приватной подписи. Перед следующим обновлением увеличьте build number в `pubspec.yaml`. При смене версии уберите старые артефакты из каталога публикации вручную, чтобы не выбрать их в Console.

Для проверки используется официальный `bundletool-all-1.18.3.jar`:

```bash
curl -fL --retry 2 https://github.com/google/bundletool/releases/download/1.18.3/bundletool-all-1.18.3.jar -o /tmp/qorgan-bundletool-1.18.3.jar
python3 scripts/inspect_play_release.py \
  --aab artifacts/play-release/qorgan-1.0.0-1.aab \
  --apk artifacts/play-release/qorgan-1.0.0-1.apk \
  --bundletool /tmp/qorgan-bundletool-1.18.3.jar
```

Инспектор проверяет SHA-256 самого bundletool, валидность AAB, подписи, равенство package/version у APK и AAB, разрешения, запрет backup/debuggable, защищённый SMS receiver, 16 KB alignment AAB/APK и 64-битных ELF. Это статические проверки, не запуск на телефоне с 16 KB страницами.

На новом Mac инструмент `scripts/install_android_toolchain.py --accept-sdk-licenses` загружает проверенные хешами Java/SDK после принятия [условий Android SDK](https://developer.android.com/studio/terms). Не запускайте `create_upload_key.py --first-upload` при уже существующей публикации: восстановите сохранённый ключ.

## CI

`checks.yml` проверяет код и собирает APK с явно выбранной временной debug-подписью. Артефакт назван `qorgan-smoke-apk-not-for-play`; его нельзя загружать в Play. Использование этого режима для AAB запрещено Gradle.

`play-bundle.yml` запускается вручную, использует environment `google-play-closed-test` и secrets:

- `QORGAN_UPLOAD_KEY_BASE64` — JKS в base64;
- `QORGAN_KEYSTORE_PASSWORD` и `QORGAN_KEY_PASSWORD`;
- `QORGAN_KEY_ALIAS` — `upload`.

Создайте secrets через защищённый интерфейс GitHub, не через вывод ключа/пароля в чат. Workflow повторяет проверки, собирает и инспектирует AAB/APK; публикации в Google Play нет. GitHub workflow ещё не запускался: по просьбе владельца изменений в Git не отправляли.

## Последовательность в Play Console

1. Завершить проверку личного аккаунта и Android-устройства, если Console требует её. Создать приложение с правильным package ID.
2. Заполнить карточку по `store-listing.md`, добавить актуальные скриншоты, иконку и feature graphic.
3. Указать публичную политику `https://qorgan-web.vercel.app/privacy`; проверить её без входа в Vercel. Заполнить Data safety по `data-safety.md`, App access — без аккаунта, остальные анкеты — по реальному продукту.
4. Включить Play App Signing и загрузить **AAB** в закрытый трек. Убедиться, что Console видит versionCode 1 и ожидаемый package ID.
5. Подать Permissions Declaration Form по `sms-permission-declaration.md`: только `RECEIVE_SMS`, anti-SMS phishing. Добавить настоящее демонстрационное видео и доступные подтверждения эффективности. Решение принимает Google; тесты не заменяют требуемую историю защиты пользователей.
6. Провести проверку по `docs/android-phone-check.md` и `closed-testing.md`, выдать доступ реальным тестировщикам, собрать обратную связь. Для этого нового личного аккаунта нужны не менее 12 тестировщиков, непрерывно подключённых к закрытому тесту 14 дней, прежде чем подавать на production access.

Официальные основания: [SMS declaration](https://support.google.com/googleplay/android-developer/answer/9214102?hl=en), [SMS exception](https://support.google.com/googleplay/android-developer/answer/10208820?hl=en), [закрытый тест](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en), [Play App Signing](https://developer.android.com/studio/publish/app-signing).
