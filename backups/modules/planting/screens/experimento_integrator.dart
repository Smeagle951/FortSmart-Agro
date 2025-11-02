import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/experimento_model.dart';
import '../services/experimento_service.dart';
import '../services/modules_integration_service.dart';
import '../widgets/enhanced_plot_selector.dart';
import '../widgets/enhanced_crop_selector.dart';
import '../widgets/enhanced_crop_variety_selector.dart';

/// Este arquivo integra as duas partes da implementação da tela de experimento
/// Importando experimento_screen_updated.dart e experimento_screen_updated_part2.dart

export 'experimento_screen_updated.dart';
export 'experimento_screen_updated_part2.dart';

/// Classe de conveniência para facilitar a importação da tela completa
class ExperimentoIntegrator {
  static Widget getScreen({ExperimentoModel? experimento}) {
    return ExperimentoScreenUpdated(experimento: experimento);
  }
}
