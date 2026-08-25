// lib/features/boat_owner/presentation/providers/boat_owner_ledger_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/boat_owner_api_service.dart';

// ── Category helpers ──────────────────────────────────────────────────────────
const List<String> kIncomeCategories = ['FISH_SALE', 'OTHER_INCOME'];
const List<String> kExpenseCategories = [
  'DIESEL', 'FUEL', 'ICE', 'LABOUR', 'FOOD', 'REPAIR', 'MAINTENANCE', 'OTHER_EXPENSE'
];

String categoryLabel(String raw) {
  return raw.replaceAll('_', ' ');
}

// ── Model ──────────────────────────────────────────────────────────────────────
class LedgerEntry {
  final String id;
  final String boatId;
  final String boatName;
  final DateTime date;
  final String type; // 'INCOME' | 'EXPENSE'
  final String category;
  final double amount;
  final String description;

  LedgerEntry({
    required this.id,
    required this.boatId,
    required this.boatName,
    required this.date,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    final boatData = json['boatId'];
    String boatId = '';
    String boatName = '';
    if (boatData is Map<String, dynamic>) {
      boatId = boatData['_id'] ?? '';
      boatName = '${boatData['boatNumber'] ?? ''} - ${boatData['boatName'] ?? ''}'.trim();
    } else {
      boatId = boatData?.toString() ?? '';
    }

    return LedgerEntry(
      id: json['_id'] ?? '',
      boatId: boatId,
      boatName: boatName,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      type: json['type'] ?? 'EXPENSE',
      category: json['category'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
    );
  }

  LedgerEntry copyWith({
    String? id, String? boatId, String? boatName,
    DateTime? date, String? type, String? category,
    double? amount, String? description,
  }) {
    return LedgerEntry(
      id: id ?? this.id, boatId: boatId ?? this.boatId,
      boatName: boatName ?? this.boatName, date: date ?? this.date,
      type: type ?? this.type, category: category ?? this.category,
      amount: amount ?? this.amount, description: description ?? this.description,
    );
  }
}

// ── Summary ────────────────────────────────────────────────────────────────────
class LedgerSummary {
  final double totalIncome;
  final double totalExpense;
  final double netProfit;

  LedgerSummary({
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.netProfit = 0,
  });

  factory LedgerSummary.fromJson(Map<String, dynamic> json) {
    return LedgerSummary(
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      totalExpense: (json['totalExpense'] ?? 0).toDouble(),
      netProfit: (json['netProfit'] ?? 0).toDouble(),
    );
  }
}

// ── State ──────────────────────────────────────────────────────────────────────
class BoatOwnerLedgerState {
  final List<LedgerEntry> entries;
  final LedgerSummary summary;
  final bool isLoading;
  final String? error;

  BoatOwnerLedgerState({
    this.entries = const [],
    LedgerSummary? summary,
    this.isLoading = false,
    this.error,
  }) : summary = summary ?? LedgerSummary();

  BoatOwnerLedgerState copyWith({
    List<LedgerEntry>? entries,
    LedgerSummary? summary,
    bool? isLoading,
    String? error,
  }) {
    return BoatOwnerLedgerState(
      entries: entries ?? this.entries,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────────
class BoatOwnerLedgerNotifier extends StateNotifier<BoatOwnerLedgerState> {
  final BoatOwnerApiService _api;

  BoatOwnerLedgerNotifier(this._api) : super(BoatOwnerLedgerState()) {
    loadAll();
  }

  Future<void> loadAll({String? boatId, String? type, String? category}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _api.getLedgerEntries(boatId: boatId, type: type, category: category, limit: 100),
        _api.getLedgerSummary(boatId: boatId),
      ]);

      final entriesRes = results[0];
      final summaryRes = results[1];

      final List raw = entriesRes['data'] ?? [];
      state = state.copyWith(
        entries: raw.map((e) => LedgerEntry.fromJson(e)).toList(),
        summary: LedgerSummary.fromJson(summaryRes),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addEntry({
    required String boatId,
    required DateTime date,
    required String type,
    required String category,
    required double amount,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final created = await _api.createLedgerEntry({
        'boatId': boatId,
        'date': date.toIso8601String(),
        'type': type,
        'category': category,
        'amount': amount,
        if (description.isNotEmpty) 'description': description,
      });
      final entry = LedgerEntry.fromJson(created);
      state = state.copyWith(
        entries: [entry, ...state.entries],
        isLoading: false,
      );
      // Refresh summary from server
      _refreshSummary();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateEntry(LedgerEntry entry) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _api.updateLedgerEntry(entry.id, {
        'boatId': entry.boatId,
        'date': entry.date.toIso8601String(),
        'type': entry.type,
        'category': entry.category,
        'amount': entry.amount,
        'description': entry.description,
      });
      final updatedEntry = LedgerEntry.fromJson(updated);
      state = state.copyWith(
        entries: state.entries.map((e) => e.id == updatedEntry.id ? updatedEntry : e).toList(),
        isLoading: false,
      );
      _refreshSummary();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteEntry(String id) async {
    try {
      await _api.deleteLedgerEntry(id);
      state = state.copyWith(
        entries: state.entries.where((e) => e.id != id).toList(),
      );
      _refreshSummary();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> _refreshSummary() async {
    try {
      final summaryRes = await _api.getLedgerSummary();
      state = state.copyWith(summary: LedgerSummary.fromJson(summaryRes));
    } catch (_) {}
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────
final boatOwnerLedgerProvider =
    StateNotifierProvider<BoatOwnerLedgerNotifier, BoatOwnerLedgerState>((ref) {
  final api = BoatOwnerApiService(ref.watch(dioClientProvider));
  return BoatOwnerLedgerNotifier(api);
});
