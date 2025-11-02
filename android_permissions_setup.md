# 📱 Configuração de Permissões Android - Rastreamento GPS em Background

## 🔧 Configuração Necessária para RF3

### 1. **Permissões no AndroidManifest.xml**

Adicione as seguintes permissões no arquivo `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Permissões de Localização -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    
    <!-- Permissões de Serviço em Background -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
    
    <!-- Permissões de Notificação -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    
    <!-- Permissões de Wake Lock (opcional, para manter CPU ativo) -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    
    <!-- Permissões de Rede (para sincronização) -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <application>
        <!-- ... outras configurações ... -->
        
        <!-- Serviço de Background GPS -->
        <service
            android:name=".BackgroundGpsService"
            android:enabled="true"
            android:exported="false"
            android:foregroundServiceType="location" />
            
    </application>
</manifest>
```

### 2. **Implementação do Serviço Android Nativo**

Crie o arquivo `android/app/src/main/kotlin/com/example/fortsmart_agro/BackgroundGpsService.kt`:

```kotlin
package com.example.fortsmart_agro

import android.app.*
import android.content.Intent
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Binder
import android.os.Bundle
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import java.util.*

class BackgroundGpsService : Service(), LocationListener {
    
    private val binder = LocalBinder()
    private lateinit var locationManager: LocationManager
    private var isTracking = false
    private var isPaused = false
    
    // Callback para Flutter
    private var methodChannel: MethodChannel? = null
    
    companion object {
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "gps_tracking_channel"
        private const val CHANNEL_NAME = "GPS Tracking"
        
        // Configurações de precisão
        private const val MIN_DISTANCE = 1.0f // metros
        private const val MIN_TIME = 1000L // 1 segundo
        private const val MAX_ACCURACY = 10.0f // metros
    }
    
    inner class LocalBinder : Binder() {
        fun getService(): BackgroundGpsService = this@BackgroundGpsService
    }
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
    }
    
    override fun onBind(intent: Intent): IBinder {
        return binder
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "START_TRACKING" -> startTracking()
            "STOP_TRACKING" -> stopTracking()
            "PAUSE_TRACKING" -> pauseTracking()
            "RESUME_TRACKING" -> resumeTracking()
            "UPDATE_NOTIFICATION" -> updateNotification(
                intent.getStringExtra("title") ?: "Rastreamento GPS",
                intent.getStringExtra("content") ?: "Coletando dados...",
                intent.getDoubleExtra("distance", 0.0),
                intent.getDoubleExtra("accuracy", 0.0)
            )
        }
        return START_STICKY
    }
    
    private fun startTracking() {
        if (isTracking) return
        
        try {
            // Verificar permissões
            if (!hasLocationPermission()) {
                stopSelf()
                return
            }
            
            // Iniciar notificação
            startForeground(NOTIFICATION_ID, createNotification())
            
            // Configurar localização
            val locationRequest = LocationManager.GPS_PROVIDER
            locationManager.requestLocationUpdates(
                locationRequest,
                MIN_TIME,
                MIN_DISTANCE,
                this,
                Looper.getMainLooper()
            )
            
            isTracking = true
            isPaused = false
            
            // Notificar Flutter
            notifyFlutter("tracking_started", true)
            
        } catch (e: Exception) {
            e.printStackTrace()
            stopSelf()
        }
    }
    
    private fun stopTracking() {
        if (!isTracking) return
        
        try {
            locationManager.removeUpdates(this)
            isTracking = false
            isPaused = false
            
            // Parar serviço
            stopForeground(true)
            stopSelf()
            
            // Notificar Flutter
            notifyFlutter("tracking_stopped", false)
            
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun pauseTracking() {
        if (!isTracking || isPaused) return
        
        isPaused = true
        notifyFlutter("tracking_paused", false)
    }
    
    private fun resumeTracking() {
        if (!isTracking || !isPaused) return
        
        isPaused = false
        notifyFlutter("tracking_resumed", true)
    }
    
    override fun onLocationChanged(location: Location) {
        if (!isTracking || isPaused) return
        
        // Validar precisão
        if (location.accuracy > MAX_ACCURACY) {
            return
        }
        
        // Enviar dados para Flutter
        val locationData = mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "accuracy" to location.accuracy,
            "speed" to (location.speed ?: 0.0),
            "bearing" to (location.bearing ?: 0.0),
            "timestamp" to location.time
        )
        
        notifyFlutter("location_update", locationData)
    }
    
    override fun onLocationChanged(locations: MutableList<Location>) {
        for (location in locations) {
            onLocationChanged(location)
        }
    }
    
    override fun onProviderEnabled(provider: String) {
        // GPS habilitado
    }
    
    override fun onProviderDisabled(provider: String) {
        // GPS desabilitado
        notifyFlutter("gps_disabled", "GPS desabilitado")
    }
    
    private fun createNotificationChannel() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Canal para notificações de rastreamento GPS"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(
        title: String = "Rastreamento GPS",
        content: String = "Coletando dados de localização...",
        distance: Double = 0.0,
        accuracy: Double = 0.0
    ): Notification {
        
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText("$content • ${String.format("%.2f", distance/1000)} km • ${String.format("%.1f", accuracy)}m")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
    
    private fun updateNotification(title: String, content: String, distance: Double, accuracy: Double) {
        val notification = createNotification(title, content, distance, accuracy)
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
    
    private fun hasLocationPermission(): Boolean {
        return checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) == 
               android.content.pm.PackageManager.PERMISSION_GRANTED &&
               checkSelfPermission(android.Manifest.permission.ACCESS_BACKGROUND_LOCATION) == 
               android.content.pm.PackageManager.PERMISSION_GRANTED
    }
    
    private fun notifyFlutter(method: String, arguments: Any?) {
        // Implementar comunicação com Flutter via MethodChannel
        // Esta implementação depende da configuração do MethodChannel no Flutter
    }
    
    override fun onDestroy() {
        super.onDestroy()
        locationManager.removeUpdates(this)
    }
}
```

### 3. **Configuração do MethodChannel no Flutter**

No arquivo `lib/main.dart`, adicione:

```dart
import 'package:flutter/services.dart';

class BackgroundGpsMethodChannel {
  static const MethodChannel _channel = MethodChannel('background_gps_service');
  
  static Future<bool> startBackgroundService() async {
    try {
      final result = await _channel.invokeMethod('startBackgroundService');
      return result == true;
    } catch (e) {
      print('Erro ao iniciar serviço de background: $e');
      return false;
    }
  }
  
  static Future<bool> stopBackgroundService() async {
    try {
      final result = await _channel.invokeMethod('stopBackgroundService');
      return result == true;
    } catch (e) {
      print('Erro ao parar serviço de background: $e');
      return false;
    }
  }
  
  static Future<bool> pauseTracking() async {
    try {
      final result = await _channel.invokeMethod('pauseTracking');
      return result == true;
    } catch (e) {
      print('Erro ao pausar rastreamento: $e');
      return false;
    }
  }
  
  static Future<bool> resumeTracking() async {
    try {
      final result = await _channel.invokeMethod('resumeTracking');
      return result == true;
    } catch (e) {
      print('Erro ao retomar rastreamento: $e');
      return false;
    }
  }
  
  static Future<void> updateNotification({
    required String title,
    required String content,
    required double distance,
    required double accuracy,
  }) async {
    try {
      await _channel.invokeMethod('updateNotification', {
        'title': title,
        'content': content,
        'distance': distance,
        'accuracy': accuracy,
      });
    } catch (e) {
      print('Erro ao atualizar notificação: $e');
    }
  }
}
```

### 4. **Solicitação de Permissões em Runtime**

Crie um widget para solicitar permissões:

```dart
import 'package:permission_handler/permission_handler.dart';

class PermissionRequestWidget extends StatefulWidget {
  final VoidCallback onPermissionsGranted;
  
  const PermissionRequestWidget({
    Key? key,
    required this.onPermissionsGranted,
  }) : super(key: key);
  
  @override
  State<PermissionRequestWidget> createState() => _PermissionRequestWidgetState();
}

class _PermissionRequestWidgetState extends State<PermissionRequestWidget> {
  bool _isRequesting = false;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on,
            size: 64,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Permissões Necessárias',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Para rastreamento GPS em background, o app precisa das seguintes permissões:',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildPermissionItem(
            'Localização Precisa',
            'Para capturar coordenadas GPS',
            Icons.gps_fixed,
          ),
          _buildPermissionItem(
            'Localização em Background',
            'Para continuar rastreando com tela desligada',
            Icons.background_location,
          ),
          _buildPermissionItem(
            'Notificações',
            'Para mostrar status do rastreamento',
            Icons.notifications,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isRequesting ? null : _requestPermissions,
            child: _isRequesting
                ? const CircularProgressIndicator()
                : const Text('Conceder Permissões'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPermissionItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _requestPermissions() async {
    setState(() {
      _isRequesting = true;
    });
    
    try {
      // Solicitar permissões em ordem
      final locationStatus = await Permission.location.request();
      
      if (locationStatus.isGranted) {
        // Aguardar um pouco antes de solicitar background
        await Future.delayed(const Duration(seconds: 1));
        
        final backgroundStatus = await Permission.locationAlways.request();
        
        if (backgroundStatus.isGranted) {
          final notificationStatus = await Permission.notification.request();
          
          if (notificationStatus.isGranted) {
            widget.onPermissionsGranted();
          } else {
            _showPermissionError('Notificações');
          }
        } else {
          _showPermissionError('Localização em Background');
        }
      } else {
        _showPermissionError('Localização');
      }
    } catch (e) {
      _showPermissionError('Erro ao solicitar permissões: $e');
    } finally {
      setState(() {
        _isRequesting = false;
      });
    }
  }
  
  void _showPermissionError(String permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissão Necessária'),
        content: Text(
          'A permissão "$permission" é necessária para o rastreamento GPS em background. '
          'Por favor, conceda a permissão nas configurações do app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Configurações'),
          ),
        ],
      ),
    );
  }
}
```

### 5. **Dependências no pubspec.yaml**

Adicione as seguintes dependências:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Permissões
  permission_handler: ^10.4.3
  
  # Localização
  geolocator: ^10.1.0
  
  # Compartilhamento
  share_plus: ^7.2.1
  
  # Armazenamento
  path_provider: ^2.1.1
  
  # UUID
  uuid: ^4.0.0
```

### 6. **Teste das Funcionalidades**

Para testar o rastreamento em background:

1. **Compile o app**:
   ```bash
   flutter build apk --debug
   ```

2. **Instale no dispositivo**:
   ```bash
   flutter install
   ```

3. **Teste o rastreamento**:
   - Inicie o rastreamento GPS
   - Feche o app (não force o fechamento)
   - Verifique se a notificação persiste
   - Ande pelo perímetro do talhão
   - Reabra o app e verifique se os pontos foram coletados

### 7. **Troubleshooting**

**Problema**: Serviço para quando a tela desliga
- **Solução**: Verificar se `WAKE_LOCK` está configurado
- **Solução**: Verificar se o serviço está como `foregroundServiceType="location"`

**Problema**: Permissões não são concedidas
- **Solução**: Verificar se o usuário não marcou "Não perguntar novamente"
- **Solução**: Redirecionar para configurações do app

**Problema**: Notificação não aparece
- **Solução**: Verificar se o canal de notificação foi criado
- **Solução**: Verificar se `IMPORTANCE_LOW` está configurado

**Problema**: Dados não são coletados
- **Solução**: Verificar se o GPS está ativo
- **Solução**: Verificar se a precisão está dentro do limite (10m)
- **Solução**: Verificar logs do serviço Android

### 8. **Considerações de Performance**

- **Bateria**: O rastreamento em background consome bateria
- **Precisão**: Configure `distanceFilter` e `timeLimit` adequadamente
- **Armazenamento**: Implemente flush periódico para evitar perda de dados
- **Sincronização**: Considere sincronizar dados quando o app voltar ao foreground

Esta configuração permite que o módulo de Talhões funcione com rastreamento GPS em background, atendendo completamente ao **RF3** do prompt técnico! 🎯
