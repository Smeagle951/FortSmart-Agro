---

# 📦 FUNCIONALIDADES OFFLINE & EM SEGUNDO PLANO – FORTSMART

## 🎯 OBJETIVO GERAL

Permitir que os módulos **Talhões**, **Monitoramento** e **Mapa de Infestação** do FortSmart funcionem **100% offline**, com:

* Cache real de mapas
* Registro contínuo de dados com a tela desligada
* Sincronização automática e leve
* Execução estável em segundo plano

---

## 🧱 ARQUITETURA TÉCNICA GERAL

| Componente           | Tecnologias/Funções Aplicadas                                     |
| -------------------- | ----------------------------------------------------------------- |
| Mapa Offline         | MapLibre + MapTiler (tiles em cache com área da fazenda + buffer) |
| Cache Mapas          | flutter\_map\_tile\_caching, mbtiles ou tilecache via SQLite      |
| Execução 2º plano    | ForegroundService (Android), flutter\_background\_service         |
| GPS Offline          | Geolocator + Kalman filter (suavização)                           |
| Registro de Dados    | SQLite local com drift/floor                                      |
| Sincronização Diária | WorkManager + verificação de conexão automática                   |
| Interface Offline    | Renderização por cache, aviso de status offline                   |

---

## 🌾 MÓDULO TALHÕES – FUNCIONALIDADE OFFLINE

### ✅ Dados Locais

* Lista de talhões armazenada localmente (com geometrias)
* Polígonos carregados no mapa com cache (sem internet)

### ✅ Visualização

* Mapa satélite ou híbrido offline
* Talhões desenhados com cores por cultura

### ✅ Edição e Ações

* Visualização de informações por talhão
* Cadastro e edição offline (nome, cultura, área, observação)
* Registro de ocorrências por talhão (ex: alerta de infestação)

### 🔄 Sincronização

* Atualiza automaticamente quando há internet
* Notifica usuário de sucesso ou falha

> Tabelas: `talhoes_local`, `ocorrencias_talhao_local`

---

## 🦠 MÓDULO MONITORAMENTO – FUNCIONALIDADE OFFLINE & 2º PLANO

### ✅ Funcionalidades Suportadas

* Mapa visual com cache local
* Registro com GPS em segundo plano
* Registro manual por desenho
* Registro de ponto com praga/doença, intensidade, imagem e observação
* Sincronização automática dos dados coletados

#### 🔹 Desenho Manual

* Desenha polígono de infestação offline
* Salvo localmente com metadados (tipo, intensidade, data)

> Tabela: `monitoramento_desenhos_local`

#### 🔹 Caminhada GPS

* Rastreia percurso mesmo com tela desligada
* Cria trilha ou área georreferenciada

> Tabela: `monitoramento_trajetos_local`

#### 🔹 Registro de Ponto

* Marca ponto com localização, cultura, praga/doença, intensidade
* Foto armazenada localmente
* Armazena status "pendente" para sincronização

> Tabela: `monitoramento_pontos_local`

---

## 🗺️ MÓDULO MAPA DE INFESTAÇÃO – FUNCIONALIDADE OFFLINE

### ✅ Visualização Offline

* Usa mapa com cache real em tiles (MapLibre)
* Sobrepõe talhões, trilhas, pontos de infestação com base em dados locais
* Níveis críticos destacados (ex: vermelho para intensidade alta)

### ✅ Interatividade

* Permite filtro por cultura, praga ou data mesmo sem conexão
* Exibe ícones e áreas vetoriais (GeoJSON ou vetor do SQLite)

### ✅ Atualização de Mapa

* Detecta necessidade de atualização de cache ao abrir o app
* Permite baixar nova versão 1x por dia (usuário escolhe)

---

## 📦 ARMAZENAMENTO LOCAL (SQLite)

Tabelas locais:

* `talhoes_local`
* `monitoramento_pontos_local`
* `monitoramento_desenhos_local`
* `monitoramento_trajetos_local`
* `map_tiles_cache_index`
* `historico_sincronizacao`
* `ocorrencias_talhao_local`

Imagens:

* Armazenadas no dispositivo (`/pictures/fortsmart/monitoramento/`)
* Referência cruzada via ID no banco de dados

---

## 🔄 SINCRONIZAÇÃO INTELIGENTE

* Roda automaticamente 1x por dia ou ao detectar internet
* Verifica status dos dados:

  * Se "pendente": tenta envio
  * Se sucesso: marca como "sincronizado"
* Notifica: "✔️ Dados sincronizados com sucesso"
* Permite forçar manualmente se necessário

> Tarefa agendada via `WorkManager` (Flutter + Android)

---

## 📲 UI/UX COMPORTAMENTO

* Interface sempre ativa, mesmo offline
* Ao abrir os módulos:

  * Exibe: "📴 Operando em modo offline"
  * Mapa: renderiza pelo cache
  * Status GPS: Verde (ok), Vermelho (falha)
* Durante caminhada:

  * Cronômetro, distância, precisão GPS visível
* Após marcação:

  * Exibe “✔️ Ponto salvo localmente”

---

## 📥 DOWNLOAD DE MAPA

* Ao abrir o app (com internet):

  * Detecta se há cache desatualizado
  * Notifica: "🔄 Atualize o mapa para uso offline"
  * Botão: "📥 Baixar Mapa Visual"

Configurações de download:

* Área: Fazenda + 5 km de buffer
* Zoom: 12 a 18
* Tamanho máximo configurável (ex: 200 MB)

---

## 🧪 TESTES ESSENCIAIS

| Cenário                               | Esperado                               |
| ------------------------------------- | -------------------------------------- |
| Caminhada de 30min com tela desligada | Trilhas e pontos gravados com precisão |
| Entrada offline com mapa já baixado   | Mapa renderiza normalmente             |
| Registro de ponto sem internet        | Ponto salvo com status pendente        |
| Queda de energia e reinício           | Dados recuperados do SQLite            |
| 48h sem internet                      | Dados mantidos localmente sem perda    |

---

## ✅ CONCLUSÃO

Com esta estrutura:

* O app operará **offline**, com **visualização e coleta completas**
* Os módulos **Talhões**, **Monitoramento** e **Mapa de Infestação** estarão sincronizados
* A **execução em segundo plano garante continuidade de coleta**, mesmo com a tela desligada
* A experiência será robusta, leve e fluida para o campo
