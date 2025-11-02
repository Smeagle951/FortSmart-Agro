import 'package:flutter/material.dart';
import '../../../../../models/canteiro_model.dart';
import '../../../../../database/app_database.dart';
import '../../../../../widgets/elegant_canteiro_2d_widget.dart';

/// Tela elegante para criação de canteiros com visualização 2D
/// Estrutura padrão 7x3 (21 posições) conforme especificado
class ElegantCanteiroCreationScreen extends StatefulWidget {
  const ElegantCanteiroCreationScreen({super.key});

  @override
  State<ElegantCanteiroCreationScreen> createState() => _ElegantCanteiroCreationScreenState();
}

class _ElegantCanteiroCreationScreenState extends State<ElegantCanteiroCreationScreen>
    with TickerProviderStateMixin {
  
  // Controllers
  final _nomeController = TextEditingController();
  final _culturaController = TextEditingController();
  final _variedadeController = TextEditingController();
  final _loteIdController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  // Estado
  bool _isLoading = false;
  String _status = 'ativo';
  String? _selectedPosition;
  
  // Animação
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Canteiro temporário para preview
  CanteiroModel? _previewCanteiro;

  @override
  void initState() {
    super.initState();
    
    // Configurar animações
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    
    // Criar preview inicial
    _createPreviewCanteiro();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nomeController.dispose();
    _culturaController.dispose();
    _variedadeController.dispose();
    _loteIdController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildFormSection(),
                const SizedBox(height: 24),
                _buildPreviewSection(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Criar Canteiro Elegante',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.green.shade600,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          onPressed: _showHelp,
          icon: const Icon(Icons.help_outline),
          tooltip: 'Ajuda',
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade600,
            Colors.blue.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.grid_view,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Canteiro de Germinação',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Estrutura 3x7 - 21 posições de teste',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📐 Estrutura do Canteiro 3x7',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Linhas (1-3) = blocos de repetição\nColunas (A-G) = diferentes lotes ou tratamentos\nTotal = 21 posições de teste',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações do Canteiro',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 20),
            _buildFormFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _nomeController,
          label: 'Nome do Canteiro',
          hint: 'Ex: Canteiro Principal, Canteiro Experimental',
          icon: Icons.grid_view,
          onChanged: (_) => _updatePreview(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _culturaController,
                label: 'Cultura',
                hint: 'Ex: Soja, Milho',
                icon: Icons.eco,
                onChanged: (_) => _updatePreview(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _variedadeController,
                label: 'Variedade',
                hint: 'Ex: BRS 284',
                icon: Icons.science,
                onChanged: (_) => _updatePreview(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _loteIdController,
          label: 'ID do Lote',
          hint: 'Ex: LOTE001',
          icon: Icons.tag,
          onChanged: (_) => _updatePreview(),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _observacoesController,
          label: 'Observações (Opcional)',
          hint: 'Informações adicionais sobre o canteiro',
          icon: Icons.note,
          maxLines: 3,
          onChanged: (_) => _updatePreview(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.green.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.preview,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Preview do Canteiro',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_previewCanteiro != null)
              ElegantCanteiro2DWidget(
                canteiro: _previewCanteiro,
                onPositionTap: _onPositionTap,
                onPositionLongPress: _onPositionLongPress,
                interactive: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _createCanteiro,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.add_circle, size: 24),
            label: Text(
              _isLoading ? 'Criando Canteiro...' : 'Criar Canteiro Elegante',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _resetForm,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text(
              'Limpar Formulário',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _createPreviewCanteiro() {
    final posicoes = <CanteiroPosition>[];
    
    // Criar 21 posições (3x7)
    for (int row = 1; row <= 3; row++) {
      for (int col = 0; col < 7; col++) {
        final letter = String.fromCharCode(65 + col); // A, B, C, D, E, F, G
        final position = '$letter$row';
        
        posicoes.add(CanteiroPosition(
          posicao: position,
          cor: Colors.green.value,
          germinadas: 0,
          total: 0,
          percentual: 0.0,
          dadosDiarios: {},
        ));
      }
    }
    
    _previewCanteiro = CanteiroModel(
      id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
      nome: 'Preview Canteiro',
      loteId: 'PREVIEW',
      cultura: 'Preview',
      variedade: 'Preview',
      dataCriacao: DateTime.now(),
      status: 'ativo',
      posicoes: posicoes,
      dadosAgronomicos: {},
      observacoes: '',
    );
  }

  void _updatePreview() {
    if (_previewCanteiro == null) return;
    
    setState(() {
      _previewCanteiro = _previewCanteiro!.copyWith(
        nome: _nomeController.text.isNotEmpty ? _nomeController.text : 'Preview Canteiro',
        loteId: _loteIdController.text.isNotEmpty ? _loteIdController.text : 'PREVIEW',
        cultura: _culturaController.text.isNotEmpty ? _culturaController.text : 'Preview',
        variedade: _variedadeController.text.isNotEmpty ? _variedadeController.text : 'Preview',
        observacoes: _observacoesController.text,
      );
    });
  }

  void _onPositionTap(String position) {
    setState(() {
      _selectedPosition = position;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Posição $position selecionada'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onPositionLongPress(String position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Posição $position'),
        content: const Text('Esta posição estará disponível para colocar testes de germinação.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _createCanteiro() async {
    if (_nomeController.text.isEmpty || 
        _culturaController.text.isEmpty || 
        _variedadeController.text.isEmpty || 
        _loteIdController.text.isEmpty) {
      _showError('Por favor, preencha todos os campos obrigatórios.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final posicoes = <CanteiroPosition>[];
      
      // Criar 21 posições (3x7)
      for (int row = 1; row <= 3; row++) {
        for (int col = 0; col < 7; col++) {
          final letter = String.fromCharCode(65 + col); // A, B, C, D, E, F, G
          final position = '$letter$row';
          
          posicoes.add(CanteiroPosition(
            posicao: position,
            cor: Colors.green.value,
            germinadas: 0,
            total: 0,
            percentual: 0.0,
            dadosDiarios: {},
          ));
        }
      }

      final canteiro = CanteiroModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nome: _nomeController.text,
        loteId: _loteIdController.text,
        cultura: _culturaController.text,
        variedade: _variedadeController.text,
        dataCriacao: DateTime.now(),
        status: _status,
        posicoes: posicoes,
        dadosAgronomicos: {},
        observacoes: _observacoesController.text,
      );

      // Salvar no banco
      await _saveCanteiroToDatabase(canteiro);
      
      // Sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Canteiro "${canteiro.nome}" criado com sucesso!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Voltar para a tela anterior
        Navigator.pop(context, canteiro);
      }
      
    } catch (e) {
      _showError('Erro ao criar canteiro: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveCanteiroToDatabase(CanteiroModel canteiro) async {
    final database = await AppDatabase.instance.database;
    
    // Inserir canteiro
    await database.insert('canteiros', {
      'id': canteiro.id,
      'nome': canteiro.nome,
      'lote_id': canteiro.loteId,
      'cultura': canteiro.cultura,
      'variedade': canteiro.variedade,
      'data_criacao': canteiro.dataCriacao.toIso8601String(),
      'data_conclusao': canteiro.dataConclusao?.toIso8601String(),
      'status': canteiro.status,
      'observacoes': canteiro.observacoes,
    });
    
    // Inserir posições
    for (final posicao in canteiro.posicoes) {
      await database.insert('canteiro_posicoes', {
        'canteiro_id': canteiro.id,
        'posicao': posicao.posicao,
        'cor': posicao.cor,
        'germinadas': posicao.germinadas,
        'total': posicao.total,
        'percentual': posicao.percentual,
        'dados_diarios': posicao.dadosDiarios.toString(),
      });
    }
  }

  void _resetForm() {
    _nomeController.clear();
    _culturaController.clear();
    _variedadeController.clear();
    _loteIdController.clear();
    _observacoesController.clear();
    _selectedPosition = null;
    _updatePreview();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda - Canteiro Elegante'),
        content: const SingleChildScrollView(
          child: Text(
            'Este canteiro segue a estrutura padrão 3x7:\n\n'
            '• 3 linhas (1-3) = blocos de repetição\n'
            '• 7 colunas (A-G) = diferentes lotes/tratamentos\n'
            '• Total = 21 posições de teste\n\n'
            'Cada posição pode receber um teste de germinação.\n\n'
            'Toque em uma posição para selecioná-la.\n'
            'Mantenha pressionado para ver informações.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
}
