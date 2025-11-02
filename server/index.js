const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 10000;

// Middlewares de segurança e performance
app.use(helmet());
app.use(compression());
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// URL da API Base44
const BASE44_API_URL = process.env.BASE44_API_URL || 'https://api.base44.com.br/v1';
const BASE44_TOKEN = process.env.BASE44_TOKEN || '';

// ============================================================================
// ROUTES - HEALTH CHECK
// ============================================================================

app.get('/', (req, res) => {
  res.json({
    status: 'online',
    service: 'FortSmart Agro API',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

// ============================================================================
// ROUTES - SINCRONIZAÇÃO COM BASE44
// ============================================================================

// Sincronizar fazenda
app.post('/api/sync/farm', async (req, res) => {
  try {
    console.log('📡 [SYNC] Sincronizando fazenda com Base44...');
    
    const farmData = req.body;
    
    // Enviar para Base44
    const response = await axios.post(
      `${BASE44_API_URL}/farms/sync`,
      farmData,
      {
        headers: {
          'Authorization': `Bearer ${BASE44_TOKEN}`,
          'Content-Type': 'application/json',
        },
        timeout: 30000,
      }
    );
    
    console.log('✅ [SYNC] Fazenda sincronizada com sucesso');
    
    res.json({
      success: true,
      message: 'Fazenda sincronizada com Base44',
      data: response.data,
    });
  } catch (error) {
    console.error('❌ [SYNC] Erro ao sincronizar fazenda:', error.message);
    
    res.status(500).json({
      success: false,
      message: 'Erro ao sincronizar fazenda',
      error: error.message,
    });
  }
});

// Sincronizar relatório agronômico
app.post('/api/sync/agronomic-report', async (req, res) => {
  try {
    console.log('🌾 [SYNC] Sincronizando relatório agronômico...');
    
    const reportData = req.body;
    
    // Validar dados
    if (!reportData.farm_id || !reportData.talhao_id) {
      return res.status(400).json({
        success: false,
        message: 'farm_id e talhao_id são obrigatórios',
      });
    }
    
    // Enviar para Base44
    const response = await axios.post(
      `${BASE44_API_URL}/agronomic-reports/sync`,
      reportData,
      {
        headers: {
          'Authorization': `Bearer ${BASE44_TOKEN}`,
          'Content-Type': 'application/json',
        },
        timeout: 60000,
      }
    );
    
    console.log('✅ [SYNC] Relatório agronômico sincronizado');
    
    res.json({
      success: true,
      message: 'Relatório agronômico sincronizado',
      report_id: response.data.report_id,
      data: response.data,
    });
  } catch (error) {
    console.error('❌ [SYNC] Erro ao sincronizar relatório:', error.message);
    
    res.status(500).json({
      success: false,
      message: 'Erro ao sincronizar relatório',
      error: error.message,
    });
  }
});

// Sincronizar dados de infestação
app.post('/api/sync/infestation', async (req, res) => {
  try {
    console.log('🐛 [SYNC] Sincronizando dados de infestação...');
    
    const infestationData = req.body;
    
    // Enviar para Base44
    const response = await axios.post(
      `${BASE44_API_URL}/infestation/sync`,
      infestationData,
      {
        headers: {
          'Authorization': `Bearer ${BASE44_TOKEN}`,
          'Content-Type': 'application/json',
        },
        timeout: 30000,
      }
    );
    
    console.log('✅ [SYNC] Infestação sincronizada');
    
    res.json({
      success: true,
      message: 'Dados de infestação sincronizados',
      data: response.data,
    });
  } catch (error) {
    console.error('❌ [SYNC] Erro ao sincronizar infestação:', error.message);
    
    res.status(500).json({
      success: false,
      message: 'Erro ao sincronizar infestação',
      error: error.message,
    });
  }
});

// Sincronizar mapa térmico
app.post('/api/sync/heatmap', async (req, res) => {
  try {
    console.log('🗺️ [SYNC] Sincronizando mapa térmico...');
    
    const heatmapData = req.body;
    
    // Enviar para Base44
    const response = await axios.post(
      `${BASE44_API_URL}/heatmap/sync`,
      heatmapData,
      {
        headers: {
          'Authorization': `Bearer ${BASE44_TOKEN}`,
          'Content-Type': 'application/json',
        },
        timeout: 30000,
      }
    );
    
    console.log('✅ [SYNC] Heatmap sincronizado');
    
    res.json({
      success: true,
      message: 'Mapa térmico sincronizado',
      points_count: heatmapData.heatmap_points?.length || 0,
      data: response.data,
    });
  } catch (error) {
    console.error('❌ [SYNC] Erro ao sincronizar heatmap:', error.message);
    
    res.status(500).json({
      success: false,
      message: 'Erro ao sincronizar mapa térmico',
      error: error.message,
    });
  }
});

// Verificar status de sincronização
app.get('/api/sync/status/:farmId', async (req, res) => {
  try {
    const { farmId } = req.params;
    
    console.log(`🔍 [SYNC] Verificando status da fazenda: ${farmId}`);
    
    const response = await axios.get(
      `${BASE44_API_URL}/farms/${farmId}/sync-status`,
      {
        headers: {
          'Authorization': `Bearer ${BASE44_TOKEN}`,
        },
        timeout: 15000,
      }
    );
    
    res.json({
      success: true,
      data: response.data,
    });
  } catch (error) {
    console.error('❌ [SYNC] Erro ao verificar status:', error.message);
    
    res.status(500).json({
      success: false,
      message: 'Erro ao verificar status',
      error: error.message,
    });
  }
});

// Histórico de sincronizações
app.get('/api/sync/history/:farmId', async (req, res) => {
  try {
    const { farmId } = req.params;
    
    console.log(`📜 [SYNC] Buscando histórico da fazenda: ${farmId}`);
    
    const response = await axios.get(
      `${BASE44_API_URL}/farms/${farmId}/sync-history`,
      {
        headers: {
          'Authorization': `Bearer ${BASE44_TOKEN}`,
        },
        timeout: 15000,
      }
    );
    
    res.json({
      success: true,
      history: response.data,
    });
  } catch (error) {
    console.error('❌ [SYNC] Erro ao buscar histórico:', error.message);
    
    res.status(500).json({
      success: false,
      message: 'Erro ao buscar histórico',
      error: error.message,
    });
  }
});

// ============================================================================
// ERROR HANDLING
// ============================================================================

app.use((err, req, res, next) => {
  console.error('❌ [ERROR]', err);
  res.status(500).json({
    success: false,
    message: 'Erro interno do servidor',
    error: err.message,
  });
});

// ============================================================================
// START SERVER
// ============================================================================

app.listen(PORT, '0.0.0.0', () => {
  console.log('🚀 ========================================');
  console.log(`🚀 FortSmart Agro API rodando na porta ${PORT}`);
  console.log(`🚀 Ambiente: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🚀 Base44 URL: ${BASE44_API_URL}`);
  console.log('🚀 ========================================');
});

module.exports = app;

