import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// ─── Primary button with loading state ─────────────────────────────
class OwlButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool outlined;
  final Color? color;
  final double? width;

  const OwlButton({
    super.key,
    required this.label,
    this.loading = false,
    this.onTap,
    this.icon,
    this.outlined = false,
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? AppColors.primary;

    if (outlined) {
      return SizedBox(
        width: width ?? double.infinity,
        child: OutlinedButton.icon(
          onPressed: loading ? null : onTap,
          icon: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
          label: Text(label),
          style: OutlinedButton.styleFrom(foregroundColor: bgColor, side: BorderSide(color: bgColor), padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(backgroundColor: bgColor, padding: const EdgeInsets.symmetric(vertical: 16)),
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[Icon(icon, size: 18, color: Colors.white), const SizedBox(width: 8)],
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ]),
      ),
    );
  }
}

// ─── Stat card for platform stats ──────────────────────────────────
class PlatformStatCard extends StatelessWidget {
  final String platform;
  final int totalSolved;
  final int easySolved;
  final int mediumSolved;
  final int hardSolved;
  final int rating;
  final int contestCount;
  final Color platformColor;
  final String platformEmoji;
  final VoidCallback? onTap;

  const PlatformStatCard({
    super.key,
    required this.platform,
    required this.totalSolved,
    required this.easySolved,
    required this.mediumSolved,
    required this.hardSolved,
    required this.rating,
    required this.contestCount,
    required this.platformColor,
    required this.platformEmoji,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: platformColor.withValues(alpha: 0.2)),
          boxShadow: AppShadow.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: platformColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(platformEmoji, style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(platform, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text('Solved: $totalSolved', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.darkTextSecondary)),
              ]),
              const Spacer(),
              if (rating > 0) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: platformColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadius.round)),
                child: Text('⭐ $rating', style: TextStyle(color: platformColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _DiffBadge('Easy', easySolved, AppColors.easy),
              const SizedBox(width: 8),
              _DiffBadge('Med', mediumSolved, AppColors.medium),
              const SizedBox(width: 8),
              _DiffBadge('Hard', hardSolved, AppColors.hard),
              const Spacer(),
              if (contestCount > 0) Text('🏁 $contestCount contests', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.darkTextSecondary)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.round),
              child: LinearProgressIndicator(
                value: totalSolved / 500,
                minHeight: 4,
                backgroundColor: platformColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(platformColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiffBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _DiffBadge(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.round)),
      child: Text('$label: $count', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Difficulty chip ────────────────────────────────────────────────
class DifficultyChip extends StatelessWidget {
  final String difficulty;
  const DifficultyChip(this.difficulty, {super.key});

  Color get _color => difficulty == 'easy' ? AppColors.easy : difficulty == 'medium' ? AppColors.medium : AppColors.hard;
  String get _label => difficulty[0].toUpperCase() + difficulty.substring(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: _color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadius.round)),
      child: Text(_label, style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Section header ────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const SectionHeader({super.key, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          if (subtitle != null) Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.darkTextSecondary)),
        ])),
        if (action != null) action!,
      ]),
    );
  }
}

// ─── Problem card ──────────────────────────────────────────────────
class ProblemCard extends StatelessWidget {
  final String name;
  final String topic;
  final String platform;
  final String difficulty;
  final int? timeTaken;
  final int? confidence;
  final bool? bookmarked;
  final String? link;
  final VoidCallback? onOpenLink;
  final VoidCallback? onRevise;
  final VoidCallback? onDelete;

  const ProblemCard({
    super.key,
    required this.name,
    required this.topic,
    required this.platform,
    required this.difficulty,
    this.timeTaken,
    this.confidence,
    this.bookmarked,
    this.link,
    this.onOpenLink,
    this.onRevise,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
          DifficultyChip(difficulty),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.category_outlined, size: 13, color: AppColors.darkTextSecondary),
          const SizedBox(width: 4),
          Text(topic, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.darkTextSecondary)),
          const SizedBox(width: 12),
          const Icon(Icons.computer, size: 13, color: AppColors.darkTextSecondary),
          const SizedBox(width: 4),
          Text(platform, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.darkTextSecondary)),
          if (timeTaken != null && timeTaken! > 0) ...[
            const SizedBox(width: 12),
            const Icon(Icons.timer_outlined, size: 13, color: AppColors.darkTextSecondary),
            const SizedBox(width: 4),
            Text('${timeTaken}m', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.darkTextSecondary)),
          ],
        ]),
        if (confidence != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            ...List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < confidence! ? AppColors.warning : AppColors.darkBorder)),
            const SizedBox(width: 8),
            Text('Confidence', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.darkTextSecondary)),
          ]),
        ],
        const SizedBox(height: 8),
        Row(children: [
          if (link != null && link!.isNotEmpty)
            _ActionBtn('Open', Icons.open_in_new, AppColors.accent, onOpenLink),
          if (onRevise != null) ...[const SizedBox(width: 8), _ActionBtn('Revise', Icons.refresh, AppColors.warning, onRevise)],
          const Spacer(),
          if (bookmarked == true)
            const Icon(Icons.bookmark, color: AppColors.primary, size: 16),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 16), color: AppColors.danger, constraints: const BoxConstraints(), padding: EdgeInsets.zero),
          ],
        ]),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _ActionBtn(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.round)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ─── XP + Level badge ──────────────────────────────────────────────
class XpLevelBadge extends StatelessWidget {
  final int xp;
  final int level;
  const XpLevelBadge({super.key, required this.xp, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.round),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('⭐', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text('Lv.$level  •  $xp XP', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─── Streak badge ──────────────────────────────────────────────────
class StreakBadge extends StatelessWidget {
  final int streak;
  const StreakBadge({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.round),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('🔥', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text('$streak days', style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
