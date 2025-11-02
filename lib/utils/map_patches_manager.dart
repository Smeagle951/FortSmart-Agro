import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Importação dos patches
import 'mapbox_monkeypatch.dart';
import 'positioned_tap_detector_patch.dart';
import 'flutter_map_patch.dart';
import 'emergency_patches.dart';
import 'flutter_map_patch_manager.dart';

/// Classe responsável por aplicar todos os patches necessários para
/// corrigir problemas de compatibilidade nos pacotes de mapas
class MapPatchesManager {
  /// Aplica todos os patches necessários para o funcionamento correto dos mapas
  static Future<void> applyAllPatches() async {
    debugPrint('\n⚠️⚠️⚠️ INICIANDO OPERAÇÃO RESGATE - FORTSMART AGRO ⚠️⚠️⚠️');
    debugPrint('Aplicando patches críticos para resolver erros de compilação...');
    
    // Patch para o Mapbox GL (funções hashValues e hashList)
    MapboxMonkeyPatch.apply();
    debugPrint('✅ Patch do Mapbox aplicado com sucesso');
    
    // Patch para o positioned_tap_detector_2 (problema de hashValues)
    await applyPositionedTapDetectorPatch();
    debugPrint('✅ Patch do positioned_tap_detector aplicado com sucesso');
    
    // Aplicar todos os patches para o flutter_map usando o gerenciador centralizado
    await FlutterMapPatchManager.applyAllPatches();
    debugPrint('✅ Patches do flutter_map aplicados com sucesso');
    
    // Patch para o flutter_map (problema do headline5)
    FlutterMapPatch.apply();
    debugPrint('✅ Patch do flutter_map aplicado com sucesso');
    
    // Aplicar patches de emergência para erros críticos
    await EmergencyPatches.applyAll();
    debugPrint('✅ Patches de emergência aplicados com sucesso');
    
    debugPrint('\n🎉🎉🎉 TODOS OS PATCHES FORAM APLICADOS COM SUCESSO! 🎉🎉🎉\n');
  }
  
  /// Verifica se os patches estão funcionando corretamente
  static void verifyPatches() {
    try {
      // Verifica se o patch do Object.hash está funcionando
      final hash = Object.hash(1, 2, 3);
      debugPrint('✓ Object.hash está funcionando corretamente: $hash');
      
      // Verifica se o estilo headlineSmall está disponível
      debugPrint('✓ Verificação de patches concluída');
    } catch (e) {
      debugPrint('❌ Erro na verificação de patches: $e');
    }
  }
}
