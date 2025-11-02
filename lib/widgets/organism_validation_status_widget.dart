import 'package:flutter/material.dart';
import '../models/organism_catalog.dart';
import '../services/agricultural_expert_validation_service.dart';
import '../utils/enums.dart';

/// Widget para mostrar o status de validação de um organismo
class OrganismValidationStatusWidget extends StatefulWidget {
  final OrganismCatalog organism;
  final bool showDetails;
  final VoidCallback? onValidationChanged;

  const OrganismValidationStatusWidget({
    Key? key,
    required this.organism,
    this.showDetails = false,
    this.onValidationChanged,
  }) : super(key: key);

  @override
  State<OrganismValidationStatusWidget> createState() => _OrganismValidationStatusWidgetState();
}

class _OrganismValidationStatusWidgetState extends State<OrganismValidationStatusWidget> {
  final AgriculturalExpertValidationService _validationService = AgriculturalExpertValidationService();
  ValidationResult? _validationResult;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _validateOrganism();
  }

  @override
  void didUpdateWidget(OrganismValidationStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organism.id != widget.organism.id) {
      _validateOrganism();
    }
  }

  Future<void> _validateOrganism() async {
    setState(() {
      _isValidating = true;
    });

    try {
      final result = await _validationService.validateOrganismData(widget.organism);
      setState(() {
        _validationResult = result;
        _isValidating = false;
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isValidating) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_validationResult == null) {
      return const Icon(
        Icons.help_outline,
        size: 16,
        color: Colors.grey,
      );
    }

    return GestureDetector(
      onTap: widget.showDetails ? _showValidationDetails : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getValidationIcon(_validationResult!.severity),
            size: 16,
            color: _getValidationColor(_validationResult!.severity),
          ),
          if (widget.showDetails) ...[
            const SizedBox(width: 4),
            Text(
              _getValidationText(_validationResult!.severity),
              style: TextStyle(
                fontSize: 12,
                color: _getValidationColor(_validationResult!.severity),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getValidationIcon(ValidationSeverity severity) {
    switch (severity) {
      case ValidationSeverity.none:
        return Icons.check_circle;
      case ValidationSeverity.low:
        return Icons.info;
      case ValidationSeverity.medium:
        return Icons.warning;
      case ValidationSeverity.high:
        return Icons.error;
      case ValidationSeverity.critical:
        return Icons.dangerous;
    }
  }

  Color _getValidationColor(ValidationSeverity severity) {
    switch (severity) {
      case ValidationSeverity.none:
        return Colors.green;
      case ValidationSeverity.low:
        return Colors.blue;
      case ValidationSeverity.medium:
        return Colors.orange;
      case ValidationSeverity.high:
        return Colors.red;
      case ValidationSeverity.critical:
        return Colors.red.shade800;
    }
  }

  String _getValidationText(ValidationSeverity severity) {
    switch (severity) {
      case ValidationSeverity.none:
        return 'Válido';
      case ValidationSeverity.low:
        return 'Baixo';
      case ValidationSeverity.medium:
        return 'Médio';
      case ValidationSeverity.high:
        return 'Alto';
      case ValidationSeverity.critical:
        return 'Crítico';
    }
  }

  void _showValidationDetails() {
    if (_validationResult == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getValidationIcon(_validationResult!.severity),
              color: _getValidationColor(_validationResult!.severity),
            ),
            const SizedBox(width: 8),
            Text('Validação: ${widget.organism.name}'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status geral
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getValidationColor(_validationResult!.severity).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getValidationColor(_validationResult!.severity),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _validationResult!.isValid ? Icons.check_circle : Icons.error,
                      color: _getValidationColor(_validationResult!.severity),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationResult!.isValid
                            ? 'Organismo válido e em conformidade'
                            : 'Organismo com problemas de validação',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _getValidationColor(_validationResult!.severity),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Problemas encontrados
              if (_validationResult!.issues.isNotEmpty) ...[
                const Text(
                  'Problemas Encontrados:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._validationResult!.issues.map((issue) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _getIssueIcon(issue.severity),
                        size: 16,
                        color: _getValidationColor(issue.severity),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              issue.message,
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (issue.currentValue != null)
                              Text(
                                'Valor atual: ${issue.currentValue}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
              ],
              
              // Sugestões
              if (_validationResult!.suggestions.isNotEmpty) ...[
                const Text(
                  'Sugestões de Melhoria:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._validationResult!.suggestions.map((suggestion) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestion.message,
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (suggestion.suggestedValue != null)
                              Text(
                                'Valor sugerido: ${suggestion.suggestedValue}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            if (suggestion.example != null)
                              Text(
                                'Exemplo: ${suggestion.example}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          if (!_validationResult!.isValid)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onValidationChanged?.call();
              },
              child: const Text('Corrigir'),
            ),
        ],
      ),
    );
  }

  IconData _getIssueIcon(ValidationSeverity severity) {
    switch (severity) {
      case ValidationSeverity.none:
        return Icons.check;
      case ValidationSeverity.low:
        return Icons.info_outline;
      case ValidationSeverity.medium:
        return Icons.warning_amber;
      case ValidationSeverity.high:
        return Icons.error_outline;
      case ValidationSeverity.critical:
        return Icons.dangerous;
    }
  }
}
