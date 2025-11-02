# 📥 Guia Completo: Download de Fazenda para Uso Offline

## 🎯 O Que É?

Funcionalidade que permite **baixar TODA a fazenda** (talhões + mapas) para uso **100% offline** nos módulos:
- 📍 **Módulo Talhões**
- 🔍 **Módulo Monitoramento** 
- 🗺️ **Módulo Mapa de Infestação**

## ✨ Arquivos Criados

### 1. Widget de Download
**`lib/widgets/download_fazenda_offline_widget.dart`**
- Widget reutilizável para baixar fazenda
- Mostra progresso em tempo real
- Configurações de qualidade
- Integração com OfflineMapService

### 2. Tela Dedicada
**`lib/screens/offline/download_fazenda_screen.dart`**
- Tela completa para download
- Seletor de fazenda
- Ajuda e instruções
- Interface intuitiva

### 3. Rota Registrada
**`lib/routes.dart`**
- Rota: `/download_fazenda_offline`
- Acessível via Navigator
- Integrada ao sistema

## 🚀 Como Acessar

### Opção 1: Via Código
```dart
Navigator.pushNamed(context, Routes.downloadFazendaOffline);
```

### Opção 2: Adicionar Menu

Adicione no menu de configurações ou na tela inicial:

```dart
ListTile(
  leading: const Icon(Icons.cloud_download, color: Colors.blue),
  title: const Text('Download Offline'),
  subtitle: const Text('Baixar fazenda para uso sem internet'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    Navigator.pushNamed(context, Routes.downloadFazendaOffline);
  },
)
```

## 📱 Como Usar

### Passo 1: Acessar a Tela
1. Abra o menu de **Configurações** ou **Menu Principal**
2. Procure por **"Download Offline"** ou **"Modo Offline"**
3. Toque para abrir

### Passo 2: Selecionar Fazenda
1. Use o seletor **"Selecionar Fazenda"**
2. Escolha a fazenda que deseja baixar
3. Veja informações:
   - Número de talhões
   - Total de hectares

### Passo 3: Configurar Qualidade
1. **Tipo de Mapa:**
   - 🛰️ Satélite (recomendado)
   - 🗺️ Híbrido (satélite + nomes)
   - 🚗 Ruas (mapa de ruas)

2. **Qualidade (Slider):**
   - **Baixa:** ~50 MB, rápido, menos detalhe
   - **Média:** ~150 MB, equilibrado ✅ (RECOMENDADO)
   - **Alta:** ~600 MB, muito detalhe
   - **Máxima:** ~1 GB, detalhe extremo

### Passo 4: Iniciar Download
1. Certifique-se de estar conectado ao **Wi-Fi** (recomendado)
2. Clique em **"Baixar Fazenda Completa"**
3. Confirme no diálogo que aparece
4. Aguarde o download (pode levar 5-30 minutos)

### Passo 5: Acompanhar Progresso
Durante o download, você verá:
- 📊 Barra de progresso (0% → 100%)
- 📍 Talhão atual sendo baixado
- ⏱️ Talhões processados (ex: 5 de 10)

### Passo 6: Concluir
Quando terminar:
- ✅ Diálogo de sucesso
- ✅ Confirmação de quais módulos estão offline
- ✅ Pronto para usar sem internet!

## 🌐 Usando os Módulos Offline

### Módulo Talhões 📍
```dart
// Acesso normal - automaticamente usa mapas offline
Navigator.pushNamed(context, Routes.novoTalhao);
```
- ✅ Visualizar talhões sem internet
- ✅ Editar talhões offline
- ✅ Criar novos talhões
- ✅ Mapas carregam do cache local

### Módulo Monitoramento 🔍
```dart
Navigator.pushNamed(context, Routes.advancedMonitoring);
```
- ✅ Registrar pontos de monitoramento
- ✅ Ver talhões no mapa
- ✅ GPS funciona normalmente
- ✅ Dados salvos localmente

### Módulo Mapa de Infestação 🗺️
```dart
Navigator.pushNamed(context, Routes.infestationMap);
```
- ✅ Visualizar mapa de calor
- ✅ Analisar infestações
- ✅ Ver talhões e ocorrências
- ✅ Tudo funciona offline

## ⚙️ Detalhes Técnicos

### Zooms de Mapa

| Zoom | Descrição | Uso |
|------|-----------|-----|
| 14-15 | Visão geral da fazenda | Navegação |
| 16-17 | Talhões individuais | Trabalho normal |
| 18-19 | Alto detalhe | Análise precisa |
| 20 | Máximo detalhe | Raramente necessário |

### Tipos de Mapa

| Tipo | Descrição | Quando Usar |
|------|-----------|-------------|
| Satélite | Imagem de satélite pura | Melhor para agricultura |
| Híbrido | Satélite + nomes/estradas | Navegação + agricultura |
| Ruas | Mapa de ruas tradicional | Não recomendado p/ agro |

### Estimativa de Tamanho

Para uma fazenda com **10 talhões** e qualidade **Média**:
- Zoom 14-17
- ~1000 tiles por talhão
- ~15 KB por tile
- **Total: ~150 MB**

Fórmula:
```
Tamanho = Talhões × Tiles/Talhão × 15 KB
```

## 🔋 Economia de Dados

### Com Download Offline:
```
Antes do download:
├─ Conectado ao Wi-Fi: Download da fazenda (150 MB uma vez)
└─ No campo SEM internet:
    ├─ Módulo Talhões: 0 MB ✅
    ├─ Módulo Monitoramento: 0 MB ✅
    └─ Módulo Mapa de Infestação: 0 MB ✅
Total: 150 MB (Wi-Fi) + 0 MB (campo)
```

### Sem Download Offline:
```
No campo COM internet móvel:
├─ Módulo Talhões: 50 MB por sessão ❌
├─ Módulo Monitoramento: 30 MB por sessão ❌
└─ Módulo Mapa de Infestação: 70 MB por sessão ❌
Total: ~150 MB POR DIA de campo ❌
```

**Economia: 100% dos dados móveis no campo!**

## 📋 Exemplo de Uso Completo

```dart
// 1. Adicionar botão no menu de configurações
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          // ... outros itens ...
          
          // Botão de Download Offline
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cloud_download, color: Colors.blue),
              ),
              title: const Text(
                'Download Offline',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Baixar fazenda para trabalhar sem internet',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, Routes.downloadFazendaOffline);
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## ⚡ Fluxo de Funcionamento

```
1. Usuário abre tela de Download
   ↓
2. Seleciona fazenda
   ↓
3. Configura qualidade
   ↓
4. Clica em "Baixar"
   ↓
5. Sistema baixa tiles para cada talhão
   │  ├─ Talhão 1: 850 tiles
   │  ├─ Talhão 2: 920 tiles
   │  └─ ... Talhão 10: 1100 tiles
   ↓
6. Salva tiles no cache local
   │  Pasta: /app_documents/offline_maps/{talhaoId}/
   ↓
7. Download concluído!
   ↓
8. Módulos detectam mapas offline automaticamente
   │  ├─ Talhões: Carrega de cache
   │  ├─ Monitoramento: Usa tiles locais
   │  └─ Mapa Infestação: Renderiza offline
   ↓
9. Funciona SEM internet! ✅
```

## 🛠️ Manutenção e Gerenciamento

### Verificar Mapas Baixados

```dart
final offlineMapService = OfflineMapService();

// Ver estatísticas
final stats = await offlineMapService.getStorageStats();
print('Espaço usado: ${stats['totalSize']} MB');
print('Tiles baixados: ${stats['totalTiles']}');

// Verificar se fazenda tem mapas
final hasOffline = await offlineMapService.hasOfflineMaps(talhaoId);
```

### Limpar Mapas Antigos

```dart
// Limpar mapas com mais de 30 dias
await offlineMapService.cleanupOldMaps(daysOld: 30);
```

### Atualizar Mapas

Para atualizar (após mudanças nos talhões):
1. Exclua os mapas antigos
2. Baixe novamente

## 🎨 Personalização

### Ajustar Qualidade Padrão

```dart
// Em download_fazenda_offline_widget.dart
int _zoomMin = 14; // Zoom mínimo
int _zoomMax = 17; // Zoom máximo (média qualidade)
```

### Ajustar Tamanho do Cache

```dart
// Em enhanced_offline_map_service.dart
static const int _maxCacheSize = 500 * 1024 * 1024; // 500MB
```

### Alterar Tipo de Mapa Padrão

```dart
String _tipoMapa = 'satellite'; // satellite, hybrid, streets
```

## ❓ Perguntas Frequentes

### 1. Quanto tempo leva o download?
- Depende de:
  - Número de talhões (1-50+)
  - Qualidade escolhida (baixa-máxima)
  - Velocidade da internet
- **Típico:** 5-15 minutos para fazenda média (10 talhões, qualidade média)

### 2. Preciso baixar toda vez?
- ❌ NÃO! Baixe uma vez e use por 30+ dias
- ✅ Só baixe novamente se:
  - Criar/editar talhões
  - Querer mapas mais recentes
  - Mudar de fazenda

### 3. Funciona com GPS offline?
- ✅ SIM! GPS não precisa de internet
- ✅ Posição é calculada por satélites
- ✅ Apenas os mapas são baixados

### 4. Os dados de monitoramento ficam salvos?
- ✅ SIM! Tudo salvo no SQLite local
- ✅ Sincroniza automático quando voltar conexão
- ✅ Nada é perdido

### 5. Posso usar em várias fazendas?
- ✅ SIM! Baixe quantas quiser
- ⚠️ Cuidado com espaço de armazenamento
- 💡 Recomendado: baixar apenas fazendas ativas

## 🔮 Melhorias Futuras

### Fase 2:
- [ ] Download em segundo plano
- [ ] Atualização automática periódica
- [ ] Compressão de tiles
- [ ] Download seletivo (só talhões marcados)

### Fase 3:
- [ ] Compartilhar mapas entre dispositivos
- [ ] Backup de mapas offline
- [ ] Download agendado
- [ ] Estatísticas de uso

## 📊 Comparação: Online vs Offline

| Aspecto | Modo Online | Modo Offline |
|---------|-------------|--------------|
| **Conexão** | Requer internet | SEM internet |
| **Velocidade Mapas** | Depende da conexão | Instantâneo ✅ |
| **Uso de Dados** | ~150 MB/dia | 0 MB/dia ✅ |
| **Bateria** | Mais consumo | Menos consumo ✅ |
| **Confiabilidade** | Depende de sinal | 100% confiável ✅ |
| **Espaço Storage** | 0 MB | 150-600 MB |

## 💡 Dicas de Uso

### ✅ FAÇA:
- Baixe com Wi-Fi (economiza dados móveis)
- Use qualidade "Média" (suficiente para 99% dos casos)
- Baixe antes de ir ao campo
- Teste offline antes de sair

### ❌ NÃO FAÇA:
- Baixar com dados móveis 4G (caro!)
- Usar qualidade "Máxima" sem necessidade
- Esquecer de baixar antes do campo
- Baixar fazendas que não vai usar

## 🧪 Teste de Funcionalidade

### Como Testar:

1. **Baixe a fazenda** (qualidade baixa para teste rápido)
2. **Ative modo avião** no celular
3. **Abra cada módulo:**
   - Talhões: ✅ Mapas devem carregar
   - Monitoramento: ✅ GPS deve funcionar
   - Mapa de Infestação: ✅ Deve renderizar
4. **Desative modo avião**
5. **Sucesso!** ✅

## 📞 Suporte

Se tiver problemas:
1. Verifique espaço de armazenamento disponível
2. Tente qualidade mais baixa
3. Verifique se a fazenda tem talhões cadastrados
4. Veja os logs no console (procure por 🌾 e 📥)

---

**Criado em:** 27 de Outubro de 2025  
**Versão:** 1.0  
**Status:** ✅ Implementado e Pronto para Uso  
**Compatibilidade:** Android + iOS  
**Requisitos:** Mínimo 200 MB de espaço livre

