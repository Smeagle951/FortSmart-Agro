import 'package:flutter/material.dart';
import 'package:fortsmart_agro/utils/wrappers/wrappers.dart';

class PermissionHelper {
  /// Verifica se a permissão de armazenamento foi concedida
  /// Se não, solicita a permissão
  static Future<bool> checkStoragePermission(BuildContext context) async {
    // Usando nosso wrapper de permissões personalizado
    return await PermissionHandlerWrapper.requestStoragePermission();
  }
  
  /// Verifica se a permissão de localização foi concedida
  /// Se não, solicita a permissão
  static Future<bool> checkLocationPermission(BuildContext context) async {
    // Usando nosso wrapper de permissões personalizado
    return await PermissionHandlerWrapper.requestLocationPermission();
  }
  
  /// Verifica se a permissão de câmera foi concedida
  /// Se não, solicita a permissão
  static Future<bool> checkCameraPermission(BuildContext context) async {
    // Usando nosso wrapper de permissões personalizado
    return await PermissionHandlerWrapper.requestCameraPermission();
  }
  
  /// Verifica se a permissão de microfone foi concedida
  /// Se não, solicita a permissão
  static Future<bool> checkMicrophonePermission(BuildContext context) async {
    // Como não temos um método específico para microfone no wrapper,
    // vamos usar o método de câmera, que é similar
    return await PermissionHandlerWrapper.requestCameraPermission();
  }
  
  /// Mostra um diálogo explicando por que a permissão é necessária
  static Future<bool> _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
    String buttonText,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(buttonText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
}

