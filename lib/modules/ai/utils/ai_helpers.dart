import 'dart:math';
import 'dart:convert';
import '../constants/ai_constants.dart';
import '../models/ai_organism_data.dart';
import '../models/ai_diagnosis_result.dart';

/// Utilitários do Sistema IA FortSmart
class AIHelpers {
  
  // ===== FUNÇÕES DE VALIDAÇÃO =====
  
  /// Valida se uma string está vazia ou nula
  static bool isValidString(String? text) {
    return text != null && text.trim().isNotEmpty;
  }
  
  /// Valida se uma lista não está vazia
  static bool isValidList(List? list) {
    return list != null && list.isNotEmpty;
  }
  
  /// Valida se um número está dentro do intervalo
  static bool isValidRange(double value, double min, double max) {
    return value >= min && value <= max;
  }
  
  /// Valida se uma imagem tem formato suportado
  static bool isValidImageFormat(String fileName) {
    if (!isValidString(fileName)) return false;
    
    final extension = fileName.split('.').last.toLowerCase();
    return AIConstants.supportedImageFormats.contains(extension);
  }
  
  /// Valida se uma imagem tem tamanho válido
  static bool isValidImageSize(int sizeInBytes) {
    final maxSizeInBytes = AIConstants.maxImageSizeMB * 1024 * 1024;
    return sizeInBytes <= maxSizeInBytes;
  }
  
  // ===== FUNÇÕES DE FORMATAÇÃO =====
  
  /// Formata um número para porcentagem
  static String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }
  
  /// Formata um número para decimal
  static String formatDecimal(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }
  
  /// Formata um tamanho de arquivo
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  /// Formata uma data para exibição
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  /// Formata uma data e hora para exibição
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  // ===== FUNÇÕES DE CÁLCULO =====
  
  /// Calcula a similaridade entre duas strings
  static double calculateStringSimilarity(String text1, String text2) {
    if (text1.isEmpty || text2.isEmpty) return 0.0;
    
    final normalized1 = text1.toLowerCase().trim();
    final normalized2 = text2.toLowerCase().trim();
    
    if (normalized1 == normalized2) return 1.0;
    
    // Algoritmo de similaridade de Jaccard
    final set1 = normalized1.split(' ').toSet();
    final set2 = normalized2.split(' ').toSet();
    
    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;
    
    return union > 0 ? intersection / union : 0.0;
  }
  
  /// Calcula a similaridade entre listas de sintomas
  static double calculateSymptomsSimilarity(List<String> symptoms1, List<String> symptoms2) {
    if (symptoms1.isEmpty || symptoms2.isEmpty) return 0.0;
    
    double totalSimilarity = 0.0;
    int comparisons = 0;
    
    for (final symptom1 in symptoms1) {
      for (final symptom2 in symptoms2) {
        final similarity = calculateStringSimilarity(symptom1, symptom2);
        totalSimilarity += similarity;
        comparisons++;
      }
    }
    
    return comparisons > 0 ? totalSimilarity / comparisons : 0.0;
  }
  
  /// Calcula a confiança baseada na similaridade
  static double calculateConfidence(double similarity) {
    // Aplica uma função sigmóide para suavizar a confiança
    return 1.0 / (1.0 + exp(-10 * (similarity - 0.5)));
  }
  
  /// Calcula a severidade média de uma lista de organismos
  static double calculateAverageSeverity(List<AIOrganismData> organisms) {
    if (organisms.isEmpty) return 0.0;
    
    final totalSeverity = organisms.fold<double>(0.0, (sum, org) => sum + org.severity);
    return totalSeverity / organisms.length;
  }
  
  // ===== FUNÇÕES DE FILTRO =====
  
  /// Filtra organismos por cultura
  static List<AIOrganismData> filterByCrop(List<AIOrganismData> organisms, String crop) {
    if (!isValidString(crop)) return organisms;
    
    return organisms.where((org) => 
        org.crops.any((c) => c.toLowerCase() == crop.toLowerCase())
    ).toList();
  }
  
  /// Filtra organismos por tipo
  static List<AIOrganismData> filterByType(List<AIOrganismData> organisms, String type) {
    if (!isValidString(type)) return organisms;
    
    return organisms.where((org) => 
        org.type.toLowerCase() == type.toLowerCase()
    ).toList();
  }
  
  /// Filtra organismos por severidade mínima
  static List<AIOrganismData> filterByMinSeverity(List<AIOrganismData> organisms, double minSeverity) {
    return organisms.where((org) => org.severity >= minSeverity).toList();
  }
  
  /// Filtra organismos por severidade máxima
  static List<AIOrganismData> filterByMaxSeverity(List<AIOrganismData> organisms, double maxSeverity) {
    return organisms.where((org) => org.severity <= maxSeverity).toList();
  }
  
  // ===== FUNÇÕES DE BUSCA =====
  
  /// Busca organismos por texto
  static List<AIOrganismData> searchOrganisms(List<AIOrganismData> organisms, String query) {
    if (!isValidString(query) || query.length < AIConstants.minSearchLength) {
      return organisms;
    }
    
    final normalizedQuery = query.toLowerCase().trim();
    
    return organisms.where((org) {
      // Busca no nome
      if (org.name.toLowerCase().contains(normalizedQuery)) return true;
      
      // Busca no nome científico
      if (org.scientificName.toLowerCase().contains(normalizedQuery)) return true;
      
      // Busca nos sintomas
      if (org.symptoms.any((symptom) => 
          symptom.toLowerCase().contains(normalizedQuery))) return true;
      
      // Busca nas palavras-chave
      if (org.keywords.any((keyword) => 
          keyword.toLowerCase().contains(normalizedQuery))) return true;
      
      // Busca na descrição
      if (org.description.toLowerCase().contains(normalizedQuery)) return true;
      
      return false;
    }).toList();
  }
  
  // ===== FUNÇÕES DE ORDENAÇÃO =====
  
  /// Ordena organismos por severidade (decrescente)
  static List<AIOrganismData> sortBySeverity(List<AIOrganismData> organisms) {
    final sorted = List<AIOrganismData>.from(organisms);
    sorted.sort((a, b) => b.severity.compareTo(a.severity));
    return sorted;
  }
  
  /// Ordena organismos por nome
  static List<AIOrganismData> sortByName(List<AIOrganismData> organisms) {
    final sorted = List<AIOrganismData>.from(organisms);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }
  
  /// Ordena resultados de diagnóstico por confiança
  static List<AIDiagnosisResult> sortByConfidence(List<AIDiagnosisResult> results) {
    final sorted = List<AIDiagnosisResult>.from(results);
    sorted.sort((a, b) => b.confidence.compareTo(a.confidence));
    return sorted;
  }
  
  // ===== FUNÇÕES DE CACHE =====
  
  /// Gera uma chave de cache para organismos
  static String generateOrganismCacheKey() {
    return 'ai_organisms_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// Gera uma chave de cache para diagnóstico
  static String generateDiagnosisCacheKey(List<String> symptoms) {
    final symptomsHash = symptoms.join('_').hashCode.toString();
    return 'ai_diagnosis_$symptomsHash';
  }
  
  /// Gera uma chave de cache para predição
  static String generatePredictionCacheKey(String crop, DateTime date) {
    final dateHash = date.millisecondsSinceEpoch.toString();
    return 'ai_prediction_${crop}_$dateHash';
  }
  
  // ===== FUNÇÕES DE LOGGING =====
  
  /// Log de debug
  static void debugLog(String message) {
    if (AIConstants.enableDebugLogs) {
      print('${AIConstants.logPrefix} [DEBUG] $message');
    }
  }
  
  /// Log de erro
  static void errorLog(String message, [dynamic error]) {
    print('${AIConstants.logPrefix} [ERROR] $message');
    if (error != null) {
      print('${AIConstants.logPrefix} [ERROR] Details: $error');
    }
  }
  
  /// Log de informação
  static void infoLog(String message) {
    print('${AIConstants.logPrefix} [INFO] $message');
  }
  
  /// Log de warning
  static void warningLog(String message) {
    print('${AIConstants.logPrefix} [WARNING] $message');
  }
  
  // ===== FUNÇÕES DE VALIDAÇÃO DE DADOS =====
  
  /// Valida se um organismo tem dados válidos
  static bool isValidOrganism(AIOrganismData organism) {
    return isValidString(organism.name) &&
           isValidString(organism.scientificName) &&
           isValidString(organism.type) &&
           isValidList(organism.crops) &&
           isValidList(organism.symptoms) &&
           isValidList(organism.managementStrategies) &&
           isValidRange(organism.severity, 0.0, 1.0);
  }
  
  /// Valida se um resultado de diagnóstico tem dados válidos
  static bool isValidDiagnosisResult(AIDiagnosisResult result) {
    return isValidString(result.organismName) &&
           isValidString(result.scientificName) &&
           isValidRange(result.confidence, 0.0, 1.0) &&
           isValidList(result.matchedSymptoms) &&
           isValidList(result.recommendations);
  }
  
  // ===== FUNÇÕES DE CONVERSÃO =====
  
  /// Converte uma lista de organismos para JSON
  static String organismsToJson(List<AIOrganismData> organisms) {
    final jsonList = organisms.map((org) => org.toMap()).toList();
    return jsonEncode(jsonList);
  }
  
  /// Converte JSON para lista de organismos
  static List<AIOrganismData> organismsFromJson(String json) {
    try {
      final jsonList = jsonDecode(json) as List;
      return jsonList.map((item) => AIOrganismData.fromMap(item)).toList();
    } catch (e) {
      errorLog('Erro ao converter JSON para organismos', e);
      return [];
    }
  }
  
  /// Converte uma lista de resultados para JSON
  static String resultsToJson(List<AIDiagnosisResult> results) {
    final jsonList = results.map((result) => result.toMap()).toList();
    return jsonEncode(jsonList);
  }
  
  /// Converte JSON para lista de resultados
  static List<AIDiagnosisResult> resultsFromJson(String json) {
    try {
      final jsonList = jsonDecode(json) as List;
      return jsonList.map((item) => AIDiagnosisResult.fromMap(item)).toList();
    } catch (e) {
      errorLog('Erro ao converter JSON para resultados', e);
      return [];
    }
  }
  
  // ===== FUNÇÕES DE UTILIDADE GERAL =====
  
  /// Gera um ID único
  static String generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }
  
  /// Verifica se uma string contém apenas números
  static bool isNumeric(String text) {
    return double.tryParse(text) != null;
  }
  
  /// Capitaliza a primeira letra de uma string
  static String capitalize(String text) {
    if (!isValidString(text)) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  /// Remove acentos de uma string
  static String removeAccents(String text) {
    return text
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }
}
