import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FishPriceEntry {
  final String fishId;
  final String fishName;
  final String category;
  final double lowestPrice;
  final double averagePrice;
  final double highestPrice;
  final double previousAverage;
  final DateTime date;
  final String trend;

  const FishPriceEntry({
    required this.fishId,
    required this.fishName,
    required this.category,
    required this.lowestPrice,
    required this.averagePrice,
    required this.highestPrice,
    required this.previousAverage,
    required this.date,
    required this.trend,
  });
}

class AnalyticsState {
  final List<FishPriceEntry> prices;
  final bool isLoading;
  final String? error;
  final String? selectedCategory;

  const AnalyticsState({
    this.prices = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory,
  });

  AnalyticsState copyWith({
    List<FishPriceEntry>? prices,
    bool? isLoading,
    String? error,
    String? selectedCategory,
  }) =>
      AnalyticsState(
        prices: prices ?? this.prices,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        selectedCategory: selectedCategory ?? this.selectedCategory,
      );

  List<FishPriceEntry> get filtered {
    if (selectedCategory == null || selectedCategory!.isEmpty) return prices;
    return prices.where((p) => p.category == selectedCategory).toList();
  }

  List<String> get categories {
    final set = <String>{};
    for (final p in prices) set.add(p.category);
    return set.toList()..sort();
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final DioClient _client;

  AnalyticsNotifier(this._client) : super(const AnalyticsState()) {
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.dio.get(ApiConstants.fish);
      final List<dynamic> dataList = res.data is Map<String, dynamic> 
          ? (res.data['data'] as List<dynamic>)
          : (res.data as List<dynamic>);
      
      final entries = dataList.map((e) {
        final fishName = e['name'] ?? 'Unknown';
        final category = e['category'] ?? 'General';
        final price = (e['pricePerKg'] as num?)?.toDouble() ?? 0.0;
        
        return FishPriceEntry(
          fishId: e['_id'] ?? e['id'] ?? '',
          fishName: fishName,
          category: category,
          lowestPrice: price,
          averagePrice: price,
          highestPrice: price,
          previousAverage: 0.0,
          date: DateTime.now(),
          trend: 'stable',
        );
      }).toList();

      state = state.copyWith(isLoading: false, prices: entries);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void filterByCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  Future<void> refresh() async {
    await _loadPrices();
  }
}

final priceAnalyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(ref.watch(dioClientProvider));
});
