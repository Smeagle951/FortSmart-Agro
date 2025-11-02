import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tipos de animação disponíveis para visualização do clima
enum AnimationType {
  lottie,
  rive,
  flutterAnimate,
  customPainter,
  hybrid,
  auto
}

/// Classe para gerenciar as configurações de animação do clima
class WeatherAnimationConfig {
  // Tipo de animação selecionado
  AnimationType _animationType = AnimationType.auto;
  
  // Modo de alto desempenho (animações mais simples para dispositivos com menos recursos)
  bool _highPerformanceMode = false;
  
  // Chaves para armazenamento nas preferências
  static const String _animationTypeKey = 'weather_animation_type';
  static const String _highPerformanceModeKey = 'weather_high_performance_mode';
  
  /// Construtor que carrega as configurações salvas
  WeatherAnimationConfig() {
    _loadConfig();
  }
  
  /// Obtém o tipo de animação atual
  AnimationType get animationType => _animationType;
  
  /// Define o tipo de animação
  set animationType(AnimationType type) {
    _animationType = type;
    _saveConfig();
  }
  
  /// Verifica se o modo de alto desempenho está ativado
  bool get highPerformanceMode => _highPerformanceMode;
  
  /// Define o modo de alto desempenho
  set highPerformanceMode(bool enabled) {
    _highPerformanceMode = enabled;
    _saveConfig();
  }
  
  /// Carrega as configurações salvas
  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final animationTypeIndex = prefs.getInt(_animationTypeKey);
      if (animationTypeIndex != null && animationTypeIndex < AnimationType.values.length) {
        _animationType = AnimationType.values[animationTypeIndex];
      }
      
      _highPerformanceMode = prefs.getBool(_highPerformanceModeKey) ?? false;
    } catch (e) {
      debugPrint('Erro ao carregar configurações de animação: $e');
    }
  }
  
  /// Salva as configurações atuais
  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setInt(_animationTypeKey, _animationType.index);
      await prefs.setBool(_highPerformanceModeKey, _highPerformanceMode);
    } catch (e) {
      debugPrint('Erro ao salvar configurações de animação: $e');
    }
  }
  
  /// Método estático para carregar configurações
  static Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Apenas verifica se as preferências estão disponíveis
      await prefs.reload();
    } catch (e) {
      debugPrint('Erro ao inicializar configurações de animação: $e');
    }
  }
  
  /// Retorna uma string representando o tipo de animação atual
  String getAnimationTypeString() {
    switch (_animationType) {
      case AnimationType.lottie:
        return 'Lottie';
      case AnimationType.rive:
        return 'Rive';
      case AnimationType.flutterAnimate:
        return 'Flutter Animate';
      case AnimationType.customPainter:
        return 'CustomPainter';
      case AnimationType.hybrid:
        return 'Híbrido';
      case AnimationType.auto:
        return 'Automático';
      default:
        return 'Desconhecido';
    }
  }
  
  /// Retorna o tipo de animação a ser usado com base nas configurações
  AnimationType getEffectiveAnimationType(String condition) {
    // Se estiver no modo de alto desempenho, usar Lottie que é mais leve
    if (highPerformanceMode) {
      return AnimationType.lottie;
    }
    
    // Se o tipo padrão for auto, fazer a seleção automática
    if (animationType == AnimationType.auto) {
      // Lógica para escolher automaticamente o melhor tipo de animação
      condition = condition.toLowerCase();
      
      if (condition.contains('chuva') || 
          condition.contains('tempestade') ||
          condition.contains('trovoada')) {
        // Para chuva e tempestade, CustomPainter é melhor para efeitos de física
        return AnimationType.customPainter;
      } else if (condition.contains('sol') || 
                condition.contains('limpo') ||
                condition.contains('claro')) {
        // Para sol e céu limpo, Lottie é bom para efeitos de brilho
        return AnimationType.lottie;
      } else if (condition.contains('neve')) {
        // Para neve, Flutter Animate é ótimo para efeitos de queda suave
        return AnimationType.flutterAnimate;
      } else {
        // Para outras condições, Rive pode ser uma boa opção
        return AnimationType.rive;
      }
    }
    
    // Caso contrário, usar o tipo configurado pelo usuário
    return animationType;
  }
}

/// Tela para configurar as animações climáticas
class WeatherAnimationConfigScreen extends StatefulWidget {
  final WeatherAnimationConfig? config;
  
  const WeatherAnimationConfigScreen({
    Key? key,
    this.config,
  }) : super(key: key);

  @override
  State<WeatherAnimationConfigScreen> createState() => _WeatherAnimationConfigScreenState();
}

class _WeatherAnimationConfigScreenState extends State<WeatherAnimationConfigScreen> {
  late WeatherAnimationConfig _config;
  
  @override
  void initState() {
    super.initState();
    _config = widget.config ?? WeatherAnimationConfig();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Animação'),
        backgroundColor: const Color(0xFF1E3B5A),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E3B5A),
              const Color(0xFF1E3B5A).withOpacity(0.8),
              const Color(0xFF0D2137),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tipo de Animação',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              _buildAnimationTypeSelector(),
              const SizedBox(height: 24),
              _buildPerformanceModeToggle(),
              const SizedBox(height: 24),
              _buildInfoCard(),
              const Spacer(),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A4F3D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnimationTypeSelector() {
    return Column(
      children: [
        RadioListTile<AnimationType>(
          title: const Text(
            'Automático',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Seleciona o melhor tipo de animação com base na condição climática',
            style: TextStyle(color: Colors.white70),
          ),
          value: AnimationType.auto,
          groupValue: _config.animationType,
          activeColor: const Color(0xFF2A4F3D),
          onChanged: _updateAnimationType,
        ),
        RadioListTile<AnimationType>(
          title: const Text(
            'Lottie',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Animações vetoriais leves e escaláveis',
            style: TextStyle(color: Colors.white70),
          ),
          value: AnimationType.lottie,
          groupValue: _config.animationType,
          activeColor: const Color(0xFF2A4F3D),
          onChanged: _updateAnimationType,
        ),
        RadioListTile<AnimationType>(
          title: const Text(
            'Rive',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Animações interativas e responsivas',
            style: TextStyle(color: Colors.white70),
          ),
          value: AnimationType.rive,
          groupValue: _config.animationType,
          activeColor: const Color(0xFF2A4F3D),
          onChanged: _updateAnimationType,
        ),
        RadioListTile<AnimationType>(
          title: const Text(
            'Flutter Animate',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Animações fluidas e fáceis de personalizar',
            style: TextStyle(color: Colors.white70),
          ),
          value: AnimationType.flutterAnimate,
          groupValue: _config.animationType,
          activeColor: const Color(0xFF2A4F3D),
          onChanged: _updateAnimationType,
        ),
        RadioListTile<AnimationType>(
          title: const Text(
            'CustomPainter',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Animações personalizadas com física realista',
            style: TextStyle(color: Colors.white70),
          ),
          value: AnimationType.customPainter,
          groupValue: _config.animationType,
          activeColor: const Color(0xFF2A4F3D),
          onChanged: _updateAnimationType,
        ),
        RadioListTile<AnimationType>(
          title: const Text(
            'Híbrido',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Combinação de Lottie com efeitos personalizados',
            style: TextStyle(color: Colors.white70),
          ),
          value: AnimationType.hybrid,
          groupValue: _config.animationType,
          activeColor: const Color(0xFF2A4F3D),
          onChanged: _updateAnimationType,
        ),
      ],
    );
  }
  
  Widget _buildPerformanceModeToggle() {
    return SwitchListTile(
      title: const Text(
        'Modo de Alto Desempenho',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: const Text(
        'Usa animações mais leves para economizar bateria e melhorar o desempenho',
        style: TextStyle(color: Colors.white70),
      ),
      value: _config.highPerformanceMode,
      activeColor: const Color(0xFF2A4F3D),
      onChanged: (value) {
        setState(() {
          _config.highPerformanceMode = value;
        });
      },
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      color: Colors.white.withOpacity(0.1),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Sobre as Animações',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Diferentes tipos de animação podem ter impacto no desempenho do aplicativo. '
              'Se você notar lentidão, experimente mudar para um tipo de animação mais leve '
              'ou ative o modo de alto desempenho.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
  
  void _updateAnimationType(AnimationType? type) {
    if (type != null) {
      setState(() {
        _config.animationType = type;
      });
    }
  }
}
