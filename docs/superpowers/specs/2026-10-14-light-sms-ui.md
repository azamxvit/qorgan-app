# Qorğan light SMS UI

User supplied the visual specification and selected working Flutter screens with a four-screen preview. Preserve the SMS receiver, on-device classifier, its five signals/weights and threshold. No fake statistics in the actual app: the dashboard is based on the last 100 locally retained SMS. Synthetic fixtures appear only in the preview and tests.

Implement a light Manrope theme: #F7F8F8 canvas, white cards, #121212 text, #6F6F6F secondary text, #E6E6E6 separators, #3AD99A/#5EE0A4 accent, #062117 mint ink and #2A2A2A secondary surface. Requested #F1F1F1 safe-status fill and #E7F8F1 preview background are treated as explicit exceptions to the supplied palette.

Four app screens: protection dashboard; SMS details; score/signals; filterable SMS list. Only dashboard has the two-item navigation. SMS tab opens the list; manual text check is reachable from the list and grid menu. Shared header: back, four-dot grid menu, local profile/settings avatar. Protection permissions/switch/license screen moves to settings; home has only a compact true status, no permission essay. Preserve enabling protection discoverability through that compact status.

Scores are real. The preview score 7 uses bank + code + unofficial link (1+3+3). Detail metrics and contribution rows include a fifth Code row when that signal exists. This keeps visible contributions consistent with the total without altering the rule.

The requested 4×4 matrix has four signal rows and four state columns: none plus three contribution levels, with three level captions. It is a compact signal contribution map, not a probability/GRC risk matrix. A code signal adds a separate contribution row above it. Score appears only in one selected tile; it is a visual summary, not an additional calculation.

Work sequence: behavioral tests for history/filter/navigation; SQLite recent query and service API; reusable light components, four screens/settings/manual check; preview entry point showing those same widgets at 390×844 in four rounded frames on white→#E7F8F1; widget image capture, visual review, analyzer/tests, APK and smoke check. Existing edits stay intact; work is inline in the current checkout.
