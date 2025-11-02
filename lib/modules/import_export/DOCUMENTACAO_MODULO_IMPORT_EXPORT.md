# Módulo de Importação & Exportação - FortSmart Agro

## 📋 Visão Geral

O módulo de Importação & Exportação do FortSmart Agro permite a transferência de dados entre sistemas, backup de informações e integração com softwares terceiros. Este módulo é essencial para manter a interoperabilidade e garantir a segurança dos dados agrícolas.

## 🎯 Funcionalidades Principais

### Exportação de Dados
- **Formatos Suportados**: CSV, XLSX, JSON
- **Tipos de Dados**:
  - Histórico de Custos
  - Prescrições Agronômicas
  - Talhões e Culturas
- **Filtros Avançados**:
  - Período (data início/fim)
  - Talhão específico
  - Cultura
  - Tipo de operação
- **Compartilhamento**: WhatsApp, E-mail, Drive

### Importação de Dados
- **Formatos Suportados**: CSV, XLSX, JSON
- **Tipos de Dados**:
  - Prescrições Agronômicas
  - Talhões
- **Validação Automática**:
  - Estrutura do arquivo
  - Compatibilidade com dados existentes
  - Tratamento de duplicidades
- **Pré-visualização**: Primeiras 10 linhas antes da importação

### Sincronização com Sistemas Externos
- **API REST**: Para integração com Siagri, Aegro, Strider
- **Mapeamento de Campos**: Padronização de dados
- **Sincronização Offline/Online**: Cache local com envio quando online

## 🏗️ Arquitetura do Módulo

### Estrutura de Diretórios
```
lib/modules/import_export/
├── models/
│   ├── export_job_model.dart
│   └── import_job_model.dart
├── daos/
│   ├── export_job_dao.dart
│   └── import_job_dao.dart
├── services/
│   └── import_export_service.dart
├── screens/
│   ├── import_export_main_screen.dart
│   ├── export_screen.dart
│   └── import_screen.dart
├── index.dart
└── DOCUMENTACAO_MODULO_IMPORT_EXPORT.md
```

### Modelos de Dados

#### ExportJobModel
```dart
class ExportJobModel {
  final int? id;
  final String tipo; // 'custos', 'prescricoes', 'talhoes'
  final String filtros; // JSON com filtros aplicados
  final String formato; // 'csv', 'xlsx', 'json'
  final String status; // 'pendente', 'concluido', 'erro'
  final String? arquivoPath;
  final DateTime dataCriacao;
  final String? usuarioId;
  final String? observacoes;
  final int? totalRegistros;
  final double? tamanhoArquivo; // em MB
}
```

#### ImportJobModel
```dart
class ImportJobModel {
  final int? id;
  final String tipo; // 'prescricoes', 'talhoes'
  final String arquivoPath;
  final String status; // 'pendente', 'validado', 'concluido', 'erro'
  final String? erros; // JSON com erros de validação
  final DateTime dataCriacao;
  final String? usuarioId;
  final String? observacoes;
  final int? totalRegistros;
  final int? registrosProcessados;
  final int? registrosSucesso;
  final int? registrosErro;
  final String? nomeArquivoOriginal;
  final double? tamanhoArquivo; // em MB
}
```

### Banco de Dados (SQLite)

#### Tabela export_jobs
```sql
CREATE TABLE export_jobs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tipo TEXT NOT NULL,
  filtros TEXT NOT NULL,
  formato TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pendente',
  arquivo_path TEXT,
  data_criacao TEXT NOT NULL,
  usuario_id TEXT,
  observacoes TEXT,
  total_registros INTEGER,
  tamanho_arquivo REAL
);
```

#### Tabela import_jobs
```sql
CREATE TABLE import_jobs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tipo TEXT NOT NULL,
  arquivo_path TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pendente',
  erros TEXT,
  data_criacao TEXT NOT NULL,
  usuario_id TEXT,
  observacoes TEXT,
  total_registros INTEGER,
  registros_processados INTEGER DEFAULT 0,
  registros_sucesso INTEGER DEFAULT 0,
  registros_erro INTEGER DEFAULT 0,
  nome_arquivo_original TEXT,
  tamanho_arquivo REAL
);
```

## 🔧 Serviços e Lógica de Negócio

### ImportExportService

#### Métodos Principais

**Exportação:**
```dart
Future<Map<String, dynamic>> exportarDados({
  required String tipo,
  required String formato,
  required Map<String, dynamic> filtros,
  String? usuarioId,
})
```

**Importação:**
```dart
Future<Map<String, dynamic>> importarDados({
  required String tipo,
  required String arquivoPath,
  required String nomeArquivoOriginal,
  double? tamanhoArquivo,
  String? usuarioId,
})
```

**Consultas:**
```dart
Future<List<ExportJobModel>> getExportJobs({String? tipo, String? status})
Future<List<ImportJobModel>> getImportJobs({String? tipo, String? status})
Future<Map<String, dynamic>> getStatistics()
Future<void> cleanupOldJobs({int daysToKeep = 90})
```

## 🖥️ Interface do Usuário

### Tela Principal (ImportExportMainScreen)
- **Dashboard** com estatísticas de exportações e importações
- **Ações Principais**: Cards para Exportar e Importar dados
- **Ações Rápidas**: Exportar custos, prescrições, limpar jobs antigos
- **Design Responsivo** com gradientes e sombras

### Tela de Exportação (ExportScreen)
- **Formulário de Configuração**:
  - Seleção de tipo de dados
  - Formato do arquivo (CSV, XLSX, JSON)
  - Filtros opcionais (período, talhão, cultura, operação)
- **Exportações Recentes**: Lista dos últimos 5 jobs
- **Compartilhamento**: Botão para compartilhar arquivos gerados

### Tela de Importação (ImportScreen)
- **Seleção de Arquivo**: Upload com drag & drop
- **Informações do Arquivo**: Nome, tamanho, extensão
- **Pré-visualização**: Tabela com primeiras 10 linhas
- **Importações Recentes**: Histórico com status e estatísticas

## 📊 Fluxo de Trabalho

### Exportação
1. **Configuração**: Usuário seleciona tipo, formato e filtros
2. **Processamento**: Sistema gera arquivo com dados filtrados
3. **Armazenamento**: Arquivo salvo localmente com metadados
4. **Compartilhamento**: Opção de compartilhar via apps nativos
5. **Histórico**: Job registrado para consulta posterior

### Importação
1. **Upload**: Usuário seleciona arquivo para importação
2. **Validação**: Sistema verifica estrutura e compatibilidade
3. **Pré-visualização**: Mostra primeiras linhas para confirmação
4. **Processamento**: Importa dados com validação linha por linha
5. **Resultado**: Relatório de sucessos e erros
6. **Histórico**: Job registrado com estatísticas detalhadas

## 🔗 Integrações

### Módulo de Custos
- **Exportação**: Histórico completo de custos por talhão
- **Importação**: Dados de custos de outros sistemas
- **Sincronização**: Atualização automática de custos

### Módulo de Prescrições
- **Exportação**: Prescrições com cálculos e produtos
- **Importação**: Prescrições de sistemas externos
- **Validação**: Verificação de produtos e doses

### Módulo de Talhões
- **Exportação**: Dados geográficos e culturais
- **Importação**: Novos talhões de outros sistemas
- **Mapeamento**: Conversão de coordenadas

## 🛡️ Segurança e Validação

### Validação de Arquivos
- **Formato**: Verificação de extensão e estrutura
- **Tamanho**: Limite máximo de 50MB por arquivo
- **Conteúdo**: Validação de tipos de dados e formatos

### Tratamento de Erros
- **Logs Detalhados**: Registro de todos os erros
- **Recuperação**: Possibilidade de retomar importações interrompidas
- **Notificações**: Alertas para o usuário sobre problemas

### Backup e Recuperação
- **Arquivos Temporários**: Preservação durante processamento
- **Rollback**: Possibilidade de desfazer importações
- **Versionamento**: Controle de versões dos dados

## 📈 Estatísticas e Relatórios

### Métricas de Exportação
- Total de exportações
- Exportações por tipo
- Exportações por status
- Exportações dos últimos 30 dias

### Métricas de Importação
- Total de importações
- Registros processados
- Taxa de sucesso
- Erros por tipo

### Relatórios Disponíveis
- **Relatório de Uso**: Frequência de importações/exportações
- **Relatório de Erros**: Análise de problemas comuns
- **Relatório de Performance**: Tempo de processamento

## 🚀 Melhorias Futuras

### Funcionalidades Planejadas
1. **API REST Completa**: Endpoints para integração externa
2. **Sincronização em Tempo Real**: WebSockets para atualizações
3. **Templates de Exportação**: Formatos personalizáveis
4. **Agendamento**: Exportações automáticas programadas
5. **Compressão**: Redução do tamanho dos arquivos
6. **Criptografia**: Proteção de dados sensíveis

### Integrações Futuras
- **Siagri**: Sincronização bidirecional
- **Aegro**: Importação de dados de campo
- **Strider**: Exportação de mapas de aplicação
- **John Deere Operations Center**: Integração com máquinas
- **Climate FieldView**: Dados climáticos

## 📝 Exemplos de Uso

### Exportação de Custos
```dart
final resultado = await ImportExportService().exportarDados(
  tipo: 'custos',
  formato: 'xlsx',
  filtros: {
    'data_inicio': '2024-01-01',
    'data_fim': '2024-12-31',
    'talhao_id': 'talhao_001',
  },
);
```

### Importação de Prescrições
```dart
final resultado = await ImportExportService().importarDados(
  tipo: 'prescricoes',
  arquivoPath: '/path/to/prescricoes.xlsx',
  nomeArquivoOriginal: 'prescricoes_2024.xlsx',
  tamanhoArquivo: 2.5,
);
```

## 🔧 Configuração e Instalação

### Dependências Necessárias
```yaml
dependencies:
  file_picker: ^5.0.0
  share_plus: ^7.0.0
  excel: ^2.0.0
  csv: ^5.0.0
  path_provider: ^2.0.0
  uuid: ^3.0.0
```

### Inicialização do Módulo
```dart
// No AppDatabase, adicionar criação das tabelas
await ExportJobDao.createTable(db);
await ImportJobDao.createTable(db);
```

## 📞 Suporte e Manutenção

### Logs e Debugging
- **Logger**: Todas as operações são logadas
- **Erro Handling**: Tratamento robusto de exceções
- **Performance**: Monitoramento de tempo de processamento

### Limpeza Automática
- **Jobs Antigos**: Remoção automática após 90 dias
- **Arquivos Temporários**: Limpeza periódica
- **Cache**: Gerenciamento de memória

---

**Desenvolvido para FortSmart Agro**  
*Sistema de Gestão Agrícola Inteligente*
