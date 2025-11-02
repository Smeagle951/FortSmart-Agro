import 'dart:async';
import '../models/infestacao_model.dart';
import '../utils/logger.dart';
import 'monitoring_infestation_integration_service.dart';

/// Evento de monitoramento
class MonitoringEvent {
  final String type;
  final InfestacaoModel occurrence;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  MonitoringEvent({
    required this.type,
    required this.occurrence,
    this.metadata = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Serviço de eventos de monitoramento
/// Gerencia listeners e dispara integrações automáticas
class MonitoringEventService {
  static final MonitoringEventService _instance = MonitoringEventService._internal();
  factory MonitoringEventService() => _instance;
  MonitoringEventService._internal();

  // Stream controller para eventos
  final StreamController<MonitoringEvent> _eventController = 
      StreamController<MonitoringEvent>.broadcast();
  
  // Lista de listeners registrados
  final List<MonitoringEventListener> _listeners = [];
  
  // Serviço de integração
  final MonitoringInfestationIntegrationService _integrationService = 
      MonitoringInfestationIntegrationService();
  
  /// Stream público de eventos
  Stream<MonitoringEvent> get eventStream => _eventController.stream;
  
  /// Inicializa o serviço
  Future<void> initialize() async {
    try {
      await _integrationService.initialize();
      Logger.info('✅ [EVENTS] Serviço de eventos inicializado');
    } catch (e) {
      Logger.error('❌ [EVENTS] Erro ao inicializar: $e');
    }
  }
  
  /// Registra um listener
  void addListener(MonitoringEventListener listener) {
    _listeners.add(listener);
    Logger.info('✅ [EVENTS] Listener registrado: ${listener.runtimeType}');
  }
  
  /// Remove um listener
  void removeListener(MonitoringEventListener listener) {
    _listeners.remove(listener);
    Logger.info('✅ [EVENTS] Listener removido: ${listener.runtimeType}');
  }
  
  /// Dispara evento de ocorrência salva
  Future<void> onOccurrenceSaved({
    required InfestacaoModel occurrence,
    required int culturaId,
    String? culturaNome,
    String? talhaoNome,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final event = MonitoringEvent(
        type: 'occurrence_saved',
        occurrence: occurrence,
        metadata: {
          ...metadata,
          'cultura_id': culturaId,
          'cultura_nome': culturaNome,
          'talhao_nome': talhaoNome,
        },
      );
      
      // Emitir evento no stream
      _eventController.add(event);
      
      // Notificar listeners
      for (final listener in _listeners) {
        try {
          await listener.onOccurrenceSaved(event);
        } catch (e) {
          Logger.error('❌ [EVENTS] Erro no listener ${listener.runtimeType}: $e');
        }
      }
      
      Logger.info('✅ [EVENTS] Evento de ocorrência salva disparado: ${occurrence.id}');
    } catch (e) {
      Logger.error('❌ [EVENTS] Erro ao disparar evento: $e');
    }
  }
  
  /// Dispara evento de ocorrência atualizada
  Future<void> onOccurrenceUpdated({
    required InfestacaoModel occurrence,
    required InfestacaoModel oldOccurrence,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final event = MonitoringEvent(
        type: 'occurrence_updated',
        occurrence: occurrence,
        metadata: {
          ...metadata,
          'old_occurrence': oldOccurrence.toMap(),
        },
      );
      
      _eventController.add(event);
      
      for (final listener in _listeners) {
        try {
          await listener.onOccurrenceUpdated(event);
        } catch (e) {
          Logger.error('❌ [EVENTS] Erro no listener ${listener.runtimeType}: $e');
        }
      }
      
      Logger.info('✅ [EVENTS] Evento de ocorrência atualizada disparado: ${occurrence.id}');
    } catch (e) {
      Logger.error('❌ [EVENTS] Erro ao disparar evento: $e');
    }
  }
  
  /// Dispara evento de ocorrência removida
  Future<void> onOccurrenceDeleted({
    required String occurrenceId,
    required int talhaoId,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final event = MonitoringEvent(
        type: 'occurrence_deleted',
        occurrence: InfestacaoModel(
          id: occurrenceId,
          talhaoId: talhaoId,
          pontoId: 0,
          tipo: '',
          subtipo: '',
          nivel: '',
          percentual: 0,
          observacao: '',
          fotoPaths: '',
          dataHora: DateTime.now(),
          latitude: 0.0,
          longitude: 0.0,
        ),
        metadata: metadata,
      );
      
      _eventController.add(event);
      
      for (final listener in _listeners) {
        try {
          await listener.onOccurrenceDeleted(event);
        } catch (e) {
          Logger.error('❌ [EVENTS] Erro no listener ${listener.runtimeType}: $e');
        }
      }
      
      Logger.info('✅ [EVENTS] Evento de ocorrência removida disparado: $occurrenceId');
    } catch (e) {
      Logger.error('❌ [EVENTS] Erro ao disparar evento: $e');
    }
  }
  
  /// Dispara evento de sincronização
  Future<void> onSyncRequested({
    required List<String> occurrenceIds,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final event = MonitoringEvent(
        type: 'sync_requested',
        occurrence: InfestacaoModel(
          id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
          talhaoId: 0,
          pontoId: 0,
          tipo: 'sync',
          subtipo: 'batch',
          nivel: '',
          percentual: 0,
          observacao: '',
          fotoPaths: '',
          dataHora: DateTime.now(),
          latitude: 0.0,
          longitude: 0.0,
        ),
        metadata: {
          ...metadata,
          'occurrence_ids': occurrenceIds,
        },
      );
      
      _eventController.add(event);
      
      for (final listener in _listeners) {
        try {
          await listener.onSyncRequested(event);
        } catch (e) {
          Logger.error('❌ [EVENTS] Erro no listener ${listener.runtimeType}: $e');
        }
      }
      
      Logger.info('✅ [EVENTS] Evento de sincronização disparado: ${occurrenceIds.length} registros');
    } catch (e) {
      Logger.error('❌ [EVENTS] Erro ao disparar evento: $e');
    }
  }
  
  /// Dispose do serviço
  void dispose() {
    _eventController.close();
    _listeners.clear();
    Logger.info('✅ [EVENTS] Serviço de eventos finalizado');
  }
}

/// Interface para listeners de eventos de monitoramento
abstract class MonitoringEventListener {
  /// Chamado quando uma ocorrência é salva
  Future<void> onOccurrenceSaved(MonitoringEvent event);
  
  /// Chamado quando uma ocorrência é atualizada
  Future<void> onOccurrenceUpdated(MonitoringEvent event);
  
  /// Chamado quando uma ocorrência é removida
  Future<void> onOccurrenceDeleted(MonitoringEvent event);
  
  /// Chamado quando sincronização é solicitada
  Future<void> onSyncRequested(MonitoringEvent event);
}

/// Listener automático para integração com mapa de infestação
class InfestationMapAutoIntegrationListener implements MonitoringEventListener {
  final MonitoringInfestationIntegrationService _integrationService;
  
  InfestationMapAutoIntegrationListener(this._integrationService);
  
  @override
  Future<void> onOccurrenceSaved(MonitoringEvent event) async {
    try {
      final culturaId = event.metadata['cultura_id'] as int?;
      
      if (culturaId != null) {
        await _integrationService.sendMonitoringDataToInfestationMap(
          occurrence: event.occurrence,
          preventDuplicates: true,
        );
        
        Logger.info('✅ [AUTO-INTEGRATION] Ocorrência integrada automaticamente: ${event.occurrence.id}');
      }
    } catch (e) {
      Logger.error('❌ [AUTO-INTEGRATION] Erro na integração automática: $e');
    }
  }
  
  @override
  Future<void> onOccurrenceUpdated(MonitoringEvent event) async {
    try {
      // Para atualizações, reenviar dados atualizados
      await _integrationService.sendMonitoringDataToInfestationMap(
        occurrence: event.occurrence,
        preventDuplicates: true,
      );
      
      Logger.info('✅ [AUTO-INTEGRATION] Ocorrência atualizada integrada: ${event.occurrence.id}');
    } catch (e) {
      Logger.error('❌ [AUTO-INTEGRATION] Erro na integração de atualização: $e');
    }
  }
  
  @override
  Future<void> onOccurrenceDeleted(MonitoringEvent event) async {
    try {
      // Para remoções, limpar dados relacionados
      await _integrationService.cleanDuplicateInfestationRecords();
      
      Logger.info('✅ [AUTO-INTEGRATION] Limpeza após remoção: ${event.occurrence.id}');
    } catch (e) {
      Logger.error('❌ [AUTO-INTEGRATION] Erro na limpeza: $e');
    }
  }
  
  @override
  Future<void> onSyncRequested(MonitoringEvent event) async {
    try {
      final occurrenceIds = event.metadata['occurrence_ids'] as List<String>?;
      
      if (occurrenceIds != null && occurrenceIds.isNotEmpty) {
        await _integrationService.syncPendingInfestationData();
        
        Logger.info('✅ [AUTO-INTEGRATION] Sincronização automática concluída: ${occurrenceIds.length} registros');
      }
    } catch (e) {
      Logger.error('❌ [AUTO-INTEGRATION] Erro na sincronização automática: $e');
    }
  }
}
