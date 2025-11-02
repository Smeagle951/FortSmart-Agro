import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/farm.dart';
import '../../services/farm_service.dart';
import '../../repositories/talhao_repository.dart';
import '../../services/base44_sync_service.dart';
import '../../utils/logger.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/app_colors.dart';

/// Tela de Perfil da Fazenda - Criação e Visualização
/// Preparada para sincronização com o sistema Base44
class FarmProfileScreen extends StatefulWidget {
  final String? farmId;

  const FarmProfileScreen({
    super.key,
    this.farmId,
  });

  @override
  State<FarmProfileScreen> createState() => _FarmProfileScreenState();
}

class _FarmProfileScreenState extends State<FarmProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _farmService = FarmService();
  final _talhaoRepository = TalhaoRepository();
  final _base44SyncService = Base44SyncService();

  // Controllers para os campos
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _documentController = TextEditingController();

  Farm? _farm;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSyncing = false;

  // Dados calculados da fazenda
  double _totalHectares = 0.0;
  int _totalTalhoes = 0;
  List<String> _culturas = [];

  @override
  void initState() {
    super.initState();
    _loadFarmData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  /// Carrega os dados da fazenda
  Future<void> _loadFarmData() async {
    try {
      setState(() => _isLoading = true);

      Farm? farm;
      
      if (widget.farmId != null) {
        farm = await _farmService.getFarmById(widget.farmId!);
      } else {
        farm = await _farmService.getCurrentFarm();
      }

      if (farm != null) {
        setState(() {
          _farm = farm;
          _populateControllers();
          _isEditing = false;
        });
        
        await _calculateFarmData();
      } else {
        // Se não há fazenda, habilita o modo de edição para criar uma nova
        setState(() {
          _isEditing = true;
        });
      }
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados da fazenda: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'Erro ao carregar dados da fazenda');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Preenche os controllers com os dados da fazenda
  void _populateControllers() {
    if (_farm != null) {
      _nameController.text = _farm!.name;
      _addressController.text = _farm!.address;
      _cityController.text = _farm!.municipality ?? '';
      _stateController.text = _farm!.state ?? '';
      _ownerController.text = _farm!.ownerName ?? '';
      _phoneController.text = _farm!.phone ?? '';
      _emailController.text = _farm!.email ?? '';
      _documentController.text = _farm!.documentNumber ?? '';
    }
  }

  /// Calcula os dados da fazenda (hectares, talhões, culturas)
  Future<void> _calculateFarmData() async {
    try {
      Logger.info('📊 Calculando dados da fazenda...');

      // Buscar todos os talhões da fazenda
      final talhoes = await _talhaoRepository.getTalhoes();
      
      // Calcular total de hectares
      double totalHectares = 0.0;
      Set<String> culturasSet = {};

      for (var talhao in talhoes) {
        totalHectares += talhao.area;
        
        // Coletar culturas das safras
        for (var safra in talhao.safras) {
          if (safra.culturaNome.isNotEmpty) {
            culturasSet.add(safra.culturaNome);
          }
        }
      }

      // Adicionar culturas do modelo Farm também
      if (_farm != null && _farm!.crops.isNotEmpty) {
        culturasSet.addAll(_farm!.crops);
      }

      setState(() {
        _totalHectares = totalHectares;
        _totalTalhoes = talhoes.length;
        _culturas = culturasSet.toList();
      });

      Logger.info('✅ Dados calculados: ${_totalHectares.toStringAsFixed(2)} ha, $_totalTalhoes talhões, ${_culturas.length} culturas');
    } catch (e) {
      Logger.error('❌ Erro ao calcular dados da fazenda: $e');
    }
  }

  /// Salva os dados da fazenda
  Future<void> _saveFarmData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Logger.info('💾 Salvando dados da fazenda...');

      Farm farmToSave;

      if (_farm != null) {
        // Atualizar fazenda existente
        farmToSave = _farm!.copyWith(
          name: _nameController.text,
          address: _addressController.text,
          municipality: _cityController.text.isEmpty ? null : _cityController.text,
          state: _stateController.text.isEmpty ? null : _stateController.text,
          ownerName: _ownerController.text.isEmpty ? null : _ownerController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          documentNumber: _documentController.text.isEmpty ? null : _documentController.text,
          totalArea: _totalHectares,
          plotsCount: _totalTalhoes,
          crops: _culturas,
        );

        await _farmService.updateFarm(farmToSave);
        Logger.info('✅ Fazenda atualizada com sucesso');
      } else {
        // Criar nova fazenda
        farmToSave = Farm(
          name: _nameController.text,
          address: _addressController.text,
          municipality: _cityController.text.isEmpty ? null : _cityController.text,
          state: _stateController.text.isEmpty ? null : _stateController.text,
          ownerName: _ownerController.text.isEmpty ? null : _ownerController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          documentNumber: _documentController.text.isEmpty ? null : _documentController.text,
          totalArea: _totalHectares,
          plotsCount: _totalTalhoes,
          crops: _culturas,
          hasIrrigation: false,
        );

        await _farmService.addFarm(farmToSave);
        Logger.info('✅ Fazenda criada com sucesso');
      }

      setState(() {
        _farm = farmToSave;
        _isEditing = false;
      });

      // Recalcular dados após salvar
      await _calculateFarmData();

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          _farm != null ? 'Fazenda atualizada com sucesso!' : 'Fazenda criada com sucesso!',
        );
      }
    } catch (e) {
      Logger.error('❌ Erro ao salvar fazenda: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'Erro ao salvar fazenda: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Sincroniza com o Base44
  Future<void> _syncWithBase44() async {
    if (_farm == null) {
      SnackbarHelper.showWarning(context, 'Salve a fazenda antes de sincronizar');
      return;
    }

    setState(() => _isSyncing = true);

    try {
      Logger.info('🔄 Iniciando sincronização com Base44...');

      final result = await _base44SyncService.syncFarm(_farm!);

      if (result['success'] == true) {
        Logger.info('✅ Sincronização com Base44 concluída');
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Sincronização concluída com sucesso!');
        }
      } else {
        throw Exception(result['message'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      Logger.error('❌ Erro ao sincronizar com Base44: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'Erro ao sincronizar: $e');
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Perfil da Fazenda'),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando dados da fazenda...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_farm != null ? 'Perfil da Fazenda' : 'Nova Fazenda'),
        backgroundColor: AppColors.primary,
        actions: [
          if (_farm != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Editar',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _isEditing = false);
                _populateControllers();
              },
              tooltip: 'Cancelar',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header com dados calculados
              if (_farm != null) _buildDataSummaryCard(),
              
              const SizedBox(height: 24),

              // Informações Básicas
              _buildSectionTitle('Informações Básicas'),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _nameController,
                label: 'Nome da Fazenda',
                icon: Icons.agriculture,
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _addressController,
                label: 'Endereço',
                icon: Icons.location_on,
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Endereço é obrigatório';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cityController,
                      label: 'Cidade',
                      icon: Icons.location_city,
                      enabled: _isEditing,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _stateController,
                      label: 'Estado',
                      icon: Icons.map,
                      enabled: _isEditing,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Dados do Proprietário
              _buildSectionTitle('Dados do Proprietário'),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _ownerController,
                label: 'Nome do Proprietário',
                icon: Icons.person,
                enabled: _isEditing,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _documentController,
                label: 'CPF/CNPJ',
                icon: Icons.badge,
                enabled: _isEditing,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 24),

              // Contato
              _buildSectionTitle('Contato'),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _phoneController,
                label: 'Telefone',
                icon: Icons.phone,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailController,
                label: 'E-mail',
                icon: Icons.email,
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 32),

              // Botões de ação
              if (_isEditing)
                ElevatedButton.icon(
                  onPressed: _saveFarmData,
                  icon: const Icon(Icons.save),
                  label: Text(_farm != null ? 'Salvar Alterações' : 'Criar Fazenda'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

              if (_farm != null && !_isEditing) ...[
                ElevatedButton.icon(
                  onPressed: _isSyncing ? null : _syncWithBase44,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.sync),
                  label: Text(_isSyncing ? 'Sincronizando...' : 'Sincronizar com Base44'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showSyncHistory(),
                  icon: const Icon(Icons.history),
                  label: const Text('Histórico de Sincronização'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Card com resumo dos dados calculados
  Widget _buildDataSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _farm!.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _farm!.address,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Hectares',
                    _totalHectares.toStringAsFixed(2).replaceAll('.', ','),
                    Icons.area_chart,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Talhões',
                    _totalTalhoes.toString(),
                    Icons.grid_view,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Culturas',
                    _culturas.length.toString(),
                    Icons.grass,
                  ),
                ),
              ],
            ),
            if (_culturas.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              const Text(
                'Culturas Existentes:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _culturas.map((cultura) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cultura,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Item de estatística no card de resumo
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Título de seção
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  /// Campo de texto customizado
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade50,
      ),
    );
  }

  /// Mostra o histórico de sincronização
  void _showSyncHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Histórico de Sincronização'),
        content: const Text(
          'Funcionalidade em desenvolvimento.\n\n'
          'Aqui você poderá ver todo o histórico de sincronizações com o sistema Base44.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

