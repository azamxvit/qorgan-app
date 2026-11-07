import 'package:flutter/material.dart';

import '../../domain/models/message_verdict.dart';
import 'colors.dart';
import '../launch/brand_mark.dart';
import '../messages/message_presentation.dart';

export 'qorgan_bottom_bar.dart';

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
      fixedSize: const Size(48, 48),
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
    this.root = false,
    super.key,
  });
  final VoidCallback onBack;
  final VoidCallback onMenu;
  final VoidCallback onProfile;
  final bool root;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
    child: Row(
      children: [
        if (!root) ...[
          RoundAction(
            label: 'Назад',
            onTap: onBack,
            child: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 12),
        ] else ...[
          const BrandMark(size: 28),
          const SizedBox(width: 10),
        ],
        const Expanded(
          child: Text(
            'Qorğan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -.6,
            ),
          ),
        ),
        if (root)
          RoundAction(
            label: 'Настройки',
            onTap: onProfile,
            child: const Icon(Icons.settings_outlined),
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
    required this.risk,
    this.label,
    this.check = false,
    this.compact = false,
    super.key,
  });
  final MessageRisk risk;
  final String? label;
  final bool check;
  final bool compact;

  Color get _fill => switch (risk) {
    MessageRisk.warn => QorganColors.dark,
    MessageRisk.watch => QorganColors.backdrop,
    MessageRisk.clear => QorganColors.pale,
  };

  Color get _ink => switch (risk) {
    MessageRisk.warn => QorganColors.surface,
    MessageRisk.clear => QorganColors.ink,
    MessageRisk.watch => QorganColors.mintInk,
  };

  String get _label => riskLabel(risk);

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 10 : 12,
      vertical: compact ? 6 : 8,
    ),
    decoration: BoxDecoration(
      color: _fill,
      borderRadius: BorderRadius.circular(40),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          switch (risk) {
            MessageRisk.clear => Icons.check_rounded,
            MessageRisk.watch => Icons.info_outline_rounded,
            MessageRisk.warn => Icons.warning_amber_rounded,
          },
          size: 16,
          color: _ink,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label ?? _label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              color: _ink,
              fontWeight: FontWeight.w500,
            ),
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
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
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
