import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManagementNotifier extends StateNotifier<int> {
  ManagementNotifier() : super(0); // Default to first tab (Boats: 0)

  void switchTab(int index) {
    state = index;
  }
}

final managementTabProvider = StateNotifierProvider<ManagementNotifier, int>((ref) {
  return ManagementNotifier();
});
