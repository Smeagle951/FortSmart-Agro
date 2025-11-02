import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../utils/logger.dart';
import 'consolidated_report_service.dart';
import 'export_service.dart';

/// Enum para frequência de agendamento
enum ScheduleFrequency {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly
}

/// Enum para status do agendamento
enum ScheduleStatus {
  active,
  paused,
  completed,
  failed
}

/// Configuração de agendamento de relatório
class ReportSchedule {
  final String id;
  final String name;
  final String description;
  final ConsolidatedReportConfig reportConfig;
  final ScheduleFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final TimeOfDay time;
  final List<int> weekdays; // Para frequência semanal (1-7, domingo=1)
  final int dayOfMonth; // Para frequência mensal (1-31)
  final ScheduleStatus status;
  final DateTime? lastRun;
  final DateTime? nextRun;
  final int runCount;
  final String? lastError;

  ReportSchedule({
    required this.id,
    required this.name,
    required this.description,
    required this.reportConfig,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.time,
    this.weekdays = const [],
    this.dayOfMonth = 1,
    this.status = ScheduleStatus.active,
    this.lastRun,
    this.nextRun,
    this.runCount = 0,
    this.lastError,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'reportConfig': {
        'startDate': reportConfig.startDate.millisecondsSinceEpoch,
        'endDate': reportConfig.endDate.millisecondsSinceEpoch,
        'farm': reportConfig.farm,
        'season': reportConfig.season,
        'includePlanting': reportConfig.includePlanting,
        'includeMonitoring': reportConfig.includeMonitoring,
        'includeApplications': reportConfig.includeApplications,
        'includeHarvest': reportConfig.includeHarvest,
        'includeInventory': reportConfig.includeInventory,
        'includeCosts': reportConfig.includeCosts,
      },
      'frequency': frequency.name,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'time': {
        'hour': time.hour,
        'minute': time.minute,
      },
      'weekdays': weekdays,
      'dayOfMonth': dayOfMonth,
      'status': status.name,
      'lastRun': lastRun?.millisecondsSinceEpoch,
      'nextRun': nextRun?.millisecondsSinceEpoch,
      'runCount': runCount,
      'lastError': lastError,
    };
  }

  factory ReportSchedule.fromJson(Map<String, dynamic> json) {
    return ReportSchedule(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      reportConfig: ConsolidatedReportConfig(
        startDate: DateTime.fromMillisecondsSinceEpoch(json['reportConfig']['startDate']),
        endDate: DateTime.fromMillisecondsSinceEpoch(json['reportConfig']['endDate']),
        farm: json['reportConfig']['farm'],
        season: json['reportConfig']['season'],
        includePlanting: json['reportConfig']['includePlanting'],
        includeMonitoring: json['reportConfig']['includeMonitoring'],
        includeApplications: json['reportConfig']['includeApplications'],
        includeHarvest: json['reportConfig']['includeHarvest'],
        includeInventory: json['reportConfig']['includeInventory'],
        includeCosts: json['reportConfig']['includeCosts'],
      ),
      frequency: ScheduleFrequency.values.firstWhere(
        (f) => f.name == json['frequency'],
        orElse: () => ScheduleFrequency.daily,
      ),
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate']),
      endDate: json['endDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['endDate'])
          : null,
      time: TimeOfDay(
        hour: json['time']['hour'],
        minute: json['time']['minute'],
      ),
      weekdays: List<int>.from(json['weekdays'] ?? []),
      dayOfMonth: json['dayOfMonth'] ?? 1,
      status: ScheduleStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ScheduleStatus.active,
      ),
      lastRun: json['lastRun'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['lastRun'])
          : null,
      nextRun: json['nextRun'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['nextRun'])
          : null,
      runCount: json['runCount'] ?? 0,
      lastError: json['lastError'],
    );
  }

  ReportSchedule copyWith({
    String? name,
    String? description,
    ConsolidatedReportConfig? reportConfig,
    ScheduleFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    TimeOfDay? time,
    List<int>? weekdays,
    int? dayOfMonth,
    ScheduleStatus? status,
    DateTime? lastRun,
    DateTime? nextRun,
    int? runCount,
    String? lastError,
  }) {
    return ReportSchedule(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      reportConfig: reportConfig ?? this.reportConfig,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      time: time ?? this.time,
      weekdays: weekdays ?? this.weekdays,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      status: status ?? this.status,
      lastRun: lastRun ?? this.lastRun,
      nextRun: nextRun ?? this.nextRun,
      runCount: runCount ?? this.runCount,
      lastError: lastError ?? this.lastError,
    );
  }
}

/// Serviço para agendamento automático de relatórios
class ReportSchedulerService {
  static const String _tag = 'ReportSchedulerService';
  static const String _schedulesKey = 'report_schedules';
  
  final ConsolidatedReportService _reportService = ConsolidatedReportService();
  final ExportService _exportService = ExportService();
  
  Timer? _schedulerTimer;
  List<ReportSchedule> _schedules = [];
  
  static final ReportSchedulerService _instance = ReportSchedulerService._internal();
  factory ReportSchedulerService() => _instance;
  ReportSchedulerService._internal();

  /// Inicializa o serviço de agendamento
  Future<void> initialize() async {
    Logger.info('$_tag: Inicializando serviço de agendamento');
    
    try {
      await _loadSchedules();
      _startScheduler();
    } catch (e) {
      Logger.error('$_tag: Erro ao inicializar agendamento: $e');
    }
  }

  /// Carrega agendamentos salvos
  Future<void> _loadSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schedulesJson = prefs.getString(_schedulesKey);
      
      if (schedulesJson != null) {
        final List<dynamic> schedulesList = jsonDecode(schedulesJson);
        _schedules = schedulesList
            .map((json) => ReportSchedule.fromJson(json))
            .toList();
        
        Logger.info('$_tag: ${_schedules.length} agendamentos carregados');
      }
    } catch (e) {
      Logger.error('$_tag: Erro ao carregar agendamentos: $e');
    }
  }

  /// Salva agendamentos
  Future<void> _saveSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schedulesJson = jsonEncode(_schedules.map((s) => s.toJson()).toList());
      await prefs.setString(_schedulesKey, schedulesJson);
      
      Logger.info('$_tag: Agendamentos salvos');
    } catch (e) {
      Logger.error('$_tag: Erro ao salvar agendamentos: $e');
    }
  }

  /// Inicia o agendador
  void _startScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkSchedules();
    });
    
    Logger.info('$_tag: Agendador iniciado');
  }

  /// Verifica agendamentos que devem ser executados
  Future<void> _checkSchedules() async {
    final now = DateTime.now();
    
    for (final schedule in _schedules) {
      if (schedule.status != ScheduleStatus.active) continue;
      if (schedule.nextRun == null) continue;
      if (schedule.nextRun!.isAfter(now)) continue;
      if (schedule.endDate != null && schedule.endDate!.isBefore(now)) continue;
      
      await _executeSchedule(schedule);
    }
  }

  /// Executa um agendamento
  Future<void> _executeSchedule(ReportSchedule schedule) async {
    Logger.info('$_tag: Executando agendamento: ${schedule.name}');
    
    try {
      // Gera o relatório
      final reportPath = await _reportService.generateConsolidatedReport(schedule.reportConfig);
      
      // Exporta em múltiplos formatos
      final exportConfig = ExportConfig(
        fileName: '${schedule.name}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}',
        format: ExportFormat.pdf,
        data: {'scheduleId': schedule.id, 'generatedAt': DateTime.now().toIso8601String()},
        title: schedule.name,
        subtitle: schedule.description,
      );
      
      await _exportService.exportData(exportConfig);
      
      // Atualiza o agendamento
      final updatedSchedule = schedule.copyWith(
        lastRun: DateTime.now(),
        nextRun: _calculateNextRun(schedule),
        runCount: schedule.runCount + 1,
        lastError: null,
      );
      
      _updateSchedule(updatedSchedule);
      
      Logger.info('$_tag: Agendamento executado com sucesso: ${schedule.name}');
    } catch (e) {
      Logger.error('$_tag: Erro ao executar agendamento ${schedule.name}: $e');
      
      // Atualiza com erro
      final updatedSchedule = schedule.copyWith(
        lastError: e.toString(),
        status: ScheduleStatus.failed,
      );
      
      _updateSchedule(updatedSchedule);
    }
  }

  /// Calcula próxima execução
  DateTime _calculateNextRun(ReportSchedule schedule) {
    final now = DateTime.now();
    final time = schedule.time;
    
    switch (schedule.frequency) {
      case ScheduleFrequency.daily:
        var nextRun = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        if (nextRun.isBefore(now)) {
          nextRun = nextRun.add(const Duration(days: 1));
        }
        return nextRun;
        
      case ScheduleFrequency.weekly:
        var nextRun = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        while (!schedule.weekdays.contains(nextRun.weekday)) {
          nextRun = nextRun.add(const Duration(days: 1));
        }
        if (nextRun.isBefore(now)) {
          nextRun = nextRun.add(const Duration(days: 7));
        }
        return nextRun;
        
      case ScheduleFrequency.monthly:
        var nextRun = DateTime(now.year, now.month, schedule.dayOfMonth, time.hour, time.minute);
        if (nextRun.isBefore(now)) {
          nextRun = DateTime(now.year, now.month + 1, schedule.dayOfMonth, time.hour, time.minute);
        }
        return nextRun;
        
      case ScheduleFrequency.quarterly:
        var nextRun = DateTime(now.year, now.month, schedule.dayOfMonth, time.hour, time.minute);
        while (nextRun.isBefore(now) || (nextRun.month - 1) % 3 != 0) {
          nextRun = DateTime(nextRun.year, nextRun.month + 1, schedule.dayOfMonth, time.hour, time.minute);
        }
        return nextRun;
        
      case ScheduleFrequency.yearly:
        var nextRun = DateTime(now.year, now.month, schedule.dayOfMonth, time.hour, time.minute);
        if (nextRun.isBefore(now)) {
          nextRun = DateTime(now.year + 1, now.month, schedule.dayOfMonth, time.hour, time.minute);
        }
        return nextRun;
    }
  }

  /// Adiciona novo agendamento
  Future<void> addSchedule(ReportSchedule schedule) async {
    _schedules.add(schedule);
    await _saveSchedules();
    
    Logger.info('$_tag: Agendamento adicionado: ${schedule.name}');
  }

  /// Atualiza agendamento existente
  Future<void> updateSchedule(ReportSchedule schedule) async {
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      _schedules[index] = schedule;
      await _saveSchedules();
      
      Logger.info('$_tag: Agendamento atualizado: ${schedule.name}');
    }
  }

  /// Remove agendamento
  Future<void> removeSchedule(String scheduleId) async {
    _schedules.removeWhere((s) => s.id == scheduleId);
    await _saveSchedules();
    
    Logger.info('$_tag: Agendamento removido: $scheduleId');
  }

  /// Atualiza agendamento na lista
  void _updateSchedule(ReportSchedule schedule) {
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      _schedules[index] = schedule;
      _saveSchedules();
    }
  }

  /// Obtém todos os agendamentos
  List<ReportSchedule> getSchedules() => List.unmodifiable(_schedules);

  /// Obtém agendamento por ID
  ReportSchedule? getSchedule(String scheduleId) {
    try {
      return _schedules.firstWhere((s) => s.id == scheduleId);
    } catch (e) {
      return null;
    }
  }

  /// Pausa/reativa agendamento
  Future<void> toggleScheduleStatus(String scheduleId) async {
    final schedule = getSchedule(scheduleId);
    if (schedule != null) {
      final newStatus = schedule.status == ScheduleStatus.active 
          ? ScheduleStatus.paused 
          : ScheduleStatus.active;
      
      final updatedSchedule = schedule.copyWith(status: newStatus);
      await updateSchedule(updatedSchedule);
    }
  }

  /// Executa agendamento manualmente
  Future<void> executeScheduleNow(String scheduleId) async {
    final schedule = getSchedule(scheduleId);
    if (schedule != null) {
      await _executeSchedule(schedule);
    }
  }

  /// Obtém estatísticas dos agendamentos
  Map<String, dynamic> getStatistics() {
    final active = _schedules.where((s) => s.status == ScheduleStatus.active).length;
    final paused = _schedules.where((s) => s.status == ScheduleStatus.paused).length;
    final failed = _schedules.where((s) => s.status == ScheduleStatus.failed).length;
    final totalRuns = _schedules.fold<int>(0, (sum, s) => sum + s.runCount);
    
    return {
      'total': _schedules.length,
      'active': active,
      'paused': paused,
      'failed': failed,
      'totalRuns': totalRuns,
    };
  }

  /// Limpa agendamentos antigos
  Future<void> cleanupOldSchedules() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 365));
    
    _schedules.removeWhere((schedule) {
      return schedule.endDate != null && schedule.endDate!.isBefore(cutoffDate);
    });
    
    await _saveSchedules();
    
    Logger.info('$_tag: Limpeza de agendamentos antigos concluída');
  }

  /// Finaliza o serviço
  void dispose() {
    _schedulerTimer?.cancel();
    Logger.info('$_tag: Serviço de agendamento finalizado');
  }
}
