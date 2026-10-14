import 'package:flutter/material.dart';

import 'colors.dart';

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: QorganColors.surface,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: QorganColors.ink.withValues(alpha: .025),
          blurRadius: 18,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

class RoundAction extends StatelessWidget {
  const RoundAction({
    required this.child,
    required this.label,
    required this.onTap,
    super.key,
  });
  final Widget child;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onTap,
    icon: child,
    style: IconButton.styleFrom(
      backgroundColor: QorganColors.surface,
      foregroundColor: QorganColors.muted,
      fixedSize: const Size(44, 44),
      padding: EdgeInsets.zero,
    ),
  );
}

class FourDots extends StatelessWidget {
  const FourDots({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 17,
    height: 17,
    child: Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(
        4,
        (_) => Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: QorganColors.muted,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  );
}

class SmsHeader extends StatelessWidget {
  const SmsHeader({
    required this.onBack,
    required this.onMenu,
    required this.onProfile,
    super.key,
  });
  final VoidCallback onBack;
  final VoidCallback onMenu;
  final VoidCallback onProfile;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
    child: Row(
      children: [
        RoundAction(
          label: 'Назад',
          onTap: onBack,
          child: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
        const Spacer(),
        RoundAction(label: 'Меню', onTap: onMenu, child: const FourDots()),
        const SizedBox(width: 10),
        RoundAction(
          label: 'Настройки защиты',
          onTap: onProfile,
          child: const Icon(Icons.person_outline_rounded, size: 21),
        ),
      ],
    ),
  );
}

class SenderAvatar extends StatelessWidget {
  const SenderAvatar({required this.name, this.size = 36, super.key});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) {
    final words = name.split(' ').where((word) => word.isNotEmpty).toList();
    final initials = words.take(2).map((word) => word[0]).join().toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: QorganColors.canvas,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? 'Q' : initials,
        style: TextStyle(
          fontSize: size / 3,
          fontWeight: FontWeight.w600,
          color: QorganColors.muted,
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.suspicious,
    this.label,
    this.check = false,
    this.compact = false,
    super.key,
  });
  final bool suspicious;
  final String? label;
  final bool check;
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 10 : 12,
      vertical: compact ? 6 : 8,
    ),
    decoration: BoxDecoration(
      color: suspicious ? QorganColors.mint : QorganColors.pale,
      borderRadius: BorderRadius.circular(40),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (check) ...[
          const Icon(Icons.check_rounded, size: 12, color: QorganColors.muted),
          const SizedBox(width: 4),
        ],
        Text(
          label ?? (suspicious ? 'Подозрительно' : 'Можно пропустить'),
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            color: suspicious ? QorganColors.mintInk : QorganColors.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class MintDot extends StatelessWidget {
  const MintDot({this.size = 6, super.key});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: QorganColors.mint,
      shape: BoxShape.circle,
    ),
  );
}

class CardHeading extends StatelessWidget {
  const CardHeading({required this.title, this.trailing, super.key});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(title, style: Theme.of(context).textTheme.titleSmall),
      const Spacer(),
      ?trailing,
    ],
  );
}

class PhonePage extends StatelessWidget {
  const PhonePage({
    required this.header,
    required this.children,
    this.bottom,
    super.key,
  });
  final SmsHeader header;
  final List<Widget> children;
  final Widget? bottom;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: QorganColors.canvas,
    body: SafeArea(
      child: Column(
        children: [
          header,
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: children,
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: bottom,
  );
}

class QorganBottomBar extends StatelessWidget {
  const QorganBottomBar({required this.onSms, super.key});
  final VoidCallback onSms;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: QorganColors.surface,
      border: Border(top: BorderSide(color: QorganColors.line)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: QorganColors.mint.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 21,
                      color: QorganColors.mintInk,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Защита',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: QorganColors.mintInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: InkWell(
                onTap: onSms,
                borderRadius: BorderRadius.circular(40),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sms_outlined,
                        size: 21,
                        color: QorganColors.muted,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'SMS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: QorganColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
