import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/logger.dart';
import '../../models/rain_data_model.dart';
import '../../repositories/rain_data_repository.dart';

/// Tela de registro de dados de chuva
/// Permite registrar informações de precipitação em pontos específicos
class RainRegistrationScreen extends StatefulWidget {
  final String? stationId;
  final String? stationName;
  final LatLng? position;

  const RainRegistrationScreen({
    Key? key,
    this.stationId,
    this.stationName,
    this.position,
  }) : super(key: key);

  @override
  State<RainRegistrationScreen> createState() => _RainRegistrationScreenState();
}

class _RainRegistrationScreenState extends State<RainRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rainfallController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _rainType = 'Chuva Normal (5-10mm)';
  bool _isSubmitting = false;
  final RainDataRepository _repository = RainDataRepository();

  final List<String> _rainTypes = [
    'Garoa (0-2mm)',
    'Chuva Fraca (2-5mm)',
    'Chuva Normal (5-10mm)',
    'Chuva Moderada (10-15mm)',
    'Chuva Forte (15-20mm)',
    'Chuva Torrencial (20mm+)',
  ];

  @override
  void initState() {
    super.initState();
    _updateDateTime();
  }

  void _updateDateTime() {
    setState(() {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    });
  }

  @override
  void dispose() {
    _rainfallController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Obtém ícone para tipo de chuva
  IconData _getRainTypeIcon(String type) {
    if (type.contains('Garoa')) return Icons.grain;
    if (type.contains('Fraca')) return Icons.water_drop_outlined;
    if (type.contains('Normal')) return Icons.water_drop;
    if (type.contains('Moderada')) return Icons.thunderstorm_outlined;
    if (type.contains('Forte')) return Icons.thunderstorm;
    if (type.contains('Torrencial')) return Icons.flash_on;
    return Icons.water_drop;
  }

  /// Obtém cor para tipo de chuva
  Color _getRainTypeColor(String type) {
    if (type.contains('Garoa')) return Colors.grey[400]!;
    if (type.contains('Fraca')) return Colors.blue[300]!;
    if (type.contains('Normal')) return Colors.blue[500]!;
    if (type.contains('Moderada')) return Colors.blue[700]!;
    if (type.contains('Forte')) return Colors.orange[600]!;
    if (type.contains('Torrencial')) return Colors.red[600]!;
    return Colors.blue;
  }

  /// Sugere tipo de chuva baseado na quantidade (apenas sugestão)
  String _suggestRainType(double rainfall) {
    if (rainfall >= 20) return 'Chuva Torrencial (20mm+)';
    if (rainfall >= 15) return 'Chuva Forte (15-20mm)';
    if (rainfall >= 10) return 'Chuva Moderada (10-15mm)';
    if (rainfall >= 5) return 'Chuva Normal (5-10mm)';
    if (rainfall >= 2) return 'Chuva Fraca (2-5mm)';
    return 'Garoa (0-2mm)';
  }

  /// Atualiza sugestão de tipo quando quantidade muda
  void _onRainfallChanged(String value) {
    final rainfall = double.tryParse(value);
    if (rainfall != null) {
      final suggestedType = _suggestRainType(rainfall);
      if (mounted) {
        setState(() {
          _rainType = suggestedType;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Registro de Chuva',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF2D9CDB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de informações da estação
              _buildStationInfoCard(),
              
              const SizedBox(height: 20),
              
              // Card de dados de chuva
              _buildRainDataCard(),
              
              const SizedBox(height: 20),
              
              // Card de observações
              _buildObservationsCard(),
              
              const SizedBox(height: 30),
              
              // Botões de ação
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStationInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: Colors.blue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.stationName ?? 'Estação de Chuva',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ponto de Coleta de Dados',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (widget.stationId != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'ID: ${widget.stationId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRainDataCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dados de Chuva',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Quantidade de chuva
          TextFormField(
            controller: _rainfallController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            onChanged: _onRainfallChanged,
            decoration: InputDecoration(
              labelText: 'Quantidade de Chuva (mm)',
              hintText: 'Ex: 15.5',
              prefixIcon: const Icon(Icons.water_drop, color: Colors.blue),
              suffixText: 'mm',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Digite a quantidade de chuva';
              }
              final rainfall = double.tryParse(value);
              if (rainfall == null || rainfall < 0) {
                return 'Digite um valor válido';
              }
              if (rainfall > 500) {
                return 'Valor muito alto (máximo 500mm)';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Tipo de chuva
          DropdownButtonFormField<String>(
            value: _rainType,
            decoration: InputDecoration(
              labelText: 'Tipo de Chuva',
              helperText: 'Sugestão baseada na quantidade (você pode alterar)',
              prefixIcon: const Icon(Icons.cloud, color: Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
            items: _rainTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      _getRainTypeIcon(type),
                      color: _getRainTypeColor(type),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            type.split(' (')[0],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            type.split(' (')[1].replaceAll(')', ''),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _rainType = newValue!;
              });
            },
          ),
          
          const SizedBox(height: 20),
          
          // Data e hora
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue),
                        const SizedBox(width: 12),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: InkWell(
                  onTap: _selectTime,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.blue),
                        const SizedBox(width: 12),
                        Text(
                          _selectedTime.format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObservationsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Observações',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Adicione observações sobre a chuva (opcional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitRainData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Registrar Chuva',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitRainData() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final rainfall = double.parse(_rainfallController.text);
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      
      // Criar modelo de dados
      final rainData = RainDataModel.create(
        stationId: widget.stationId ?? 'UNKNOWN',
        stationName: widget.stationName ?? 'Estação Desconhecida',
        rainfall: rainfall,
        rainType: _rainType,
        dateTime: dateTime,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        latitude: widget.position?.latitude ?? 0.0,
        longitude: widget.position?.longitude ?? 0.0,
      );
      
      // Salvar no repositório
      final success = await _repository.saveRainData(rainData);
      
      if (success) {
        Logger.info('✅ Dados de chuva salvos com sucesso: ${rainData.id}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Chuva de ${rainfall}mm registrada com sucesso!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Falha ao salvar dados');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao registrar dados de chuva: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar dados: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
