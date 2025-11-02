import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/germination_test_provider.dart';
import '../models/germination_test_model.dart';
// import '../widgets/germination_test_info_card.dart'; // Comentado - arquivo pode não existir
// import '../widgets/germination_daily_records_list.dart'; // Comentado - arquivo pode não existir
// import '../widgets/germination_accumulated_info_widget.dart'; // Comentado - arquivo pode não existir
import '../widgets/agronomic_dashboard_widget.dart';
import 'germination_daily_record_screen.dart';
import 'germination_test_results_screen.dart';
import 'germination_test_edit_screen.dart';
import 'subtest_selection_screen.dart';
import 'germination_consolidated_report_screen.dart';

class GerminationTestDetailScreen extends StatefulWidget {
  final int testId;

  const GerminationTestDetailScreen({
    super.key,
    required this.testId,
  });

  @override
  State<GerminationTestDetailScreen> createState() => _GerminationTestDetailScreenState();
}

class _GerminationTestDetailScreenState extends State<GerminationTestDetailScreen> {
  GerminationTest? _test;
  List<GerminationDailyRecord> _dailyRecords = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTest();
  }

  Future<void> _loadTest() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final provider = context.read<GerminationTestProvider>();
      
      // Carregar teste e registros diários em paralelo
      final results = await Future.wait([
        provider.getTestById(widget.testId),
        provider.getDailyRecords(widget.testId),
      ]);
      
      final test = results[0] as GerminationTest?;
      final dailyRecords = results[1] as List<GerminationDailyRecord>;
      
      if (test != null) {
        setState(() {
          _test = test;
          _dailyRecords = dailyRecords;
          _isLoading = false;
        });
        print('📊 Teste carregado: ${test.culture} - ${dailyRecords.length} registros diários');
      } else {
        setState(() {
          _error = 'Teste não encontrado';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar teste: $e';
        _isLoading = false;
      });
      print('❌ Erro ao carregar teste: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _test?.status == 'active' 
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubtestSelectionScreen(
                      test: _test!,
                    ),
                  ),
                );
                
                // Recarregar registros se um novo foi adicionado
                if (result == true) {
                  _loadTest();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Registrar'),
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.green.shade600,
      foregroundColor: Colors.white,
      title: Text(
        _test?.culture ?? 'Detalhes do Teste',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (_test != null) ...[
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GerminationConsolidatedReportScreen(test: _test!),
                ),
              );
            },
            tooltip: 'Relatório Consolidado',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editTest();
                  break;
                case 'delete':
                  _showDeleteDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_test == null) {
      return _buildNotFoundWidget();
    }

    return RefreshIndicator(
      onRefresh: _loadTest,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GerminationTestInfoCard(test: _test!), // Widget comentado - pode não existir
            _buildTestInfoCard(),
            const SizedBox(height: 16),
            // GerminationAccumulatedInfoWidget( // Widget comentado - pode não existir
            //   test: _test!,
            //   records: _dailyRecords,
            // ),
            const SizedBox(height: 16),
            _buildDailyRecordsSection(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTestInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _test!.culture,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Variedade: ${_test!.variety}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            Text(
              'Lote: ${_test!.seedLot}',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              'Total de sementes: ${_test!.totalSeeds}',
              style: const TextStyle(fontSize: 14),
            ),
            if (_test!.hasSubtests)
              Text(
                'Teste com ${_test!.subtestSeedCount} subtestes',
                style: TextStyle(fontSize: 14, color: Colors.blue[600]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar teste',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadTest,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar Novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Teste não encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'O teste solicitado não foi encontrado ou foi removido',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Voltar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRecordsSection() {
    return Card(
      elevation: 2,
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
                Icon(
                  Icons.calendar_today,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Registros Diários',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // GerminationDailyRecordsList( // Widget comentado - pode não existir
            //   records: _dailyRecords,
            //   onEditRecord: (record) => _editRecord(record),
            //   onDeleteRecord: (record) => _deleteRecord(record),
            // ),
            _buildSimpleDailyRecordsList(),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Teste'),
        content: const Text(
          'Tem certeza que deseja excluir este teste? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleDailyRecordsList() {
    if (_dailyRecords.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Nenhum registro diário ainda'),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _dailyRecords.length,
      itemBuilder: (context, index) {
        final record = _dailyRecords[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Text('${record.day}'),
            ),
            title: Text('Dia ${record.day}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Germinadas: ${record.normalGerminated}'),
                Text(
                  'Data: ${_formatDate(record.recordDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editRecord(record),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteRecord(record),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// Edita o teste atual
  Future<void> _editTest() async {
    if (_test == null) return;
    
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GerminationTestEditScreen(test: _test!),
        ),
      );
      
      // Se houve alteração, recarregar os dados
      if (result == true) {
        await _loadTest();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir edição: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    /*
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GerminationTestEditScreen(test: _test!),
        ),
      );
      
      // Recarregar teste se houve alteração
      if (result == true) {
        _loadTest();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir edição: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    */
  }

  Future<void> _deleteTest() async {
    try {
      final provider = Provider.of<GerminationTestProvider>(context, listen: false);
      
      // Mostrar indicador de carregamento
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Excluindo teste...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
      
      final success = await provider.deleteTest(widget.testId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teste excluído com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar que foi excluído
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao excluir teste'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir teste: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Edita um registro diário existente
  Future<void> _editRecord(GerminationDailyRecord record) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GerminationDailyRecordScreen(
            test: _test!,
            day: record.day,
            existingRecord: record, // Passar o registro existente para edição
          ),
        ),
      );
      
      // Recarregar registros se houve alteração
      if (result == true) {
        _loadTest();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir edição: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Exclui um registro diário
  Future<void> _deleteRecord(GerminationDailyRecord record) async {
    try {
      final provider = Provider.of<GerminationTestProvider>(context, listen: false);
      
      // Mostrar indicador de carregamento
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Excluindo registro...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
      
      final success = await provider.deleteDailyRecord(record.id!);
      
      if (success) {
        // Reordenar registros após exclusão
        await provider.updateRecordsSequentialOrder(_test!.id!);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro excluído com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recarregar a lista de registros
        _loadTest();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao excluir registro'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir registro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Formata data para exibição
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }
}
