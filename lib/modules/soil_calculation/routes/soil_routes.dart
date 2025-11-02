import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/soil_compaction_point_repository.dart';
import '../screens/soil_compaction_main_v2_screen.dart';
import '../screens/soil_compaction_menu_screen.dart';
import '../screens/simple_compaction_screen.dart';
import '../screens/irp_compaction_screen.dart';
import '../screens/soil_collection_screen.dart';
import '../screens/soil_map_visualization_screen.dart';
import '../screens/soil_trajectory_mode_screen.dart';
import '../screens/soil_laboratory_upload_screen.dart';
import '../screens/soil_temporal_analysis_screen.dart';
import '../screens/soil_report_generation_screen.dart';
import '../screens/soil_bluetooth_collection_screen.dart';
import '../screens/penetrometro_bluetooth_professional_screen.dart';

class SoilRoutes {
  static const String main = '/soil';
  static const String compaction = '/soil/compaction';
  static const String simpleCompaction = '/soil/compaction/simple';
  static const String irpCompaction = '/soil/compaction/irp';
  
  // Novas rotas V2.0
  static const String collection = '/soil/collection';
  static const String mapVisualization = '/soil/map';
  static const String trajectoryMode = '/soil/trajectory';
  static const String laboratoryUpload = '/soil/laboratory';
  static const String temporalAnalysis = '/soil/temporal';
  static const String reportGeneration = '/soil/reports';
  static const String bluetoothCollection = '/soil/bluetooth';
  static const String bluetoothProfessional = '/soil/bluetooth-pro';

  static Map<String, WidgetBuilder> get routes => {
    main: (context) => ChangeNotifierProvider<SoilCompactionPointRepository>(
      create: (_) => SoilCompactionPointRepository(),
      child: const SoilCompactionMainV2Screen(),
    ),
    compaction: (context) => const SoilCompactionMenuScreen(),
    simpleCompaction: (context) => const SimpleCompactionScreen(),
    irpCompaction: (context) => const IrpCompactionScreen(),
    
    // Novas rotas V2.0
    collection: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return SoilCollectionScreen(
        ponto: args?['ponto'],
        talhaoId: args?['talhaoId'] ?? 0,
      );
    },
    mapVisualization: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return SoilMapVisualizationScreen(
        talhaoId: args?['talhaoId'] ?? 0,
        nomeTalhao: args?['nomeTalhao'] ?? 'Talhão',
        polygonCoordinates: args?['polygonCoordinates'] ?? [],
      );
    },
    trajectoryMode: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return SoilTrajectoryModeScreen(
        talhaoId: args?['talhaoId'] ?? 0,
        nomeTalhao: args?['nomeTalhao'] ?? 'Talhão',
        polygonCoordinates: args?['polygonCoordinates'] ?? [],
      );
    },
    laboratoryUpload: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return SoilLaboratoryUploadScreen(
        pointId: args?['pointId'] ?? 0,
        pointCode: args?['pointCode'] ?? 'C-001',
      );
    },
    temporalAnalysis: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return SoilTemporalAnalysisScreen(
        talhaoId: args?['talhaoId'] ?? 0,
        nomeTalhao: args?['nomeTalhao'] ?? 'Talhão',
        polygonCoordinates: args?['polygonCoordinates'] ?? [],
      );
    },
    reportGeneration: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return SoilReportGenerationScreen(
        talhaoId: args?['talhaoId'] ?? 0,
        nomeTalhao: args?['nomeTalhao'] ?? 'Talhão',
        nomeFazenda: args?['nomeFazenda'] ?? 'Fazenda',
        polygonCoordinates: args?['polygonCoordinates'] ?? [],
      );
    },
    bluetoothCollection: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return SoilBluetoothCollectionScreen(
        talhaoId: args?['talhaoId'],
        nomeTalhao: args?['nomeTalhao'],
        polygonCoordinates: args?['polygonCoordinates'],
      );
    },
    bluetoothProfessional: (context) => const PenetrometroBluetoothProfessionalScreen(),
  };
}
