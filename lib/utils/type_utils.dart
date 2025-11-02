import 'dart:math' as math;
import 'package:flutter/material.dart';

class TypeUtils {
  static double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value.replaceAll(',', '.'));
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  static int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  static String toSafeString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static bool toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value != 0;
    if (value is double) return value != 0.0;
    return false;
  }

  static String formatNumber(dynamic value, {int decimalPlaces = 2}) {
    final double numValue = toDouble(value);
    String numberStr = numValue.toStringAsFixed(decimalPlaces);
    List<String> parts = numberStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';
    
    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += '.';
      }
      formattedInteger += integerPart[i];
    }
    
    if (decimalPart.isEmpty || decimalPart == '0' * decimalPart.length) {
      return formattedInteger;
    } else {
      return '$formattedInteger,$decimalPart';
    }
  }

  static String formatArea(double areaHa, {int decimalPlaces = 2}) {
    if (areaHa >= 1.0) {
      return '${formatNumber(areaHa, decimalPlaces: 1)} ha';
    } else if (areaHa >= 0.01) {
      return '${formatNumber(areaHa, decimalPlaces: 2)} ha';
    } else {
      final areaM2 = areaHa * 10000;
      if (areaM2 >= 100) {
        return '${formatNumber(areaM2, decimalPlaces: 0)} m²';
      } else {
        return '${formatNumber(areaM2, decimalPlaces: 1)} m²';
      }
    }
  }

  static String formatDistance(double distanceM) {
    if (distanceM >= 1000) {
      return '${formatNumber(distanceM / 1000, decimalPlaces: 1)} km';
    } else {
      return '${formatNumber(distanceM, decimalPlaces: 0)} m';
    }
  }

  static Color parseColorSafely(dynamic value, {Color fallback = Colors.blue}) {
    if (value == null) return fallback;
    
    if (value is Color) return value;
    
    if (value is String) {
      try {
        // Remover # se presente
        String colorStr = value.replaceAll('#', '');
        
        // Adicionar FF se não tiver alpha
        if (colorStr.length == 6) {
          colorStr = 'FF$colorStr';
        }
        
        return Color(int.parse(colorStr, radix: 16));
      } catch (e) {
        return fallback;
      }
    }
    
    if (value is int) {
      return Color(value);
    }
    
    return fallback;
  }

  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
