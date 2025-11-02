# 🚀 Guia Rápido: IA Unificada FortSmart

## ⚡ **USO RÁPIDO EM 3 PASSOS**

### **1. Inicializar (uma vez no app)**
```dart
final ai = FortSmartAgronomicAI();
await ai.initialize();
```

### **2. Usar em qualquer módulo**
```dart
// Germinação
final result = await ai.analyzeGermination(...);

// Vigor
final vigor = await ai.analyzeVigor(...);

// Diagnóstico
final diag = await ai.diagnoseBySyntoms(...);

// Infestação
final infest = await ai.analyzeInfestation(...);

// Predição
final pred = await ai.predictOutbreakRisk(...);
```

### **3. Ver resultados**
```dart
print(result['germinacao_percentual']);
print(result['classificacao']);
print(result['recomendacoes']);
```

---

## 📊 **EXEMPLOS PRÁTICOS**

### **Exemplo 1: Teste de Germinação**
```dart
final ai = FortSmartAgronomicAI();

final resultado = await ai.analyzeGermination(
  contagensPorDia: {
    3: 5,
    5: 28,
    7: 35,
    10: 42,
  },
  sementesTotais: 50,
  germinadasFinal: 45,
  manchas: 2,
  podridao: 1,
  cotiledonesAmarelados: 1,
  pureza: 98.0,
  cultura: 'soja',
);

// Resultados:
// ✅ Germinação: 90%
// ✅ Vigor (PCG): 62.2%
// ✅ IVG: 11.43
// ✅ Valor Cultural: 88.2%
// ✅ Classificação: Classe A (Premium)
```

### **Exemplo 2: Análise Rápida de Vigor**
```dart
final ai = FortSmartAgronomicAI();

final vigor = await ai.analyzeVigor(
  germinadas: 32,
  dia: 5,
  sementesTotais: 50,
  cultura: 'milho',
);

// Resultados:
// ✅ Vigor: 82%
// ✅ Classificação: Alto
// ✅ Recomendações: Lote de alta qualidade
```

### **Exemplo 3: Diagnóstico de Pragas**
```dart
final ai = FortSmartAgronomicAI();

final diagnostico = await ai.diagnoseBySyntoms(
  sintomas: [
    'manchas escuras nas folhas',
    'desfolha',
    'murcha',
  ],
  cultura: 'soja',
);

// Resultados:
// Organismo: Ferrugem asiática
// Confiança: 85%
// Tipo: Doença fúngica
// Estratégias: [...]
```

---

## 🔄 **MIGRAÇÃO DOS SERVIÇOS ANTIGOS**

### **Substitua:**

```dart
// ❌ ANTES
final tfliteService = TFLiteAIService();
await tfliteService.initialize();
final result = await tfliteService.analyze(...);

// ✅ AGORA
final ai = FortSmartAgronomicAI();
await ai.initialize();
final result = await ai.analyzeGermination(...);
```

```dart
// ❌ ANTES
final diagService = AIDiagnosisService();
final result = await diagService.diagnose(...);

// ✅ AGORA
final ai = FortSmartAgronomicAI();
final result = await ai.diagnoseBySyntoms(...);
```

---

## ✅ **CHECKLIST DE USO**

### **Setup Inicial:**
- [ ] Import: `import 'package:fortsmart_agro/services/fortsmart_agronomic_ai.dart';`
- [ ] Criar instância: `final ai = FortSmartAgronomicAI();`
- [ ] Inicializar: `await ai.initialize();`

### **Usar Módulos:**
- [ ] Germinação: `await ai.analyzeGermination(...)`
- [ ] Vigor: `await ai.analyzeVigor(...)`
- [ ] Diagnóstico: `await ai.diagnoseBySyntoms(...)`
- [ ] Infestação: `await ai.analyzeInfestation(...)`
- [ ] Predição: `await ai.predictOutbreakRisk(...)`

### **Validar:**
- [ ] Testar em modo avião ✈️
- [ ] Verificar resultados
- [ ] Confirmar que funciona offline

---

## 🎯 **RESULTADO FINAL**

**UM serviço de IA que faz TUDO, funciona SEMPRE (offline), e entrega resultados PROFISSIONAIS!**

**📱 Simples. Rápido. Profissional. Offline. ✅**
