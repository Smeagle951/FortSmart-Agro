# 📥 Guia Completo: Restauração de Backup

## 🔄 Como Funciona o Processo de Restauração

### Visão Geral
O processo de restauração **substitui completamente** o banco de dados atual pelo banco de dados contido no arquivo de backup (.zip). É uma operação **irreversível**.

---

## 📋 Passo a Passo do Usuário

### 1️⃣ **Acessar o Módulo de Backup**
```
Menu → Configurações → Backup e Restauração
```

### 2️⃣ **Iniciar Restauração**
Existem **DUAS formas** de restaurar um backup:

#### Opção A: Restaurar do Histórico
1. Role até a seção **"Histórico de Backups"**
2. Localize o backup desejado na lista
3. Clique no ícone de **restaurar** (⟲) ao lado do backup
4. Confirme a ação no diálogo de aviso

#### Opção B: Restaurar Arquivo Externo
1. Clique no botão **"Restaurar"** no topo da tela
2. Confirme a ação no diálogo de aviso
3. Selecione o arquivo `.zip` do backup na pasta do dispositivo
4. Aguarde o processo de restauração

### 3️⃣ **Confirmação de Segurança**
Um diálogo será exibido com o aviso:
```
⚠️ Restaurar um backup substituirá todos os dados atuais.
   Esta ação não pode ser desfeita. Deseja continuar?
```

**Botões:**
- ❌ **Cancelar** - Aborta a operação
- ✅ **Restaurar** - Confirma e inicia a restauração

### 4️⃣ **Processo de Restauração**
Enquanto o backup é restaurado:
- 🔄 Indicador de carregamento é exibido
- 📁 O arquivo `.zip` é descompactado
- 🗄️ O banco de dados é substituído
- ✅ Mensagem de sucesso é exibida

### 5️⃣ **Reiniciar o Aplicativo**
⚠️ **IMPORTANTE:** O aplicativo precisa ser **reiniciado manualmente** após a restauração para aplicar as mudanças.

**Como reiniciar:**
1. Feche o aplicativo completamente
2. Abra o aplicativo novamente
3. Todos os dados restaurados estarão disponíveis

---

## 🔧 Processo Técnico (Código)

### Fluxo de Execução

```dart
// 1. BackupScreen._restoreBackup()
//    ↓ Exibe diálogo de confirmação
//    ↓ Usuário confirma
//    ↓ Seleciona arquivo .zip (se opção B)
//    ↓

// 2. BackupService.restoreBackup(backupPath)
async restoreBackup(String backupPath) {
  // Etapa 1: Validar arquivo
  if (!File(backupPath).exists()) ❌
  
  // Etapa 2: Fechar banco de dados
  await db.close(); // Libera arquivo para escrita
  
  // Etapa 3: Descompactar .zip
  final bytes = await File(backupPath).readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);
  
  // Etapa 4: Localizar banco de dados no .zip
  final dbFile = archive.findFile('fortsmart_agro.db');
  
  // Etapa 5: Substituir banco de dados atual
  final dbPath = await getDatabasesPath();
  await File(dbPath).writeAsBytes(dbFile.content);
  
  // Etapa 6: Reabrir banco de dados
  await _database.database;
  
  return true; ✅
}
```

### Arquivos Envolvidos

| Arquivo | Função |
|---------|--------|
| `backup_service.dart` | Lógica de restauração |
| `backup_screen.dart` | Interface do usuário |
| `app_database.dart` | Gerenciamento do banco |

---

## ⚠️ Avisos Importantes

### ❗ Dados Serão Substituídos
- **TODOS** os dados atuais serão **PERDIDOS**
- Não há como desfazer a operação
- Recomenda-se criar um backup antes de restaurar outro

### 📦 Formato do Arquivo
- Deve ser um arquivo `.zip` válido
- Criado pelo sistema de backup do FortSmart Agro
- Contém o arquivo `fortsmart_agro.db`

### 🔄 Reinício Necessário
- O app deve ser **fechado e reaberto** após restaurar
- Caso contrário, pode exibir dados inconsistentes
- Recomenda-se fechar TODAS as telas abertas

### 🔐 Integridade dos Dados
- O backup restaura o banco **exatamente** como estava
- Versão do banco deve ser compatível
- Migrações automáticas são aplicadas ao reabrir

---

## 🐛 Problemas Comuns

### Problema 1: "Arquivo de backup não encontrado"
**Causa:** Caminho do arquivo inválido ou arquivo foi movido  
**Solução:** Verifique se o arquivo `.zip` existe no dispositivo

### Problema 2: "Arquivo de banco de dados não encontrado no backup"
**Causa:** Arquivo `.zip` corrompido ou não é um backup válido  
**Solução:** Tente outro arquivo de backup ou crie um novo

### Problema 3: Dados não aparecem após restaurar
**Causa:** Aplicativo não foi reiniciado  
**Solução:** Feche e reabra o aplicativo completamente

### Problema 4: Erro de permissão ao ler arquivo
**Causa:** App não tem permissão para acessar a pasta  
**Solução:** Conceda permissões de armazenamento ao app

---

## 📊 Estatísticas Restauradas

Ao restaurar um backup, os seguintes dados são recuperados:

### Dados Principais
- ✅ Talhões e polígonos
- ✅ Safras e culturas
- ✅ Plantios e estande de plantas
- ✅ Monitoramentos e pontos de monitoramento
- ✅ Ocorrências e mapa de infestação

### Dados de Configuração
- ✅ Produtos agrícolas
- ✅ Variedades de culturas
- ✅ Catálogo de organismos (pragas, doenças, plantas daninhas)
- ✅ Histórico de calibrações
- ✅ Registros fenológicos

### Dados de Laboratório
- ✅ Testes de germinação
- ✅ Subtestes e registros diários
- ✅ Produtos de inventário

---

## 🔍 Logs e Debug

### Mensagens de Log
```dart
✅ "Backup restaurado com sucesso!"
❌ "Arquivo de backup não encontrado"
❌ "Arquivo de banco de dados não encontrado no backup"
❌ "Erro ao restaurar backup: [detalhes]"
```

### Como Verificar no Console
```bash
# Android
adb logcat | grep -i "backup"

# Procure por:
# - "Backup restaurado com sucesso"
# - "Erro ao restaurar backup"
```

---

## 💡 Dicas e Boas Práticas

### ✅ Fazer Antes de Restaurar
1. **Criar backup atual** dos dados antes de restaurar outro
2. **Fechar todas as telas** abertas no app
3. **Verificar espaço disponível** no dispositivo
4. **Anotar o caminho** do arquivo de backup

### ✅ Fazer Depois de Restaurar
1. **Fechar o app completamente** (não apenas minimizar)
2. **Reabrir o app** para carregar dados restaurados
3. **Verificar dados principais** (talhões, plantios, etc.)
4. **Testar funcionalidades** críticas

### ❌ Evitar
- ❌ Restaurar backup de versão muito antiga
- ❌ Restaurar backup corrompido ou incompleto
- ❌ Continuar usando o app sem reiniciar
- ❌ Restaurar sem criar backup dos dados atuais

---

## 🎯 Exemplo Prático

### Cenário: Trocar de Dispositivo

**Dispositivo Antigo:**
```
1. Abrir FortSmart Agro
2. Ir em Backup e Restauração
3. Clicar em "Criar Backup"
4. Copiar arquivo .zip para nuvem/pen drive
```

**Dispositivo Novo:**
```
1. Instalar FortSmart Agro
2. Copiar arquivo .zip para o novo dispositivo
3. Abrir FortSmart Agro
4. Ir em Backup e Restauração
5. Clicar em "Restaurar"
6. Selecionar arquivo .zip copiado
7. Confirmar restauração
8. Fechar e reabrir o app
9. ✅ Dados restaurados com sucesso!
```

---

## 📞 Suporte

Se encontrar problemas durante a restauração:
1. Verifique os logs do console
2. Confira se o arquivo `.zip` está intacto
3. Teste com outro arquivo de backup
4. Verifique permissões do app
5. Entre em contato com o suporte técnico

---

**Última atualização:** 28/10/2025  
**Versão do guia:** 1.0  
**Status:** ✅ Completo e testado

