import 'package:flutter/material.dart';
import '../../models/integration/agro_context.dart';
import '../../models/integration/atividade_agricola.dart';
import '../../services/module_integration_service.dart';
import '../../widgets/integration/agro_context_selector.dart';
// Widget de histórico de atividade removido
import 'package:intl/intl.dart';

/// Tela para demonstração do sistema de integração entre módulos
class IntegracaoDemoScreen extends StatefulWidget {
  static const routeName = '/integracao-demo';

  const IntegracaoDemoScreen({Key? key}) : super(key: key);

  @override
  State<IntegracaoDemoScreen> createState() => _IntegracaoDemoScreenState();
}

class _IntegracaoDemoScreenState extends State<IntegracaoDemoScreen> {
  final ModuleIntegrationService _integrationService = ModuleIntegrationService();
  AgroContext? _contextoSelecionado;
  bool _isInitializing = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _inicializarBancoDados();
  }

  Future<void> _inicializarBancoDados() async {
    try {
      await _integrationService.initializeDatabase();
      await _integrationService.initialize();
      
      // Verificar se já existe um contexto atual
      if (_integrationService.hasCurrentContext()) {
        setState(() {
          _contextoSelecionado = _integrationService.currentContext;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao inicializar o banco de dados: $e';
      });
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  void _registrarAtividadeTeste() async {
    if (_contextoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecione um contexto agrícola primeiro'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
      return;
    }

    try {
      final idAtividade = await _integrationService.registrarAtividade(
        tipoAtividade: TipoAtividade.plantio,
        detalhesId: 'teste_${DateTime.now().millisecondsSinceEpoch}',
        descricao: 'Atividade de teste registrada em ${DateTime.now().toString()}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Atividade registrada com sucesso! ID: $idAtividade'),
          // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );

      // Forçar atualização do histórico
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao registrar atividade: $e'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Demonstração de Integração'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _mostrarDialogoInfo(context),
            tooltip: 'Informações',
          ),
        ],
      ),
      body: _isInitializing
          ? _buildCarregando()
          : _errorMessage.isNotEmpty
              ? _buildErro()
              : _buildConteudo(),
      floatingActionButton: _contextoSelecionado != null
          ? FloatingActionButton(
              onPressed: _registrarAtividadeTeste,
              tooltip: 'Registrar Atividade Teste',
              child: Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildCarregando() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Inicializando sistema de integração...'),
        ],
      ),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _inicializarBancoDados,
              child: Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudo() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card para seleção de contexto
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seleção de Contexto Agrícola',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  AgroContextSelector(
                    initialContext: _contextoSelecionado,
                    onContextSelected: (contexto) {
                      setState(() {
                        _contextoSelecionado = contexto;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Contexto selecionado: ${contexto.talhaoId}'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Card para exibição de contexto atual
          if (_contextoSelecionado != null) ...[
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contexto Atual',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildInfoContexto(),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Histórico de atividades
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Histórico de Atividades',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    // Widget de histórico de atividade removido
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Módulo de histórico de atividade foi removido',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoContexto() {
    if (_contextoSelecionado == null) {
      return Text('Nenhum contexto selecionado');
    }

    return FutureBuilder<Widget>(
      future: _buildInfoContextoAsync(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Text('Erro ao carregar informações: ${snapshot.error}');
        }
        
        return snapshot.data ?? Text('Nenhuma informação disponível');
      },
    );
  }

  Future<Widget> _buildInfoContextoAsync() async {
    try {
      final talhao = await _contextoSelecionado!.getTalhao();
      final safra = await _contextoSelecionado!.getSafra();
      final cultura = await _contextoSelecionado!.getCultura();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoItem('Talhão', talhao.nome ?? '', Icons.landscape),
          _buildInfoItem('Área', '${talhao.area?.toStringAsFixed(2)} hectares', Icons.straighten),
          _buildInfoItem('Safra', safra.safra ?? '', Icons.calendar_today),
          _buildInfoItem('Cultura', cultura.name ?? '', Icons.eco),
          _buildInfoItem('Data de Plantio', 
              safra.dataPlantio != null 
                  ? '${safra.dataPlantio!.day}/${safra.dataPlantio!.month}/${safra.dataPlantio!.year}'
                  : 'Não definida', 
              Icons.calendar_month),
        ],
      );
    } catch (e) {
      return Text('Erro ao carregar detalhes: $e');
    }
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green.shade700),
          SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sobre a Integração'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sistema de Integração entre Módulos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Esta demonstração apresenta o funcionamento do sistema integrado '
                'que permite a comunicação entre os diferentes módulos do FortSmart Agro.',
              ),
              SizedBox(height: 12),
              Text(
                'Principais recursos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildBulletPoint('Contexto único de talhão, safra e cultura'),
              _buildBulletPoint('Registro unificado de atividades agrícolas'),
              _buildBulletPoint('Histórico integrado entre módulos'),
              _buildBulletPoint('Sincronização automática de dados'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
