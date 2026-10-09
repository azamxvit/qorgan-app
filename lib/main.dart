import 'package:flutter/material.dart';

void main() {
  runApp(const QorganApp());
}

class QorganApp extends StatelessWidget {
  const QorganApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qorğan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF3EFE6),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E6B52)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const BackgroundPage(),
      const MessagePage(),
      const AnalyzePage(),
    ];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Qorğan', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Фон, проверка сообщений и дипфейк в одном приложении.',
              style: TextStyle(color: Color(0xFF5C675F), fontSize: 16, height: 1.35),
            ),
            const SizedBox(height: 18),
            pages[tab],
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.shield_outlined), label: 'Фон'),
          NavigationDestination(icon: Icon(Icons.sms_outlined), label: 'Текст'),
          NavigationDestination(icon: Icon(Icons.face_retouching_natural), label: 'AI Analyze'),
        ],
      ),
    );
  }
}

class BackgroundPage extends StatefulWidget {
  const BackgroundPage({super.key});

  @override
  State<BackgroundPage> createState() => _BackgroundPageState();
}

class _BackgroundPageState extends State<BackgroundPage> {
  bool armed = true;
  bool incoming = false;

  @override
  Widget build(BuildContext context) {
    final blocked = incoming && armed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Фоновое приложение', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Пока защита включена, сообщение со срочностью, кодом или чужой ссылкой уходит в блок само.'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => setState(() => armed = !armed),
          child: Text(armed ? 'Фон включён' : 'Фон выключен'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => setState(() => incoming = true),
          child: const Text('Симулировать входящее'),
        ),
        const SizedBox(height: 12),
        Card(
          color: blocked ? const Color(0xFFF8E8E4) : const Color(0xFFFFFDF8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              !incoming
                  ? 'Фон включён. Ждём сообщение.'
                  : blocked
                      ? 'Заблокировано. Срочность, просьба кода и чужая ссылка.'
                      : 'Пропущено: фон был выключен.',
            ),
          ),
        ),
      ],
    );
  }
}

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final samples = {
    'Фишинг':
        'KASPI: Счёт заблокируют через 15 минут. Срочно подтвердите код: http://kaspi-secure.xyz/login',
    'Обычное': 'Halyk Bank: Поступление 20 000 ₸. Доступно 145 300 ₸.',
  };
  late final TextEditingController controller = TextEditingController(text: samples['Фишинг']);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = analyzeMessage(controller.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Детектор сообщений', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final entry in samples.entries)
              OutlinedButton(
                onPressed: () => setState(() => controller.text = entry.value),
                child: Text(entry.key),
              ),
          ],
        ),
        TextField(
          controller: controller,
          maxLines: 5,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        Card(
          color: result.block ? const Color(0xFFF8E8E4) : const Color(0xFFE5F3EC),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.block ? 'В блок · ${result.score}' : 'Можно пропустить · ${result.score}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                for (final reason in result.reasons) Text(reason),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AnalyzePage extends StatelessWidget {
  const AnalyzePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI Analyze', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        SizedBox(height: 8),
        Text('Модуль научного руководителя. Два опубликованных сервиса: синтетическая личность и проверка документов.'),
        SizedBox(height: 12),
        Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text('Модель ещё не подключена к приложению. Вердикт по видео и голосу не показываем, чтобы не выдавать ложный результат.'),
          ),
        ),
      ],
    );
  }
}

class Analysis {
  const Analysis(this.block, this.score, this.reasons);
  final bool block;
  final int score;
  final List<String> reasons;
}

Analysis analyzeMessage(String raw) {
  final text = raw.toLowerCase();
  final reasons = <String>[];
  var score = 0;
  bool has(List<String> words) => words.any(text.contains);
  if (has(['kaspi', 'каспи', 'halyk', 'халык', 'банк', 'bank'])) {
    score += 1;
    reasons.add('Есть название банка.');
  }
  if (has(['срочно', 'шұғыл', 'минут', 'жедел'])) {
    score += 2;
    reasons.add('Есть срочность.');
  }
  if (has(['заблок', 'бұғат', 'штраф'])) {
    score += 2;
    reasons.add('Есть давление.');
  }
  if (has(['код', 'пароль', 'растау', 'подтверд'])) {
    score += 3;
    reasons.add('Просят код или пароль.');
  }
  if (text.contains('http') && !text.contains('kaspi.kz') && !text.contains('halykbank.kz')) {
    score += 3;
    reasons.add('Ссылка не на официальный сайт банка.');
  }
  if (reasons.isEmpty) reasons.add('Признаков социальной инженерии нет.');
  return Analysis(score >= 4, score, reasons);
}
