import 'package:flutter/material.dart';
import '../../../models/new_culture_model.dart';
import '../../../models/crop_variety.dart';
import '../../../repositories/crop_variety_repository.dart';

/// Diálogo para adicionar nova variedade
class AddVarietyDialog extends StatefulWidget {
  final NewCulture culture;
  final VoidCallback onVarietyAdded;

  const AddVarietyDialog({
    super.key,
    required this.culture,
    required this.onVarietyAdded,
  });

  @override
  State<AddVarietyDialog> createState() => _AddVarietyDialogState();
}

class _AddVarietyDialogState extends State<AddVarietyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _varietyRepository = CropVarietyRepository();
  
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cycleDaysController = TextEditingController();
  final _characteristicsController = TextEditingController();
  final _yieldValueController = TextEditingController();
  final _recommendedPopulationController = TextEditingController();
  final _weightOf1000SeedsController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    _cycleDaysController.dispose();
    _characteristicsController.dispose();
    _yieldValueController.dispose();
    _recommendedPopulationController.dispose();
    _weightOf1000SeedsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nova Variedade - ${widget.culture.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const Divider(),
            
            // Formulário
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Nome da variedade
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome da Variedade *',
                          border: OutlineInputBorder(),
                          hintText: 'Ex: BRS 284, Pioneer 30F53',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nome da variedade é obrigatório';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Empresa
                      TextFormField(
                        controller: _companyController,
                        decoration: const InputDecoration(
                          labelText: 'Empresa Desenvolvedora',
                          border: OutlineInputBorder(),
                          hintText: 'Ex: Embrapa, Pioneer, Syngenta',
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Descrição
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          border: OutlineInputBorder(),
                          hintText: 'Descrição geral da variedade',
                        ),
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Características
                      TextFormField(
                        controller: _characteristicsController,
                        decoration: const InputDecoration(
                          labelText: 'Características',
                          border: OutlineInputBorder(),
                          hintText: 'Características específicas da variedade',
                        ),
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Ciclo em dias
                      TextFormField(
                        controller: _cycleDaysController,
                        decoration: const InputDecoration(
                          labelText: 'Ciclo (dias)',
                          border: OutlineInputBorder(),
                          hintText: 'Ex: 120',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final days = int.tryParse(value);
                            if (days == null || days <= 0) {
                              return 'Digite um número válido de dias';
                            }
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Produtividade esperada
                      TextFormField(
                        controller: _yieldValueController,
                        decoration: const InputDecoration(
                          labelText: 'Produtividade Esperada (sc/ha)',
                          border: OutlineInputBorder(),
                          hintText: 'Ex: 60.5',
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // População recomendada
                      TextFormField(
                        controller: _recommendedPopulationController,
                        decoration: const InputDecoration(
                          labelText: 'População Recomendada (plantas/ha)',
                          border: OutlineInputBorder(),
                          hintText: 'Ex: 250000',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Peso de mil sementes
                      TextFormField(
                        controller: _weightOf1000SeedsController,
                        decoration: const InputDecoration(
                          labelText: 'Peso de Mil Sementes (g)',
                          border: OutlineInputBorder(),
                          hintText: 'Ex: 150.5',
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Observações
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Observações',
                          border: OutlineInputBorder(),
                          hintText: 'Informações adicionais',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botões
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveVariety,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.culture.color,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveVariety() async {
    print('🔍 DEBUG: _saveVariety() chamado!');
    print('🔍 DEBUG: culture.id = ${widget.culture.id}');
    print('🔍 DEBUG: culture.name = ${widget.culture.name}');
    
    if (_formKey.currentState!.validate()) {
      print('🔍 DEBUG: Formulário validado com sucesso!');
      try {
        print('🔍 DEBUG: Criando objeto CropVariety...');
        
        // CORREÇÃO: Mapear nome da cultura para ID numérico
        final cropIdMap = {
          'soja': '10', 'milho': '2', 'algodao': '3', 'algodão': '3',
          'feijao': '4', 'feijão': '4', 'girassol': '5', 'arroz': '14',
          'sorgo': '16', 'trigo': '13', 'aveia': '11', 'gergelim': '12',
          'cana-de-acucar': '15', 'cana_acucar': '15', 'tomate': '17',
        };
        
        final culturaNome = widget.culture.id.toLowerCase();
        final cropIdNumerico = cropIdMap[culturaNome] ?? widget.culture.id;
        
        print('🔍 DEBUG: culture.id original: ${widget.culture.id}');
        print('🔍 DEBUG: cropId numérico: $cropIdNumerico');
        
        final variety = CropVariety(
          cropId: cropIdNumerico,
          name: _nameController.text,
          company: _companyController.text.isEmpty ? null : _companyController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          characteristics: _characteristicsController.text.isEmpty ? null : _characteristicsController.text,
          cycleDays: _cycleDaysController.text.isNotEmpty 
              ? int.tryParse(_cycleDaysController.text) 
              : null,
          yieldValue: _yieldValueController.text.isNotEmpty 
              ? double.tryParse(_yieldValueController.text) 
              : null,
          recommendedPopulation: _recommendedPopulationController.text.isNotEmpty 
              ? double.tryParse(_recommendedPopulationController.text) 
              : null,
          weightOf1000Seeds: _weightOf1000SeedsController.text.isNotEmpty 
              ? double.tryParse(_weightOf1000SeedsController.text) 
              : null,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

        print('🔍 DEBUG: CropVariety criado: ${variety.name}');
        print('🔍 DEBUG: Chamando _varietyRepository.insert()...');
        
        // Salvar no banco de dados usando o repositório
        await _varietyRepository.insert(variety);
        
        print('✅ DEBUG: Variedade salva com sucesso!');
        
        Navigator.pop(context);
        widget.onVarietyAdded();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Variedade "${variety.name}" adicionada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('❌ DEBUG: Erro em _saveVariety(): $e');
        print('❌ DEBUG: Stack trace: ${StackTrace.current}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar variedade: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print('⚠️ DEBUG: Formulário NÃO validado!');
    }
  }
}
