/// Modelo para diferentes tipos de penetrômetros Bluetooth
class PenetrometroDeviceModel {
  final String id;
  final String nome;
  final String fabricante;
  final String modelo;
  final String serviceUuid;
  final String characteristicUuid;
  final PenetrometroProtocolo protocolo;
  final Map<String, dynamic> configuracoes;

  const PenetrometroDeviceModel({
    required this.id,
    required this.nome,
    required this.fabricante,
    required this.modelo,
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.protocolo,
    required this.configuracoes,
  });

  /// Lista de penetrômetros suportados
  static const List<PenetrometroDeviceModel> dispositivosSuportados = [
    // SoilTest Pro
    PenetrometroDeviceModel(
      id: 'soil_test_pro',
      nome: 'SoilTest Pro',
      fabricante: 'SoilTest',
      modelo: 'STP-2023',
      serviceUuid: '0000180A-0000-1000-8000-00805F9B34FB',
      characteristicUuid: '00002A19-0000-1000-8000-00805F9B34FB',
      protocolo: PenetrometroProtocolo.soilTestPro,
      configuracoes: {
        'unidade': 'MPa',
        'precisao': 0.01,
        'range_min': 0.0,
        'range_max': 10.0,
        'frequencia_leitura': 1000, // ms
        'formato_dados': 'float32',
        'endianness': 'little',
      },
    ),

    // FieldPen Digital
    PenetrometroDeviceModel(
      id: 'field_pen_digital',
      nome: 'FieldPen Digital',
      fabricante: 'FieldTech',
      modelo: 'FPD-2023',
      serviceUuid: '0000180D-0000-1000-8000-00805F9B34FB',
      characteristicUuid: '00002A37-0000-1000-8000-00805F9B34FB',
      protocolo: PenetrometroProtocolo.fieldPenDigital,
      configuracoes: {
        'unidade': 'MPa',
        'precisao': 0.1,
        'range_min': 0.0,
        'range_max': 5.0,
        'frequencia_leitura': 2000, // ms
        'formato_dados': 'uint16',
        'endianness': 'big',
      },
    ),

    // AgriPen Compact
    PenetrometroDeviceModel(
      id: 'agri_pen_compact',
      nome: 'AgriPen Compact',
      fabricante: 'AgriTech',
      modelo: 'APC-2023',
      serviceUuid: '0000180F-0000-1000-8000-00805F9B34FB',
      characteristicUuid: '00002A19-0000-1000-8000-00805F9B34FB',
      protocolo: PenetrometroProtocolo.agriPenCompact,
      configuracoes: {
        'unidade': 'MPa',
        'precisao': 0.05,
        'range_min': 0.0,
        'range_max': 8.0,
        'frequencia_leitura': 1500, // ms
        'formato_dados': 'float16',
        'endianness': 'little',
      },
    ),

    // SoilMaster Pro
    PenetrometroDeviceModel(
      id: 'soil_master_pro',
      nome: 'SoilMaster Pro',
      fabricante: 'SoilMaster',
      modelo: 'SMP-2023',
      serviceUuid: '0000180A-0000-1000-8000-00805F9B34FB',
      characteristicUuid: '00002A1C-0000-1000-8000-00805F9B34FB',
      protocolo: PenetrometroProtocolo.soilMasterPro,
      configuracoes: {
        'unidade': 'MPa',
        'precisao': 0.001,
        'range_min': 0.0,
        'range_max': 15.0,
        'frequencia_leitura': 500, // ms
        'formato_dados': 'float32',
        'endianness': 'little',
        'temperatura': true,
        'umidade': true,
        'profundidade': true,
      },
    ),

    // Falker PenetroLOG
    PenetrometroDeviceModel(
      id: 'falker_penetrolog',
      nome: 'PenetroLOG',
      fabricante: 'Falker',
      modelo: 'PenetroLOG',
      serviceUuid: '0000180A-0000-1000-8000-00805F9B34FB', // UUID genérico - precisa ser descoberto
      characteristicUuid: '00002A19-0000-1000-8000-00805F9B34FB', // UUID genérico - precisa ser descoberto
      protocolo: PenetrometroProtocolo.falkerPenetrolog,
      configuracoes: {
        'unidade': 'MPa',
        'precisao': 0.01,
        'range_min': 0.0,
        'range_max': 10.0,
        'frequencia_leitura': 1000, // ms
        'formato_dados': 'float32',
        'endianness': 'little',
        'profundidade_maxima': 60, // cm
        'gps_integrado': true,
        'temperatura': false,
        'umidade': false,
        'profundidade': true,
        'nome_dispositivo': 'PenetroLOG', // Nome que aparece no Bluetooth
      },
    ),

    // Eijkelkamp Penetrologger
    PenetrometroDeviceModel(
      id: 'eijkelkamp_penetrologger',
      nome: 'Penetrologger',
      fabricante: 'Eijkelkamp',
      modelo: 'Penetrologger',
      serviceUuid: '0000180A-0000-1000-8000-00805F9B34FB',
      characteristicUuid: '00002A19-0000-1000-8000-00805F9B34FB',
      protocolo: PenetrometroProtocolo.eijkelkampPenetrologger,
      configuracoes: {
        'unidade': 'MPa',
        'precisao': 0.01,
        'range_min': 0.0,
        'range_max': 15.0,
        'frequencia_leitura': 2000, // ms
        'formato_dados': 'float32',
        'endianness': 'little',
        'profundidade_maxima': 100, // cm
        'gps_integrado': false,
        'temperatura': true,
        'umidade': false,
        'profundidade': true,
        'nome_dispositivo': 'Penetrologger',
      },
    ),

    // Spectrum FieldScout SC-900
    PenetrometroDeviceModel(
      id: 'spectrum_fieldscout_sc900',
      nome: 'FieldScout SC-900',
      fabricante: 'Spectrum Technologies',
      modelo: 'SC-900',
      serviceUuid: '0000180A-0000-1000-8000-00805F9B34FB',
      characteristicUuid: '00002A19-0000-1000-8000-00805F9B34FB',
      protocolo: PenetrometroProtocolo.spectrumFieldscout,
      configuracoes: {
        'unidade': 'MPa',
        'precisao': 0.1,
        'range_min': 0.0,
        'range_max': 5.0,
        'frequencia_leitura': 1500, // ms
        'formato_dados': 'uint16',
        'endianness': 'big',
        'profundidade_maxima': 50, // cm
        'gps_integrado': true,
        'temperatura': true,
        'umidade': true,
        'profundidade': true,
        'nome_dispositivo': 'FieldScout SC-900',
      },
    ),

    // SoilOptix Penetrometer
    PenetrometroDeviceModel(
      id: 'soiloptix_penetrometer',
      nome: 'SoilOptix Penetrometer',
      fabricante: 'SoilOptix',
      modelo: 'SP-2024',
      serviceUuid: '0000180A-0000-1000-8000-00805F9B34FB',
      characteristicUuid: '00002A19-0000-1000-8000-00805F9B34FB',
      protocolo: PenetrometroProtocolo.soiloptixPenetrometer,
      configuracoes: {
        'unidade': 'MPa',
        'precisao': 0.05,
        'range_min': 0.0,
        'range_max': 8.0,
        'frequencia_leitura': 1000, // ms
        'formato_dados': 'float16',
        'endianness': 'little',
        'profundidade_maxima': 80, // cm
        'gps_integrado': true,
        'temperatura': false,
        'umidade': true,
        'profundidade': true,
        'nome_dispositivo': 'SoilOptix Penetrometer',
      },
    ),

    // Agrosmart Penetrometer Pro
    PenetrometroDeviceModel(
      id: 'agrosmart_penetrometer_pro',
      nome: 'Penetrometer Pro',
      fabricante: 'Agrosmart',
      modelo: 'APP-2024',
      serviceUuid: '0000180A-0000-1000-8000-00805F9B34FB',
      characteristicUuid: '00002A19-0000-1000-8000-00805F9B34FB',
      protocolo: PenetrometroProtocolo.agrosmartPenetrometer,
      configuracoes: {
        'unidade': 'MPa',
        'precisao': 0.01,
        'range_min': 0.0,
        'range_max': 12.0,
        'frequencia_leitura': 800, // ms
        'formato_dados': 'float32',
        'endianness': 'little',
        'profundidade_maxima': 60, // cm
        'gps_integrado': true,
        'temperatura': true,
        'umidade': true,
        'profundidade': true,
        'nome_dispositivo': 'Agrosmart Penetrometer Pro',
      },
    ),

    // SoilTest Digital Penetrometer
    PenetrometroDeviceModel(
      id: 'soiltest_digital_penetrometer',
      nome: 'Digital Penetrometer',
      fabricante: 'SoilTest',
      modelo: 'ST-DP-2024',
      serviceUuid: '0000180A-0000-1000-8000-00805F9B34FB',
      characteristicUuid: '00002A19-0000-1000-8000-00805F9B34FB',
      protocolo: PenetrometroProtocolo.soiltestDigital,
      configuracoes: {
        'unidade': 'MPa',
        'precisao': 0.1,
        'range_min': 0.0,
        'range_max': 6.0,
        'frequencia_leitura': 2000, // ms
        'formato_dados': 'uint16',
        'endianness': 'little',
        'profundidade_maxima': 40, // cm
        'gps_integrado': false,
        'temperatura': false,
        'umidade': false,
        'profundidade': true,
        'nome_dispositivo': 'SoilTest Digital Penetrometer',
      },
    ),

    // FieldMaster Compact Penetrometer
    PenetrometroDeviceModel(
      id: 'fieldmaster_compact_penetrometer',
      nome: 'Compact Penetrometer',
      fabricante: 'FieldMaster',
      modelo: 'FCP-2024',
      serviceUuid: '0000180A-0000-1000-8000-00805F9B34FB',
      characteristicUuid: '00002A19-0000-1000-8000-00805F9B34FB',
      protocolo: PenetrometroProtocolo.fieldmasterCompact,
      configuracoes: {
        'unidade': 'MPa',
        'precisao': 0.05,
        'range_min': 0.0,
        'range_max': 4.0,
        'frequencia_leitura': 3000, // ms
        'formato_dados': 'float16',
        'endianness': 'big',
        'profundidade_maxima': 30, // cm
        'gps_integrado': false,
        'temperatura': false,
        'umidade': false,
        'profundidade': true,
        'nome_dispositivo': 'FieldMaster Compact',
      },
    ),

    // AgriSense Pro Penetrometer
    PenetrometroDeviceModel(
      id: 'agrisense_pro_penetrometer',
      nome: 'Pro Penetrometer',
      fabricante: 'AgriSense',
      modelo: 'ASP-2024',
      serviceUuid: '0000180A-0000-1000-8000-00805F9B34FB',
      characteristicUuid: '00002A19-0000-1000-8000-00805F9B34FB',
      protocolo: PenetrometroProtocolo.agrisensePro,
      configuracoes: {
        'unidade': 'MPa',
        'precisao': 0.01,
        'range_min': 0.0,
        'range_max': 10.0,
        'frequencia_leitura': 1200, // ms
        'formato_dados': 'float32',
        'endianness': 'little',
        'profundidade_maxima': 70, // cm
        'gps_integrado': true,
        'temperatura': true,
        'umidade': false,
        'profundidade': true,
        'nome_dispositivo': 'AgriSense Pro',
      },
    ),

    // Generic Penetrometer
    PenetrometroDeviceModel(
      id: 'generic_penetrometer',
      nome: 'Penetrômetro Genérico',
      fabricante: 'Genérico',
      modelo: 'GEN-2023',
      serviceUuid: '0000180A-0000-1000-8000-00805F9B34FB',
      characteristicUuid: '00002A19-0000-1000-8000-00805F9B34FB',
      protocolo: PenetrometroProtocolo.generic,
      configuracoes: {
        'unidade': 'MPa',
        'precisao': 0.1,
        'range_min': 0.0,
        'range_max': 10.0,
        'frequencia_leitura': 2000, // ms
        'formato_dados': 'uint16',
        'endianness': 'little',
      },
    ),
  ];

  /// Busca dispositivo por ID
  static PenetrometroDeviceModel? getById(String id) {
    try {
      return dispositivosSuportados.firstWhere((device) => device.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Lista dispositivos por fabricante
  static List<PenetrometroDeviceModel> getByFabricante(String fabricante) {
    return dispositivosSuportados
        .where((device) => device.fabricante.toLowerCase().contains(fabricante.toLowerCase()))
        .toList();
  }

  /// Lista dispositivos por protocolo
  static List<PenetrometroDeviceModel> getByProtocolo(PenetrometroProtocolo protocolo) {
    return dispositivosSuportados
        .where((device) => device.protocolo == protocolo)
        .toList();
  }
}

/// Protocolos de comunicação suportados
enum PenetrometroProtocolo {
  soilTestPro,
  fieldPenDigital,
  agriPenCompact,
  soilMasterPro,
  falkerPenetrolog,
  eijkelkampPenetrologger,
  spectrumFieldscout,
  soiloptixPenetrometer,
  agrosmartPenetrometer,
  soiltestDigital,
  fieldmasterCompact,
  agrisensePro,
  generic,
}

/// Extensão para facilitar o uso dos protocolos
extension PenetrometroProtocoloExtension on PenetrometroProtocolo {
  String get nome {
    switch (this) {
      case PenetrometroProtocolo.soilTestPro:
        return 'SoilTest Pro Protocol';
      case PenetrometroProtocolo.fieldPenDigital:
        return 'FieldPen Digital Protocol';
      case PenetrometroProtocolo.agriPenCompact:
        return 'AgriPen Compact Protocol';
      case PenetrometroProtocolo.soilMasterPro:
        return 'SoilMaster Pro Protocol';
      case PenetrometroProtocolo.falkerPenetrolog:
        return 'Falker PenetroLOG Protocol';
      case PenetrometroProtocolo.eijkelkampPenetrologger:
        return 'Eijkelkamp Penetrologger Protocol';
      case PenetrometroProtocolo.spectrumFieldscout:
        return 'Spectrum FieldScout Protocol';
      case PenetrometroProtocolo.soiloptixPenetrometer:
        return 'SoilOptix Penetrometer Protocol';
      case PenetrometroProtocolo.agrosmartPenetrometer:
        return 'Agrosmart Penetrometer Protocol';
      case PenetrometroProtocolo.soiltestDigital:
        return 'SoilTest Digital Protocol';
      case PenetrometroProtocolo.fieldmasterCompact:
        return 'FieldMaster Compact Protocol';
      case PenetrometroProtocolo.agrisensePro:
        return 'AgriSense Pro Protocol';
      case PenetrometroProtocolo.generic:
        return 'Generic Protocol';
    }
  }

  String get descricao {
    switch (this) {
      case PenetrometroProtocolo.soilTestPro:
        return 'Protocolo avançado com alta precisão e múltiplos sensores';
      case PenetrometroProtocolo.fieldPenDigital:
        return 'Protocolo simples e confiável para uso em campo';
      case PenetrometroProtocolo.agriPenCompact:
        return 'Protocolo compacto para dispositivos portáteis';
      case PenetrometroProtocolo.soilMasterPro:
        return 'Protocolo profissional com dados completos';
      case PenetrometroProtocolo.falkerPenetrolog:
        return 'Protocolo oficial Falker com GPS integrado e alta precisão';
      case PenetrometroProtocolo.eijkelkampPenetrologger:
        return 'Protocolo Eijkelkamp para medições profundas até 100cm';
      case PenetrometroProtocolo.spectrumFieldscout:
        return 'Protocolo Spectrum com GPS, temperatura e umidade';
      case PenetrometroProtocolo.soiloptixPenetrometer:
        return 'Protocolo SoilOptix com GPS e sensor de umidade';
      case PenetrometroProtocolo.agrosmartPenetrometer:
        return 'Protocolo Agrosmart com sensores completos e GPS';
      case PenetrometroProtocolo.soiltestDigital:
        return 'Protocolo SoilTest digital simples e confiável';
      case PenetrometroProtocolo.fieldmasterCompact:
        return 'Protocolo FieldMaster compacto para uso rápido';
      case PenetrometroProtocolo.agrisensePro:
        return 'Protocolo AgriSense Pro com GPS e temperatura';
      case PenetrometroProtocolo.generic:
        return 'Protocolo genérico para dispositivos compatíveis';
    }
  }

  bool get suportaTemperatura {
    switch (this) {
      case PenetrometroProtocolo.soilMasterPro:
      case PenetrometroProtocolo.eijkelkampPenetrologger:
      case PenetrometroProtocolo.spectrumFieldscout:
      case PenetrometroProtocolo.agrosmartPenetrometer:
      case PenetrometroProtocolo.agrisensePro:
        return true;
      case PenetrometroProtocolo.falkerPenetrolog:
      case PenetrometroProtocolo.soiloptixPenetrometer:
      case PenetrometroProtocolo.soiltestDigital:
      case PenetrometroProtocolo.fieldmasterCompact:
        return false;
      default:
        return false;
    }
  }

  bool get suportaUmidade {
    switch (this) {
      case PenetrometroProtocolo.soilMasterPro:
      case PenetrometroProtocolo.spectrumFieldscout:
      case PenetrometroProtocolo.soiloptixPenetrometer:
      case PenetrometroProtocolo.agrosmartPenetrometer:
        return true;
      case PenetrometroProtocolo.falkerPenetrolog:
      case PenetrometroProtocolo.eijkelkampPenetrologger:
      case PenetrometroProtocolo.soiltestDigital:
      case PenetrometroProtocolo.fieldmasterCompact:
      case PenetrometroProtocolo.agrisensePro:
        return false;
      default:
        return false;
    }
  }

  bool get suportaProfundidade {
    switch (this) {
      case PenetrometroProtocolo.soilMasterPro:
      case PenetrometroProtocolo.falkerPenetrolog:
      case PenetrometroProtocolo.eijkelkampPenetrologger:
      case PenetrometroProtocolo.spectrumFieldscout:
      case PenetrometroProtocolo.soiloptixPenetrometer:
      case PenetrometroProtocolo.agrosmartPenetrometer:
      case PenetrometroProtocolo.soiltestDigital:
      case PenetrometroProtocolo.fieldmasterCompact:
      case PenetrometroProtocolo.agrisensePro:
        return true;
      default:
        return false;
    }
  }

  bool get suportaGPS {
    switch (this) {
      case PenetrometroProtocolo.falkerPenetrolog:
      case PenetrometroProtocolo.spectrumFieldscout:
      case PenetrometroProtocolo.soiloptixPenetrometer:
      case PenetrometroProtocolo.agrosmartPenetrometer:
      case PenetrometroProtocolo.agrisensePro:
        return true;
      case PenetrometroProtocolo.eijkelkampPenetrologger:
      case PenetrometroProtocolo.soiltestDigital:
      case PenetrometroProtocolo.fieldmasterCompact:
        return false;
      default:
        return false;
    }
  }
}
