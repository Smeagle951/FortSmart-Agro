import 'package:flutter/material.dart';
import '../models/application_target_model.dart';
import '../../../utils/app_colors.dart';

class ApplicationTargetsSection extends StatelessWidget {
  final List<String> selectedTargetIds;
  final List<ApplicationTargetModel> availableTargets;
  final ApplicationControlType controlType;
  final Function(List<String>) onTargetsChanged;
  final Function(ApplicationControlType) onControlTypeChanged;
  
  const ApplicationTargetsSection({
    Key? key,
    required this.selectedTargetIds,
    required this.availableTargets,
    required this.controlType,
    required this.onTargetsChanged,
    required this.onControlTypeChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Controle e Alvos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Tipos de controle
            const Text(
              'Tipos de Controle',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Checkbox para pragas
            CheckboxListTile(
              title: const Text('Pragas'),
              value: controlType.controlsPests,
              onChanged: (value) {
                if (value != null) {
                  onControlTypeChanged(
                    ApplicationControlType(
                      controlsPests: value,
                      controlsDiseases: controlType.controlsDiseases,
                      controlsWeeds: controlType.controlsWeeds,
                    ),
                  );
                }
              },
              activeColor: AppColors.primaryColor,
              contentPadding: EdgeInsets.zero,
            ),
            
            // Checkbox para doenças
            CheckboxListTile(
              title: const Text('Doenças'),
              value: controlType.controlsDiseases,
              onChanged: (value) {
                if (value != null) {
                  onControlTypeChanged(
                    ApplicationControlType(
                      controlsPests: controlType.controlsPests,
                      controlsDiseases: value,
                      controlsWeeds: controlType.controlsWeeds,
                    ),
                  );
                }
              },
              activeColor: AppColors.primaryColor,
              contentPadding: EdgeInsets.zero,
            ),
            
            // Checkbox para plantas daninhas
            CheckboxListTile(
              title: const Text('Plantas Daninhas'),
              value: controlType.controlsWeeds,
              onChanged: (value) {
                if (value != null) {
                  onControlTypeChanged(
                    ApplicationControlType(
                      controlsPests: controlType.controlsPests,
                      controlsDiseases: controlType.controlsDiseases,
                      controlsWeeds: value,
                    ),
                  );
                }
              },
              activeColor: AppColors.primaryColor,
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Alvos específicos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Alvos Específicos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Selecionar'),
                  onPressed: () => _showTargetSelectionDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Lista de alvos selecionados
            if (selectedTargetIds.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Nenhum alvo específico selecionado',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedTargetIds.map((targetId) {
                  final target = availableTargets.firstWhere(
                    (t) => t.id == targetId,
                    orElse: () => ApplicationTargetModel(
                      name: 'Desconhecido',
                      type: TargetType.pest,
                    ),
                  );
                  
                  return Chip(
                    label: Text(target.name),
                    avatar: Text(target.icon),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      onTargetsChanged(
                        selectedTargetIds.where((id) => id != targetId).toList(),
                      );
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
  
  void _showTargetSelectionDialog(BuildContext context) {
    // Filtrar alvos disponíveis com base nos tipos de controle selecionados
    final List<ApplicationTargetModel> filteredTargets = [];
    
    if (controlType.controlsPests) {
      filteredTargets.addAll(
        availableTargets.where((target) => target.type == TargetType.pest),
      );
    }
    
    if (controlType.controlsDiseases) {
      filteredTargets.addAll(
        availableTargets.where((target) => target.type == TargetType.disease),
      );
    }
    
    if (controlType.controlsWeeds) {
      filteredTargets.addAll(
        availableTargets.where((target) => target.type == TargetType.weed),
      );
    }
    
    // Ordenar por tipo e nome
    filteredTargets.sort((a, b) {
      if (a.type != b.type) {
        return a.type.index - b.type.index;
      }
      return a.name.compareTo(b.name);
    });
    
    // Lista temporária para armazenar as seleções durante o diálogo
    final List<String> tempSelectedIds = List.from(selectedTargetIds);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Selecione os Alvos'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: filteredTargets.isEmpty
                  ? const Center(
                      child: Text('Nenhum alvo disponível para os tipos de controle selecionados'),
                    )
                  : ListView.builder(
                      itemCount: filteredTargets.length,
                      itemBuilder: (context, index) {
                        final target = filteredTargets[index];
                        final isSelected = tempSelectedIds.contains(target.id);
                        
                        // Adicionar cabeçalho para cada tipo de alvo
                        if (index == 0 || filteredTargets[index - 1].type != target.type) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (index > 0) const Divider(),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  _getTargetTypeHeader(target.type),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                              CheckboxListTile(
                                title: Text(target.name),
                                subtitle: target.scientificName != null
                                    ? Text(
                                        target.scientificName!,
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      if (!tempSelectedIds.contains(target.id)) {
                                        tempSelectedIds.add(target.id);
                                      }
                                    } else {
                                      tempSelectedIds.remove(target.id);
                                    }
                                  });
                                },
                                activeColor: AppColors.primaryColor,
                              ),
                            ],
                          );
                        }
                        
                        return CheckboxListTile(
                          title: Text(target.name),
                          subtitle: target.scientificName != null
                              ? Text(
                                  target.scientificName!,
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                if (!tempSelectedIds.contains(target.id)) {
                                  tempSelectedIds.add(target.id);
                                }
                              } else {
                                tempSelectedIds.remove(target.id);
                              }
                            });
                          },
                          activeColor: AppColors.primaryColor,
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  onTargetsChanged(tempSelectedIds);
                  Navigator.pop(context);
                },
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  String _getTargetTypeHeader(TargetType type) {
    switch (type) {
      case TargetType.pest:
        return 'PRAGAS';
      case TargetType.disease:
        return 'DOENÇAS';
      case TargetType.weed:
        return 'PLANTAS DANINHAS';
    }
  }
}
