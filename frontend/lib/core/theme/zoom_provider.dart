import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ZoomLevelNotifier extends StateNotifier<double> {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _zoomKey = 'ui_zoom_level';

  ZoomLevelNotifier() : super(1.0) {
    _loadZoomLevel();
  }

  Future<void> _loadZoomLevel() async {
    try {
      final savedVal = await _storage.read(key: _zoomKey);
      if (savedVal != null) {
        final val = double.tryParse(savedVal);
        if (val != null) {
          state = val;
        }
      }
    } catch (e) {
      // ignore errors
    }
  }

  Future<void> setZoomLevel(double level) async {
    state = level;
    try {
      await _storage.write(key: _zoomKey, value: level.toString());
    } catch (e) {
      // ignore errors
    }
  }
}

final zoomLevelProvider = StateNotifierProvider<ZoomLevelNotifier, double>((ref) {
  return ZoomLevelNotifier();
});

class ZoomWrapper extends StatelessWidget {
  final double zoomLevel;
  final Widget child;

  const ZoomWrapper({
    super.key,
    required this.zoomLevel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (zoomLevel == 1.0) {
      return child;
    }

    final mediaQuery = MediaQuery.of(context);
    
    // Scale constraints/size/paddings by dividing by the zoom level
    final scaledSize = mediaQuery.size / zoomLevel;
    final scaledPadding = mediaQuery.padding / zoomLevel;
    final scaledViewInsets = mediaQuery.viewInsets / zoomLevel;
    final scaledViewPadding = mediaQuery.viewPadding / zoomLevel;

    return MediaQuery(
      data: mediaQuery.copyWith(
        size: scaledSize,
        padding: scaledPadding,
        viewInsets: scaledViewInsets,
        viewPadding: scaledViewPadding,
      ),
      child: FractionallySizedBox(
        widthFactor: 1 / zoomLevel,
        heightFactor: 1 / zoomLevel,
        alignment: Alignment.topLeft,
        child: Transform.scale(
          scale: zoomLevel,
          alignment: Alignment.topLeft,
          child: child,
        ),
      ),
    );
  }
}
