import '../constants/ai_constants.dart';

/// Validadores específicos do Sistema IA FortSmart
class AIValidators {
  
  // ===== VALIDAÇÕES DE ENTRADA =====
  
  /// Valida se uma string de busca é válida
  static String? validateSearchQuery(String? query) {
    if (query == null || query.trim().isEmpty) {
      return 'Digite um termo para buscar';
    }
    
    if (query.trim().length < AIConstants.minSearchLength) {
      return 'Digite pelo menos ${AIConstants.minSearchLength} caracteres';
    }
    
    if (query.trim().length > AIConstants.maxSearchLength) {
      return 'Busca muito longa. Máximo ${AIConstants.maxSearchLength} caracteres';
    }
    
    return null;
  }
  
  /// Valida se uma lista de sintomas é válida
  static String? validateSymptoms(List<String> symptoms) {
    if (symptoms.isEmpty) {
      return 'Selecione pelo menos um sintoma';
    }
    
    if (symptoms.length < AIConstants.minSymptomsForDiagnosis) {
      return 'Selecione pelo menos ${AIConstants.minSymptomsForDiagnosis} sintoma';
    }
    
    if (symptoms.length > AIConstants.maxSymptomsForDiagnosis) {
      return 'Máximo ${AIConstants.maxSymptomsForDiagnosis} sintomas permitidos';
    }
    
    // Verifica se há sintomas duplicados
    final uniqueSymptoms = symptoms.toSet();
    if (uniqueSymptoms.length != symptoms.length) {
      return 'Sintomas duplicados não são permitidos';
    }
    
    // Verifica se todos os sintomas são válidos
    for (final symptom in symptoms) {
      if (symptom.trim().isEmpty) {
        return 'Sintoma não pode estar vazio';
      }
      
      if (symptom.trim().length < 3) {
        return 'Sintoma deve ter pelo menos 3 caracteres';
      }
    }
    
    return null;
  }
  
  /// Valida se uma cultura é suportada
  static String? validateCrop(String? crop) {
    if (crop == null || crop.trim().isEmpty) {
      return 'Selecione uma cultura';
    }
    
    // Removido limite restritivo - agora aceita qualquer cultura
    // A validação básica garante que não está vazio
    return null;
  }
  
  /// Valida se um tipo de organismo é válido
  static String? validateOrganismType(String? type) {
    if (type == null || type.trim().isEmpty) {
      return 'Selecione um tipo de organismo';
    }
    
    if (!AIConstants.supportedOrganismTypes.contains(type)) {
      return 'Tipo de organismo não suportado';
    }
    
    return null;
  }
  
  // ===== VALIDAÇÕES DE IMAGEM =====
  
  /// Valida se um arquivo de imagem é válido
  static String? validateImageFile(String? fileName, int? fileSize) {
    if (fileName == null || fileName.trim().isEmpty) {
      return 'Selecione uma imagem';
    }
    
    // Valida formato
    if (!isValidImageFormat(fileName)) {
      return 'Formato de imagem não suportado. Use: ${AIConstants.supportedImageFormats.join(', ')}';
    }
    
    // Valida tamanho
    if (fileSize != null && !isValidImageSize(fileSize)) {
      return 'Imagem muito grande. Máximo ${AIConstants.maxImageSizeMB}MB';
    }
    
    return null;
  }
  
  /// Valida se o formato de imagem é suportado
  static bool isValidImageFormat(String fileName) {
    if (fileName.trim().isEmpty) return false;
    
    final extension = fileName.split('.').last.toLowerCase();
    return AIConstants.supportedImageFormats.contains(extension);
  }
  
  /// Valida se o tamanho da imagem é aceitável
  static bool isValidImageSize(int sizeInBytes) {
    final maxSizeInBytes = AIConstants.maxImageSizeMB * 1024 * 1024;
    return sizeInBytes <= maxSizeInBytes;
  }
  
  // ===== VALIDAÇÕES DE CONFIGURAÇÕES =====
  
  /// Valida se um valor de confiança é válido
  static String? validateConfidence(double confidence) {
    if (confidence < 0.0 || confidence > 1.0) {
      return 'Confiança deve estar entre 0.0 e 1.0';
    }
    
    return null;
  }
  
  /// Valida se um valor de severidade é válido
  static String? validateSeverity(double severity) {
    if (severity < 0.0 || severity > 1.0) {
      return 'Severidade deve estar entre 0.0 e 1.0';
    }
    
    return null;
  }
  
  /// Valida se um valor de risco é válido
  static String? validateRisk(double risk) {
    if (risk < 0.0 || risk > 1.0) {
      return 'Risco deve estar entre 0.0 e 1.0';
    }
    
    return null;
  }
  
  // ===== VALIDAÇÕES DE DATA =====
  
  /// Valida se uma data é válida
  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'Data é obrigatória';
    }
    
    final now = DateTime.now();
    if (date.isAfter(now)) {
      return 'Data não pode ser no futuro';
    }
    
    // Verifica se a data não é muito antiga (mais de 1 ano)
    final oneYearAgo = now.subtract(Duration(days: 365));
    if (date.isBefore(oneYearAgo)) {
      return 'Data muito antiga';
    }
    
    return null;
  }
  
  /// Valida se um período de datas é válido
  static String? validateDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null) {
      return 'Data inicial é obrigatória';
    }
    
    if (endDate == null) {
      return 'Data final é obrigatória';
    }
    
    if (startDate.isAfter(endDate)) {
      return 'Data inicial não pode ser posterior à data final';
    }
    
    // Verifica se o período não é muito longo (máximo 90 dias)
    final difference = endDate.difference(startDate).inDays;
    if (difference > 90) {
      return 'Período muito longo. Máximo 90 dias';
    }
    
    return null;
  }
  
  // ===== VALIDAÇÕES DE CACHE =====
  
  /// Valida se uma chave de cache é válida
  static String? validateCacheKey(String? key) {
    if (key == null || key.trim().isEmpty) {
      return 'Chave de cache é obrigatória';
    }
    
    if (key.trim().length < 3) {
      return 'Chave de cache deve ter pelo menos 3 caracteres';
    }
    
    if (key.trim().length > 100) {
      return 'Chave de cache muito longa';
    }
    
    // Verifica se contém apenas caracteres válidos
    final validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!validPattern.hasMatch(key)) {
      return 'Chave de cache contém caracteres inválidos';
    }
    
    return null;
  }
  
  /// Valida se um tempo de cache é válido
  static String? validateCacheTime(int? minutes) {
    if (minutes == null) {
      return 'Tempo de cache é obrigatório';
    }
    
    if (minutes < 1) {
      return 'Tempo de cache deve ser pelo menos 1 minuto';
    }
    
    if (minutes > 1440) { // 24 horas
      return 'Tempo de cache não pode ser maior que 24 horas';
    }
    
    return null;
  }
  
  // ===== VALIDAÇÕES DE PERFORMANCE =====
  
  /// Valida se um timeout é válido
  static String? validateTimeout(int? seconds) {
    if (seconds == null) {
      return 'Timeout é obrigatório';
    }
    
    if (seconds < 1) {
      return 'Timeout deve ser pelo menos 1 segundo';
    }
    
    if (seconds > 300) { // 5 minutos
      return 'Timeout não pode ser maior que 5 minutos';
    }
    
    return null;
  }
  
  /// Valida se um número de tentativas é válido
  static String? validateRetryAttempts(int? attempts) {
    if (attempts == null) {
      return 'Número de tentativas é obrigatório';
    }
    
    if (attempts < 1) {
      return 'Número de tentativas deve ser pelo menos 1';
    }
    
    if (attempts > 10) {
      return 'Número de tentativas não pode ser maior que 10';
    }
    
    return null;
  }
  
  // ===== VALIDAÇÕES DE CONFIGURAÇÕES DE UI =====
  
  /// Valida se uma duração de animação é válida
  static String? validateAnimationDuration(int? milliseconds) {
    if (milliseconds == null) {
      return 'Duração da animação é obrigatória';
    }
    
    if (milliseconds < 0) {
      return 'Duração da animação não pode ser negativa';
    }
    
    if (milliseconds > 2000) { // 2 segundos
      return 'Duração da animação não pode ser maior que 2 segundos';
    }
    
    return null;
  }
  
  /// Valida se um valor de padding é válido
  static String? validatePadding(double? padding) {
    if (padding == null) {
      return 'Padding é obrigatório';
    }
    
    if (padding < 0) {
      return 'Padding não pode ser negativo';
    }
    
    if (padding > 100) {
      return 'Padding não pode ser maior que 100';
    }
    
    return null;
  }
  
  /// Valida se um border radius é válido
  static String? validateBorderRadius(double? radius) {
    if (radius == null) {
      return 'Border radius é obrigatório';
    }
    
    if (radius < 0) {
      return 'Border radius não pode ser negativo';
    }
    
    if (radius > 50) {
      return 'Border radius não pode ser maior que 50';
    }
    
    return null;
  }
  
  // ===== VALIDAÇÕES DE CONFIGURAÇÕES DE API =====
  
  /// Valida se uma URL de API é válida
  static String? validateApiUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return 'URL da API é obrigatória';
    }
    
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return 'URL da API deve ter protocolo e domínio';
      }
    } catch (e) {
      return 'URL da API inválida';
    }
    
    return null;
  }
  
  /// Valida se uma chave de API é válida
  static String? validateApiKey(String? key) {
    if (key == null || key.trim().isEmpty) {
      return 'Chave da API é obrigatória';
    }
    
    if (key.trim().length < 10) {
      return 'Chave da API deve ter pelo menos 10 caracteres';
    }
    
    return null;
  }
  
  // ===== VALIDAÇÕES COMPOSTAS =====
  
  /// Valida múltiplos campos de uma vez
  static Map<String, String?> validateMultipleFields(Map<String, dynamic> fields) {
    final errors = <String, String?>{};
    
    for (final entry in fields.entries) {
      final fieldName = entry.key;
      final value = entry.value;
      
      switch (fieldName) {
        case 'searchQuery':
          errors[fieldName] = validateSearchQuery(value as String?);
          break;
        case 'symptoms':
          errors[fieldName] = validateSymptoms(value as List<String>);
          break;
        case 'crop':
          errors[fieldName] = validateCrop(value as String?);
          break;
        case 'organismType':
          errors[fieldName] = validateOrganismType(value as String?);
          break;
        case 'confidence':
          errors[fieldName] = validateConfidence(value as double);
          break;
        case 'severity':
          errors[fieldName] = validateSeverity(value as double);
          break;
        case 'risk':
          errors[fieldName] = validateRisk(value as double);
          break;
        case 'date':
          errors[fieldName] = validateDate(value as DateTime?);
          break;
        case 'cacheKey':
          errors[fieldName] = validateCacheKey(value as String?);
          break;
        case 'cacheTime':
          errors[fieldName] = validateCacheTime(value as int?);
          break;
        case 'timeout':
          errors[fieldName] = validateTimeout(value as int?);
          break;
        case 'retryAttempts':
          errors[fieldName] = validateRetryAttempts(value as int?);
          break;
        case 'animationDuration':
          errors[fieldName] = validateAnimationDuration(value as int?);
          break;
        case 'padding':
          errors[fieldName] = validatePadding(value as double?);
          break;
        case 'borderRadius':
          errors[fieldName] = validateBorderRadius(value as double?);
          break;
        case 'apiUrl':
          errors[fieldName] = validateApiUrl(value as String?);
          break;
        case 'apiKey':
          errors[fieldName] = validateApiKey(value as String?);
          break;
        default:
          errors[fieldName] = 'Campo não reconhecido';
      }
    }
    
    return errors;
  }
  
  /// Verifica se há erros de validação
  static bool hasValidationErrors(Map<String, String?> errors) {
    return errors.values.any((error) => error != null);
  }
  
  /// Obtém a primeira mensagem de erro
  static String? getFirstError(Map<String, String?> errors) {
    for (final error in errors.values) {
      if (error != null) return error;
    }
    return null;
  }
}
