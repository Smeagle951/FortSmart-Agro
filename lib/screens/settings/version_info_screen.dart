import 'package:flutter/material.dart';
// import 'premium_theme.dart'; // Removido
import 'package:fortsmart_agro/widgets/app_drawer.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Tela que exibe informações sobre a versão do aplicativo
class VersionInfoScreen extends StatefulWidget {
  const VersionInfoScreen({Key? key}) : super(key: key);

  @override
  _VersionInfoScreenState createState() => _VersionInfoScreenState();
}

class _VersionInfoScreenState extends State<VersionInfoScreen> {
  String _version = '';
  String _buildNumber = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _version = '3.0.0';  // Versão padrão caso não consiga obter via package_info
        _buildNumber = '30';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informações da Versão'),
        // backgroundColor: Colors.blue.shade900, // backgroundColor não é suportado em flutter_map 5.0.0
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildVersionInfo(),
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade900,
            Colors.black,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.agriculture,
                    size: 80,
                    color: Colors.green,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'FortSmart Agro',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Versão $_version (build $_buildNumber)',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoCard(
              title: '🚀 Novidades da Versão 3.0.0 - IA Agronômica',
              items: [
                '🧠 Módulo de IA Agronômica completo',
                '🔍 Diagnóstico inteligente por sintomas e imagens',
                '📚 Catálogo de organismos com IA integrada',
                '🔥 Heatmap inteligente com processamento de IA',
                '📊 Relatórios agronômicos com validação de dados',
                '🎯 Sistema de confiabilidade e qualidade de dados',
                '⚡ Integração completa entre Monitoramento e Mapa de Infestação',
                '🛠️ Otimizações de performance e estabilidade',
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: '🎯 Funcionalidades Avançadas',
              items: [
                '📱 Dashboard com botão de IA Agronômica',
                '🗺️ Mapa de Infestação com processamento de IA',
                '🔬 Análise de confiabilidade de dados em tempo real',
                '📈 Histórico de confiabilidade e benchmarking',
                '🚨 Alertas automáticos baseados em qualidade de dados',
                '🎨 Interface moderna e responsiva',
                '⚙️ Sistema de validação profissional de dados',
                '🔗 Integração total entre todos os módulos',
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: '💡 Diferenciais Competitivos',
              items: [
                '🎯 Único sistema com IA integrada ao monitoramento',
                '📊 Relatórios com indicadores de confiabilidade',
                '🔥 Heatmap inteligente com cores baseadas em confiança',
                '🧠 Diagnóstico automático por sintomas e imagens',
                '📱 Interface profissional superior aos concorrentes',
                '⚡ Performance otimizada para campo',
                '🔒 Dados 100% reais, sem simulações',
                '🌾 Foco total na precisão agronômica',
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '© ${DateTime.now().year} FortSmart Agro - Versão 3.0.0',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 32), // Espaço extra no final
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<String> items}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.greenAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

