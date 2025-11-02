# 🌱 **Guia de Gerenciamento de Culturas e Pragas - FortSmart**

## 📋 **Visão Geral**

Este guia explica como usar o sistema completo de gerenciamento de culturas, pragas, doenças e plantas daninhas do FortSmart. O sistema foi projetado para integrar perfeitamente com o módulo de monitoramento premium.

## 🚀 **Inicialização do Sistema**

### **1. Primeira Execução**
O sistema automaticamente carrega todos os dados padrão na primeira execução:

```dart
// O sistema verifica se os dados já foram inicializados
final initService = DataInitializationService();
final isInitialized = await initService.isDataInitialized();

if (!isInitialized) {
  // Carrega automaticamente:
  // - 7 culturas principais (Soja, Milho, Algodão, etc.)
  // - 43 pragas específicas por cultura
  // - 40 doenças específicas por cultura
  // - 42 plantas daninhas específicas por cultura
  // - 15+ variedades por cultura
  await initService.initializeAllData();
}
```

### **2. Verificação de Integridade**
```dart
// Verificar se todos os dados estão completos
final integrity = await initService.validateDataIntegrity();
if (integrity['isValid']) {
  print('✅ Dados completos e válidos');
} else {
  print('❌ Dados incompletos ou corrompidos');
}
```

## 📊 **Dados Incluídos**

### **🌾 Culturas Padrão**
1. **Soja** - Glycine max
2. **Milho** - Zea mays
3. **Algodão** - Gossypium hirsutum
4. **Feijão** - Phaseolus vulgaris
5. **Girassol** - Helianthus annuus
6. **Arroz** - Oryza sativa
7. **Sorgo** - Sorghum bicolor

### **🐛 Pragas por Cultura**
- **Soja**: 10 pragas (Lagarta-da-soja, Percevejo-marrom, etc.)
- **Milho**: 8 pragas (Lagarta-do-cartucho, Cigarrinha, etc.)
- **Algodão**: 8 pragas (Helicoverpa, Bicudo, etc.)
- **Feijão**: 5 pragas (Besouro-do-feijão, Pulgão-preto, etc.)
- **Girassol**: 4 pragas (Lagarta-do-cartucho, Helicoverpa, etc.)
- **Arroz**: 4 pragas (Percevejo-do-grão, Broca-da-cana, etc.)
- **Sorgo**: 4 pragas (Lagarta-do-cartucho, Helicoverpa, etc.)

### **🦠 Doenças por Cultura**
- **Soja**: 9 doenças (Ferrugem asiática, Oídio, Mancha-alvo, etc.)
- **Milho**: 7 doenças (Cercosporiose, Ferrugem polissora, etc.)
- **Algodão**: 7 doenças (Ramulária, Mancha de Alternaria, etc.)
- **Feijão**: 5 doenças (Antracnose, Mosaico dourado, etc.)
- **Girassol**: 4 doenças (Mofo-branco, Ferrugem do girassol, etc.)
- **Arroz**: 4 doenças (Brusone, Queima-da-bainha, etc.)
- **Sorgo**: 4 doenças (Antracnose, Ferrugem do sorgo, etc.)

### **🌿 Plantas Daninhas por Cultura**
- **Soja**: 8 daninhas (Caruru, Buva, Capim-amargoso, etc.)
- **Milho**: 7 daninhas (Sorgo-de-alepo, Capim-pé-de-galinha, etc.)
- **Algodão**: 8 daninhas (Cordas-de-viola, Trapoeraba, etc.)
- **Feijão**: 5 daninhas (Picão-preto, Capins, etc.)
- **Girassol**: 5 daninhas (Cordas-de-viola, Caruru, etc.)
- **Arroz**: 4 daninhas (Capim-arroz, Alface-d'água, etc.)
- **Sorgo**: 5 daninhas (Sorgo-de-alepo, Capins, etc.)

### **🌱 Variedades por Cultura**
- **Soja**: Variedades serão adicionadas pelo usuário com dados reais
- **Milho**: Variedades serão adicionadas pelo usuário com dados reais
- **Algodão**: Variedades serão adicionadas pelo usuário com dados reais
- **Feijão**: Variedades serão adicionadas pelo usuário com dados reais
- **Girassol**: Variedades serão adicionadas pelo usuário com dados reais
- **Arroz**: Variedades serão adicionadas pelo usuário com dados reais
- **Sorgo**: Variedades serão adicionadas pelo usuário com dados reais

## 🛠️ **Como Usar**

### **1. Acessar a Tela de Culturas**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const FarmCropsScreen()),
);
```

### **2. Adicionar Nova Cultura**
```dart
final importService = CultureImportService();
await importService.addCrop(
  'Cana-de-açúcar',
  description: 'Saccharum officinarum - Cultura para produção de açúcar e etanol'
);
```

### **3. Adicionar Nova Praga**
```dart
await importService.addPest(
  'Broca-da-cana',
  'Diatraea saccharalis',
  1, // ID da cultura (Soja)
  description: 'Larva que perfura o colmo da cana'
);
```

### **4. Adicionar Nova Doença**
```dart
await importService.addDisease(
  'Mancha-parda',
  'Bipolaris oryzae',
  6, // ID da cultura (Arroz)
  description: 'Doença fúngica que afeta as folhas do arroz'
);
```

### **5. Adicionar Nova Planta Daninha**
```dart
await importService.addWeed(
  'Capim-amargoso',
  'Digitaria insularis',
  1, // ID da cultura (Soja)
  description: 'Planta daninha resistente a herbicidas'
);
```

### **6. Adicionar Nova Variedade**
```dart
await importService.addVariety(
  '1', // ID da cultura (Soja)
  'Variedade Real', // Nome da variedade real
  company: 'Empresa Real',
  cycleDays: 115,
  description: 'Descrição da variedade real'
);
```

## 🔍 **Funcionalidades de Busca**

### **Buscar Culturas**
```dart
final results = await importService.searchCrops('soja');
// Retorna: Soja, Soja Variedade Real, etc.
```

### **Buscar Pragas**
```dart
final results = await importService.searchPests('lagarta');
// Retorna: Lagarta-da-soja, Lagarta-do-cartucho, etc.
```

### **Buscar Doenças**
```dart
final results = await importService.searchDiseases('ferrugem');
// Retorna: Ferrugem asiática, Ferrugem polissora, etc.
```

### **Buscar Plantas Daninhas**
```dart
final results = await importService.searchWeeds('capim');
// Retorna: Capim-amargoso, Capim-pé-de-galinha, etc.
```

## 📈 **Estatísticas e Relatórios**

### **Obter Estatísticas Gerais**
```dart
final stats = await importService.getStatistics();
print('Culturas: ${stats['crops']}');
print('Pragas: ${stats['pests']}');
print('Doenças: ${stats['diseases']}');
print('Plantas Daninhas: ${stats['weeds']}');
print('Variedades: ${stats['varieties']}');
```

### **Obter Dados por Cultura**
```dart
final cropId = 1; // ID da Soja
final pests = await importService.getPestsByCrop(cropId);
final diseases = await importService.getDiseasesByCrop(cropId);
final weeds = await importService.getWeedsByCrop(cropId);
final varieties = await importService.getVarietiesByCrop(cropId.toString());
```

## 🔄 **Sincronização e Backup**

### **Exportar Dados**
```dart
final data = await importService.exportData();
// Salva todos os dados em formato JSON
```

### **Verificar Diagnóstico**
```dart
final diagnostic = await initService.getDiagnosticInfo();
print('Inicializado: ${diagnostic['initialization']['isInitialized']}');
print('Última inicialização: ${diagnostic['initialization']['lastInitialization']}');
print('Dias desde última inicialização: ${diagnostic['initialization']['daysSinceLastInit']}');
```

## 🎯 **Integração com Monitoramento Premium**

### **Usar no Novo Monitoramento**
```dart
// No PremiumNewMonitoringScreen
final crops = await importService.getAllCrops();
final selectedCrop = crops.firstWhere((c) => c.name == 'Soja');

final pests = await importService.getPestsByCrop(selectedCrop.id);
final diseases = await importService.getDiseasesByCrop(selectedCrop.id);
final weeds = await importService.getWeedsByCrop(selectedCrop.id);
final varieties = await importService.getVarietiesByCrop(selectedCrop.id.toString());
```

### **Criar Ocorrência Premium**
```dart
final pest = pests.firstWhere((p) => p.name == 'Lagarta-da-soja');
final occurrence = PremiumOccurrence(
  id: const Uuid().v4(),
  type: OccurrenceType.pest,
  name: pest.name,
  scientificName: pest.scientificName,
  severityLevel: 7.0,
  quantity: 5.0,
  quantityUnit: 'lagartas/m²',
  affectedSections: [PlantSection.upper, PlantSection.middle],
  notes: 'Infestação moderada no centro do talhão',
);
```

## 🛠️ **Manutenção e Desenvolvimento**

### **Reinicializar Dados (Desenvolvimento)**
```dart
// ⚠️ APENAS PARA DESENVOLVIMENTO
await initService.forceReinitialize();
```

### **Resetar Todos os Dados**
```dart
// ⚠️ APENAS PARA DESENVOLVIMENTO
await initService.resetAllData();
```

### **Limpar Dados Específicos**
```dart
// ⚠️ APENAS PARA DESENVOLVIMENTO
await importService.clearAllData();
```

## 📱 **Interface do Usuário**

### **Tela Principal - Culturas da Fazenda**
- Lista todas as culturas com estatísticas
- Botão para adicionar nova cultura
- Menu de contexto para editar/remover
- Botão "Pragas e Doenças" para ver detalhes

### **Tela de Detalhes da Cultura**
- 4 abas: Pragas, Doenças, Daninhas, Variedades
- Lista organizada com ícones e cores
- Informações científicas e descrições
- Botão de informação para detalhes

### **Funcionalidades**
- ✅ Adicionar/Editar/Remover culturas
- ✅ Visualizar pragas e doenças por cultura
- ✅ Busca por nome ou descrição
- ✅ Estatísticas em tempo real
- ✅ Sincronização automática
- ✅ Backup e exportação
- ✅ Validação de integridade

## 🎨 **Design e UX**

### **Cores e Ícones**
- **Culturas**: 🌱 Verde (theme.PremiumTheme.primary)
- **Pragas**: 🐛 Laranja (Colors.orange)
- **Doenças**: 🦠 Vermelho (Colors.red)
- **Plantas Daninhas**: 🌿 Verde (Colors.green)
- **Variedades**: 📦 Azul (Colors.blue)

### **Cards e Layout**
- Cards com gradiente suave
- Estatísticas visuais com ícones
- Botões com cores temáticas
- Animações suaves
- Feedback visual para ações

## 🔧 **Troubleshooting**

### **Problema: Dados não carregam**
```dart
// Verificar inicialização
final isInit = await initService.isDataInitialized();
if (!isInit) {
  await initService.initializeAllData();
}
```

### **Problema: Dados corrompidos**
```dart
// Validar integridade
final integrity = await initService.validateDataIntegrity();
if (!integrity['isValid']) {
  await initService.forceReinitialize();
}
```

### **Problema: Erro de banco de dados**
```dart
// Verificar diagnóstico
final diagnostic = await initService.getDiagnosticInfo();
print('Erro: ${diagnostic['error']}');
```

## 📞 **Suporte**

Para problemas ou dúvidas:
1. Verificar logs do console
2. Executar diagnóstico completo
3. Verificar integridade dos dados
4. Reinicializar se necessário

---

**🎉 Sistema pronto para uso em produção!** 