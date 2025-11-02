import 'package:flutter/material.dart';
import '../utils/text_encoding_helper.dart';
import 'safe_text.dart';

/// Widget para exibir tabelas de dados com tratamento seguro de codificação de texto
/// 
/// Este widget garante que todos os textos exibidos na tabela tenham a codificação correta,
/// evitando problemas com caracteres especiais e acentuação.
class SafeDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool showCheckboxColumn;
  final bool sortAscending;
  final int? sortColumnIndex;
  final DataTableSource? source;
  final double? dataRowHeight;
  final double? headingRowHeight;
  final double? horizontalMargin;
  final double? columnSpacing;
  final double? dividerThickness;
  final Function(bool?)? onSelectAll;
  final MaterialStateProperty<Color?>? headingRowColor;
  final MaterialStateProperty<Color?>? dataRowColor;

  /// Construtor para o widget SafeDataTable
  const SafeDataTable({
    Key? key,
    required this.columns,
    required this.rows,
    this.showCheckboxColumn = true,
    this.sortAscending = true,
    this.sortColumnIndex,
    this.source,
    this.dataRowHeight,
    this.headingRowHeight,
    this.horizontalMargin,
    this.columnSpacing,
    this.dividerThickness,
    this.onSelectAll,
    this.headingRowColor,
    this.dataRowColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: columns,
      rows: rows,
      showCheckboxColumn: showCheckboxColumn,
      sortAscending: sortAscending,
      sortColumnIndex: sortColumnIndex,
      dataRowHeight: dataRowHeight,
      headingRowHeight: headingRowHeight,
      horizontalMargin: horizontalMargin,
      columnSpacing: columnSpacing,
      dividerThickness: dividerThickness,
      onSelectAll: onSelectAll,
      headingRowColor: headingRowColor,
      dataRowColor: dataRowColor,
    );
  }

  /// Cria uma coluna com texto seguro
  static DataColumn safeColumn({
    required String label,
    String tooltip = '',
    bool numeric = false,
    Function(int, bool)? onSort,
  }) {
    final normalizedLabel = TextEncodingHelper.normalizeText(label);
    final normalizedTooltip = tooltip.isNotEmpty 
        ? TextEncodingHelper.normalizeText(tooltip) 
        : '';

    return DataColumn(
      label: SafeText(
        normalizedLabel,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      tooltip: normalizedTooltip.isNotEmpty ? normalizedTooltip : null,
      numeric: numeric,
      onSort: onSort,
    );
  }

  /// Cria uma célula com texto seguro
  static DataCell safeCell(
    String text, {
    bool placeholder = false,
    bool showEditIcon = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    GestureTapDownCallback? onTapDown,
    VoidCallback? onDoubleTap,
    VoidCallback? onTapCancel,
  }) {
    final normalizedText = TextEncodingHelper.normalizeText(text);

    return DataCell(
      SafeText(normalizedText),
      placeholder: placeholder,
      showEditIcon: showEditIcon,
      onTap: onTap,
      onLongPress: onLongPress,
      onTapDown: onTapDown,
      onDoubleTap: onDoubleTap,
      onTapCancel: onTapCancel,
    );
  }

  /// Cria uma célula com widget personalizado
  static DataCell customCell(
    Widget child, {
    bool placeholder = false,
    bool showEditIcon = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    GestureTapDownCallback? onTapDown,
    VoidCallback? onDoubleTap,
    VoidCallback? onTapCancel,
  }) {
    return DataCell(
      child,
      placeholder: placeholder,
      showEditIcon: showEditIcon,
      onTap: onTap,
      onLongPress: onLongPress,
      onTapDown: onTapDown,
      onDoubleTap: onDoubleTap,
      onTapCancel: onTapCancel,
    );
  }
}
