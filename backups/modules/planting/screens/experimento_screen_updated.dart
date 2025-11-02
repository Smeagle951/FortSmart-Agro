import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/experimento_model.dart';
import '../services/experimento_service.dart';
import '../services/modules_integration_service.dart';

class ExperimentoScreenUpdated extends StatefulWidget {
  final ExperimentoModel? experimento;

  const ExperimentoScreenUpdated({Key? key, this.experimento}) : super(key: key);

  @override
  _ExperimentoScreenUpdatedState createState() => _ExperimentoScreenUpdatedState();
}

class _ExperimentoScreenUpdatedState extends State<ExperimentoScreenUpdated> {
  final _formKey = GlobalKey<FormState>();
  final _experimento = ExperimentoService();
  final _modulesService = ModulesIntegrationService();
  
  // Controllers
  final _nomeController = TextEditingController();
  final _areaController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  // Dados
  String? _talhaoId;
  String? _culturaId;
  String? _variedadeId;
  String? _culturaNome;
  String? _variedadeNome;
  DateTime _dataInicio = DateTime.now();
  DateTime? _dataFim;
  List<String> _fotos = [];
  
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditing = false;
  
  // Cores do tema para melhor aparência visual
  final Color _primaryColor = const Color(0xFF2A8E5D); // Verde principal
  final Color _backgroundColor = const Color(0xFFF5F9F5); // Fundo suave
  final Color _cardColor = Colors.white; // Cor dos cards

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }
  
  // Carregar dados do experimento se estiver em modo de edição
  Future<void> _carregarDados() async {
    if (widget.experimento != null) {
      setState(() => _isLoading = true);
      try {
        final experimento = widget.experimento;
        if (experimento != null) {
          setState(() {
            _isEditing = true;
            _nomeController.text = experimento.nome;
            _talhaoId = experimento.talhaoId;
            _culturaId = experimento.culturaId;
            _variedadeId = experimento.variedadeId;
            _culturaNome = experimento.culturaNome;
            _variedadeNome = experimento.variedadeNome;
            _dataInicio = experimento.dataInicio;
            _dataFim = experimento.dataFim;
            _areaController.text = experimento.area.toString();
            _descricaoController.text = experimento.descricao;
            _observacoesController.text = experimento.observacoes ?? '';
            _fotos = experimento.fotos ?? [];
          });
        }
      } catch (e) {
        _mostrarErro('Erro ao carregar dados: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Método auxiliar para mostrar erros
  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: const Color(0xFF228B22),
      ),
    );
  }

  // Método para salvar o experimento
  Future<void> _salvarExperimento() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_talhaoId == null) {
      _mostrarErro('Selecione um talhão');
      return;
    }
    
    if (_culturaNome == null || _culturaNome!.isEmpty) {
      _mostrarErro('Digite o nome da cultura');
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final experimento = ExperimentoModel(
        id: widget.experimento?.id,
        nome: _nomeController.text,
        talhaoId: _talhaoId!,
        culturaId: _culturaId,
        variedadeId: _variedadeId,
        culturaNome: _culturaNome!,
        variedadeNome: _variedadeNome,
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        area: double.tryParse(_areaController.text) ?? 0.0,
        descricao: _descricaoController.text,
        observacoes: _observacoesController.text,
        fotos: _fotos,
        createdAt: widget.experimento?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      if (_isEditing) {
        await _experimento.update(experimento);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Experimento atualizado com sucesso!'),
            backgroundColor: const Color(0xFF228B22),
          ),
        );
      } else {
        await _experimento.create(experimento);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Experimento criado com sucesso!'),
            backgroundColor: const Color(0xFF228B22),
          ),
        );
      }
      
      Navigator.pop(context, true);
    } catch (e) {
      _mostrarErro('Erro ao salvar experimento: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Método para selecionar/capturar fotos
  Future<void> _selecionarFoto() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    
    if (source != null) {
      try {
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1280,
          maxHeight: 720,
          imageQuality: 85,
        );
        
        if (pickedFile != null) {
          setState(() {
            _fotos.add(pickedFile.path);
          });
        }
      } catch (e) {
        _mostrarErro('Erro ao selecionar foto: $e');
      }
    }
  }
}
