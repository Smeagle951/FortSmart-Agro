const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 10000;

// Configuração do PostgreSQL (Render fornece automaticamente)
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

// Middlewares
app.use(helmet());
app.use(compression());
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// ============================================================================
// INICIALIZAÇÃO DO BANCO DE DADOS
// ============================================================================

async function initDatabase() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS farms (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT,
        municipality TEXT,
        state TEXT,
        owner_name TEXT,
        document_number TEXT,
        phone TEXT,
        email TEXT,
        total_area DECIMAL(10,2),
        plots_count INTEGER,
        cultures JSONB,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS plots (
        id TEXT PRIMARY KEY,
        farm_id TEXT REFERENCES farms(id),
        name TEXT NOT NULL,
        area DECIMAL(10,2),
        polygon JSONB,
        culture_id TEXT,
        culture_name TEXT,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS monitorings (
        id TEXT PRIMARY KEY,
        farm_id TEXT REFERENCES farms(id),
        plot_id TEXT REFERENCES plots(id),
        date TIMESTAMP NOT NULL,
        crop_name TEXT,
        plot_name TEXT,
        points JSONB,
        weather_data JSONB,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS infestation_data (
        id TEXT PRIMARY KEY,
        monitoring_id TEXT REFERENCES monitorings(id),
        organism_id TEXT,
        organism_name TEXT,
        severity DECIMAL(5,2),
        quantity INTEGER,
        latitude DECIMAL(10,8),
        longitude DECIMAL(11,8),
        date TIMESTAMP,
        created_at TIMESTAMP DEFAULT NOW()
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS agronomic_reports (
        id TEXT PRIMARY KEY,
        farm_id TEXT REFERENCES farms(id),
        plot_id TEXT REFERENCES plots(id),
        report_type TEXT,
        period_start DATE,
        period_end DATE,
        summary JSONB,
        monitoring_data JSONB,
        infestation_analysis JSONB,
        heatmap_data JSONB,
        created_at TIMESTAMP DEFAULT NOW()
      );
    `);

    console.log('✅ Banco de dados inicializado com sucesso');
  } catch (error) {
    console.error('❌ Erro ao inicializar banco de dados:', error);
  }
}

// Inicializar banco ao startar
initDatabase();

// ============================================================================
// ROUTES - HEALTH CHECK
// ============================================================================

app.get('/', (req, res) => {
  res.json({
    status: 'online',
    service: 'FortSmart Agro API',
    version: '2.0.0',
    backend: 'Render + PostgreSQL',
    timestamp: new Date().toISOString(),
  });
});

app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({
      status: 'healthy',
      database: 'connected',
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      database: 'disconnected',
      error: error.message,
    });
  }
});

// ============================================================================
// ROUTES - FAZENDAS
// ============================================================================

// Criar/Atualizar fazenda
app.post('/api/farms/sync', async (req, res) => {
  try {
    console.log('🏡 [FARM] Sincronizando fazenda...');
    
    const { farm, plots } = req.body;

    // Upsert fazenda
    await pool.query(`
      INSERT INTO farms (id, name, address, municipality, state, owner_name, 
                         document_number, phone, email, total_area, plots_count, cultures)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        address = EXCLUDED.address,
        municipality = EXCLUDED.municipality,
        state = EXCLUDED.state,
        owner_name = EXCLUDED.owner_name,
        document_number = EXCLUDED.document_number,
        phone = EXCLUDED.phone,
        email = EXCLUDED.email,
        total_area = EXCLUDED.total_area,
        plots_count = EXCLUDED.plots_count,
        cultures = EXCLUDED.cultures,
        updated_at = NOW()
    `, [
      farm.id, farm.name, farm.address, farm.city, farm.state,
      farm.owner, farm.document, farm.phone, farm.email,
      farm.total_area, farm.plots_count, JSON.stringify(farm.cultures)
    ]);

    // Sincronizar talhões
    if (plots && plots.length > 0) {
      for (const plot of plots) {
        await pool.query(`
          INSERT INTO plots (id, farm_id, name, area, polygon, culture_id, culture_name)
          VALUES ($1, $2, $3, $4, $5, $6, $7)
          ON CONFLICT (id) DO UPDATE SET
            name = EXCLUDED.name,
            area = EXCLUDED.area,
            culture_name = EXCLUDED.culture_name,
            updated_at = NOW()
        `, [
          plot.id, farm.id, plot.name, plot.area,
          JSON.stringify(plot.polygon), plot.culture_id, plot.culture_name
        ]);
      }
    }

    console.log('✅ [FARM] Fazenda sincronizada');

    res.json({
      success: true,
      message: 'Fazenda sincronizada com sucesso',
      farm_id: farm.id,
    });
  } catch (error) {
    console.error('❌ [FARM] Erro:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao sincronizar fazenda',
      error: error.message,
    });
  }
});

// Buscar fazenda
app.get('/api/farms/:farmId', async (req, res) => {
  try {
    const { farmId } = req.params;
    
    const farmResult = await pool.query('SELECT * FROM farms WHERE id = $1', [farmId]);
    
    if (farmResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Fazenda não encontrada',
      });
    }

    const plotsResult = await pool.query('SELECT * FROM plots WHERE farm_id = $1', [farmId]);

    res.json({
      success: true,
      farm: farmResult.rows[0],
      plots: plotsResult.rows,
    });
  } catch (error) {
    console.error('❌ [FARM] Erro ao buscar:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// ============================================================================
// ROUTES - RELATÓRIOS AGRONÔMICOS
// ============================================================================

// Sincronizar relatório agronômico completo
app.post('/api/reports/agronomic', async (req, res) => {
  try {
    console.log('🌾 [REPORT] Sincronizando relatório agronômico...');
    
    const {
      farm_id,
      plot_id,
      report_type,
      period,
      monitoring_data,
      infestation_analysis,
      heatmap_data,
    } = req.body;

    // Salvar monitoramentos
    if (monitoring_data && monitoring_data.length > 0) {
      for (const monitoring of monitoring_data) {
        await pool.query(`
          INSERT INTO monitorings (id, farm_id, plot_id, date, crop_name, plot_name, points, weather_data)
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
          ON CONFLICT (id) DO UPDATE SET
            points = EXCLUDED.points,
            weather_data = EXCLUDED.weather_data,
            updated_at = NOW()
        `, [
          monitoring.id,
          farm_id,
          plot_id,
          monitoring.date,
          monitoring.crop_name,
          monitoring.plot_name,
          JSON.stringify(monitoring.points || []),
          JSON.stringify(monitoring.weather_data || {})
        ]);
      }
    }

    // Salvar relatório completo
    const reportResult = await pool.query(`
      INSERT INTO agronomic_reports 
        (id, farm_id, plot_id, report_type, period_start, period_end, 
         summary, monitoring_data, infestation_analysis, heatmap_data)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      RETURNING id
    `, [
      `report_${Date.now()}`,
      farm_id,
      plot_id,
      report_type || 'agronomic_complete',
      period?.start_date,
      period?.end_date,
      JSON.stringify(req.body.summary || {}),
      JSON.stringify(monitoring_data || []),
      JSON.stringify(infestation_analysis || {}),
      JSON.stringify(heatmap_data || [])
    ]);

    console.log('✅ [REPORT] Relatório salvo');

    res.json({
      success: true,
      message: 'Relatório agronômico sincronizado',
      report_id: reportResult.rows[0].id,
    });
  } catch (error) {
    console.error('❌ [REPORT] Erro:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// Buscar relatórios de uma fazenda
app.get('/api/reports/farm/:farmId', async (req, res) => {
  try {
    const { farmId } = req.params;
    
    const result = await pool.query(`
      SELECT * FROM agronomic_reports 
      WHERE farm_id = $1 
      ORDER BY created_at DESC
    `, [farmId]);

    res.json({
      success: true,
      reports: result.rows,
    });
  } catch (error) {
    console.error('❌ [REPORT] Erro:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// ============================================================================
// ROUTES - INFESTAÇÃO E HEATMAP
// ============================================================================

// Sincronizar dados de infestação
app.post('/api/infestation/sync', async (req, res) => {
  try {
    console.log('🐛 [INFESTATION] Sincronizando infestação...');
    
    const { monitoring_id, points } = req.body;

    if (points && points.length > 0) {
      for (const point of points) {
        await pool.query(`
          INSERT INTO infestation_data 
            (id, monitoring_id, organism_id, organism_name, severity, 
             quantity, latitude, longitude, date)
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
          ON CONFLICT (id) DO UPDATE SET
            severity = EXCLUDED.severity,
            quantity = EXCLUDED.quantity
        `, [
          point.id || `inf_${Date.now()}_${Math.random()}`,
          monitoring_id,
          point.organism_id,
          point.organism_name,
          point.severity,
          point.quantity,
          point.latitude,
          point.longitude,
          point.date
        ]);
      }
    }

    console.log('✅ [INFESTATION] Dados sincronizados');

    res.json({
      success: true,
      message: 'Dados de infestação sincronizados',
      points_count: points?.length || 0,
    });
  } catch (error) {
    console.error('❌ [INFESTATION] Erro:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// Buscar dados de infestação
app.get('/api/infestation/plot/:plotId', async (req, res) => {
  try {
    const { plotId } = req.params;
    const { startDate, endDate } = req.query;

    let query = `
      SELECT i.*, m.date as monitoring_date, m.crop_name
      FROM infestation_data i
      JOIN monitorings m ON i.monitoring_id = m.id
      WHERE m.plot_id = $1
    `;
    
    const params = [plotId];

    if (startDate) {
      query += ` AND m.date >= $2`;
      params.push(startDate);
    }
    
    if (endDate) {
      const dateParamNum = params.length + 1;
      query += ` AND m.date <= $${dateParamNum}`;
      params.push(endDate);
    }

    query += ` ORDER BY m.date DESC`;

    const result = await pool.query(query, params);

    res.json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    console.error('❌ [INFESTATION] Erro:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// Gerar heatmap
app.get('/api/heatmap/plot/:plotId', async (req, res) => {
  try {
    const { plotId } = req.params;
    
    const result = await pool.query(`
      SELECT 
        latitude,
        longitude,
        AVG(severity) as avg_severity,
        COUNT(*) as occurrence_count,
        array_agg(DISTINCT organism_name) as organisms
      FROM infestation_data i
      JOIN monitorings m ON i.monitoring_id = m.id
      WHERE m.plot_id = $1
      GROUP BY latitude, longitude
    `, [plotId]);

    // Processar heatmap
    const heatmapPoints = result.rows.map(row => {
      const avgSeverity = parseFloat(row.avg_severity);
      const intensity = avgSeverity / 100.0;
      
      let color, level;
      if (avgSeverity >= 75) {
        color = '#FF0000';
        level = 'critical';
      } else if (avgSeverity >= 50) {
        color = '#FF9800';
        level = 'high';
      } else if (avgSeverity >= 25) {
        color = '#FFEB3B';
        level = 'medium';
      } else {
        color = '#4CAF50';
        level = 'low';
      }

      return {
        latitude: parseFloat(row.latitude),
        longitude: parseFloat(row.longitude),
        intensity,
        severity: avgSeverity,
        color,
        level,
        occurrence_count: parseInt(row.occurrence_count),
        organisms: row.organisms,
      };
    });

    res.json({
      success: true,
      heatmap_points: heatmapPoints,
    });
  } catch (error) {
    console.error('❌ [HEATMAP] Erro:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// ============================================================================
// ROUTES - ESTATÍSTICAS E ANÁLISES
// ============================================================================

// Dashboard de estatísticas
app.get('/api/dashboard/farm/:farmId', async (req, res) => {
  try {
    const { farmId } = req.params;

    // Total de talhões
    const plotsResult = await pool.query(
      'SELECT COUNT(*) as total, SUM(area) as total_area FROM plots WHERE farm_id = $1',
      [farmId]
    );

    // Total de monitoramentos
    const monitoringsResult = await pool.query(
      'SELECT COUNT(*) as total FROM monitorings WHERE farm_id = $1',
      [farmId]
    );

    // Infestações por organismo
    const infestationsResult = await pool.query(`
      SELECT 
        organism_name,
        COUNT(*) as count,
        AVG(severity) as avg_severity
      FROM infestation_data i
      JOIN monitorings m ON i.monitoring_id = m.id
      WHERE m.farm_id = $1
      GROUP BY organism_name
      ORDER BY count DESC
      LIMIT 10
    `, [farmId]);

    res.json({
      success: true,
      statistics: {
        plots: {
          total: parseInt(plotsResult.rows[0].total),
          total_area: parseFloat(plotsResult.rows[0].total_area || 0),
        },
        monitorings: {
          total: parseInt(monitoringsResult.rows[0].total),
        },
        top_organisms: infestationsResult.rows,
      },
    });
  } catch (error) {
    console.error('❌ [DASHBOARD] Erro:', error);
    res.status(500).json({
      success: false,
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
  console.log(`🚀 Database: PostgreSQL no Render`);
  console.log(`🚀 Backend: Próprio (sem Base44)`);
  console.log('🚀 ========================================');
});

module.exports = app;
