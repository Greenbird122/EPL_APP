import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/network/backend_services.dart';

class PatientCard {
  const PatientCard({
    required this.id,
    required this.balance,
    required this.status,
    required this.createdAt,
    this.approvedAt,
  });

  final int id;
  final double balance;
  final String status;
  final DateTime createdAt;
  final DateTime? approvedAt;

  factory PatientCard.fromMap(Map<String, dynamic> map) {
    return PatientCard(
      id: (map['id'] as num).toInt(),
      balance: (map['balance'] as num).toDouble(),
      status: map['status'] as String? ?? 'inactive',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      approvedAt: map['approved_at'] != null
          ? DateTime.tryParse(map['approved_at'].toString())
          : null,
    );
  }
}

class Transaction {
  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.reference,
    required this.status,
    required this.description,
    required this.createdAt,
  });

  final int id;
  final double amount;
  final String type;
  final String reference;
  final String status;
  final String description;
  final DateTime createdAt;

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: (map['id'] as num).toInt(),
      amount: (map['amount'] as num).toDouble(),
      type: map['transaction_type'] as String? ?? 'topup',
      reference: map['reference'] as String? ?? '',
      status: map['status'] as String? ?? '',
      description: map['description'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class PaymentsState {
  const PaymentsState({
    required this.hasPid,
    this.card,
  });

  final bool hasPid;
  final PatientCard? card;
}

final paymentsStateProvider =
    FutureProvider.autoDispose<PaymentsState>((ref) async {
  final api = ref.watch(paymentsApiProvider);
  final data = await api.getCard();
  final hasPid = data['has_pid'] == true;
  final cardData = data['card'];
  return PaymentsState(
    hasPid: hasPid,
    card: cardData != null ? PatientCard.fromMap(Map<String, dynamic>.from(cardData as Map)) : null,
  );
});

final transactionsProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
  final api = ref.watch(paymentsApiProvider);
  final data = await api.getTransactions();
  return data.map((item) => Transaction.fromMap(item)).toList();
});

class TopUpController extends StateNotifier<AsyncValue<void>> {
  TopUpController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> topUp({
    required double amount,
    required String reference,
  }) async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(paymentsApiProvider);
      await api.topUp(amount: amount, reference: reference);
      _ref.invalidate(paymentsStateProvider);
      _ref.invalidate(transactionsProvider);
      state = const AsyncValue.data(null);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

final topUpControllerProvider =
    StateNotifierProvider.autoDispose<TopUpController, AsyncValue<void>>((ref) {
  return TopUpController(ref);
});
