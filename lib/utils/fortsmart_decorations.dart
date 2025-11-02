import 'package:flutter/material.dart';
import 'fortsmart_colors.dart';

/// Decorações FortSmart
class FortSmartDecorations {
  // Decoração de input
  static const InputDecoration inputDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: FortSmartColors.neutralMedium),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: FortSmartColors.neutralMedium),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: FortSmartColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: FortSmartColors.error),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    filled: true,
    fillColor: FortSmartColors.neutralLight,
  );

  // Decoração de dropdown
  static const BoxDecoration dropdownDecoration = BoxDecoration(
    color: FortSmartColors.white,
    borderRadius: BorderRadius.all(Radius.circular(8)),
    border: Border(
      top: BorderSide(color: FortSmartColors.neutralMedium),
      left: BorderSide(color: FortSmartColors.neutralMedium),
      right: BorderSide(color: FortSmartColors.neutralMedium),
      bottom: BorderSide(color: FortSmartColors.neutralMedium),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  );

  // Decoração de item selecionado
  static const BoxDecoration selectedItemDecoration = BoxDecoration(
    color: FortSmartColors.primary,
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );

  // Decoração de card histórico
  static const BoxDecoration historicalCard = BoxDecoration(
    color: FortSmartColors.white,
    borderRadius: BorderRadius.all(Radius.circular(12)),
    boxShadow: [
      BoxShadow(
        color: const Color(0x14000000),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  // Decoração de lista
  static const BoxDecoration listDecoration = BoxDecoration(
    color: FortSmartColors.white,
    borderRadius: BorderRadius.all(Radius.circular(8)),
    border: Border(
      top: BorderSide(color: FortSmartColors.neutralMedium),
      left: BorderSide(color: FortSmartColors.neutralMedium),
      right: BorderSide(color: FortSmartColors.neutralMedium),
      bottom: BorderSide(color: FortSmartColors.neutralMedium),
    ),
  );

  // Decoração de card primário
  static const BoxDecoration primaryCard = BoxDecoration(
    color: FortSmartColors.white,
    borderRadius: BorderRadius.all(Radius.circular(12)),
    boxShadow: [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  // Decoração de card de cultura
  static const BoxDecoration cultureCard = BoxDecoration(
    color: FortSmartColors.backgroundLight,
    borderRadius: BorderRadius.all(Radius.circular(12)),
    border: Border(
      top: BorderSide(color: FortSmartColors.accent),
      left: BorderSide(color: FortSmartColors.accent),
      right: BorderSide(color: FortSmartColors.accent),
      bottom: BorderSide(color: FortSmartColors.accent),
    ),
  );

  // Decoração de card de distância
  static const BoxDecoration distanceCard = BoxDecoration(
    color: FortSmartColors.routePrimary,
    borderRadius: BorderRadius.all(Radius.circular(12)),
    boxShadow: [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  // Decoração de card de ocorrência
  static const BoxDecoration occurrenceCard = BoxDecoration(
    color: FortSmartColors.neutralLight,
    borderRadius: BorderRadius.all(Radius.circular(12)),
    border: Border(
      top: BorderSide(color: FortSmartColors.neutralMedium),
      left: BorderSide(color: FortSmartColors.neutralMedium),
      right: BorderSide(color: FortSmartColors.neutralMedium),
      bottom: BorderSide(color: FortSmartColors.neutralMedium),
    ),
  );
}
