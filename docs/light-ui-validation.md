# Qorğan light UI validation — 2026-10-14

Four working Flutter screens share the same Manrope theme and reusable components. The 390×844 four-screen preview uses those exact widgets with synthetic messages; no demo messages or fake counts enter the Android history.

Validation: 29 Flutter tests pass; flutter analyze reports no issues.

Verified: dashboard → SMS detail → signal breakdown; all/ordinary filter behavior; SQLite history order and deduplication; incoming SMS during a pending refresh; 320×640 layout with 2× text scaling; long sender wrapping; four-frame render without overflow. Source rule and native receiver are preserved. Settings, permission activation and licenses remain reachable through the avatar; manual checks through the grid menu or message list.

Preview image: ../artifacts/qorgan-light-preview.png. Local browser preview: http://127.0.0.1:8788/. Run using flutter run -d web-server --web-port 8788 --dart-define=QORGAN_PREVIEW=true.

A first light-theme release APK compiled successfully. Its later rebuild request was rejected, so no APK of the final reviewed source is being delivered in this UI update. The previously delivered APK is the earlier build; final UI code and preview are the deliverables for this turn.

Design adaptation: score 7 comes from real bank/code/unofficial-link weights (1+3+3). Code is shown as an additional contribution rather than dropping it from the total. The 4×4 grid shows none plus three contribution levels; it adds no probability or GRC calculation. Review status appears for non-blocking messages with score 2–3, without changing the classifier threshold.
