import 'entities/category.dart';

/// Built-in categories, seeded the first time a user's books are opened.
///
/// Ids are persisted and referenced by transactions: never change one.
abstract final class DefaultCategories {
  static const otherExpenseId = 'other';
  static const otherIncomeId = 'income.other';
  static const refundsId = 'income.refunds';

  /// Where allocations go when their category is deleted and it has no
  /// parent to fall back to.
  static String fallbackFor(CategoryKind kind) =>
      kind == CategoryKind.expense ? otherExpenseId : otherIncomeId;

  static List<Category> build() {
    final categories = <Category>[];
    var order = 0;

    void add(
      String id,
      String name,
      CategoryKind kind,
      CategoryGlyph glyph,
      CategoryTone tone, [
      List<(String, String, CategoryGlyph)> children = const [],
    ]) {
      categories.add(
        Category(
          id: id,
          name: name,
          kind: kind,
          glyph: glyph,
          tone: tone,
          sortOrder: order++,
        ),
      );
      for (final (childId, childName, childGlyph) in children) {
        categories.add(
          Category(
            id: '$id.$childId',
            name: childName,
            kind: kind,
            parentId: id,
            glyph: childGlyph,
            tone: tone,
            sortOrder: order++,
          ),
        );
      }
    }

    const expense = CategoryKind.expense;
    add('food', 'Food', expense, CategoryGlyph.food, CategoryTone.blue, [
      ('groceries', 'Groceries', CategoryGlyph.groceries),
      ('restaurants', 'Restaurants', CategoryGlyph.food),
      ('delivery', 'Delivery', CategoryGlyph.delivery),
    ]);
    add(
      'transport',
      'Transportation',
      expense,
      CategoryGlyph.transport,
      CategoryTone.orange,
      [
        ('fuel', 'Fuel', CategoryGlyph.fuel),
        ('cab', 'Cab', CategoryGlyph.cab),
        ('public', 'Public transport', CategoryGlyph.transit),
      ],
    );
    add(
      'housing',
      'Housing',
      expense,
      CategoryGlyph.housing,
      CategoryTone.aqua,
      [
        ('rent', 'Rent', CategoryGlyph.housing),
        ('maintenance', 'Maintenance', CategoryGlyph.maintenance),
        ('electricity', 'Electricity', CategoryGlyph.utilities),
      ],
    );
    add(
      'shopping',
      'Shopping',
      expense,
      CategoryGlyph.shopping,
      CategoryTone.yellow,
      [
        ('clothing', 'Clothing', CategoryGlyph.clothing),
        ('electronics', 'Electronics', CategoryGlyph.electronics),
      ],
    );
    add(
      'health',
      'Healthcare',
      expense,
      CategoryGlyph.health,
      CategoryTone.magenta,
      [
        ('medicines', 'Medicines', CategoryGlyph.medicine),
        ('doctor', 'Doctor', CategoryGlyph.doctor),
      ],
    );
    add(
      'entertainment',
      'Entertainment',
      expense,
      CategoryGlyph.entertainment,
      CategoryTone.violet,
      [
        ('movies', 'Movies', CategoryGlyph.entertainment),
        ('subscriptions', 'Subscriptions', CategoryGlyph.subscriptions),
      ],
    );
    add(
      'education',
      'Education',
      expense,
      CategoryGlyph.education,
      CategoryTone.neutral,
      [
        ('courses', 'Courses', CategoryGlyph.education),
        ('books', 'Books', CategoryGlyph.books),
      ],
    );
    add(
      'financial',
      'Financial',
      expense,
      CategoryGlyph.financial,
      CategoryTone.red,
      [
        ('emi', 'EMI', CategoryGlyph.financial),
        ('insurance', 'Insurance', CategoryGlyph.insurance),
        ('investments', 'Investments', CategoryGlyph.savings),
      ],
    );
    add(
      'personal',
      'Personal',
      expense,
      CategoryGlyph.personal,
      CategoryTone.green,
      [
        ('grooming', 'Grooming', CategoryGlyph.grooming),
        ('travel', 'Travel', CategoryGlyph.travel),
      ],
    );
    add(
      otherExpenseId,
      'Other',
      expense,
      CategoryGlyph.other,
      CategoryTone.neutral,
    );

    const income = CategoryKind.income;
    add(
      'income.salary',
      'Salary',
      income,
      CategoryGlyph.salary,
      CategoryTone.blue,
    );
    add(
      'income.freelance',
      'Freelance',
      income,
      CategoryGlyph.freelance,
      CategoryTone.orange,
    );
    add(
      'income.business',
      'Business',
      income,
      CategoryGlyph.business,
      CategoryTone.aqua,
    );
    add(
      'income.interest',
      'Interest',
      income,
      CategoryGlyph.interest,
      CategoryTone.yellow,
    );
    add(
      'income.dividends',
      'Dividends',
      income,
      CategoryGlyph.dividends,
      CategoryTone.magenta,
    );
    add(
      refundsId,
      'Refunds & reimbursements',
      income,
      CategoryGlyph.refund,
      CategoryTone.green,
    );
    add(
      'income.gifts',
      'Gifts',
      income,
      CategoryGlyph.gift,
      CategoryTone.violet,
    );
    add(
      otherIncomeId,
      'Other income',
      income,
      CategoryGlyph.other,
      CategoryTone.neutral,
    );
    return categories;
  }
}
