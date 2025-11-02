/// 🌱 Tela de Configurações de Germinação
/// 
/// Configurações elegantes para testes de germinação
/// seguindo padrão visual FortSmart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../../../../../widgets/app_bar_widget.dart';

class GerminationTestSettingsScreen extends StatefulWidget {
  const GerminationTestSettingsScreen({super.key});

  @override
  State<GerminationTestSettingsScreen> createState() => _GerminationTestSettingsScreenState();
}

class _GerminationTestSettingsScreenState extends State<GerminationTestSettingsScreen> {
  // Variáveis de estado para configurações
  double _approvalThreshold = 80.0;
  double _alertThreshold = 70.0;
  double _diseaseThreshold = 10.0;
  bool _autoAlerts = true;
  bool _autoApproval = false;
  int _defaultSeedCount = 100;
  int _vigorDays = 5;
  String _defaultTemperature = '25°C';
  String _defaultHumidity = '60%';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  /// Carrega configurações salvas
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _approvalThreshold = prefs.getDouble('germination_approval_threshold') ?? 80.0;
        _alertThreshold = prefs.getDouble('germination_alert_threshold') ?? 70.0;
        _diseaseThreshold = prefs.getDouble('germination_disease_threshold') ?? 10.0;
        _autoAlerts = prefs.getBool('germination_auto_alerts') ?? true;
        _autoApproval = prefs.getBool('germination_auto_approval') ?? false;
        _defaultSeedCount = prefs.getInt('germination_default_seed_count') ?? 100;
        _vigorDays = prefs.getInt('germination_vigor_days') ?? 5;
        _defaultTemperature = prefs.getString('germination_default_temperature') ?? '25°C';
        _defaultHumidity = prefs.getString('germination_default_humidity') ?? '60%';
      });
    } catch (e) {
      // Usar valores padrão em caso de erro
      print('Erro ao carregar configurações: $e');
    }
  }
  
  /// Salva configurações
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setDouble('germination_approval_threshold', _approvalThreshold);
      await prefs.setDouble('germination_alert_threshold', _alertThreshold);
      await prefs.setDouble('germination_disease_threshold', _diseaseThreshold);
      await prefs.setBool('germination_auto_alerts', _autoAlerts);
      await prefs.setBool('germination_auto_approval', _autoApproval);
      await prefs.setInt('germination_default_seed_count', _defaultSeedCount);
      await prefs.setInt('germination_vigor_days', _vigorDays);
      await prefs.setString('germination_default_temperature', _defaultTemperature);
      await prefs.setString('germination_default_humidity', _defaultHumidity);
      
      // Mostrar feedback visual
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas com sucesso!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar configurações: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSettingsSections(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBarWidget(
      title: 'Configurações',
      showBackButton: true,
      backgroundColor: FortSmartTheme.primaryColor,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FortSmartTheme.primaryColor,
            FortSmartTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FortSmartTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configurações de Germinação',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Personalize os parâmetros dos testes',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSections() {
    return Column(
      children: [
        _buildThresholdsSection(),
        const SizedBox(height: 16),
        _buildAutomationSection(),
        const SizedBox(height: 16),
        _buildDefaultsSection(),
      ],
    );
  }

  Widget _buildThresholdsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: FortSmartTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Limites de Aprovação',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSliderSetting(
              'Limite de Aprovação',
              'Percentual mínimo para aprovação',
              _approvalThreshold,
              (value) {
                setState(() {
                  _approvalThreshold = value;
                });
                _saveSettings();
              },
            ),
            const SizedBox(height: 16),
            _buildSliderSetting(
              'Limite de Alerta',
              'Percentual para gerar alertas',
              _alertThreshold,
              (value) {
                setState(() {
                  _alertThreshold = value;
                });
                _saveSettings();
              },
            ),
            const SizedBox(height: 16),
            _buildSliderSetting(
              'Limite de Doenças',
              'Percentual máximo de contaminação',
              _diseaseThreshold,
              (value) {
                setState(() {
                  _diseaseThreshold = value;
                });
                _saveSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomationSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: FortSmartTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Automação',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSwitchSetting(
              'Alertas Automáticos',
              'Gerar alertas quando germinação for baixa',
              _autoAlerts,
              (value) {
                setState(() {
                  _autoAlerts = value;
                });
                _saveSettings();
              },
            ),
            const SizedBox(height: 16),
            _buildSwitchSetting(
              'Aprovação Automática',
              'Aprovar automaticamente lotes com boa germinação',
              _autoApproval,
              (value) {
                setState(() {
                  _autoApproval = value;
                });
                _saveSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_applications,
                  color: FortSmartTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Configurações Padrão',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNumberSetting(
              'Quantidade de Sementes',
              'Número padrão de sementes por teste',
              _defaultSeedCount,
              (value) {
                setState(() {
                  _defaultSeedCount = value;
                });
                _saveSettings();
              },
            ),
            const SizedBox(height: 16),
            _buildNumberSetting(
              'Dias para Vigor',
              'Número de dias para cálculo de vigor',
              _vigorDays,
              (value) {
                setState(() {
                  _vigorDays = value;
                });
                _saveSettings();
              },
            ),
            const SizedBox(height: 16),
            _buildTextSetting(
              'Temperatura Padrão',
              'Temperatura para testes',
              _defaultTemperature,
              (value) {
                setState(() {
                  _defaultTemperature = value;
                });
                _saveSettings();
              },
            ),
            const SizedBox(height: 16),
            _buildTextSetting(
              'Umidade Padrão',
              'Umidade relativa para testes',
              _defaultHumidity,
              (value) {
                setState(() {
                  _defaultHumidity = value;
                });
                _saveSettings();
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSliderSetting(
    String title,
    String subtitle,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: 0,
                max: 100,
                divisions: 100,
                activeColor: FortSmartTheme.primaryColor,
                onChanged: onChanged,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: FortSmartTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildNumberSetting(
    String title,
    String subtitle,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: value.toString()),
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  if (intValue != null) {
                    onChanged(intValue);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextSetting(
    String title,
    String subtitle,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          controller: TextEditingController(text: value),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
