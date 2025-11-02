import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../utils/logger.dart';

/// Serviço para gerenciar e monitorar a conectividade com a internet
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  // Estado atual da conectividade
  bool _isConnected = false;
  
  // Stream controller para notificar mudanças de conectividade
  final _connectivityController = StreamController<bool>.broadcast();
  
  // Singleton pattern
  factory ConnectivityService() {
    return _instance;
  }
  
  ConnectivityService._internal();
  
  /// Inicializa o serviço de conectividade
  Future<void> initialize() async {
    // Verificar o estado inicial da conectividade
    _isConnected = await isConnected();
    
    // Iniciar monitoramento de mudanças na conectividade
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    
    Logger.log('Serviço de conectividade inicializado. Estado inicial: ${_isConnected ? 'Conectado' : 'Desconectado'}');
  }
  
  /// Libera recursos ao encerrar o serviço
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
  
  /// Verifica se o dispositivo está conectado à internet
  Future<bool> isConnected() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult == ConnectivityResult.mobile || 
             connectivityResult == ConnectivityResult.wifi;
    } catch (e) {
      Logger.error('Erro ao verificar conectividade', e);
      return false;
    }
  }
  
  /// Atualiza o estado de conectividade e notifica os ouvintes
  void _updateConnectionStatus(ConnectivityResult result) {
    final wasConnected = _isConnected;
    _isConnected = result == ConnectivityResult.mobile || result == ConnectivityResult.wifi;
    
    // Notificar apenas se houver mudança no estado
    if (wasConnected != _isConnected) {
      Logger.log('Estado de conectividade alterado: ${_isConnected ? 'Conectado' : 'Desconectado'}');
      _connectivityController.add(_isConnected);
    }
  }
  
  /// Retorna o estado atual da conectividade
  bool get isOnline => _isConnected;
  
  /// Stream para ouvir mudanças no estado de conectividade
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;
  
  /// Mostra um snackbar informando sobre a mudança de conectividade
  static void showConnectivitySnackBar(BuildContext context, bool isConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isConnected 
              ? 'Conexão com a internet restaurada' 
              : 'Sem conexão com a internet. Operando em modo offline',
        ),
        backgroundColor: isConnected ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// Widget para monitorar mudanças de conectividade e mostrar feedback visual
  static Widget connectivityBuilder({
    required BuildContext context,
    required Widget child,
    Widget? offlineWidget,
    bool showSnackBar = true,
  }) {
    return StreamBuilder<bool>(
      stream: ConnectivityService()._connectivityController.stream,
      builder: (context, snapshot) {
        // Mostrar snackbar se houver mudança de conectividade
        if (snapshot.hasData && showSnackBar) {
          final isConnected = snapshot.data!;
          // Atrasar um pouco para garantir que o scaffold esteja disponível
          Future.delayed(Duration.zero, () {
            showConnectivitySnackBar(context, isConnected);
          });
        }
        
        // Se estiver offline e um widget offline for fornecido, mostrar ele
        if (snapshot.hasData && !snapshot.data! && offlineWidget != null) {
          return offlineWidget;
        }
        
        // Caso contrário, mostrar o widget filho normal
        return child;
      },
    );
  }
}
