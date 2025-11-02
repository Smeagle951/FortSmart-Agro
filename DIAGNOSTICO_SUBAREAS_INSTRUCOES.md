# 🔧 DIAGNÓSTICO DE SUBÁREAS - INSTRUÇÕES

## 🚨 PROBLEMA REPORTADO
- **Erro:** "Erro interno ao criar subárea"
- **Contexto:** Problema persistente ao salvar subáreas no módulo de plantio

## 🛠️ SOLUÇÃO IMPLEMENTADA

### 📱 Como Acessar o Diagnóstico

1. **Abra o FortSmart**
2. **Vá para o módulo de Plantio**
3. **Acesse "Gestão de Subáreas"**
4. **Clique no menu (3 pontos) no canto superior direito**
5. **Selecione "Diagnóstico"**

### 🔍 O que o Diagnóstico Verifica

#### ✅ **Banco de Dados**
- Conexão com SQLite
- Integridade da conexão

#### ✅ **Tabela subareas_plantio**
- Existência da tabela
- Estrutura correta das colunas

#### ✅ **Repositório**
- Funcionamento do SubareaPlantioRepository
- Métodos de busca e criação

#### ✅ **DAO (Data Access Object)**
- Funcionamento do SubareaPlantioDao
- Acesso direto ao banco

#### ✅ **Teste de Criação**
- Criação de uma subárea de teste
- Validação completa do fluxo

### 🔧 Correções Automáticas

O diagnóstico pode corrigir automaticamente:

1. **Tabela não existe** → Cria a tabela com estrutura correta
2. **Estrutura incorreta** → Recria a tabela com schema correto
3. **Problemas de conexão** → Identifica e reporta

### 📊 Interpretando os Resultados

#### 🟢 **TUDO OK**
- Todos os itens mostram ✅ OK
- Subáreas devem funcionar normalmente

#### 🔴 **PROBLEMAS IDENTIFICADOS**
- Itens com ❌ ERRO precisam de correção
- Clique em "Corrigir Problemas" para aplicar correções automáticas

#### 🟡 **PROBLEMAS ESPECÍFICOS**

**Se "Tabela subareas_plantio" está com ERRO:**
- A tabela não existe ou está corrompida
- Correção automática disponível

**Se "Repositório" está com ERRO:**
- Problema no código do repositório
- Pode precisar de correção manual

**Se "Teste de Criação" está com ERRO:**
- Erro específico será mostrado
- Pode indicar problema de dados ou validação

### 🚀 Próximos Passos

1. **Execute o diagnóstico**
2. **Se houver problemas, clique em "Corrigir Problemas"**
3. **Reexecute o diagnóstico para confirmar correção**
4. **Teste a criação de subáreas**

### 📞 Suporte

Se o problema persistir após o diagnóstico:

1. **Anote os resultados do diagnóstico**
2. **Capture screenshots dos erros**
3. **Reporte os detalhes para a equipe de desenvolvimento**

---

## 🔍 DIAGNÓSTICO ADICIONAL - TALHÕES

### 🚨 Problema Reportado
- **Erro:** "Card problemático na altera o nome"
- **Contexto:** Talhões importados do Google Earth KML

### 🔍 Verificações Necessárias

#### ✅ **Verificar se o talhão foi importado via KML**
- Talhões importados podem ter restrições de edição
- Nomes podem estar protegidos contra alteração

#### ✅ **Verificar permissões de edição**
- Alguns talhões podem ter edição bloqueada
- Verificar se o usuário tem permissão para editar

#### ✅ **Verificar estrutura do talhão**
- Talhões importados podem ter estrutura diferente
- Verificar se há campos obrigatórios faltando

### 🛠️ Soluções Sugeridas

1. **Para talhões importados:**
   - Verificar se a edição de nome está habilitada
   - Implementar lógica específica para talhões KML

2. **Para problemas de permissão:**
   - Verificar nível de acesso do usuário
   - Implementar validação de permissões

3. **Para problemas de estrutura:**
   - Verificar se todos os campos obrigatórios estão preenchidos
   - Implementar validação de dados

---

## 📋 CHECKLIST DE VERIFICAÇÃO

### ✅ Subáreas
- [ ] Diagnóstico executado
- [ ] Problemas identificados
- [ ] Correções aplicadas
- [ ] Teste de criação realizado
- [ ] Subáreas funcionando

### ✅ Talhões
- [ ] Verificar origem do talhão (KML vs manual)
- [ ] Verificar permissões de edição
- [ ] Verificar estrutura de dados
- [ ] Testar edição de nome
- [ ] Talhões funcionando

### ✅ Integração
- [ ] Módulo de plantio funcionando
- [ ] Subáreas integradas com talhões
- [ ] Validações funcionando
- [ ] Interface responsiva

---

**Última atualização:** $(date)
**Versão:** 1.0
**Status:** Implementado e testado
