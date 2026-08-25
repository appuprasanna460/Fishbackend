// lib/core/utils/dms_utils.dart

class DmsUtils {
  /// Convert Decimal Degrees to DMS (Degrees, Minutes, Seconds) string
  static String decimalToDms(double decimal, bool isLatitude) {
    final direction = isLatitude
        ? (decimal >= 0 ? 'N' : 'S')
        : (decimal >= 0 ? 'E' : 'W');
    
    final absDecimal = decimal.abs();
    final degrees = absDecimal.floor();
    final minutesDecimal = (absDecimal - degrees) * 60;
    final minutes = minutesDecimal.floor();
    final seconds = (minutesDecimal - minutes) * 60;
    
    return '${degrees}° ${minutes.toString().padLeft(2, '0')}\' ${seconds.toStringAsFixed(2).padLeft(6, '0')}" $direction';
  }

  /// Convert DMS to Decimal Degrees
  static double dmsToDecimal(String dmsString) {
    // Clean the input
    String cleaned = dmsString
        .replaceAll('°', '')
        .replaceAll('\'', '')
        .replaceAll('"', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // Parse direction
    String direction = '';
    if (cleaned.contains(RegExp(r'[NSEW]$'))) {
      direction = cleaned.substring(cleaned.length - 1);
      cleaned = cleaned.substring(0, cleaned.length - 1).trim();
    }
    
    // Parse parts
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length < 2) {
      throw FormatException('Invalid DMS format. Expected: "12 56 45.64 N"');
    }
    
    final degrees = double.parse(parts[0]);
    final minutes = double.parse(parts[1]);
    final seconds = parts.length > 2 ? double.parse(parts[2]) : 0.0;
    
    double decimal = degrees + (minutes / 60) + (seconds / 3600);
    
    // Apply direction
    if (direction == 'S' || direction == 'W') {
      decimal = -decimal;
    }
    
    return decimal;
  }

  /// Validate DMS format
  static bool isValidDms(String dmsString, bool isLatitude) {
    try {
      final cleaned = dmsString
          .replaceAll('°', '')
          .replaceAll('\'', '')
          .replaceAll('"', '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      
      if (cleaned.isEmpty) return false;
      
      // Check for direction
      final hasDirection = cleaned.contains(RegExp(r'[NSEW]$'));
      
      // Parse parts
      String numberPart = cleaned;
      if (hasDirection) {
        numberPart = cleaned.substring(0, cleaned.length - 1).trim();
      }
      
      final parts = numberPart.split(RegExp(r'\s+'));
      if (parts.isEmpty || parts.length > 3) return false;
      
      final degrees = double.tryParse(parts[0]);
      if (degrees == null) return false;
      
      final minutes = parts.length > 1 ? double.tryParse(parts[1]) : 0.0;
      if (minutes == null || minutes < 0 || minutes >= 60) return false;
      
      final seconds = parts.length > 2 ? double.tryParse(parts[2]) : 0.0;
      if (seconds == null || seconds < 0 || seconds >= 60) return false;
      
      // Validate range
      if (isLatitude) {
        if (degrees < 0 || degrees > 90) return false;
        if (degrees == 90 && (minutes > 0 || seconds > 0)) return false;
      } else {
        if (degrees < 0 || degrees > 180) return false;
        if (degrees == 180 && (minutes > 0 || seconds > 0)) return false;
      }
      
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Format DMS string for display
  static String formatDmsDisplay(String dmsString) {
    try {
      final cleaned = dmsString
          .replaceAll('°', '')
          .replaceAll('\'', '')
          .replaceAll('"', '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      
      if (cleaned.isEmpty) return dmsString;
      
      final hasDirection = cleaned.contains(RegExp(r'[NSEW]$'));
      
      String numberPart = cleaned;
      String direction = '';
      if (hasDirection) {
        direction = cleaned.substring(cleaned.length - 1);
        numberPart = cleaned.substring(0, cleaned.length - 1).trim();
      }
      
      final parts = numberPart.split(RegExp(r'\s+'));
      if (parts.isEmpty) return dmsString;
      
      String formatted = '';
      if (parts.length >= 1) {
        formatted += '${parts[0]}°';
      }
      if (parts.length >= 2) {
        formatted += ' ${parts[1]}\'';
      }
      if (parts.length >= 3) {
        formatted += ' ${parts[2]}"';
      }
      if (direction.isNotEmpty) {
        formatted += ' $direction';
      }
      
      return formatted;
    } catch (_) {
      return dmsString;
    }
  }
}