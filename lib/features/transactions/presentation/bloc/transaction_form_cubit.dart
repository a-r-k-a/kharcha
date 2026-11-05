import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/clock.dart';
import '../../../../core/domain/failure.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/domain/result.dart';
import '../../../ledger/domain/entities/account.dart';
import '../../../ledger/domain/entities/category.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../../ledger/domain/entities/transaction.dart';
import '../../../ledger/domain/ledger_violation.dart';
import '../../../ledger/domain/repositories/ledger_repositories.dart';
import '../../../ledger/domain/services/ledger_validator.dart';
import '../../../ledger/domain/usecases/drafts.dart';
import '../../../ledger/domain/usecases/transaction_usecases.dart';
import '../../../ledger/presentation/ledger_labels.dart';

/// Why the form was opened.
sealed class TransactionFormIntent extends Equatable {
  const TransactionFormIntent();

  @override
  List<Object?> get props => [];
}

final class NewTransaction extends TransactionFormIntent {
  const NewTransaction({this.type = TransactionType.expense, this.accountId});

  final TransactionType type;

  /// Preselected account, e.g. when adding from an account's page.
  final String? accountId;

  @override
  List<Object?> get props => [type, accountId];
}

final class EditTransaction extends TransactionFormIntent {
  const EditTransaction(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class DuplicateTransaction extends TransactionFormIntent {
  const DuplicateTransaction(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

enum TransactionFormStatus {
  editing,
  saving,
  saved,

  /// The transaction to edit or copy doesn't exist.
  notFound,

  /// No books are open.
  unavailable,
}

/// Which field an error belongs to.
enum TransactionField {
  amount,
  account,
  destination,
  category,
  title,
  note,
  tags,
}

final class SplitLine extends Equatable {
  const SplitLine({this.categoryId, this.amountText = ''});

  final String? categoryId;
  final String amountText;

  SplitLine copyWith({String? categoryId, String? amountText}) => SplitLine(
    categoryId: categoryId ?? this.categoryId,
    amountText: amountText ?? this.amountText,
  );

  @override
  List<Object?> get props => [categoryId, amountText];
}

final class TransactionFormState extends Equatable {
  const TransactionFormState({
    required this.status,
    required this.type,
    required this.occurredAt,
    this.ledger,
    this.editingId,
    this.amountText = '',
    this.accountId,
    this.counterpartyAccountId,
    this.categoryId,
    this.isSplit = false,
    this.splits = const [SplitLine(), SplitLine()],
    this.title = '',
    this.note = '',
    this.tags = const [],
    this.paymentMethod,
    this.paymentMethodChosen = false,
    this.isReimbursable = false,
    this.showErrors = false,
    this.violation,
    this.failure,
  });

  final TransactionFormStatus status;
  final Ledger? ledger;
  final String? editingId;
  final TransactionType type;
  final String amountText;
  final String? accountId;
  final String? counterpartyAccountId;
  final String? categoryId;
  final bool isSplit;
  final List<SplitLine> splits;
  final DateTime occurredAt;
  final String title;
  final String note;
  final List<String> tags;
  final PaymentMethod? paymentMethod;

  /// True once the user picked a method; until then it follows the account.
  final bool paymentMethodChosen;
  final bool isReimbursable;

  /// Errors are shown only after the first save attempt.
  final bool showErrors;

  /// The rule the last save attempt broke.
  final LedgerViolation? violation;

  /// A non-validation failure from the last save attempt.
  final Failure? failure;

  bool get isEditing => editingId != null;
  bool get hasCategories =>
      type == TransactionType.expense || type == TransactionType.income;
  CategoryKind get categoryKind => type == TransactionType.income
      ? CategoryKind.income
      : CategoryKind.expense;

  Currency get currency => ledger?.currency ?? Currency.inr;

  Money? get amount => Money.tryParse(amountText, currency: currency);

  Money? amountOfLine(SplitLine line) =>
      Money.tryParse(line.amountText, currency: currency);

  /// Total minus the split lines entered so far; null if the total or any
  /// line can't be read yet.
  Money? get splitRemaining {
    final total = amount;
    if (total == null) return null;
    var remaining = total;
    for (final line in splits) {
      if (line.amountText.trim().isEmpty) continue;
      final value = amountOfLine(line);
      if (value == null) return null;
      remaining -= value;
    }
    return remaining;
  }

  /// Message for [field], once errors are visible.
  String? errorFor(TransactionField field) {
    if (!showErrors) return null;
    if (field == TransactionField.amount) {
      if (amountText.trim().isEmpty) return 'Enter an amount.';
      final value = amount;
      if (value == null) return 'Enter a valid amount, like 1250 or 1250.50.';
    }
    final violation = this.violation;
    if (violation == null || _fieldOf(violation) != field) return null;
    return violation.message;
  }

  /// A violation that isn't tied to a single field, or a failure.
  String? get generalError {
    final failure = this.failure;
    if (failure != null) return failureMessage(failure);
    final violation = this.violation;
    if (showErrors && violation != null && _fieldOf(violation) == null) {
      return violation.message;
    }
    return null;
  }

  static TransactionField? _fieldOf(LedgerViolation violation) =>
      switch (violation) {
        LedgerViolation.amountNotPositive ||
        LedgerViolation.amountZero => TransactionField.amount,
        LedgerViolation.accountMissing ||
        LedgerViolation.accountArchived => TransactionField.account,
        LedgerViolation.transferNeedsDestination ||
        LedgerViolation.transferSameAccount => TransactionField.destination,
        LedgerViolation.categoryMissing ||
        LedgerViolation.categoryKindMismatch ||
        LedgerViolation.splitDoesNotAddUp ||
        LedgerViolation.splitDuplicateCategory ||
        LedgerViolation.splitAmountNotPositive => TransactionField.category,
        LedgerViolation.titleTooLong => TransactionField.title,
        LedgerViolation.noteTooLong => TransactionField.note,
        LedgerViolation.tooManyTags ||
        LedgerViolation.tagTooLong => TransactionField.tags,
        _ => null,
      };

  TransactionFormState copyWith({
    TransactionFormStatus? status,
    Ledger? ledger,
    TransactionType? type,
    String? amountText,
    String? Function()? accountId,
    String? Function()? counterpartyAccountId,
    String? Function()? categoryId,
    bool? isSplit,
    List<SplitLine>? splits,
    DateTime? occurredAt,
    String? title,
    String? note,
    List<String>? tags,
    PaymentMethod? Function()? paymentMethod,
    bool? paymentMethodChosen,
    bool? isReimbursable,
    bool? showErrors,
    LedgerViolation? Function()? violation,
    Failure? Function()? failure,
  }) {
    return TransactionFormState(
      status: status ?? this.status,
      ledger: ledger ?? this.ledger,
      editingId: editingId,
      type: type ?? this.type,
      amountText: amountText ?? this.amountText,
      accountId: accountId != null ? accountId() : this.accountId,
      counterpartyAccountId: counterpartyAccountId != null
          ? counterpartyAccountId()
          : this.counterpartyAccountId,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      isSplit: isSplit ?? this.isSplit,
      splits: splits ?? this.splits,
      occurredAt: occurredAt ?? this.occurredAt,
      title: title ?? this.title,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      paymentMethod: paymentMethod != null
          ? paymentMethod()
          : this.paymentMethod,
      paymentMethodChosen: paymentMethodChosen ?? this.paymentMethodChosen,
      isReimbursable: isReimbursable ?? this.isReimbursable,
      showErrors: showErrors ?? this.showErrors,
      violation: violation != null ? violation() : this.violation,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    ledger,
    editingId,
    type,
    amountText,
    accountId,
    counterpartyAccountId,
    categoryId,
    isSplit,
    splits,
    occurredAt,
    title,
    note,
    tags,
    paymentMethod,
    paymentMethodChosen,
    isReimbursable,
    showErrors,
    violation,
    failure,
  ];
}

/// State for the add / edit / duplicate transaction sheet.
class TransactionFormCubit extends Cubit<TransactionFormState> {
  TransactionFormCubit({
    required LedgerRepository ledger,
    required this._save,
    required Clock clock,
    required TransactionFormIntent intent,
  }) : super(_initialState(ledger.current, clock.now(), intent));

  final SaveTransaction _save;

  static TransactionFormState _initialState(
    Ledger? ledger,
    DateTime now,
    TransactionFormIntent intent,
  ) {
    if (ledger == null) {
      return TransactionFormState(
        status: TransactionFormStatus.unavailable,
        type: TransactionType.expense,
        occurredAt: now,
      );
    }
    switch (intent) {
      case NewTransaction(:final type, :final accountId):
        final active = ledger.activeAccounts;
        final preferred =
            active.where((a) => a.id == accountId).firstOrNull ??
            active
                .where((a) => a.type.group == AccountGroup.liquid)
                .firstOrNull ??
            active.firstOrNull;
        final state = TransactionFormState(
          status: TransactionFormStatus.editing,
          ledger: ledger,
          type: type,
          occurredAt: now,
          accountId: preferred?.id,
          paymentMethod: preferred?.type.defaultPaymentMethod,
        );
        return type == TransactionType.transfer
            ? state.copyWith(
                counterpartyAccountId: () =>
                    _otherAccount(ledger, preferred?.id),
              )
            : state;
      case EditTransaction(:final id) || DuplicateTransaction(:final id):
        final original = ledger.transactionById(id);
        if (original == null) {
          return TransactionFormState(
            status: TransactionFormStatus.notFound,
            ledger: ledger,
            type: TransactionType.expense,
            occurredAt: now,
          );
        }
        final draft = intent is EditTransaction
            ? TransactionDraft.fromTransaction(original)
            : TransactionDraft.duplicateOf(original, now);
        return _fromDraft(ledger, draft);
    }
  }

  static TransactionFormState _fromDraft(Ledger ledger, TransactionDraft d) {
    final currency = ledger.currency;
    String text(Money m) {
      final whole = m.abs().minorUnits ~/ currency.minorPerMajor;
      final fraction = m.abs().minorUnits % currency.minorPerMajor;
      return fraction == 0
          ? '$whole'
          : '$whole.${fraction.toString().padLeft(currency.decimals, '0')}';
    }

    final isSplit = d.allocations.length > 1;
    return TransactionFormState(
      status: TransactionFormStatus.editing,
      ledger: ledger,
      editingId: d.id,
      type: d.type,
      amountText: text(d.amount),
      accountId: d.accountId,
      counterpartyAccountId: d.counterpartyAccountId,
      categoryId: isSplit ? null : d.allocations.firstOrNull?.categoryId,
      isSplit: isSplit,
      splits: isSplit
          ? [
              for (final a in d.allocations)
                SplitLine(categoryId: a.categoryId, amountText: text(a.amount)),
            ]
          : const [SplitLine(), SplitLine()],
      occurredAt: d.occurredAt.toLocal(),
      title: d.title,
      note: d.note,
      tags: d.tags,
      paymentMethod: d.paymentMethod,
      paymentMethodChosen: true,
      isReimbursable: d.isReimbursable,
    );
  }

  static String? _otherAccount(Ledger ledger, String? notThis) =>
      ledger.activeAccounts.where((a) => a.id != notThis).firstOrNull?.id;

  void setType(TransactionType type) {
    if (type == state.type || type == TransactionType.adjustment) return;
    final ledger = state.ledger;
    // Expense and income categories are disjoint, so any switch away from
    // a categorized type invalidates the chosen category.
    final kindChanges = state.hasCategories;
    _update(
      state.copyWith(
        type: type,
        categoryId: kindChanges ? () => null : null,
        isSplit: kindChanges ? false : null,
        splits: kindChanges ? const [SplitLine(), SplitLine()] : null,
        counterpartyAccountId:
            type == TransactionType.transfer &&
                state.counterpartyAccountId == null &&
                ledger != null
            ? () => _otherAccount(ledger, state.accountId)
            : null,
        isReimbursable: type == TransactionType.expense
            ? state.isReimbursable
            : false,
      ),
    );
  }

  void setAmount(String text) => _update(state.copyWith(amountText: text));

  void setAccount(String id) {
    final account = state.ledger?.accountById(id);
    _update(
      state.copyWith(
        accountId: () => id,
        // Picking the destination as the source swaps the two.
        counterpartyAccountId: state.counterpartyAccountId == id
            ? () => state.accountId
            : null,
        paymentMethod: !state.paymentMethodChosen && account != null
            ? () => account.type.defaultPaymentMethod
            : null,
      ),
    );
  }

  void setDestination(String id) {
    _update(
      state.copyWith(
        counterpartyAccountId: () => id,
        accountId: state.accountId == id
            ? () => state.counterpartyAccountId
            : null,
      ),
    );
  }

  void setCategory(String id) => _update(state.copyWith(categoryId: () => id));

  void setSplit(bool enabled) {
    if (!state.hasCategories || enabled == state.isSplit) return;
    if (enabled) {
      // Carry the chosen category into the first line.
      final first = SplitLine(categoryId: state.categoryId);
      _update(
        state.copyWith(isSplit: true, splits: [first, const SplitLine()]),
      );
    } else {
      final firstCategory = state.splits
          .map((line) => line.categoryId)
          .nonNulls
          .firstOrNull;
      _update(
        state.copyWith(
          isSplit: false,
          categoryId: () => state.categoryId ?? firstCategory,
        ),
      );
    }
  }

  void setSplitCategory(int index, String id) =>
      _updateLine(index, (line) => line.copyWith(categoryId: id));

  void setSplitAmount(int index, String text) =>
      _updateLine(index, (line) => line.copyWith(amountText: text));

  void addSplitLine() =>
      _update(state.copyWith(splits: [...state.splits, const SplitLine()]));

  void removeSplitLine(int index) {
    if (state.splits.length <= 2 || index >= state.splits.length) return;
    _update(state.copyWith(splits: [...state.splits]..removeAt(index)));
  }

  void setOccurredAt(DateTime value) =>
      _update(state.copyWith(occurredAt: value));

  void setTitle(String value) => _update(state.copyWith(title: value));

  void setNote(String value) => _update(state.copyWith(note: value));

  void addTag(String tag) {
    final tags = LedgerValidator.normalizeTags([...state.tags, tag]);
    _update(state.copyWith(tags: tags));
  }

  void removeTag(String tag) =>
      _update(state.copyWith(tags: state.tags.where((t) => t != tag).toList()));

  void setPaymentMethod(PaymentMethod method) => _update(
    state.copyWith(paymentMethod: () => method, paymentMethodChosen: true),
  );

  void setReimbursable(bool value) =>
      _update(state.copyWith(isReimbursable: value));

  Future<void> submit() async {
    if (state.status != TransactionFormStatus.editing) return;
    final amount = state.amount;
    final accountId = state.accountId;
    if (amount == null || accountId == null) {
      emit(
        state.copyWith(
          showErrors: true,
          violation: () =>
              amount == null ? null : LedgerViolation.accountMissing,
          failure: () => null,
        ),
      );
      return;
    }
    final allocations = _allocations(amount);
    if (allocations == null) {
      emit(
        state.copyWith(
          showErrors: true,
          violation: () => LedgerViolation.splitAmountNotPositive,
          failure: () => null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: TransactionFormStatus.saving,
        violation: () => null,
        failure: () => null,
      ),
    );
    final result = await _save(
      TransactionDraft(
        id: state.editingId,
        type: state.type,
        amount: amount,
        accountId: accountId,
        counterpartyAccountId: state.type == TransactionType.transfer
            ? state.counterpartyAccountId
            : null,
        allocations: allocations,
        occurredAt: state.occurredAt,
        title: state.title,
        note: state.note,
        tags: state.tags,
        paymentMethod: state.paymentMethod,
        isReimbursable: state.isReimbursable,
      ),
    );
    if (isClosed) return;
    switch (result) {
      case Ok():
        emit(state.copyWith(status: TransactionFormStatus.saved));
      case Err(:final failure):
        final violation = LedgerViolation.of(failure);
        emit(
          state.copyWith(
            status: TransactionFormStatus.editing,
            showErrors: true,
            violation: () => violation,
            failure: () => violation == null ? failure : null,
          ),
        );
    }
  }

  /// Allocations for the current input, or null when a split line amount
  /// can't be read.
  List<CategoryAllocation>? _allocations(Money amount) {
    if (!state.hasCategories) return const [];
    if (!state.isSplit) {
      final id = state.categoryId;
      return id == null
          ? const []
          : [CategoryAllocation(categoryId: id, amount: amount)];
    }
    final allocations = <CategoryAllocation>[];
    for (final line in state.splits) {
      final id = line.categoryId;
      final text = line.amountText.trim();
      if (id == null && text.isEmpty) continue;
      final value = state.amountOfLine(line);
      if (id == null) return const [];
      if (value == null) return null;
      allocations.add(CategoryAllocation(categoryId: id, amount: value));
    }
    return allocations;
  }

  void _updateLine(int index, SplitLine Function(SplitLine) change) {
    if (index < 0 || index >= state.splits.length) return;
    final splits = [...state.splits];
    splits[index] = change(splits[index]);
    _update(state.copyWith(splits: splits));
  }

  /// Applies an edit. Once errors are showing, a field-level violation is
  /// cleared on edit so stale messages don't linger.
  void _update(TransactionFormState next) {
    if (state.status != TransactionFormStatus.editing) return;
    emit(next.copyWith(violation: () => null, failure: () => null));
  }
}
