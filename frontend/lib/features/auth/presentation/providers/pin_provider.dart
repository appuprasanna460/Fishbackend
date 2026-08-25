import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/secure_storage.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class PinState {
  final bool hasPinSet;
  final bool isUnlocked;
  final String? errorMessage;

  const PinState({
    this.hasPinSet = false,
    this.isUnlocked = false,
    this.errorMessage,
  });

  PinState copyWith({
    bool? hasPinSet,
    bool? isUnlocked,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PinState(
      hasPinSet: hasPinSet ?? this.hasPinSet,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final pinProvider = StateNotifierProvider<PinNotifier, PinState>((ref) {
  return PinNotifier();
});

// ─── Notifier ─────────────────────────────────────────────────────────────────

class PinNotifier extends StateNotifier<PinState> {
  PinNotifier() : super(const PinState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final pin = await SecureStorage.getPin();
    if (pin != null && pin.isNotEmpty) {
      state = state.copyWith(hasPinSet: true, isUnlocked: false);
    } else {
      state = state.copyWith(hasPinSet: false, isUnlocked: true);
    }
  }

  /// Sets a new 4-digit PIN. Marks app as unlocked after setting.
  Future<void> setPin(String pin) async {
    await SecureStorage.savePin(pin);
    state = state.copyWith(hasPinSet: true, isUnlocked: true, clearError: true);
  }

  /// Clears the stored PIN. App remains unlocked.
  Future<void> clearPin() async {
    await SecureStorage.deletePin();
    state = state.copyWith(hasPinSet: false, isUnlocked: true, clearError: true);
  }

  /// Verifies the entered PIN against stored. Unlocks if correct.
  Future<bool> unlockApp(String enteredPin) async {
    final storedPin = await SecureStorage.getPin();
    if (storedPin == enteredPin) {
      state = state.copyWith(isUnlocked: true, clearError: true);
      return true;
    } else {
      state = state.copyWith(
        isUnlocked: false,
        errorMessage: 'Incorrect PIN. Please try again.',
      );
      return false;
    }
  }

  /// Called when app goes to background — require PIN again on next foreground.
  void lockApp() {
    if (state.hasPinSet) {
      state = state.copyWith(isUnlocked: false, clearError: true);
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
