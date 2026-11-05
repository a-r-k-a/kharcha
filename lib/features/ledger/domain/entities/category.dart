import 'package:equatable/equatable.dart';

enum CategoryKind { expense, income }

/// Domain-level icon choice. Presentation maps each value to a glyph, so the
/// domain stays free of Flutter.
enum CategoryGlyph {
  food,
  groceries,
  delivery,
  coffee,
  transport,
  fuel,
  cab,
  transit,
  housing,
  maintenance,
  utilities,
  internet,
  water,
  shopping,
  clothing,
  electronics,
  health,
  medicine,
  doctor,
  fitness,
  entertainment,
  subscriptions,
  games,
  education,
  books,
  financial,
  insurance,
  savings,
  personal,
  grooming,
  travel,
  pets,
  gift,
  heart,
  salary,
  freelance,
  business,
  interest,
  dividends,
  refund,
  sparkle,
  other,
}

/// Domain-level color choice: one of the eight categorical slots, or
/// [neutral]. Presentation maps slots to validated colors per theme.
enum CategoryTone {
  blue,
  orange,
  aqua,
  yellow,
  magenta,
  green,
  violet,
  red,
  neutral,
}

/// A transaction category. Top-level categories have no [parentId];
/// subcategories point at their parent and share its [kind].
final class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.kind,
    required this.glyph,
    required this.tone,
    this.parentId,
    this.isCustom = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final CategoryKind kind;
  final String? parentId;
  final CategoryGlyph glyph;
  final CategoryTone tone;

  /// Built-in categories can be restyled but not renamed or deleted.
  final bool isCustom;
  final int sortOrder;

  bool get isTopLevel => parentId == null;

  Category copyWith({
    String? name,
    CategoryGlyph? glyph,
    CategoryTone? tone,
    int? sortOrder,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      kind: kind,
      parentId: parentId,
      glyph: glyph ?? this.glyph,
      tone: tone ?? this.tone,
      isCustom: isCustom,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    kind,
    parentId,
    glyph,
    tone,
    isCustom,
    sortOrder,
  ];
}
