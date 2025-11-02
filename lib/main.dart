
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'screens/home_screen.dart';
import 'screens/splash_screen_premium.dart';
import 'routes.dart';
import 'providers/app_providers.dart';
import 'services/talhao_notification_service.dart';
import 'config/env_config.dart';
import 'services/device_location_service.dart';
import 'utils/text_rendering_fix.dart';
import 'modules/offline_maps/services/offline_map_service.dart';
import 'modules/offline_maps/services/talhao_integration_service.dart';
// import 'themes/responsive_theme.dart'; // Arquivo não existe

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializar configurações de ambiente
    await EnvConfig.initialize();
    
    // Inicializar localização do dispositivo
    await DeviceLocationService.instance.getCurrentLocation();
    
    // Inicializar databaseFactory baseado na plataforma
    if (Platform.isAndroid || Platform.isIOS) {
      // Para mobile, usar sqflite padrão
      print('DEBUG: Usando sqflite padrão para mobile');
    } else {
      // Para desktop, usar sqflite_common_ffi
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      print('DEBUG: Usando sqflite_common_ffi para desktop');
    }
    
    // Configurar diretório do banco de dados
    String databasePath;
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Para desktop, usar diretório de documentos
        final documentsDir = await getApplicationDocumentsDirectory();
        databasePath = path.join(documentsDir.path, 'fortsmart_agro.db');
      } else {
        // Para mobile, usar diretório padrão
        databasePath = path.join(await getDatabasesPath(), 'fortsmart_agro.db');
      }
      
      // Criar diretório se não existir
      final dbDir = path.dirname(databasePath);
      await Directory(dbDir).create(recursive: true);
      
      print('DEBUG: databaseFactory inicializado com sucesso');
      print('DEBUG: Caminho do banco: $databasePath');
      
      print('DEBUG: Configuração do banco concluída com sucesso');
    } catch (e) {
      print('DEBUG: Erro ao configurar caminho do banco: $e');
      // Fallback para caminho temporário
      databasePath = path.join(Directory.systemTemp.path, 'fortsmart_agro.db');
      print('DEBUG: Usando caminho temporário: $databasePath');
    }
    
    print('DEBUG: Inicialização do banco concluída');
    
  } catch (e) {
    print('DEBUG: Erro ao inicializar databaseFactory: $e');
  }
  
  try {
    // Configurar path_provider de forma mais robusta
    if (Platform.isAndroid || Platform.isIOS) {
      // Para mobile, usar getDatabasesPath
      await getDatabasesPath();
      print('DEBUG: path_provider configurado para mobile');
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Para desktop, usar getApplicationDocumentsDirectory
      await getApplicationDocumentsDirectory();
      print('DEBUG: path_provider configurado para desktop');
    } else {
      // Para web ou outras plataformas
      print('DEBUG: path_provider configurado para web/outras plataformas');
    }
    print('DEBUG: path_provider configurado com sucesso');
  } catch (e) {
    print('DEBUG: Erro ao configurar path_provider: $e');
    // Fallback para web
    print('DEBUG: Usando fallback para web');
  }
  
  runApp(const FortSmartApp());
}

/// Função para inicializar dados do app durante a splash screen
Future<void> _initializeAppData() async {
  try {
    // Simular carregamento de dados essenciais
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Inicializar serviços de mapas offline
    try {
      await OfflineMapService().init();
      await TalhaoIntegrationService().init();
      print('✅ Serviços de mapas offline inicializados');
    } catch (e) {
      print('⚠️ Erro ao inicializar mapas offline: $e');
    }
    
    // Aqui você pode adicionar:
    // - Carregar configurações do usuário
    // - Verificar conectividade
    // - Inicializar outros serviços
    // - Sincronizar dados offline
    
    print('DEBUG: Dados do app inicializados com sucesso');
  } catch (e) {
    print('DEBUG: Erro ao inicializar dados do app: $e');
    // Continuar mesmo com erro
  }
}

class FortSmartApp extends StatelessWidget {
  const FortSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders.getMultiProvider(
      child: AppLifecycleObserver(
        onResume: () {
          print('📱 App retornou do background - corrigindo renderização');
        },
        onPause: () {
          print('📱 App foi para background');
        },
        child: MaterialApp(
          title: 'FortSmart Agro',
          debugShowCheckedModeBanner: false,
          navigatorKey: TalhaoNotificationService.navigatorKey, // Chave global para notificações
          theme: ThemeData(
            useMaterial3: true, 
            colorSchemeSeed: Colors.green,
            // primarySwatch: Colors.green, // Removido - conflita com colorSchemeSeed
          ),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context),
              child: child!,
            );
          },
          home: SplashScreenPremium(
            nextScreen: const HomeScreen(),
            minimumDuration: const Duration(seconds: 3),
            onInit: _initializeAppData,
          ),
          routes: AppRoutes.allRoutes,
          onGenerateRoute: AppRoutes.generateRoute,
        ),
      ),
    );
  }
}
