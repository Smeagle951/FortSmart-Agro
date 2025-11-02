import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'logger.dart';

/// Classe utilitária para operações de rede
class NetworkUtils {
  static final NetworkUtils _instance = NetworkUtils._internal();
  static final Connectivity _connectivity = Connectivity();
  static final NetworkInfo _networkInfo = NetworkInfo();
  
  /// Construtor de fábrica para o singleton
  factory NetworkUtils() {
    return _instance;
  }
  
  NetworkUtils._internal();
  
  /// Verifica se o dispositivo está conectado à internet
  static Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.none) {
        return false;
      }
      
      // Verifica se realmente há conectividade tentando acessar um endereço
      final result2 = await InternetAddress.lookup('google.com');
      if (result2.isNotEmpty && result2[0].rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Erro ao verificar conectividade: $e');
      return false;
    }
  }
  
  /// Obtém o tipo de conexão atual
  static Future<ConnectivityResult> getConnectionType() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result;
    } catch (e) {
      Logger.error('Erro ao obter tipo de conexão', e);
      return ConnectivityResult.none;
    }
  }
  
  /// Verifica se a conexão é Wi-Fi
  static Future<bool> isWifiConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result == ConnectivityResult.wifi;
    } catch (e) {
      Logger.error('Erro ao verificar conexão Wi-Fi', e);
      return false;
    }
  }
  
  /// Verifica se a conexão é móvel
  static Future<bool> isMobileConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result == ConnectivityResult.mobile;
    } catch (e) {
      Logger.error('Erro ao verificar conexão móvel', e);
      return false;
    }
  }
  
  /// Obtém o nome da rede Wi-Fi conectada
  static Future<String?> getWifiName() async {
    try {
      return await _networkInfo.getWifiName();
    } catch (e) {
      Logger.error('Erro ao obter nome da rede Wi-Fi', e);
      return null;
    }
  }
  
  /// Obtém o endereço IP local
  static Future<String?> getIpAddress() async {
    try {
      return await _networkInfo.getWifiIP();
    } catch (e) {
      Logger.error('Erro ao obter endereço IP', e);
      return null;
    }
  }
  
  /// Adiciona um listener para mudanças de conectividade
  static StreamSubscription<ConnectivityResult> addConnectivityListener(
    void Function(ConnectivityResult) onConnectivityChanged
  ) {
    // Na versão 4.0.2, onConnectivityChanged retorna ConnectivityResult direto
    return _connectivity.onConnectivityChanged.listen(onConnectivityChanged);
  }
  
  /// Verifica se uma URL está acessível
  static Future<bool> isUrlAccessible(String url) async {
    try {
      final HttpClient client = HttpClient();
      final HttpClientRequest request = await client.getUrl(Uri.parse(url));
      final HttpClientResponse response = await request.close();
      await response.drain<void>();
      return response.statusCode == 200;
    } catch (e) {
      Logger.error('Erro ao verificar acessibilidade da URL', e);
      return false;
    }
  }
}
