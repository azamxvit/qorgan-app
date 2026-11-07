# Saved Play Console answers — 7–8 November 2026

Package: `kz.qorgan.qorgan_app`, uploaded release **1.0.0 (1)**. Account: **TeqserTeam**. The owner requested that all changes be saved without sending the app for review. The owner explicitly selected an audience aged **13 and over** and separately accepted the **IARC Terms of Use** before the agreement checkbox was selected.

## App content

| Form | Saved answer |
| --- | --- |
| Privacy policy | `https://qorgan-web.vercel.app/privacy` |
| Sign-in details | All functionality available without special access; saved in the previous operation |
| Ads | No ads |
| Government apps | Not developed by or on behalf of a government |
| Financial features | My app does not provide any financial features |
| Health | My app does not have any health features |
| Advertising ID | No |
| Target audience | 13–15, 16–17, 18 and over |
| SMS permission | Anti-SMS phishing, `RECEIVE_SMS`; saved in the previous operation, no review submission |
| Content rating | All other app types (utility); all nine content/functionality questions answered No |

IARC calculated **Everyone (ESRB)**, **PEGI 3**, **All ages (Brazil/USK)** and **3+ (generic/Russia/South Korea)**. The Console shows IARC status **Completed**. Completing the IARC questionnaire is distinct from sending the app or SMS request for Google review. The target audience remains 13+; a content rating does not change that product choice.

The nine IARC answers concern packaged ratings-relevant content, native interaction between users, an online content catalogue, promotion of age-restricted goods, sharing precise location with other users, digital purchases, cash/crypto/NFT rewards, browser/search functionality, and being primarily a news/educational product. Qorğan receives SMS for local analysis but is not a messaging client, and the technical host-list download is not a content catalogue.

## Data safety

The following answers were saved, with the Console confirmation **“Change saved. Send for review in Publishing overview.”**

| Question | Saved answer |
| --- | --- |
| Collects or shares required data types | Yes |
| Encrypted in transit | Yes — the automatic app-controlled network request uses HTTPS |
| Account creation | My app does not allow users to create an account |
| Login with externally created accounts | No |
| User data deletion request mechanism | No — no promise to delete the provider's server logs through Qorğan |
| Declared data type | Device or other IDs, for network IP in the public blocklist request |
| Collected / shared | Both |
| Ephemeral | No |
| Optional / required | Required; there is no in-app switch for foreground list downloads |
| Collection purposes | App functionality; Fraud prevention, security and compliance |
| Sharing purposes | App functionality; Fraud prevention, security and compliance |
| Other data types | None selected on the inspected implementation |
| Independent security review / UPI badge | Not claimed |

The identifier classification is a conservative mapping of the IP flow, not a claim that the app sends an advertising ID, IMEI or another app-added device identifier. SMS bodies/senders, local history, verdicts and feedback are not automatically uploaded. The correction report is copied only after an explicit action; external sharing is a separate user action. There is no in-app email submission or support-upload endpoint.

The deletion answer concerns the declared off-device flow. Local history clearing and uninstall remain available. The published privacy policy also gives a contact for voluntarily emailed support data, but that does not establish control over GitLab's access logs. No global automatic-deletion badge is claimed merely from the provider's seven-day Pages retention statement.

Sources rechecked on 7 November 2026: [Google Data safety definitions and IP FAQ](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en), [GitLab Privacy Statement](https://about.gitlab.com/privacy/). GitLab describes seven-day Pages logs and fraud/abuse-prevention purposes. The broader provider policy is not an infrastructure audit; reassess classification and location use if the endpoint or implementation changes. See [the evidence worksheet](data-safety.md).

## Store settings and listing

- App category: **Tools**; type: **App**; tag: **Privacy & security**.
- Support email: **omirtayazamatt@gmail.com**.
- Website: **https://qorgan-web.vercel.app/**.
- Phone number: not supplied, left blank. No unrelated account/trader-status settings changed.
- Default language: **Russian (ru-RU)**.
- App name: **Qorğan**.
- Short description: **Предупреждения о фишинге в SMS. Проверка на вашем телефоне.** (59 characters).
- Full description: Russian text in [store-listing.md](store-listing.md), 1,717 characters, covering manual/background checks, local history, permissions, IP flow and assessment limitations.
- Uploaded icon: **`assets/store-icon-black.png`**, 512×512, opaque black background. The owner explicitly requested this replacement after viewing the original white icon. The earlier white icon was removed from the listing assignment (not deleted from the asset library).
- Uploaded feature graphic: `assets/feature-graphic.png`, 1024×500.
- Four phone screenshots uploaded: `assets/phone-manual.png`, `assets/phone-welcome.png`, `assets/phone-home.png`, and `assets/phone-setup.png`, each 1080×1920 (9:16). These render the real Flutter screens in a widget test with empty history and permissions not granted; they are not evidence of an Android device test.
- The complete listing was saved from its Review step. Store listings now shows **“Ready to send for review”**. Publishing overview lists the Russian default listing with **“Provided app name (Qorğan), and all other required information”** under **“Changes not yet submitted for review”**. No Send action was performed.
- No promotional video supplied.

Observed App content status after saving the forms: **“You've caught up with everything.”** This means the forms are completed, not approved by Google. Release rollout, actual phone validation, SMS approval and production access remain outstanding.

The refreshed release preview reports **one error** (no countries/regions selected) and **one warning** (no testers specified). The earlier app-setup and full-description errors are gone. Countries and testers were not chosen as part of this store-listing task.

No commits or pushes.
