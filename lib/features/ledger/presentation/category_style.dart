import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../domain/entities/account.dart';
import '../domain/entities/category.dart';

/// Visual mapping for domain category glyphs and tones.
///
/// Tone colors are the eight-slot categorical palette from the dataviz
/// reference, stepped separately for each mode. Color is never the only
/// identity cue: every use pairs it with the category's icon and name.
extension CategoryGlyphIcon on CategoryGlyph {
  IconData get icon => switch (this) {
    CategoryGlyph.food => AppIcons.food,
    CategoryGlyph.groceries => AppIcons.groceries,
    CategoryGlyph.delivery => AppIcons.delivery,
    CategoryGlyph.coffee => AppIcons.coffee,
    CategoryGlyph.transport => AppIcons.transport,
    CategoryGlyph.fuel => AppIcons.fuel,
    CategoryGlyph.cab => AppIcons.cab,
    CategoryGlyph.transit => AppIcons.transit,
    CategoryGlyph.housing => AppIcons.housing,
    CategoryGlyph.maintenance => AppIcons.maintenance,
    CategoryGlyph.utilities => AppIcons.utilities,
    CategoryGlyph.internet => AppIcons.internet,
    CategoryGlyph.water => AppIcons.water,
    CategoryGlyph.shopping => AppIcons.shopping,
    CategoryGlyph.clothing => AppIcons.clothing,
    CategoryGlyph.electronics => AppIcons.electronics,
    CategoryGlyph.health => AppIcons.health,
    CategoryGlyph.medicine => AppIcons.medicine,
    CategoryGlyph.doctor => AppIcons.doctor,
    CategoryGlyph.fitness => AppIcons.fitness,
    CategoryGlyph.entertainment => AppIcons.entertainment,
    CategoryGlyph.subscriptions => AppIcons.subscriptions,
    CategoryGlyph.games => AppIcons.games,
    CategoryGlyph.education => AppIcons.education,
    CategoryGlyph.books => AppIcons.books,
    CategoryGlyph.financial => AppIcons.bank,
    CategoryGlyph.insurance => AppIcons.insurance,
    CategoryGlyph.savings => AppIcons.savings,
    CategoryGlyph.personal => AppIcons.personal,
    CategoryGlyph.grooming => AppIcons.grooming,
    CategoryGlyph.travel => AppIcons.travel,
    CategoryGlyph.pets => AppIcons.pets,
    CategoryGlyph.gift => AppIcons.gift,
    CategoryGlyph.heart => AppIcons.heart,
    CategoryGlyph.salary => AppIcons.salary,
    CategoryGlyph.freelance => AppIcons.freelance,
    CategoryGlyph.business => AppIcons.business,
    CategoryGlyph.interest => AppIcons.interest,
    CategoryGlyph.dividends => AppIcons.dividends,
    CategoryGlyph.refund => AppIcons.reimbursable,
    CategoryGlyph.sparkle => AppIcons.sparkle,
    CategoryGlyph.other => AppIcons.other,
  };
}

extension CategoryToneColor on CategoryTone {
  Color colorFrom(AppColors colors) {
    final dark = colors.isDark;
    return switch (this) {
      CategoryTone.blue =>
        dark ? const Color(0xFF3987E5) : const Color(0xFF2A78D6),
      CategoryTone.orange =>
        dark ? const Color(0xFFD95926) : const Color(0xFFEB6834),
      CategoryTone.aqua =>
        dark ? const Color(0xFF199E70) : const Color(0xFF1BAF7A),
      CategoryTone.yellow =>
        dark ? const Color(0xFFC98500) : const Color(0xFFEDA100),
      CategoryTone.magenta =>
        dark ? const Color(0xFFD55181) : const Color(0xFFE87BA4),
      CategoryTone.green => const Color(0xFF008300),
      CategoryTone.violet =>
        dark ? const Color(0xFF9085E9) : const Color(0xFF6250D6),
      CategoryTone.red =>
        dark ? const Color(0xFFE66767) : const Color(0xFFE34948),
      CategoryTone.neutral => colors.textTertiary,
    };
  }

  String get label => switch (this) {
    CategoryTone.blue => 'Blue',
    CategoryTone.orange => 'Orange',
    CategoryTone.aqua => 'Aqua',
    CategoryTone.yellow => 'Yellow',
    CategoryTone.magenta => 'Magenta',
    CategoryTone.green => 'Green',
    CategoryTone.violet => 'Violet',
    CategoryTone.red => 'Red',
    CategoryTone.neutral => 'Grey',
  };
}

extension AccountTypeIcon on AccountType {
  IconData get icon => switch (this) {
    AccountType.savings || AccountType.current => AppIcons.bank,
    AccountType.cash => AppIcons.cash,
    AccountType.digitalWallet => AppIcons.wallet,
    AccountType.creditCard => AppIcons.creditCard,
    AccountType.fixedDeposit ||
    AccountType.recurringDeposit => AppIcons.deposit,
    AccountType.investment => AppIcons.investment,
    AccountType.loan => AppIcons.loan,
  };
}
