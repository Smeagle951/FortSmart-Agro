import 'package:flutter/material.dart';
import '../../models/crop_management.dart';
import '../../repositories/crop_management_repository.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
// import 'premium_theme.dart'; // Removido

/// Tela para gerenciamento de plantas daninhas
class FarmWeedsScreen extends StatefulWidget {
  const FarmWeedsScreen({Key? key}) : super(key: key);

  @override
  State<FarmWeedsScreen> createState() => _FarmWeedsScreenState();
}

class _FarmWeedsScreenState extends State<FarmWeedsScreen> {
  final WeedRepository _repository = WeedRepository();
  bool _isLoading = true;
  String? _errorMessage;
  List<Weed> _weeds = [];

  @override
  void initState() {
    super.initState();
    _loadWeeds();
  }

  Future<void> _loadWeeds() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verificar se já existem plantas daninhas no banco de dados
      final weeds = await _repository.getAll();
      
      if (weeds.isEmpty) {
        // Se não existirem, inserir as plantas daninhas padrão
        await _repository.insertDefaultWeeds();
        // Recarregar a lista
        weeds.addAll(await _repository.getAll());
      }
      
      setState(() {
        _weeds = weeds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar plantas daninhas: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addWeed() async {
    final result = await showDialog<Weed>(
      context: context,
      builder: (context) => _WeedFormDialog(
        title: 'Nova Planta Daninha',
        saveButtonText: 'ADICIONAR',
      ),
    );

    if (result != null) {
      await _repository.insert(result);
      _loadWeeds();
    }
  }

  Future<void> _editWeed(Weed weed) async {
    final result = await showDialog<Weed>(
      context: context,
      builder: (context) => _WeedFormDialog(
        title: 'Editar Planta Daninha',
        saveButtonText: 'SALVAR',
        weed: weed,
      ),
    );

    if (result != null) {
      await _repository.update(result);
      _loadWeeds();
    }
  }

  Future<void> _deleteWeed(Weed weed) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir a planta daninha "${weed.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('EXCLUIR'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.delete(weed.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Planta daninha excluída com sucesso')),
        );
        _loadWeeds();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir planta daninha: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Fundo cinza claro para a tela
      appBar: AppBar(
        title: const Text('Plantas Daninhas'),
        backgroundColor: Colors.green, // Cor primária para a AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeeds,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWeed,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadWeeds,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_weeds.isEmpty) {
      return EmptyState(
        icon: Icons.grass,
        title: 'Nenhuma planta daninha cadastrada',
        message: 'Cadastre as plantas daninhas que afetam suas culturas',
        actionText: 'Adicionar Planta Daninha',
        onAction: _addWeed,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _weeds.length,
      itemBuilder: (context, index) {
        final weed = _weeds[index];
        return _buildWeedCard(weed);
      },
    );
  }

  Widget _buildWeedCard(Weed weed) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      color: Colors.blue.shade900.withOpacity(0.9), // Fundo escuro para melhor contraste
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    weed.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Texto branco para contraste com fundo escuro
                    ),
                  ),
                ),
                _buildWeedMenu(weed),
              ],
            ),
            if (weed.notes != null && weed.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                weed.notes!,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Origem: ${weed.origin == OriginType.standard ? 'Padrão' : 'Personalizada'}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeedMenu(Weed weed) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _editWeed(weed);
            break;
          case 'delete':
            _deleteWeed(weed);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Editar'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Excluir', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Diálogo para adicionar ou editar uma planta daninha
class _WeedFormDialog extends StatefulWidget {
  final String title;
  final String saveButtonText;
  final Weed? weed;

  const _WeedFormDialog({
    Key? key,
    required this.title,
    required this.saveButtonText,
    this.weed,
  }) : super(key: key);

  @override
  State<_WeedFormDialog> createState() => _WeedFormDialogState();
}

class _WeedFormDialogState extends State<_WeedFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.weed != null) {
      _nameController.text = widget.weed!.name;
      if (widget.weed!.notes != null) {
        _notesController.text = widget.weed!.notes!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final weed = Weed(
        id: widget.weed?.id,
        name: _nameController.text.trim(),
        origin: widget.weed?.origin ?? OriginType.custom,
        createdBy: widget.weed?.createdBy ?? 'user_id', // Substituir pelo ID do usuário atual
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.weed?.createdAt,
        updatedAt: DateTime.now(),
      );

      Navigator.pop(context, weed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da planta daninha *',
                  hintText: 'Ex: Buva, Capim-amargoso',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe o nome da planta daninha';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                  hintText: 'Informações adicionais sobre a planta daninha',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(widget.saveButtonText),
        ),
      ],
    );
  }
}
