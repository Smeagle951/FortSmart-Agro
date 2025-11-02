# 🧪 Guia de Teste - Sistema de Lista de Plantio

> Guia completo para testar todas as funcionalidades do sistema de Lista de Plantio Premium.

---

## 🚀 Como Testar o Sistema

### **1. Preparação Inicial**

#### **Verificar Migração**
```dart
// O sistema deve estar na versão 22 do banco
// Verificar no console se aparece:
// "🔄 Criando sistema completo de Lista de Plantio..."
// "✅ Sistema de Lista de Plantio criado com sucesso!"
```

#### **Inserir Dados de Exemplo**
```dart
// No seu código de inicialização, adicione:
import 'database/seeds/lista_plantio_seed_data.dart';

// Para inserir dados de teste:
await ListaPlantioSeedData.inserirDadosExemplo();

// Para limpar dados de teste:
await ListaPlantioSeedData.limparDadosExemplo();
```

---

## 📋 Checklist de Testes

### **✅ Teste 1: Acesso à Tela Premium**
- [ ] Navegar para `ListaPlantioPremiumScreen`
- [ ] Verificar se a tela carrega sem erros
- [ ] Confirmar que os dados de exemplo aparecem na lista

### **✅ Teste 2: Filtros**
- [ ] Testar filtro por Cultura (Soja, Milho)
- [ ] Testar filtro por Talhão
- [ ] Testar filtro por Data (início e fim)
- [ ] Testar botão "Aplicar Filtros"
- [ ] Testar botão "Limpar Filtros"

### **✅ Teste 3: Visualização de Dados**
- [ ] Verificar se a lista horizontal aparece corretamente
- [ ] Confirmar que as colunas estão visíveis:
  - Variedade
  - Cultura
  - Talhão/Subárea
  - Data
  - Pop/m
  - Pop/ha
  - Espaçamento (cm)
  - Custo/ha (R$)
  - DAE
  - Ações

### **✅ Teste 4: Cálculos Automáticos**
- [ ] Verificar se População/ha está calculada corretamente
- [ ] Confirmar que Custo/ha aparece com cores (verde/amarelo/vermelho)
- [ ] Verificar se DAE aparece como chip azul
- [ ] Testar com dados que não têm custo (deve aparecer "-")

### **✅ Teste 5: Apontamento de Semente**
- [ ] Clicar no ícone "📦" (inventory) em qualquer linha
- [ ] Verificar se o modal abre corretamente
- [ ] Selecionar um produto (ex: Soja - 58I59RSF)
- [ ] Selecionar um lote disponível
- [ ] Informar quantidade válida
- [ ] Clicar em "Salvar"
- [ ] Verificar se o custo/ha foi atualizado na lista

### **✅ Teste 6: Registro de Estande**
- [ ] Clicar no ícone "📊" (assessment) em qualquer linha
- [ ] Verificar se o modal abre corretamente
- [ ] Preencher dados de avaliação:
  - Comprimento: 10.0 metros
  - Linhas: 3
  - Plantas: 45
- [ ] Verificar se o DAE é calculado automaticamente
- [ ] Clicar em "Salvar"
- [ ] Verificar se o DAE foi atualizado na lista

### **✅ Teste 7: Ações de Plantio**
- [ ] Testar botão "Editar" (deve mostrar mensagem de info)
- [ ] Testar botão "Duplicar" (deve criar cópia)
- [ ] Testar botão "Deletar" (deve pedir confirmação)
- [ ] Verificar se as ações atualizam a lista

### **✅ Teste 8: Criação de Novo Plantio**
- [ ] Clicar no botão "+" no AppBar
- [ ] Verificar se navega para tela de registro
- [ ] Preencher dados obrigatórios
- [ ] Salvar o plantio
- [ ] Verificar se aparece na lista

---

## 🔍 Dados de Exemplo Inseridos

### **Talhões**
- **Talhão 1 - Centro**: 25,5 ha
- **Talhão 2 - Norte**: 18,2 ha  
- **Talhão 3 - Sul**: 32,8 ha

### **Subáreas**
- **Subárea A**: 12,5 ha (Talhão 1)
- **Subárea B**: 13,0 ha (Talhão 1)

### **Produtos de Estoque**
- **Soja 58I59RSF**: R$ 350,00/saco
- **Soja BMX Potência RR**: R$ 380,00/saco
- **Milho DKB 390 PRO3**: R$ 420,00/saco

### **Plantios**
1. **Soja 58I59RSF** (Talhão 1 - Subárea A)
   - Data: 15/10/2024
   - Espaçamento: 45 cm
   - População: 12 plantas/m
   - Custo/ha: R$ 420,00 (calculado)
   - DAE: 15.000 plantas/ha

2. **Soja BMX Potência RR** (Talhão 2)
   - Data: 18/10/2024
   - Espaçamento: 50 cm
   - População: 11,5 plantas/m
   - Custo/ha: R$ 752,75 (calculado)
   - DAE: 12.667 plantas/ha

3. **Milho DKB 390 PRO3** (Talhão 3)
   - Data: 20/10/2024
   - Espaçamento: 80 cm
   - População: 6,5 plantas/m
   - Custo/ha: R$ 1.125,00 (calculado)
   - DAE: Não avaliado

---

## 🧮 Cálculos Esperados

### **População por Hectare**
- **Fórmula**: `populacao_por_m * (100 / espacamento_cm)`
- **Soja 58I59RSF**: 12 × (100/45) = **26.667 plantas/ha**
- **Soja BMX**: 11,5 × (100/50) = **23.000 plantas/ha**
- **Milho**: 6,5 × (100/80) = **8.125 plantas/ha**

### **Custo por Hectare**
- **Fórmula**: `(quantidade × custo_unitário) / área_ha`
- **Soja 58I59RSF**: (15 × 350) / 12,5 = **R$ 420,00/ha**
- **Soja BMX**: (18 × 380) / 18,2 = **R$ 752,75/ha**
- **Milho**: (22 × 420) / 32,8 = **R$ 1.125,00/ha**

### **DAE (Densidade de Plantas)**
- **Fórmula**: `(plantas_contadas / (comprimento × linhas)) × 10.000`
- **Soja 58I59RSF**: (45 / (10 × 3)) × 10.000 = **15.000 plantas/ha**

---

## ⚠️ Problemas Comuns e Soluções

### **Erro: "Tabela não encontrada"**
- Verificar se a migração foi executada (versão 22)
- Verificar logs de inicialização do banco

### **Erro: "Dados não aparecem"**
- Verificar se os dados de exemplo foram inseridos
- Verificar se a view `vw_lista_plantio` foi criada

### **Erro: "Cálculos incorretos"**
- Verificar se as áreas dos talhões estão cadastradas
- Verificar se os apontamentos de estoque foram feitos

### **Erro: "Modal não abre"**
- Verificar se os widgets estão importados corretamente
- Verificar se não há erros de compilação

---

## 📊 Métricas de Performance

### **Tempo de Carregamento**
- Lista inicial: < 2 segundos
- Aplicação de filtros: < 1 segundo
- Abertura de modais: < 500ms

### **Dados Esperados**
- 3 plantios de exemplo
- 3 produtos de estoque
- 4 lotes de estoque
- 3 apontamentos de estoque
- 3 avaliações de estande

---

## 🎯 Critérios de Sucesso

### **Funcionalidades Básicas**
- [ ] Tela carrega sem erros
- [ ] Dados aparecem corretamente
- [ ] Filtros funcionam
- [ ] Cálculos estão corretos

### **Funcionalidades Avançadas**
- [ ] Apontamento de semente funciona
- [ ] Registro de estande funciona
- [ ] Ações de editar/duplicar/deletar funcionam
- [ ] Interface é responsiva

### **Integração**
- [ ] Sistema de estoque integrado
- [ ] Cálculo de custo/ha funcionando
- [ ] Avaliação de estande integrada
- [ ] Dados consistentes entre módulos

---

## 🚀 Próximos Passos

Após testar com sucesso:

1. **Integrar com rotas** (quando necessário)
2. **Adicionar mais dados de teste**
3. **Implementar funcionalidades adicionais**
4. **Otimizar performance se necessário**

**Sistema pronto para produção! 🎉**
