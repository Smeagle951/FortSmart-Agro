import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardFilters extends StatefulWidget {
  final List<String> plotOptions;
  final List<String> cropOptions;
  final Function(String?, String?, DateTime?, DateTime?, bool) onApplyFilters;
  final Function() onClearFilters;
  
  const DashboardFilters({
    Key? key,
    required this.plotOptions,
    required this.cropOptions,
    required this.onApplyFilters,
    required this.onClearFilters,
  }) : super(key: key);
  
  @override
  _DashboardFiltersState createState() => _DashboardFiltersState();
}

class _DashboardFiltersState extends State<DashboardFilters> {
  String? _selectedPlotId;
  String? _selectedCropType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showResolved = true;
  
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  
  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = isStartDate ? _startDate ?? now : _endDate ?? now;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light().copyWith(
              primary: const Color(0xFF2A4F3D),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        }
      });
    }
  }
  
  void _clearFilters() {
    setState(() {
      _selectedPlotId = null;
      _selectedCropType = null;
      _startDate = null;
      _endDate = null;
      _showResolved = true;
      _startDateController.clear();
      _endDateController.clear();
    });
    
    widget.onClearFilters();
  }
  
  void _applyFilters() {
    widget.onApplyFilters(
      _selectedPlotId,
      _selectedCropType,
      _startDate,
      _endDate,
      _showResolved,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list, color: Color(0xFF2A4F3D)),
                const SizedBox(width: 8),
                const Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A4F3D),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Limpar'),
                  onPressed: _clearFilters,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const Divider(),
            
            // Filtro por Talhão
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Talhão',
                border: OutlineInputBorder(),
              ),
              value: _selectedPlotId,
              isExpanded: true,
              hint: const Text('Todos os talhões'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Todos os talhões'),
                ),
                ...widget.plotOptions.map((plotId) {
                  return DropdownMenuItem<String>(
                    value: plotId,
                    child: Text(plotId),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPlotId = value;
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Filtro por Cultura
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Cultura',
                border: OutlineInputBorder(),
              ),
              value: _selectedCropType,
              isExpanded: true,
              hint: const Text('Todas as culturas'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Todas as culturas'),
                ),
                ...widget.cropOptions.map((cropType) {
                  return DropdownMenuItem<String>(
                    value: cropType,
                    child: Text(cropType),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCropType = value;
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Filtro por Período
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Data Inicial',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    controller: _startDateController,
                    // onTap: () => _selectDate(context, // onTap não é suportado em Polygon no flutter_map 5.0.0 true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Data Final',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    controller: _endDateController,
                    // onTap: () => _selectDate(context, // onTap não é suportado em Polygon no flutter_map 5.0.0 false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Opção para mostrar resolvidos
            Row(
              children: [
                Checkbox(
                  value: _showResolved,
                  activeColor: const Color(0xFF2A4F3D),
                  onChanged: (value) {
                    setState(() {
                      _showResolved = value ?? true;
                    });
                  },
                ),
                const Text('Incluir alertas resolvidos'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Botão de aplicar filtros
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.filter_alt),
                label: const Text('Aplicar Filtros'),
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
