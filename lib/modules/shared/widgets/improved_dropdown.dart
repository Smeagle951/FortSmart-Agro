import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../../../models/agricultural_product.dart';

/// Dropdown melhorado que evita problemas de renderização de texto
class ImprovedDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final String? hint;
  final bool enabled;
  final Widget? prefixIcon;

  const ImprovedDropdown({
    Key? key,
    required this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.hint,
    this.enabled = true,
    this.prefixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.greyLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.greyLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.danger, width: 2),
            ),
            filled: true,
            fillColor: enabled ? Colors.white : AppColors.light,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

/// Helper para criar itens de dropdown de forma segura
class DropdownItemHelper {
  /// Cria um DropdownMenuItem com texto seguro
  static DropdownMenuItem<T> createItem<T>({
    required T value,
    required String text,
    Widget? icon,
  }) {
    return DropdownMenuItem<T>(
      value: value,
      child: Row(
        children: [
          if (icon != null) ...[
            icon,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Cria uma lista de itens para tipos de produto
  static List<DropdownMenuItem<ProductType>> createProductTypeItems() {
    return ProductType.values.map((type) {
      return createItem<ProductType>(
        value: type,
        text: _getProductTypeDisplayName(type),
        icon: _getProductTypeIcon(type),
      );
    }).toList();
  }

  /// Cria uma lista de itens para unidades
  static List<DropdownMenuItem<String>> createUnitItems(List<String> units) {
    return units.map((unit) {
      return createItem<String>(
        value: unit,
        text: unit,
        icon: const Icon(Icons.straighten, size: 16),
      );
    }).toList();
  }

  /// Obtém o nome de exibição do tipo de produto
  static String _getProductTypeDisplayName(ProductType type) {
    switch (type) {
      case ProductType.herbicide:
        return 'Herbicida';
      case ProductType.insecticide:
        return 'Inseticida';
      case ProductType.fungicide:
        return 'Fungicida';
      case ProductType.fertilizer:
        return 'Fertilizante';
      case ProductType.growth:
        return 'Regulador de crescimento';
      case ProductType.adjuvant:
        return 'Adjuvante';
      case ProductType.seed:
        return 'Semente';
      case ProductType.other:
        return 'Outro';
      default:
        return 'Desconhecido';
    }
  }

  /// Obtém o ícone do tipo de produto
  static Widget? _getProductTypeIcon(ProductType type) {
    switch (type) {
      case ProductType.herbicide:
        return const Icon(Icons.eco, size: 16, color: Colors.green);
      case ProductType.insecticide:
        return const Icon(Icons.bug_report, size: 16, color: Colors.orange);
      case ProductType.fungicide:
        return const Icon(Icons.water_drop, size: 16, color: Colors.blue);
      case ProductType.fertilizer:
        return const Icon(Icons.agriculture, size: 16, color: Colors.brown);
      case ProductType.growth:
        return const Icon(Icons.trending_up, size: 16, color: Colors.purple);
      case ProductType.adjuvant:
        return const Icon(Icons.science, size: 16, color: Colors.cyan);
      case ProductType.seed:
        return const Icon(Icons.spa, size: 16, color: Colors.lightGreen);
      case ProductType.other:
        return const Icon(Icons.category, size: 16, color: Colors.grey);
      default:
        return null;
    }
  }
}

