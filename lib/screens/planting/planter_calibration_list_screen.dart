import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/planter_calibration.dart';
import '../../repositories/planter_calibration_repository.dart';
import '../../services/pdf_report_service.dart';
import '../../widgets/empty_state.dart';
import 'planter_calibration_form_screen.dart';

class PlanterCalibrationListScreen extends StatefulWidget {
  const PlanterCalibrationListScreen({Key? key}) : super(key: key);

  @override
  State<PlanterCalibrationListScreen> createState() => _PlanterCalibrationListScreenState();
}

class _PlanterCalibrationListScreenState extends State<PlanterCalibrationListScreen> {
  final PlanterCalibrationRepository _repository = PlanterCalibrationRepository();
  final PdfReportService _reportService = PdfReportService();
  List<PlanterCalibration> _calibrations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalibrations();
  }

  Future<void> _loadCalibrations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final calibrations = await _repository.getAll();
      setState(() {
        _calibrations = calibrations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar calibragens: $e')),
        );
      }
    }
  }

  Future<void> _deleteCalibration(PlanterCalibration calibration) async {
    try {
      await _repository.delete(calibration.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calibragem excluída com sucesso')),
      );
      _loadCalibrations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir calibragem: $e')),
      );
    }
  }

  Future<void> _generateReport(PlanterCalibration calibration) async {
    try {
      final filePath = await _reportService.generatePlanterCalibrationReport(calibration);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Relatório gerado: $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar relatório: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calibragens de Plantadeira'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _calibrations.isEmpty
              ? EmptyState(
                  icon: Icons.settings,
                  title: 'Nenhuma calibragem cadastrada',
                  message: 'Registre sua primeira calibragem de plantadeira clicando no botão abaixo',
                  buttonLabel: 'Nova Calibragem',
                  onButtonPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlanterCalibrationFormScreen(),
                      ),
                    );
                    if (result == true) {
                      _loadCalibrations();
                    }
                  },
                )
              : RefreshIndicator(
                  onRefresh: _loadCalibrations,
                  child: ListView.builder(
                    itemCount: _calibrations.length,
                    itemBuilder: (context, index) {
                      final calibration = _calibrations[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(
                            calibration.cropName ?? 'Cultura não informada',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Plantadeira: ${calibration.planterName ?? 'Não informada'}'),
                              Text('Talhão: ${calibration.plotName ?? 'Não informado'}'),
                              Text(
                                'Data: ${DateFormat('dd/MM/yyyy').format(calibration.calibrationDate)}',
                              ),
                              Text(
                                'Taxa Alvo: ${calibration.targetSeedRate.toStringAsFixed(0)} sementes/ha',
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.picture_as_pdf),
                                onPressed: () => _generateReport(calibration),
                                tooltip: 'Gerar relatório',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlanterCalibrationFormScreen(
                                        calibrationId: calibration.id,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadCalibrations();
                                  }
                                },
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirmar exclusão'),
                                      content: const Text(
                                        'Tem certeza que deseja excluir esta calibragem?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteCalibration(calibration);
                                          },
                                          child: const Text('Excluir'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                tooltip: 'Excluir',
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlanterCalibrationFormScreen(
                                  calibrationId: calibration.id,
                                  viewOnly: true,
                                ),
                              ),
                            );
                            if (result == true) {
                              _loadCalibrations();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PlanterCalibrationFormScreen(),
            ),
          );
          if (result == true) {
            _loadCalibrations();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
