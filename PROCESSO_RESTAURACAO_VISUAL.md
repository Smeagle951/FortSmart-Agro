# 📥 Processo de Restauração de Backup - Visual

## 🎯 Resumo Rápido

```
┌─────────────────────────────────────────────────────────────┐
│  RESTAURAÇÃO DE BACKUP - PASSO A PASSO                     │
└─────────────────────────────────────────────────────────────┘

1️⃣ USUÁRIO                    2️⃣ SISTEMA
   ↓                              ↓
   Clica em "Restaurar"          Exibe diálogo de confirmação
   ↓                              ↓
   Confirma ação                 Abre seletor de arquivo
   ↓                              ↓
   Seleciona arquivo .zip        Valida arquivo
   ↓                              ↓
   Aguarda processo              Fecha banco de dados
                                  ↓
                                 Descompacta .zip
                                  ↓
                                 Localiza arquivo .db
                                  ↓
                                 Substitui banco atual
                                  ↓
                                 Reabre banco de dados
                                  ↓
3️⃣ RESULTADO                     Exibe mensagem de sucesso
   ↓                              ↓
   Fecha o app                   ✅ CONCLUÍDO
   ↓
   Reabre o app
   ↓
   ✅ Dados restaurados!
```

---

## 🔄 Fluxo Técnico Detalhado

```
┌──────────────────────────────────────────────────────────────────┐
│                    FLUXO DE RESTAURAÇÃO                          │
└──────────────────────────────────────────────────────────────────┘

📱 INTERFACE (backup_screen.dart)
    │
    ├── Exibe diálogo de confirmação
    │   └── ⚠️ "Dados atuais serão perdidos"
    │
    ├── Seleciona arquivo .zip
    │   └── Valida extensão (.zip)
    │
    ├── Chama BackupService.restoreBackup()
    │
    ↓

🔧 SERVIÇO (backup_service.dart)
    │
    ├── [1] Verifica se arquivo existe
    │   ├── ✅ Arquivo existe → Continua
    │   └── ❌ Não existe → Retorna erro
    │
    ├── [2] Fecha banco de dados
    │   └── db.close()
    │
    ├── [3] Lê arquivo .zip
    │   └── File.readAsBytes()
    │
    ├── [4] Descompacta arquivo
    │   └── ZipDecoder().decodeBytes()
    │
    ├── [5] Localiza banco no .zip
    │   ├── ✅ Encontrou "fortsmart_agro.db"
    │   └── ❌ Não encontrou → Retorna erro
    │
    ├── [6] Obtém caminho do banco atual
    │   └── getDatabasesPath()
    │
    ├── [7] Substitui banco de dados
    │   └── File.writeAsBytes()
    │   └── ⚠️ Dados antigos são PERDIDOS
    │
    ├── [8] Reabre banco de dados
    │   └── _database.database
    │
    ├── [9] Retorna sucesso
    │   └── return true ✅
    │
    ↓

🗄️ BANCO DE DADOS (app_database.dart)
    │
    ├── Detecta banco restaurado
    ├── Verifica versão
    ├── Aplica migrações (se necessário)
    └── ✅ Banco pronto para uso

```

---

## 📂 Estrutura do Arquivo de Backup

```
fortsmartagro_backup_20241028_153045.zip
│
├── fortsmart_agro.db          ← Arquivo principal (banco de dados)
│   └── Contém TODAS as tabelas:
│       ├── talhoes
│       ├── safras
│       ├── plantios
│       ├── monitorings
│       ├── culturas
│       ├── agricultural_products
│       ├── catalog_organisms
│       └── ... (40+ tabelas)
│
└── backup_info.txt            ← Informações do backup
    ├── Data de criação
    ├── Versão do app
    ├── Dispositivo
    └── Estatísticas:
        ├── Talhões: 5
        ├── Plantios: 12
        ├── Monitoramentos: 34
        └── ...
```

---

## ⚡ Comparação: Backup vs Restauração

```
┌────────────────────────┬────────────────────────────────────┐
│   🔵 CRIAR BACKUP      │   🟢 RESTAURAR BACKUP              │
├────────────────────────┼────────────────────────────────────┤
│ 1. Lê dados atuais     │ 1. Fecha banco de dados            │
│ 2. Cria estatísticas   │ 2. Lê arquivo .zip                 │
│ 3. Compacta em .zip    │ 3. Descompacta arquivo             │
│ 4. Salva em Downloads  │ 4. Substitui banco atual           │
│ 5. ✅ Dados preservados │ 5. ⚠️ Dados antigos PERDIDOS       │
│ 6. App continua normal │ 6. ✅ Requer reiniciar app          │
└────────────────────────┴────────────────────────────────────┘
```

---

## 🎭 Dois Caminhos de Restauração

### Opção A: Do Histórico
```
Histórico de Backups
┌────────────────────────────────────────┐
│ 📦 fortsmartagro_backup_20241028.zip   │
│    28/10/2024 15:30                    │
│    2.34 MB                             │
│    ✅ Sucesso          [⟲ Restaurar]   │ ← Clique aqui
└────────────────────────────────────────┘
         │
         ↓
    [Confirmar?]
         │
         ↓
    [Restaurando...]
         │
         ↓
    ✅ Concluído!
```

### Opção B: Arquivo Externo
```
Botão "Restaurar"
       │
       ↓
  [Confirmar?]
       │
       ↓
[Selecionar arquivo]
       │
       ↓
   📁 Navegador
       │
       ↓
  Escolhe .zip
       │
       ↓
[Restaurando...]
       │
       ↓
  ✅ Concluído!
```

---

## 💾 Estados do Banco de Dados

```
ANTES DA RESTAURAÇÃO:
┌──────────────────┐
│ Banco Atual      │
│ ┌──────────────┐ │
│ │ Talhões: 10  │ │
│ │ Plantios: 25 │ │
│ │ Safras: 3    │ │
│ └──────────────┘ │
└──────────────────┘

        ↓
        │ Restaurar backup
        ↓

DURANTE A RESTAURAÇÃO:
┌──────────────────┐
│ ⚠️ Banco Fechado │
│ ┌──────────────┐ │
│ │ Substituindo │ │
│ │ arquivo...   │ │
│ │ [████░░░░]   │ │
│ └──────────────┘ │
└──────────────────┘

        ↓
        │ Conclusão
        ↓

DEPOIS DA RESTAURAÇÃO:
┌──────────────────┐
│ Banco Restaurado │
│ ┌──────────────┐ │
│ │ Talhões: 5   │ │
│ │ Plantios: 12 │ │
│ │ Safras: 2    │ │
│ └──────────────┘ │
└──────────────────┘
  ↓
  ⚠️ REINICIAR APP!
```

---

## 🚨 Pontos de Atenção

```
┌────────────────────────────────────────────────┐
│  ⚠️ CUIDADOS ESSENCIAIS                        │
├────────────────────────────────────────────────┤
│                                                │
│  1. BACKUP ATUAL                               │
│     ✅ Criar backup antes de restaurar         │
│     ❌ Não restaurar sem backup de segurança   │
│                                                │
│  2. ARQUIVO VÁLIDO                             │
│     ✅ Arquivo .zip do FortSmart Agro          │
│     ❌ Não usar arquivos corrompidos           │
│                                                │
│  3. ESPAÇO DISPONÍVEL                          │
│     ✅ Mínimo 50 MB livres                     │
│     ❌ Não restaurar com pouco espaço          │
│                                                │
│  4. REINICIAR APP                              │
│     ✅ Fechar e reabrir completamente          │
│     ❌ Não apenas minimizar                    │
│                                                │
│  5. VERIFICAR DADOS                            │
│     ✅ Conferir talhões e plantios             │
│     ❌ Não assumir que tudo está OK            │
│                                                │
└────────────────────────────────────────────────┘
```

---

## 🎯 Checklist de Restauração

```
ANTES:
□ Criei backup dos dados atuais
□ Tenho o arquivo .zip do backup
□ Verifiquei espaço disponível (mínimo 50 MB)
□ Fechei todas as telas abertas
□ Li o aviso de que dados serão substituídos

DURANTE:
□ Selecionei o arquivo .zip correto
□ Confirmei a ação no diálogo
□ Aguardei a mensagem de sucesso
□ Não interrompi o processo

DEPOIS:
□ Fechei o aplicativo completamente
□ Reabri o aplicativo
□ Verifiquei se os dados foram restaurados
□ Testei funcionalidades principais
□ Conferir talhões, plantios e monitoramentos

✅ RESTAURAÇÃO CONCLUÍDA COM SUCESSO!
```

---

## 📊 Tempo Estimado

```
Tamanho do Backup     | Tempo de Restauração
─────────────────────┼─────────────────────
< 10 MB               | 2-5 segundos
10-50 MB              | 5-15 segundos
50-100 MB             | 15-30 segundos
> 100 MB              | 30-60 segundos

⚠️ Tempo varia conforme:
   - Velocidade do dispositivo
   - Tamanho do banco de dados
   - Velocidade de leitura do armazenamento
```

---

## 🔍 Como Verificar se Restaurou Corretamente

```
✅ SINAIS DE SUCESSO:

1. Mensagem de sucesso exibida
   └── "Backup restaurado com sucesso!"

2. Ao reabrir, dados aparecem
   └── Talhões, plantios, monitoramentos visíveis

3. Números conferem com o backup
   └── Quantidade de registros bate

4. Sem erros ao navegar
   └── App funciona normalmente


❌ SINAIS DE PROBLEMA:

1. Erro durante restauração
   └── Mensagem de erro exibida

2. Dados não aparecem
   └── Telas aparecem vazias

3. App trava ou fecha
   └── Crashes frequentes

4. Números não batem
   └── Faltam registros
```

---

**Criado em:** 28/10/2025  
**Para:** FortSmart Agro  
**Versão:** 1.0

