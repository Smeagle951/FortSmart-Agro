/// 🎨 Helper: Campos Dinâmicos por Cultura
/// 
/// Helper para determinar quais campos fenológicos devem ser
/// exibidos no formulário de registro baseado na cultura selecionada.
/// 
/// Autor: FortSmart Agro
/// Data: Outubro 2025

class PhenologicalFieldsHelper {
  /// Obtém lista de campos para uma cultura específica
  static List<String> getFieldsForCulture(String cultura) {
    final campos = getCamposPorCultura(cultura);
    return campos.entries.where((e) => e.value).map((e) => e.key).toList();
  }

  /// Obtém label formatado para um campo
  static String getFieldLabel(String fieldId) {
    final labels = {
      'altura': 'Altura (cm)',
      'diasAposEmergencia': 'Dias Após Emergência',
      'numeroFolhas': 'Número de Folhas',
      'numeroFolhasTrifolioladas': 'Número de Trifólios',
      'diametroColmo': 'Diâmetro do Colmo (mm)',
      'vagensPlanta': 'Vagens por Planta',
      'espigasPlanta': 'Espigas por Planta',
      'comprimentoVagens': 'Comprimento Médio Vagem (cm)',
      'graosVagem': 'Grãos por Vagem/Espiga',
      'estande': 'Estande (plantas/ha)',
      'sanidade': 'Sanidade (%)',
      'numeroNos': 'Número de Nós',
      'espacamentoEntreNos': 'Espaçamento entre Nós (cm)',
      'ramosVegetativos': 'Número de Ramos Vegetativos',
      'ramosReprodutivos': 'Número de Ramos Reprodutivos',
      'alturaPrimeiroRamoFrutifero': 'Altura do 1º Ramo Frutífero (cm)',
      'botoesFlorais': 'Número de Botões Florais',
      'macasCapulhos': 'Número de Maçãs/Capulhos',
      'numeroAfilhos': 'Número de Afilhos',
      'comprimentoPanicula': 'Comprimento da Panícula (cm)',
      'insercaoEspiga': 'Inserção da Espiga (cm)',
      'comprimentoEspiga': 'Comprimento da Espiga (cm)',
      'numeroFileirasGraos': 'Número de Fileiras de Grãos',
    };
    return labels[fieldId] ?? fieldId;
  }

  /// Obter campos específicos por cultura
  static Map<String, bool> getCamposPorCultura(String cultura) {
    final culturaLower = cultura.toLowerCase();
    
    return {
      // Campos básicos (sempre visíveis)
      'altura': true,
      'diasAposEmergencia': true,
      'estande': true,
      'sanidade': true,
      
      // Campos específicos por tipo de cultura
      'numeroFolhas': _mostrarNumeroFolhas(culturaLower),
      'numeroFolhasTrifolioladas': _mostrarFolhasTrifolioladas(culturaLower),
      'numeroNos': _mostrarNumeroNos(culturaLower),
      'espacamentoEntreNos': _mostrarEspacamentoNos(culturaLower),
      
      // Algodão específico
      'ramosVegetativos': _ehAlgodao(culturaLower),
      'ramosReprodutivos': _ehAlgodao(culturaLower),
      'alturaPrimeiroRamoFrutifero': _ehAlgodao(culturaLower),
      'botoesFlorais': _ehAlgodao(culturaLower),
      'macasCapulhos': _ehAlgodao(culturaLower),
      
      // Gramíneas (trigo, aveia, arroz)
      'numeroAfilhos': _mostrarAfilhos(culturaLower),
      'comprimentoPanicula': _mostrarPanicula(culturaLower),
      
      // Milho/Sorgo específico
      'diametroColmo': _mostrarDiametroColmo(culturaLower),
      'insercaoEspiga': _mostrarInsercaoEspiga(culturaLower),
      'comprimentoEspiga': _mostrarComprimentoEspiga(culturaLower),
      'numeroFileirasGraos': _ehMilho(culturaLower),
      
      // Desenvolvimento reprodutivo
      'vagensPlanta': _mostrarVagens(culturaLower),
      'espigasPlanta': _mostrarEspigas(culturaLower),
      'comprimentoVagens': _mostrarVagens(culturaLower),
      'graosVagem': _mostrarVagens(culturaLower),
    };
  }
  
  /// Obter título da seção específica da cultura
  static String getTituloSecaoEspecifica(String cultura) {
    final culturaLower = cultura.toLowerCase();
    
    if (_ehAlgodao(culturaLower)) {
      return '🌾 Parâmetros Específicos - Algodão';
    } else if (_ehMilho(culturaLower)) {
      return '🌽 Parâmetros Específicos - Milho';
    } else if (_ehSorgo(culturaLower)) {
      return '🌾 Parâmetros Específicos - Sorgo';
    } else if (_mostrarAfilhos(culturaLower)) {
      return '🌾 Parâmetros Específicos - Cereais de Inverno';
    } else if (_mostrarFolhasTrifolioladas(culturaLower)) {
      return '🌱 Parâmetros Específicos - Leguminosas';
    }
    
    return '📊 Parâmetros Adicionais';
  }
  
  /// Obter tooltip explicativo para cada campo
  static String getTooltip(String campo, String cultura) {
    switch (campo) {
      case 'numeroNos':
        return 'Número total de nós na haste principal (importante para análise de estiolamento)';
      case 'espacamentoEntreNos':
        return 'Espaçamento médio entre nós (cm). Valores altos indicam estiolamento';
      case 'ramosVegetativos':
        return 'Número de ramos vegetativos (algodão). Crescimento em altura';
      case 'ramosReprodutivos':
        return 'Número de ramos reprodutivos/frutíferos (algodão). Produção de maçãs';
      case 'alturaPrimeiroRamoFrutifero':
        return 'Altura do primeiro ramo frutífero (cm). Ideal: 20-30cm para colheita mecanizada';
      case 'botoesFlorais':
        return 'Número de botões florais. Crítico para monitoramento de bicudo';
      case 'macasCapulhos':
        return 'Número de maçãs e capulhos formados';
      case 'numeroAfilhos':
        return 'Número de afilhos/perfilhos (trigo, aveia, arroz)';
      case 'comprimentoPanicula':
        return 'Comprimento da panícula (cm) - arroz, sorgo';
      case 'insercaoEspiga':
        return 'Altura de inserção da espiga (cm). Ideal: 1,0-1,2m para evitar acamamento';
      case 'comprimentoEspiga':
        return 'Comprimento da espiga (cm). Indicador de potencial produtivo';
      case 'numeroFileirasGraos':
        return 'Número de fileiras de grãos na espiga (milho). Componente de rendimento';
      case 'diametroColmo':
        return 'Diâmetro do colmo (mm). Resistência ao acamamento';
      default:
        return '';
    }
  }
  
  /// Obter dica de preenchimento
  static String? getDica(String campo, String cultura) {
    switch (campo) {
      case 'numeroNos':
        return 'Conte os nós da base até o ápice da planta';
      case 'espacamentoEntreNos':
        return 'Será calculado automaticamente se informar altura e nº de nós';
      case 'ramosVegetativos':
        return 'Conte ramos que produzem apenas folhas';
      case 'ramosReprodutivos':
        return 'Conte ramos com botões, flores ou maçãs';
      case 'alturaPrimeiroRamoFrutifero':
        return 'Meça da base até o primeiro ramo com botão floral';
      case 'numeroAfilhos':
        return 'Conte o número total de afilhos por planta';
      case 'insercaoEspiga':
        return 'Meça da base até a inserção da espiga principal';
      default:
        return null;
    }
  }
  
  /// Verificadores de cultura
  static bool _ehAlgodao(String cultura) {
    return cultura.contains('algod') || cultura.contains('cotton');
  }
  
  static bool _ehMilho(String cultura) {
    return cultura.contains('milho') || cultura.contains('corn') || cultura.contains('maize');
  }
  
  static bool _ehSorgo(String cultura) {
    return cultura.contains('sorgo') || cultura.contains('sorghum');
  }
  
  static bool _ehSoja(String cultura) {
    return cultura.contains('soja') || cultura.contains('soy');
  }
  
  static bool _ehFeijao(String cultura) {
    return cultura.contains('feij') || cultura.contains('bean');
  }
  
  static bool _ehTrigo(String cultura) {
    return cultura.contains('trigo') || cultura.contains('wheat');
  }
  
  static bool _ehAveia(String cultura) {
    return cultura.contains('aveia') || cultura.contains('oat');
  }
  
  static bool _ehArroz(String cultura) {
    return cultura.contains('arroz') || cultura.contains('rice');
  }
  
  /// Mostrar campos específicos
  static bool _mostrarNumeroFolhas(String cultura) {
    // Todas as culturas exceto as que usam trifólios
    return !_mostrarFolhasTrifolioladas(cultura);
  }
  
  static bool _mostrarFolhasTrifolioladas(String cultura) {
    return _ehSoja(cultura) || _ehFeijao(cultura);
  }
  
  static bool _mostrarNumeroNos(String cultura) {
    return _ehSoja(cultura) || _ehFeijao(cultura);
  }
  
  static bool _mostrarEspacamentoNos(String cultura) {
    return _mostrarNumeroNos(cultura);
  }
  
  static bool _mostrarAfilhos(String cultura) {
    return _ehTrigo(cultura) || _ehAveia(cultura) || _ehArroz(cultura);
  }
  
  static bool _mostrarPanicula(String cultura) {
    return _ehArroz(cultura) || _ehSorgo(cultura);
  }
  
  static bool _mostrarDiametroColmo(String cultura) {
    return _ehMilho(cultura) || _ehSorgo(cultura);
  }
  
  static bool _mostrarInsercaoEspiga(String cultura) {
    return _ehMilho(cultura);
  }
  
  static bool _mostrarComprimentoEspiga(String cultura) {
    return _ehMilho(cultura);
  }
  
  static bool _mostrarVagens(String cultura) {
    return _ehSoja(cultura) || _ehFeijao(cultura);
  }
  
  static bool _mostrarEspigas(String cultura) {
    return _ehMilho(cultura);
  }
  
  /// Obter ícone para o campo
  static String getIcone(String campo) {
    switch (campo) {
      case 'altura':
        return '📏';
      case 'numeroFolhas':
      case 'numeroFolhasTrifolioladas':
        return '🍃';
      case 'numeroNos':
        return '⚪';
      case 'espacamentoEntreNos':
        return '↕️';
      case 'ramosVegetativos':
        return '🌿';
      case 'ramosReprodutivos':
        return '🌸';
      case 'alturaPrimeiroRamoFrutifero':
        return '📐';
      case 'botoesFlorais':
        return '🌺';
      case 'macasCapulhos':
        return '☁️';
      case 'numeroAfilhos':
        return '🌾';
      case 'comprimentoPanicula':
        return '🌾';
      case 'diametroColmo':
        return '⭕';
      case 'insercaoEspiga':
        return '📍';
      case 'comprimentoEspiga':
        return '🌽';
      case 'numeroFileirasGraos':
        return '🔢';
      case 'vagensPlanta':
        return '🫘';
      case 'espigasPlanta':
        return '🌽';
      default:
        return '📊';
    }
  }
  
  /// Obter valor de referência (se disponível)
  static String? getValorReferencia(String campo, String cultura, int? dae) {
    if (dae == null) return null;
    
    final culturaLower = cultura.toLowerCase();
    
    // Espaçamento entre nós - valores de referência
    if (campo == 'espacamentoEntreNos') {
      if (_ehSoja(culturaLower)) {
        return 'Normal: 5-6 cm/nó';
      } else if (_ehFeijao(culturaLower)) {
        return 'Normal: 4,5-5,5 cm/nó';
      } else if (_ehMilho(culturaLower)) {
        return 'Normal: 12-15 cm/nó';
      }
    }
    
    // Altura do primeiro ramo frutífero (algodão)
    if (campo == 'alturaPrimeiroRamoFrutifero' && _ehAlgodao(culturaLower)) {
      return 'Ideal: 20-30 cm (colheita mecanizada)';
    }
    
    // Inserção da espiga (milho)
    if (campo == 'insercaoEspiga' && _ehMilho(culturaLower)) {
      return 'Ideal: 100-120 cm (resistência ao acamamento)';
    }
    
    return null;
  }
  
  /// Obter unidade de medida
  static String getUnidade(String campo) {
    if (campo.contains('Altura') || campo.contains('altura') || 
        campo.contains('Comprimento') || campo.contains('comprimento') ||
        campo.contains('Espacamento') || campo.contains('espacamento') ||
        campo.contains('Panicula') || campo.contains('panicula') ||
        campo.contains('Espiga') || campo.contains('espiga') ||
        campo.contains('Vagens') || campo.contains('vagens')) {
      return 'cm';
    }
    
    if (campo.contains('Diametro') || campo.contains('diametro') ||
        campo.contains('Colmo') || campo.contains('colmo')) {
      return 'mm';
    }
    
    if (campo.contains('Numero') || campo.contains('numero')) {
      return 'unid.';
    }
    
    return '';
  }
}

