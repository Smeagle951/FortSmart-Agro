import 'package:flutter/material.dart';
import 'dart:async';
import '../services/fortsmart_notification_service.dart';

/// Widget de notificações do FortSmart Agro
/// Exibe notificações em tempo real na interface
class FortSmartNotificationWidget extends StatefulWidget {
  const FortSmartNotificationWidget({super.key});

  @override
  State<FortSmartNotificationWidget> createState() => _FortSmartNotificationWidgetState();
}

class _FortSmartNotificationWidgetState extends State<FortSmartNotificationWidget> {
  final FortSmartNotificationService _notificationService = FortSmartNotificationService();
  
  // Subscriptions para os streams
  StreamSubscription<PlantioNotification>? _plantioSubscription;
  StreamSubscription<QualityNotification>? _qualitySubscription;
  StreamSubscription<PhenologicalReminder>? _phenologicalSubscription;
  
  // Lista de notificações ativas
  final List<NotificationItem> _notifications = [];
  
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _plantioSubscription?.cancel();
    _qualitySubscription?.cancel();
    _phenologicalSubscription?.cancel();
    super.dispose();
  }

  /// Inicializa as notificações
  void _initializeNotifications() {
    // Escutar notificações de plantio
    _plantioSubscription = _notificationService.plantioNotifications.listen((notification) {
      _addNotification(NotificationItem.fromPlantio(notification));
    });

    // Escutar notificações de qualidade
    _qualitySubscription = _notificationService.qualityNotifications.listen((notification) {
      _addNotification(NotificationItem.fromQuality(notification));
    });

    // Escutar lembretes fenológicos
    _phenologicalSubscription = _notificationService.phenologicalReminders.listen((reminder) {
      _addNotification(NotificationItem.fromPhenological(reminder));
    });
  }

  /// Adiciona nova notificação
  void _addNotification(NotificationItem item) {
    if (mounted) {
      setState(() {
        _notifications.insert(0, item);
        
        // Manter apenas as 10 notificações mais recentes
        if (_notifications.length > 10) {
          _notifications.removeRange(10, _notifications.length);
        }
      });

      // Mostrar snackbar para notificações de alta prioridade
      if (item.prioridade == NotificationPriority.alta) {
        _showHighPrioritySnackBar(item);
      }
    }
  }

  /// Mostra snackbar para notificações de alta prioridade
  void _showHighPrioritySnackBar(NotificationItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              item.icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    item.mensagem,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: item.cor,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () => _showNotificationDetails(item),
        ),
      ),
    );
  }

  /// Mostra detalhes da notificação
  void _showNotificationDetails(NotificationItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(item.icon, color: item.cor),
            const SizedBox(width: 8),
            Expanded(child: Text(item.titulo)),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.mensagem),
            const SizedBox(height: 16),
            Text(
              'Recebido em: ${_formatDateTime(item.timestamp)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (item.detalhes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Detalhes:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...item.detalhes.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key}: ',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Expanded(child: Text(entry.value.toString())),
                  ],
                ),
              )),
            ],
          ],
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

  /// Formata data e hora
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Notificações Recentes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _notifications.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista de notificações
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _notifications.take(5).length, // Mostrar apenas as 5 mais recentes
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationTile(notification);
              },
            ),
            
            // Botão para ver todas
            if (_notifications.length > 5) ...[
              Divider(height: 1, color: Colors.grey.shade200),
              InkWell(
                onTap: () => _showAllNotifications(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.expand_more, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        'Ver todas (${_notifications.length})',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Constrói tile de notificação
  Widget _buildNotificationTile(NotificationItem notification) {
    return InkWell(
      onTap: () => _showNotificationDetails(notification),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: notification.cor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                notification.icon,
                color: notification.cor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.mensagem,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTimeAgo(notification.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: notification.cor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mostra todas as notificações
  void _showAllNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Título
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Todas as Notificações',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            
            // Lista completa
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: _notifications.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return _buildNotificationTile(notification);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calcula tempo decorrido
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else {
      return '${difference.inDays}d atrás';
    }
  }
}

/// Item de notificação para exibição
class NotificationItem {
  final String id;
  final String titulo;
  final String mensagem;
  final DateTime timestamp;
  final NotificationPriority prioridade;
  final IconData icon;
  final Color cor;
  final Map<String, dynamic> detalhes;

  NotificationItem({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.timestamp,
    required this.prioridade,
    required this.icon,
    required this.cor,
    this.detalhes = const {},
  });

  /// Cria item a partir de notificação de plantio
  factory NotificationItem.fromPlantio(PlantioNotification notification) {
    return NotificationItem(
      id: notification.id,
      titulo: notification.titulo,
      mensagem: notification.mensagem,
      timestamp: notification.timestamp,
      prioridade: notification.prioridade,
      icon: Icons.agriculture,
      cor: Colors.green,
      detalhes: {
        'Talhão': notification.plantio.talhaoNome,
        'Cultura': notification.plantio.culturaId,
        'Variedade': notification.plantio.variedadeId ?? 'Não definida',
        'População': '${notification.plantio.populacao} plantas/ha',
        'Fonte': notification.plantio.fonte,
      },
    );
  }

  /// Cria item a partir de notificação de qualidade
  factory NotificationItem.fromQuality(QualityNotification notification) {
    return NotificationItem(
      id: notification.id,
      titulo: notification.titulo,
      mensagem: notification.mensagem,
      timestamp: notification.timestamp,
      prioridade: notification.prioridade,
      icon: Icons.assessment,
      cor: notification.score >= 70 ? Colors.green : Colors.orange,
      detalhes: {
        'Score': '${notification.score}%',
        'Nível': notification.nivel,
        'Recomendações': notification.recomendacoes.length.toString(),
      },
    );
  }

  /// Cria item a partir de lembrete fenológico
  factory NotificationItem.fromPhenological(PhenologicalReminder reminder) {
    return NotificationItem(
      id: reminder.id,
      titulo: reminder.titulo,
      mensagem: reminder.mensagem,
      timestamp: reminder.timestamp,
      prioridade: reminder.prioridade,
      icon: Icons.eco,
      cor: Colors.blue,
      detalhes: {
        'Estágio': reminder.estagio,
        'Dias após plantio': reminder.diasAposPlantio.toString(),
      },
    );
  }
}
