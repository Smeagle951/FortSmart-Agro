import 'package:flutter/material.dart';
import '../../models/farm.dart';
import '../../services/farm_service.dart';
import '../../utils/wrappers/notifications_wrapper.dart';
import '../../widgets/loading_indicator.dart';

class FarmAddScreen extends StatefulWidget {
  const FarmAddScreen({Key? key}) : super(key: key);

  @override
  _FarmAddScreenState createState() => _FarmAddScreenState();
}

class _FarmAddScreenState extends State<FarmAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _notificationsWrapper = NotificationsWrapper();
  final _farmService = FarmService();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveFarm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Criando um objeto Farm com todos os campos obrigatórios
      final farm = Farm(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Gerando um ID único baseado no timestamp
        name: _nameController.text,
        address: _addressController.text,
        logoUrl: null,
        isActive: true,
        plots: [],
        responsiblePerson: null,
        documentNumber: null,
        phone: null,
        email: null,
        totalArea: 0.0,
        plotsCount: 0,
        crops: [], // Inicializando com lista vazia
        cultivationSystem: null,
        hasIrrigation: false,
        irrigationType: null,
        mechanizationLevel: null,
        technicalResponsibleName: null,
        technicalResponsibleId: null,
        documents: [], // Inicializando a lista de documentos
        isVerified: false, // Inicializando como não verificado
        createdAt: DateTime.now(), // Adicionando data de criação
        updatedAt: DateTime.now(), // Adicionando data de atualização
      );
      
      print('🔄 Salvando fazenda: ${farm.name}');
      print('📊 ID gerado: ${farm.id}');
      print('📊 Endereço: ${farm.address}');
      print('📊 Área: ${farm.totalArea}');
      
      final farmId = await _farmService.addFarm(farm);
      print('✅ Fazenda salva com ID: $farmId');
      
      _notificationsWrapper.showNotificationWithContext(
        context: context,
        message: 'Fazenda adicionada com sucesso!',
        title: 'Sucesso',
        type: NotificationType.success,
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      _notificationsWrapper.showNotificationWithContext(
        context: context,
        message: 'Erro ao salvar fazenda: $e',
        title: 'Erro',
        type: NotificationType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Fazenda'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Fazenda',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o nome da fazenda';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Endereço',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o endereço da fazenda';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveFarm,
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('SALVAR FAZENDA'),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading) const LoadingIndicator(),
        ],
      ),
    );
  }
}
