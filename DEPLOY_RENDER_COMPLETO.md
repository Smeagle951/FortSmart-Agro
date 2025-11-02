# 🚀 Deploy Completo no Render - FortSmart Agro

## ✅ SISTEMA PRONTO - SEM BASE44!

Todo o sistema foi **reconfigurado** para usar **apenas Render** como backend.

---

## 🎯 Arquitetura Final

```
┌─────────────────────┐
│  App Flutter        │  ← Android/iOS (SQLite local)
│  FortSmart Agro     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  API no Render      │  ← Seu backend próprio
│  Node.js + Express  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  PostgreSQL         │  ← Banco de dados (grátis)
│  No Render          │
└─────────────────────┘
```

---

## 📁 Arquivos Criados

### Backend (Servidor)
1. ✅ `Dockerfile` - Build Docker
2. ✅ `server/package.json` - Dependências
3. ✅ `server/index.js` - API completa (593 linhas)
4. ✅ `render.yaml` - Config automática

### Frontend (App Flutter)
5. ✅ `lib/services/fortsmart_sync_service.dart` - Sincronização
6. ✅ `lib/services/appwrite_service.dart` - Appwrite (opcional)

### Documentação
7. ✅ `GUIA_COMPLETO_RENDER_APPWRITE.md` - Guia completo
8. ✅ `DEPLOY_RENDER_COMPLETO.md` - Este arquivo

---

## 🚀 PASSO A PASSO DO DEPLOY

### **PASSO 1: Criar Banco de Dados PostgreSQL**

1. Acesse: https://dashboard.render.com
2. Clique em **"New +"** → **"PostgreSQL"**
3. Configure:
   - **Name:** `fortsmart-agro-db`
   - **Database:** `fortsmart_agro`
   - **User:** `fortsmart_user`
   - **Region:** Oregon (US West)
   - **Plan:** **Free**
4. Clique em **"Create Database"**
5. **COPIE** a **"Internal Database URL"** (vamos usar depois)

Exemplo:
```
postgresql://fortsmart_user:senha@dpg-xxxxx/fortsmart_agro
```

---

### **PASSO 2: Criar Web Service (API)**

1. Clique em **"New +"** → **"Web Service"**
2. Conecte ao repositório: `Smeagle951/FortSmart-Agro`
3. Configure:

| Campo | Valor |
|-------|-------|
| **Name** | `fortsmart-agro-api` |
| **Region** | Oregon (US West) |
| **Branch** | `main` |
| **Root Directory** | (deixe vazio) |
| **Environment** | **Docker** ⚠️ IMPORTANTE! |
| **Dockerfile Path** | `./Dockerfile` |
| **Plan** | **Free** |

4. Role até **"Environment Variables"**
5. Adicione:

| Key | Value |
|-----|-------|
| `NODE_ENV` | `production` |
| `DATABASE_URL` | Cole a URL do banco que você copiou no Passo 1 |

6. Em **"Advanced"**:
   - **Health Check Path:** `/health`
   - **Auto-Deploy:** ✅ Yes

7. Clique em **"Create Web Service"**

---

### **PASSO 3: Aguardar Build**

O Render vai:
1. ✅ Clonar seu repositório
2. ✅ Detectar o Dockerfile
3. ✅ Construir a imagem Docker
4. ✅ Instalar dependências Node.js
5. ✅ Iniciar o servidor
6. ✅ Criar tabelas no PostgreSQL

**Tempo estimado:** 3-5 minutos

Logs esperados:
```
==> Cloning from https://github.com/Smeagle951/FortSmart-Agro
==> Building Docker image...
✅ Build complete!
==> Starting service...
🚀 FortSmart Agro API rodando na porta 10000
✅ Banco de dados inicializado com sucesso
✅ Deploy successful!
```

---

### **PASSO 4: Testar a API**

Quando aparecer **"Live"**, sua API estará em:
```
https://fortsmart-agro-api.onrender.com
```

**Teste no navegador:**

1. Health Check:
```
https://fortsmart-agro-api.onrender.com/health
```

Deve retornar:
```json
{
  "status": "healthy",
  "database": "connected",
  "uptime": 123.45,
  "timestamp": "2025-11-02T..."
}
```

2. Página inicial:
```
https://fortsmart-agro-api.onrender.com/
```

Deve retornar:
```json
{
  "status": "online",
  "service": "FortSmart Agro API",
  "version": "2.0.0",
  "backend": "Render + PostgreSQL"
}
```

---

## 📱 PASSO 5: Atualizar App Flutter

### 1. Alterar URL no Serviço

**Arquivo:** `lib/services/fortsmart_sync_service.dart` (linha 15)

```dart
// Alterar para a URL real que o Render gerou:
static const String _baseUrl = 'https://fortsmart-agro-api.onrender.com/api';
```

### 2. Usar no App

**Na tela de perfil da fazenda:**

```dart
import 'package:fortsmart_agro/services/fortsmart_sync_service.dart';

final syncService = FortSmartSyncService();

// Sincronizar fazenda
Future<void> _syncWithServer() async {
  final result = await syncService.syncFarm(currentFarm);
  
  if (result['success']) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Fazenda sincronizada!')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Erro: ${result['message']}')),
    );
  }
}
```

**Adicionar botão:**

```dart
ElevatedButton.icon(
  onPressed: _syncWithServer,
  icon: Icon(Icons.cloud_upload),
  label: Text('Sincronizar com Servidor'),
)
```

---

## 📊 ENDPOINTS DISPONÍVEIS

### Fazendas
```
POST /api/farms/sync              → Sincronizar fazenda
GET  /api/farms/:farmId           → Buscar fazenda
```

### Relatórios
```
POST /api/reports/agronomic       → Relatório completo
GET  /api/reports/farm/:farmId    → Listar relatórios
```

### Infestação
```
POST /api/infestation/sync        → Sincronizar infestação
GET  /api/infestation/plot/:plotId → Buscar infestações
```

### Mapas
```
GET  /api/heatmap/plot/:plotId    → Gerar heatmap
```

### Dashboard
```
GET  /api/dashboard/farm/:farmId  → Estatísticas
```

---

## 🗄️ BANCO DE DADOS

O PostgreSQL no Render cria automaticamente:

### Tabelas:

**farms** - Dados das fazendas
- id, name, address, municipality, state
- owner_name, document_number, phone, email
- total_area, plots_count, cultures

**plots** - Talhões
- id, farm_id, name, area, polygon
- culture_id, culture_name

**monitorings** - Monitoramentos
- id, farm_id, plot_id, date
- crop_name, plot_name, points, weather_data

**infestation_data** - Dados de infestação
- id, monitoring_id, organism_id, organism_name
- severity, quantity, latitude, longitude, date

**agronomic_reports** - Relatórios
- id, farm_id, plot_id, report_type
- period_start, period_end
- summary, monitoring_data, infestation_analysis, heatmap_data

---

## 💡 EXEMPLOS DE USO

### Exemplo 1: Sincronizar Fazenda

```dart
final syncService = FortSmartSyncService();

// Sincronizar fazenda atual
final farm = await farmService.getCurrentFarm();
final result = await syncService.syncFarm(farm!);

if (result['success']) {
  print('✅ Fazenda no servidor!');
}
```

### Exemplo 2: Sincronizar Relatório Agronômico

```dart
// Sincronizar relatório dos últimos 30 dias
final result = await syncService.syncAgronomicReport(
  farmId: currentFarm.id,
  plotId: selectedTalhao.id,
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now(),
);

if (result['success']) {
  print('Relatório ID: ${result['report_id']}');
}
```

### Exemplo 3: Buscar Heatmap do Servidor

```dart
// Buscar heatmap já processado
final heatmap = await syncService.getHeatmap(talhaoId);

if (heatmap['success']) {
  final points = heatmap['heatmap_points'];
  // Exibir no mapa
  for (var point in points) {
    print('${point['latitude']}, ${point['longitude']} - ${point['level']}');
  }
}
```

### Exemplo 4: Dashboard de Estatísticas

```dart
// Buscar estatísticas da fazenda
final stats = await syncService.getDashboardStats(farmId);

if (stats['success']) {
  final statistics = stats['statistics'];
  print('Total de talhões: ${statistics['plots']['total']}');
  print('Área total: ${statistics['plots']['total_area']} ha');
  print('Monitoramentos: ${statistics['monitorings']['total']}');
  
  // Top organismos
  for (var org in statistics['top_organisms']) {
    print('${org['organism_name']}: ${org['count']} ocorrências');
  }
}
```

---

## ⚠️ IMPORTANTE - Primeira Requisição

O Render Free **spin down** após 15 minutos de inatividade.

**Primeira requisição após inatividade:**
- ⏱️ Pode demorar 50+ segundos
- A API está "acordando"

**Solução:**
```dart
// Mostrar loading ao usuário
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Conectando ao servidor...\nPrimeira conexão pode demorar até 1 minuto.'),
      ],
    ),
  ),
);

final result = await syncService.syncFarm(farm);

Navigator.pop(context); // Fechar loading
```

---

## 🎨 MAPA TÉRMICO - Sistema de Cores

A API retorna heatmap com cores automáticas:

| Nível | Severidade | Cor | Hex |
|---|---|---|---|
| Baixo | 0-24% | 🟢 Verde | #4CAF50 |
| Médio | 25-49% | 🟡 Amarelo | #FFEB3B |
| Alto | 50-74% | 🟠 Laranja | #FF9800 |
| Crítico | 75-100% | 🔴 Vermelho | #FF0000 |

**Exemplo de resposta:**
```json
{
  "success": true,
  "heatmap_points": [
    {
      "latitude": -20.123,
      "longitude": -54.456,
      "intensity": 0.65,
      "severity": 65.0,
      "color": "#FF9800",
      "level": "high",
      "occurrence_count": 15,
      "organisms": ["Lagarta", "Percevejo"]
    }
  ]
}
```

---

## 🔐 SEGURANÇA

### Dados Protegidos
- ✅ API com CORS configurado
- ✅ Helmet (headers de segurança)
- ✅ PostgreSQL com SSL
- ✅ Pronto para adicionar autenticação JWT

### Adicionar Autenticação (Futuro)

```javascript
// No server/index.js
const jwt = require('jsonwebtoken');

function authMiddleware(req, res, next) {
  const token = req.headers['authorization'];
  if (!token) return res.status(401).json({ error: 'Não autorizado' });
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (e) {
    res.status(401).json({ error: 'Token inválido' });
  }
}

// Proteger rotas
app.post('/api/farms/sync', authMiddleware, async (req, res) => {
  // ... código
});
```

---

## 💾 BACKUP DOS DADOS

O PostgreSQL no Render tem:
- ✅ Backups automáticos (plano Free: 7 dias)
- ✅ Restore point-in-time
- ✅ Alta disponibilidade

Para backup manual:
```bash
# Exportar banco
pg_dump $DATABASE_URL > backup.sql

# Restaurar
psql $DATABASE_URL < backup.sql
```

---

## 📈 MONITORAMENTO

### Ver Logs em Tempo Real

No painel do Render:
1. Clique no serviço `fortsmart-agro-api`
2. Vá em **"Logs"**
3. Veja logs ao vivo:

```
🚀 FortSmart Agro API rodando na porta 10000
✅ Banco de dados inicializado
🏡 [FARM] Sincronizando fazenda...
✅ [FARM] Fazenda sincronizada
🌾 [REPORT] Sincronizando relatório...
✅ [REPORT] Relatório salvo
```

### Métricas

Em **"Metrics"** você vê:
- CPU usage
- Memory usage
- Request count
- Response times

---

## 🔄 SINCRONIZAÇÃO OFFLINE-FIRST

### Estratégia Recomendada:

```dart
class SyncManager {
  final FortSmartSyncService _syncService = FortSmartSyncService();
  
  /// Sincroniza dados pendentes
  Future<void> syncPendingData() async {
    // 1. Verificar conectividade
    final isConnected = await _checkConnectivity();
    if (!isConnected) {
      Logger.info('📡 Sem conexão, sincronização adiada');
      return;
    }
    
    // 2. Buscar dados não sincronizados do SQLite
    final pendingFarms = await _getPendingFarms();
    final pendingMonitorings = await _getPendingMonitorings();
    
    // 3. Sincronizar fazendas
    for (final farm in pendingFarms) {
      final result = await _syncService.syncFarm(farm);
      if (result['success']) {
        await _markAsSynced('farms', farm.id);
      }
    }
    
    // 4. Sincronizar monitoramentos
    for (final monitoring in pendingMonitorings) {
      // Enviar como parte do relatório
      await _syncService.syncAgronomicReport(
        farmId: monitoring.farmId,
        plotId: monitoring.plotId,
      );
    }
    
    Logger.info('✅ Sincronização concluída');
  }
}
```

---

## 🎯 FLUXO COMPLETO DE USO

```
1. USUÁRIO NO CAMPO
   ↓
   Coleta dados de monitoramento
   Registra ocorrências
   Tira fotos
   ↓
2. DADOS SALVOS LOCALMENTE (SQLite)
   ↓
   App funciona 100% offline
   ↓
3. QUANDO TEM INTERNET
   ↓
   App detecta conexão
   Chama syncService.syncFarm()
   Chama syncService.syncAgronomicReport()
   ↓
4. API NO RENDER RECEBE
   ↓
   Valida dados
   Salva no PostgreSQL
   Retorna confirmação
   ↓
5. APP MARCA COMO SINCRONIZADO
   ↓
   Dados seguros na nuvem
   Podem ser acessados de outros dispositivos
```

---

## 🌐 DASHBOARD WEB (Próximo Passo)

Você pode criar um painel web que acessa a mesma API:

```html
<!DOCTYPE html>
<html>
<head>
  <title>FortSmart Dashboard</title>
</head>
<body>
  <h1>Dashboard FortSmart</h1>
  <div id="stats"></div>
  
  <script>
    fetch('https://fortsmart-agro-api.onrender.com/api/dashboard/farm/123')
      .then(res => res.json())
      .then(data => {
        const stats = data.statistics;
        document.getElementById('stats').innerHTML = `
          <p>Talhões: ${stats.plots.total}</p>
          <p>Área Total: ${stats.plots.total_area} ha</p>
          <p>Monitoramentos: ${stats.monitorings.total}</p>
        `;
      });
  </script>
</body>
</html>
```

---

## 💰 CUSTOS

### Plano Free (Atual)
- ✅ **$0/mês**
- ✅ 750 horas/mês
- ✅ PostgreSQL 1GB
- ✅ 100GB bandwidth
- ⚠️ Spin down após 15min

### Upgrade (Quando Precisar)
- 💵 **$7/mês** - Sempre ativo
- 💵 **$25/mês** - Pro (mais recursos)

---

## 🆘 PROBLEMAS COMUNS

### Erro: "Database connection failed"
**Solução:** Verificar se DATABASE_URL está correta nas variáveis de ambiente

### Erro: "Timeout"
**Solução:** API pode estar "acordando" (primeira requisição), aguardar 1 minuto

### Erro: "Cannot find module 'pg'"
**Solução:** Verificar se `package.json` tem `"pg": "^8.11.3"`

### Erro: "Build failed"
**Solução:** Verificar logs no Render e garantir que Environment = Docker

---

## ✅ CHECKLIST FINAL

- [ ] Banco PostgreSQL criado no Render
- [ ] Web Service criado no Render
- [ ] DATABASE_URL configurada
- [ ] Build bem-sucedido
- [ ] API responde em /health
- [ ] URL atualizada no app Flutter
- [ ] Teste de sincronização OK
- [ ] (Opcional) Appwrite configurado

---

## 🎉 RESULTADO FINAL

Você agora tem:

✅ **Backend Próprio no Render**
- API RESTful completa
- PostgreSQL grátis
- Endpoints personalizados

✅ **App Flutter Completo**
- Funciona offline (SQLite)
- Sincroniza quando tem internet
- Serviço de sincronização pronto

✅ **Sem Dependências Externas**
- Não precisa de Base44
- Controle total dos dados
- Escalável e profissional

---

## 📞 PRÓXIMOS PASSOS

1. **Agora:** Fazer o deploy no Render (seguir passos acima)
2. **Depois:** Testar sincronização no app
3. **Futuro:** Adicionar autenticação
4. **Futuro:** Dashboard web
5. **Futuro:** Notificações push

---

**Tudo pronto para deploy! 🚀**

**GitHub atualizado:** ✅  
**Commit:** `0c245f0`  
**Status:** Pronto para Render  

---

**Desenvolvido para FortSmart Agro**  
*Sistema de Gestão Agrícola Inteligente - Backend Próprio*

