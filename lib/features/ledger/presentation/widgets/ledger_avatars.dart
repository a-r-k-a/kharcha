import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/theme_context.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/category.dart';
import '../category_style.dart';

/// Square tile tinted with a category's tone. The glyph stays in ink so it
/// meets contrast on every tone; the tint carries identity, not meaning.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, required this.category, this.size = 40});

  /// Null renders the "everything else" / unknown tile.
  final Category? category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final category = this.category;
    return ToneTile(
      icon: category?.glyph.icon ?? AppIcons.other,
      tone:
          category?.tone.colorFrom(context.colors) ??
          context.colors.textTertiary,
      size: size,
    );
  }
}

class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key, required this.type, this.size = 40});

  final AccountType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: context.radii.card,
        border: Border.all(
          color: colors.line,
          width: context.elevation.hairline,
        ),
      ),
      child: Icon(type.icon, size: size * 0.5, color: colors.textPrimary),
    );
  }
}

/// Icon on a tinted square with a solid tone edge at the bottom.
class ToneTile extends StatelessWidget {
  const ToneTile({
    super.key,
    required this.icon,
    required this.tone,
    this.size = 40,
  });

  final IconData icon;
  final Color tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = Color.alphaBlend(
      tone.withValues(alpha: colors.isDark ? 0.22 : 0.16),
      colors.surface,
    );
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: context.radii.card,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: tint,
            border: Border(bottom: BorderSide(color: tone, width: 3)),
          ),
          child: Icon(icon, size: size * 0.5, color: colors.textPrimary),
        ),
      ),
    );
  }
}
