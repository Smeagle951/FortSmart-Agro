# 🌱 GUIA DE USO - SUBTESTES DE GERMINAÇÃO

## 📋 **COMO USAR O SISTEMA DE SUBTESTES**

### **1. CRIAR TESTE COM SUBTESTES**

#### **Passo 1: Acessar Criação de Teste**
- Vá para **Plantio** → **Teste de Germinação** → **Novo Teste**
- Preencha os dados básicos (cultura, variedade, lote)

#### **Passo 2: Configurar Subtestes**
- Na seção **"Configuração de Subtestes"**:
  - ✅ **Ative o toggle** "Usar Subtestes (A, B, C)"
  - 🔢 **Configure** quantidade de sementes por subteste (padrão: 100)
  - 📝 **Personalize** os nomes dos subtestes (A, B, C)
  - 📊 **Visualize** o total de sementes (300 = 100 × 3)

#### **Passo 3: Criar Teste**
- Clique em **"Criar Teste"**
- Sistema criará automaticamente os 3 subtestes
- Total de sementes será calculado automaticamente

---

### **2. REGISTRAR DADOS DIÁRIOS**

#### **Passo 1: Acessar Registro Diário**
- Vá para o teste criado
- Clique em **"Adicionar Registro"** para o dia desejado

#### **Passo 2: Selecionar Subteste**
- **Se o teste tem subtestes**: Aparecerá o seletor
- **Escolha** o subteste (A, B ou C) para registrar
- **Visualize** informações do subteste selecionado

#### **Passo 3: Registrar Dados**
- Preencha os campos normalmente:
  - 🌱 **Germinadas Normais**
  - 🌿 **Germinadas Anormais** 
  - 🦠 **Doentes/Fungos**
  - ❌ **Não Germinadas**
  - 📝 **Observações**
  - 🏥 **Qualidade Sanitária**

#### **Passo 4: Salvar Registro**
- Clique em **"Salvar Registro"**
- Sistema salva para o subteste selecionado
- **Repita** para os outros subtestes (A, B, C)

---

### **3. VISUALIZAR RESULTADOS**

#### **Resultados por Subteste**
- **Subteste A**: Resultados independentes
- **Subteste B**: Resultados independentes  
- **Subteste C**: Resultados independentes
- **Média Geral**: Média dos 3 subtestes

#### **Métricas Exibidas**
- 📊 **Percentual de Germinação**
- 🌱 **Percentual de Pureza**
- 🦠 **Percentual de Doenças**
- 💰 **Valor Cultural**

#### **Comparação**
- **Evolução por dia** para cada subteste
- **Comparação entre subtestes**
- **Média consolidada** final

---

## 🔄 **COMPATIBILIDADE COM SISTEMA ATUAL**

### **✅ Testes Existentes**
- **Funcionam normalmente** sem alterações
- **Interface inalterada** para testes antigos
- **Cálculos mantidos** exatamente iguais
- **Dados preservados** integralmente

### **✅ Novos Testes**
- **Escolha do usuário**: Com ou sem subtestes
- **Interface adaptativa**: Mostra opções quando necessário
- **Funcionalidades completas** para ambos os modos

---

## 📊 **EXEMPLO PRÁTICO**

### **Cenário: Teste de Soja com Subtestes**

#### **1. Criação**
```
Cultura: Soja
Variedade: BRS 284
Lote: SOJA-2024-001
Subtestes: Ativado
Sementes por subteste: 100
Total: 300 sementes
```

#### **2. Registro Diário (Dia 5)**
```
Subteste A: 71 sementes germinadas (71%)
Subteste B: 68 sementes germinadas (68%)  
Subteste C: 75 sementes germinadas (75%)
```

#### **3. Resultado Final**
```
Subteste A: 71% germinação
Subteste B: 68% germinação
Subteste C: 75% germinação
Média Geral: 71,3% germinação
```

---

## 🎯 **BENEFÍCIOS DOS SUBTESTES**

### **✅ Maior Precisão**
- **3 avaliações independentes** por lote
- **Redução de erros** de amostragem
- **Análise estatística** mais confiável

### **✅ Análise Comparativa**
- **Identificação de variações** entre subtestes
- **Detecção de problemas** específicos
- **Qualidade diferenciada** por subteste

### **✅ Média Consolidada**
- **Resultado mais confiável** (média de 3)
- **Redução de incerteza** estatística
- **Decisões mais precisas** sobre lotes

---

## 🔧 **CONFIGURAÇÕES AVANÇADAS**

### **Personalização de Nomes**
- **Subteste A**: "Controle"
- **Subteste B**: "Tratamento 1"  
- **Subteste C**: "Tratamento 2"

### **Quantidade de Sementes**
- **Padrão**: 100 sementes por subteste
- **Configurável**: 50, 100, 150, etc.
- **Total automático**: Quantidade × 3

### **Migração de Testes**
- **Testes antigos**: Podem ser migrados para subtestes
- **Dados preservados**: Nenhuma perda de informação
- **Processo automático**: Sistema faz a conversão

---

## 📱 **INTERFACE ADAPTATIVA**

### **Testes Sem Subtestes**
- Interface **normal** (como antes)
- Campos **tradicionais** de registro
- Cálculos **padrão** do sistema

### **Testes Com Subtestes**
- **Seletor de subteste** aparece automaticamente
- **Configuração visual** clara
- **Resultados organizados** por subteste

---

## ✅ **SISTEMA PRONTO PARA USO**

O sistema de subtestes está **100% funcional** e integrado ao FortSmart Agro:

- ✅ **Compatibilidade total** com sistema atual
- ✅ **Interface intuitiva** e adaptativa  
- ✅ **Cálculos precisos** e confiáveis
- ✅ **Zero quebra** de funcionalidades existentes
- ✅ **Dados preservados** integralmente

**O usuário pode escolher livremente entre:**
- **Modo Clássico**: Teste único (300 sementes)
- **Modo Subtestes**: 3 subtestes (100 sementes cada)

Ambos os modos funcionam perfeitamente! 🎉

---

*Guia criado em: ${DateTime.now().toString().split(' ')[0]}*
*Versão: FortSmart Agro v2.0 - Subtestes de Germinação*
