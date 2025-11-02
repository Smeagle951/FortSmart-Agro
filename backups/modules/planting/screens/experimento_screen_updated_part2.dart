import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/enhanced_plot_selector.dart';
import '../widgets/free_text_input.dart';
import '../widgets/image_placeholder.dart';
import '../models/experimento_model.dart';
import '../services/experimento_service.dart';
import '../services/modules_integration_service.dart';

/// Segunda parte da implementação com o método build e widgets da UI
/// Este arquivo deve ser combinado com experimento_screen_updated.dart
part of 'experimento_screen_updated.dart';
// Não é necessário usar extension quando estamos usando 'part of'
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Experimento' : 'Novo Experimento'),
        backgroundColor: const Color(0xFF228B22),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!_isLoading && !_isSaving)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Salvar',
              onPressed: _salvarExperimento,
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _primaryColor),
                  const SizedBox(height: 16),
                  const Text('Carregando dados...'),
                ],
              ),
            )
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoSection(),
            const SizedBox(height: 24),
            _buildExperimentDataSection(),
            const SizedBox(height: 24),
            _buildAdditionalInfoSection(),
            const SizedBox(height: 24),
            _buildPhotoSection(),
            const SizedBox(height: 32),
            _buildSaveButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Seção de informações gerais
  Widget _buildInfoSection() {
    return _buildSection(
      'Informações Gerais',
      Icons.science,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo para nome do experimento
          TextFormField(
            controller: _nomeController,
            decoration: _inputDecoration(
              'Nome do Experimento', 
              Icons.edit,
              'Nome ou identificação do experimento',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Digite um nome para o experimento';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Seletor de talhão com limite de overflow corrigido
          EnhancedPlotSelector(
            initialValue: _talhaoId,
            onChanged: (value) {
              setState(() {
                _talhaoId = value;
              });
            },
            width: double.infinity,
          ),
          const SizedBox(height: 16),
          
          // Campo de texto livre para cultura
          FreeTextInput(
            initialValue: _culturaNome,
            onChanged: (value) {
              setState(() {
                _culturaNome = value;
              });
            },
            label: 'Cultura',
            hintText: 'Digite o nome da cultura',
            icon: Icons.eco,
            width: double.infinity,
          ),
          const SizedBox(height: 16),
          
          // Campo de texto livre para variedade
          FreeTextInput(
            initialValue: _variedadeNome,
            onChanged: (value) {
              setState(() {
                _variedadeNome = value;
              });
            },
            label: 'Variedade',
            hintText: 'Digite a variedade da cultura',
            icon: Icons.grass,
            width: double.infinity,
            isRequired: false,
          ),
        ],
      ),
    );
  }

  // Seção de dados do experimento (área, datas)
  Widget _buildExperimentDataSection() {
    return _buildSection(
      'Detalhes do Experimento',
      Icons.bar_chart,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo para área experimental
          TextFormField(
            controller: _areaController,
            decoration: _inputDecoration(
              'Área Experimental (ha)', 
              Icons.area_chart,
              'Área total do experimento em hectares',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Digite a área do experimento';
              }
              
              final number = double.tryParse(value);
              if (number == null) {
                return 'Digite um número válido';
              }
              
              if (number <= 0) {
                return 'A área deve ser maior que zero';
              }
              
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Seletor de data de início
          _buildDateSelector(
            label: 'Data de Início',
            selectedDate: _dataInicio,
            onDateChanged: (date) {
              setState(() {
                _dataInicio = date;
                
                // Se a data de fim for anterior à nova data de início, reset
                if (_dataFim != null && _dataFim!.isBefore(_dataInicio)) {
                  _dataFim = null;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Seletor de data de fim
          _buildDateSelector(
            label: 'Data de Fim (opcional)',
            selectedDate: _dataFim,
            onDateChanged: (date) {
              setState(() {
                _dataFim = date;
              });
            },
            isRequired: false,
            minDate: _dataInicio,
          ),
        ],
      ),
    );
  }

  // Seção para informações adicionais
  Widget _buildAdditionalInfoSection() {
    return _buildSection(
      'Informações Adicionais',
      Icons.description,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo para descrição
          TextFormField(
            controller: _descricaoController,
            decoration: _inputDecoration(
              'Descrição', 
              Icons.text_fields,
              'Descrição detalhada do experimento',
              maxLines: 3,
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Digite uma descrição para o experimento';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Campo para observações
          TextFormField(
            controller: _observacoesController,
            decoration: _inputDecoration(
              'Observações (opcional)', 
              Icons.note,
              'Observações adicionais sobre o experimento',
              maxLines: 3,
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // Seção para fotos
  Widget _buildPhotoSection() {
    return _buildSection(
      'Fotos',
      Icons.photo_library,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_fotos.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Icon(Icons.photo_album, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhuma foto adicionada',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _fotos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _primaryColor.withOpacity(0.5)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_fotos[index]),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _fotos.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _selecionarFoto,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Adicionar Foto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF228B22),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Botão de salvar
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _salvarExperimento,
        icon: _isSaving
            ? Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(2.0),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving
            ? 'Salvando...'
            : _isEditing
                ? 'Atualizar Experimento'
                : 'Salvar Experimento'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF228B22),
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primaryColor.withOpacity(0.5),
          disabledForegroundColor: Colors.white.withOpacity(0.7),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  // Widget auxiliar para seleção de data
  Widget _buildDateSelector({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onDateChanged,
    bool isRequired = true,
    DateTime? minDate,
  }) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            if (isRequired)
              Text(
                '*',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: minDate ?? DateTime(2020),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: _primaryColor,
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            
            if (picked != null) {
              onDateChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  selectedDate != null
                      ? dateFormat.format(selectedDate)
                      : 'Selecione uma data',
                  style: TextStyle(
                    color: selectedDate != null
                        ? Colors.black
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget para seção com título e conteúdo
  Widget _buildSection(String title, IconData icon, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A8E5D).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF2A8E5D)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A8E5D),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  // Decoração padrão para inputs
  InputDecoration _inputDecoration(
    String label, 
    IconData icon, 
    String hintText, {
    int? maxLines,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: maxLines == null ? Icon(icon) : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 40),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: const Color(0xFF2A8E5D).withOpacity(0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFF2A8E5D),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: maxLines != null
          ? const EdgeInsets.all(16)
          : const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }
}