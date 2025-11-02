import 'dart:async';
import 'package:flutter/material.dart';
import '../services/plantio_integration_service.dart';
import '../services/safra_validation_service.dart';
import '../database/repositories/historico_plantio_repository.dart';

/// Serviço de notificações inteligentes do FortSmart Agro
/// Gerencia alertas, lembretes e atualizações em tempo real
class FortSmartNotificationService extends ChangeNotifier {
  FortSmartNotificationService();

  final PlantioIntegrationService _plantioService = PlantioIntegrationService();
  final SafraValidationService _safraService = SafraValidationService();
  final HistoricoPlantioRepository _historicoRepository = HistoricoPlantioRepository();

  // Stream controllers para notificações em tempo real
  final _plantioNotificationController = StreamController<PlantioNotification>.broadcast();
  final _qualityNotificationController = StreamController<QualityNotification>.broadcast();
  final _phenologicalReminderController = StreamController<PhenologicalReminder>.broadcast();

  // Streams públicos
  Stream<PlantioNotification> get plantioNotifications => _plantioNotificationController.stream;
  Stream<QualityNotification> get qualityNotifications => _qualityNotificationController.stream;
  Stream<PhenologicalReminder> get phenologicalReminders => _phenologicalReminderController.stream;

  // Estado interno
  List<PlantioIntegrado> _lastKnownPlantios = [];
  DateTime _lastCheck = DateTime.now();
  Timer? _monitoringTimer;

  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    try {
      print('🔔 NOTIFICAÇÕES: Inicializando serviço...');
      
      // Carregar estado inicial
      await _loadInitialState();
      
      // Iniciar monitoramento em tempo real
      _startRealTimeMonitoring();
      
      print('✅ NOTIFICAÇÕES: Serviço inicializado com sucesso');
    } catch (e) {
      print('❌ NOTIFICAÇÕES: Erro ao inicializar: $e');
    }
  }

  /// Carrega estado inicial dos plantios
  Future<void> _loadInitialState() async {
    try {
      _lastKnownPlantios = await _plantioService.buscarPlantiosIntegrados();
      _lastCheck = DateTime.now();
      print('📊 NOTIFICAÇÕES: Estado inicial carregado - ${_lastKnownPlantios.length} plantios');
    } catch (e) {
      print('❌ NOTIFICAÇÕES: Erro ao carregar estado inicial: $e');
    }
  }

  /// Inicia monitoramento em tempo real
  void _startRealTimeMonitoring() {
    // Verificar a cada 30 segundos
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkForUpdates();
    });
    
    print('🔄 NOTIFICAÇÕES: Monitoramento em tempo real iniciado');
  }

  /// Verifica por atualizações
  Future<void> _checkForUpdates() async {
    try {
      // Verificar novos plantios
      await _checkForNewPlantios();
      
      // Verificar qualidade dos dados
      await _checkDataQuality();
      
      // Verificar lembretes fenológicos
      await _checkPhenologicalReminders();
      
      _lastCheck = DateTime.now();
    } catch (e) {
      print('❌ NOTIFICAÇÕES: Erro ao verificar atualizações: $e');
    }
  }

  /// Verifica novos plantios
  Future<void> _checkForNewPlantios() async {
    try {
      final currentPlantios = await _plantioService.buscarPlantiosIntegrados();
      
      // Comparar com estado anterior
      final newPlantios = currentPlantios.where((current) {
        return !_lastKnownPlantios.any((previous) => 
          previous.id == current.id && 
          previous.fonte == current.fonte
        );
      }).toList();

      // Notificar novos plantios
      for (final plantio in newPlantios) {
        final notification = PlantioNotification(
          id: 'plantio_${plantio.id}_${DateTime.now().millisecondsSinceEpoch}',
          tipo: PlantioNotificationType.novoPlantio,
          titulo: 'Novo Plantio Registrado',
          mensagem: 'Plantio de ${plantio.culturaId} registrado no ${plantio.talhaoNome}',
          plantio: plantio,
          timestamp: DateTime.now(),
          prioridade: NotificationPriority.media,
        );
        
        _plantioNotificationController.add(notification);
        print('🔔 NOTIFICAÇÃO: Novo plantio - ${plantio.culturaId} em ${plantio.talhaoNome}');
      }

      // Atualizar estado
      _lastKnownPlantios = currentPlantios;
      notifyListeners();
    } catch (e) {
      print('❌ NOTIFICAÇÕES: Erro ao verificar novos plantios: $e');
    }
  }

  /// Verifica qualidade dos dados
  Future<void> _checkDataQuality() async {
    try {
      final relatorio = await _safraService.gerarRelatorioValidacaoSafra(
        dataInicio: DateTime.now().subtract(const Duration(days: 30)),
        dataFim: DateTime.now(),
      );

      final qualidade = relatorio['qualidade_dados'] as Map<String, dynamic>?;
      if (qualidade != null) {
        final score = qualidade['score'] as int? ?? 0;
        final nivel = qualidade['nivel'] as String? ?? 'BAIXO';

        // Notificar se qualidade está baixa
        if (score < 70) {
          final notification = QualityNotification(
            id: 'quality_${DateTime.now().millisecondsSinceEpoch}',
            titulo: 'Qualidade dos Dados Baixa',
            mensagem: 'Score de qualidade: $score% ($nivel). Recomenda-se melhorar a completude dos dados.',
            score: score,
            nivel: nivel,
            timestamp: DateTime.now(),
            prioridade: score < 50 ? NotificationPriority.alta : NotificationPriority.media,
            recomendacoes: relatorio['recomendacoes'] as List<dynamic>? ?? [],
          );
          
          _qualityNotificationController.add(notification);
          print('🔔 NOTIFICAÇÃO: Qualidade baixa - $score% ($nivel)');
        }
      }
    } catch (e) {
      print('❌ NOTIFICAÇÕES: Erro ao verificar qualidade: $e');
    }
  }

  /// Verifica lembretes fenológicos
  Future<void> _checkPhenologicalReminders() async {
    try {
      final plantios = await _plantioService.buscarPlantiosIntegrados();
      final agora = DateTime.now();

      for (final plantio in plantios) {
        final diasAposPlantio = agora.difference(plantio.dataPlantio).inDays;
        
        // Lembretes baseados na cultura e dias após plantio
        final lembretes = _calcularLembretesFenologicos(plantio, diasAposPlantio);
        
        for (final lembrete in lembretes) {
          _phenologicalReminderController.add(lembrete);
          print('🔔 LEMBRETE: ${lembrete.titulo} - ${plantio.talhaoNome}');
        }
      }
    } catch (e) {
      print('❌ NOTIFICAÇÕES: Erro ao verificar lembretes fenológicos: $e');
    }
  }

  /// Calcula lembretes fenológicos baseados na cultura
  List<PhenologicalReminder> _calcularLembretesFenologicos(PlantioIntegrado plantio, int diasAposPlantio) {
    final lembretes = <PhenologicalReminder>[];
    final cultura = plantio.culturaId.toLowerCase();
    
    // Lembretes específicos por cultura
    if (cultura.contains('soja')) {
      lembretes.addAll(_getLembretesSoja(plantio, diasAposPlantio));
    } else if (cultura.contains('milho')) {
      lembretes.addAll(_getLembretesMilho(plantio, diasAposPlantio));
    } else if (cultura.contains('algodao') || cultura.contains('algodão')) {
      lembretes.addAll(_getLembretesAlgodao(plantio, diasAposPlantio));
    }
    
    return lembretes;
  }

  /// Lembretes específicos para soja
  List<PhenologicalReminder> _getLembretesSoja(PlantioIntegrado plantio, int dias) {
    final lembretes = <PhenologicalReminder>[];
    
    if (dias == 7) {
      lembretes.add(PhenologicalReminder(
        id: 'soja_emergencia_${plantio.id}',
        plantioId: plantio.id,
        titulo: 'Verificar Emergência da Soja',
        mensagem: 'Avaliar emergência e uniformidade do estande no ${plantio.talhaoNome}',
        estagio: 'VE - Emergência',
        diasAposPlantio: dias,
        timestamp: DateTime.now(),
        prioridade: NotificationPriority.alta,
      ));
    } else if (dias == 15) {
      lembretes.add(PhenologicalReminder(
        id: 'soja_v2_${plantio.id}',
        plantioId: plantio.id,
        titulo: 'Estágio V2 - Primeira Folha Trifoliolada',
        mensagem: 'Monitorar desenvolvimento vegetativo no ${plantio.talhaoNome}',
        estagio: 'V2',
        diasAposPlantio: dias,
        timestamp: DateTime.now(),
        prioridade: NotificationPriority.media,
      ));
    } else if (dias == 45) {
      lembretes.add(PhenologicalReminder(
        id: 'soja_r1_${plantio.id}',
        plantioId: plantio.id,
        titulo: 'Início do Florescimento (R1)',
        mensagem: 'Período crítico para manejo no ${plantio.talhaoNome}',
        estagio: 'R1 - Florescimento',
        diasAposPlantio: dias,
        timestamp: DateTime.now(),
        prioridade: NotificationPriority.alta,
      ));
    }
    
    return lembretes;
  }

  /// Lembretes específicos para milho
  List<PhenologicalReminder> _getLembretesMilho(PlantioIntegrado plantio, int dias) {
    final lembretes = <PhenologicalReminder>[];
    
    if (dias == 5) {
      lembretes.add(PhenologicalReminder(
        id: 'milho_emergencia_${plantio.id}',
        plantioId: plantio.id,
        titulo: 'Verificar Emergência do Milho',
        mensagem: 'Avaliar emergência e estande no ${plantio.talhaoNome}',
        estagio: 'VE - Emergência',
        diasAposPlantio: dias,
        timestamp: DateTime.now(),
        prioridade: NotificationPriority.alta,
      ));
    } else if (dias == 30) {
      lembretes.add(PhenologicalReminder(
        id: 'milho_v6_${plantio.id}',
        plantioId: plantio.id,
        titulo: 'Estágio V6 - Definição do Potencial',
        mensagem: 'Período crítico para definição de produtividade no ${plantio.talhaoNome}',
        estagio: 'V6',
        diasAposPlantio: dias,
        timestamp: DateTime.now(),
        prioridade: NotificationPriority.alta,
      ));
    }
    
    return lembretes;
  }

  /// Lembretes específicos para algodão
  List<PhenologicalReminder> _getLembretesAlgodao(PlantioIntegrado plantio, int dias) {
    final lembretes = <PhenologicalReminder>[];
    
    if (dias == 10) {
      lembretes.add(PhenologicalReminder(
        id: 'algodao_emergencia_${plantio.id}',
        plantioId: plantio.id,
        titulo: 'Verificar Emergência do Algodão',
        mensagem: 'Avaliar emergência e uniformidade no ${plantio.talhaoNome}',
        estagio: 'VE - Emergência',
        diasAposPlantio: dias,
        timestamp: DateTime.now(),
        prioridade: NotificationPriority.alta,
      ));
    } else if (dias == 60) {
      lembretes.add(PhenologicalReminder(
        id: 'algodao_botao_${plantio.id}',
        plantioId: plantio.id,
        titulo: 'Formação de Botões Florais',
        mensagem: 'Monitorar formação de estruturas reprodutivas no ${plantio.talhaoNome}',
        estagio: 'Botão Floral',
        diasAposPlantio: dias,
        timestamp: DateTime.now(),
        prioridade: NotificationPriority.media,
      ));
    }
    
    return lembretes;
  }

  /// Força verificação manual
  Future<void> forceCheck() async {
    print('🔄 NOTIFICAÇÕES: Verificação manual solicitada');
    await _checkForUpdates();
  }

  /// Para o monitoramento
  @override
  void dispose() {
    _monitoringTimer?.cancel();
    _plantioNotificationController.close();
    _qualityNotificationController.close();
    _phenologicalReminderController.close();
    print('🔔 NOTIFICAÇÕES: Serviço finalizado');
    super.dispose();
  }
}

/// Enums e classes de notificação
enum PlantioNotificationType {
  novoPlantio,
  plantioAtualizado,
  plantioExcluido,
}

enum NotificationPriority {
  baixa,
  media,
  alta,
}

/// Notificação de plantio
class PlantioNotification {
  final String id;
  final PlantioNotificationType tipo;
  final String titulo;
  final String mensagem;
  final PlantioIntegrado plantio;
  final DateTime timestamp;
  final NotificationPriority prioridade;

  PlantioNotification({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensagem,
    required this.plantio,
    required this.timestamp,
    required this.prioridade,
  });
}

/// Notificação de qualidade
class QualityNotification {
  final String id;
  final String titulo;
  final String mensagem;
  final int score;
  final String nivel;
  final DateTime timestamp;
  final NotificationPriority prioridade;
  final List<dynamic> recomendacoes;

  QualityNotification({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.score,
    required this.nivel,
    required this.timestamp,
    required this.prioridade,
    required this.recomendacoes,
  });
}

/// Lembrete fenológico
class PhenologicalReminder {
  final String id;
  final String plantioId;
  final String titulo;
  final String mensagem;
  final String estagio;
  final int diasAposPlantio;
  final DateTime timestamp;
  final NotificationPriority prioridade;

  PhenologicalReminder({
    required this.id,
    required this.plantioId,
    required this.titulo,
    required this.mensagem,
    required this.estagio,
    required this.diasAposPlantio,
    required this.timestamp,
    required this.prioridade,
  });
}
