import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget para exibir um tutorial sobre o uso da tela de talhões
class PlotTutorial extends StatefulWidget {
  final VoidCallback onClose;
  
  const PlotTutorial({
    Key? key,
    required this.onClose,
  }) : super(key: key);
  
  /// Método estático para verificar se o tutorial deve ser exibido
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('plot_tutorial_shown') ?? false);
  }
  
  /// Método estático para marcar o tutorial como exibido
  static Future<void> markAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('plot_tutorial_shown', true);
  }
  
  @override
  _PlotTutorialState createState() => _PlotTutorialState();
}

class _PlotTutorialState extends State<PlotTutorial> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<TutorialStep> _steps = [
    TutorialStep(
      title: 'Bem-vindo à Tela de Talhões',
      description: 'Aqui você pode visualizar, criar, editar e excluir talhões da sua propriedade.',
      icon: Icons.map,
      color: const Color(0xFF4CAF50),
    ),
    TutorialStep(
      title: 'Menu Lateral',
      description: 'Deslize da esquerda para a direita para abrir o menu lateral e ver a lista de talhões.',
      icon: Icons.menu,
      color: const Color(0xFF2196F3),
    ),
    TutorialStep(
      title: 'Criação de Talhões',
      description: 'Toque no botão flutuante (+) para criar um novo talhão. Você pode desenhar manualmente, usar GPS ou importar um arquivo KML.',
      icon: Icons.add_circle,
      color: const Color(0xFF4CAF50),
    ),
    TutorialStep(
      title: 'Desenho Manual',
      description: 'No modo desenho, toque no mapa para adicionar pontos e formar o polígono do talhão.',
      icon: Icons.edit,
      color: const Color(0xFF2196F3),
    ),
    TutorialStep(
      title: 'Modo GPS',
      description: 'No modo GPS, o aplicativo adicionará pontos automaticamente enquanto você se move pelo talhão.',
      icon: Icons.gps_fixed,
      color: const Color(0xFF2196F3),
    ),
    TutorialStep(
      title: 'Importação KML',
      description: 'Você pode importar arquivos KML do Google Earth para criar talhões automaticamente.',
      icon: Icons.file_upload,
      color: const Color(0xFF2196F3),
    ),
    TutorialStep(
      title: 'Edição e Exclusão',
      description: 'Selecione um talhão para ver suas informações. Você pode editá-lo ou excluí-lo usando os botões disponíveis.',
      icon: Icons.edit_location,
      color: const Color(0xFF4CAF50),
    ),
    TutorialStep(
      title: 'Pronto para Começar!',
      description: 'Agora você está pronto para gerenciar seus talhões. Toque em "Concluir" para começar.',
      icon: Icons.check_circle,
      color: const Color(0xFF4CAF50),
    ),
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishTutorial();
    }
  }
  
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  Future<void> _finishTutorial() async {
    await PlotTutorial.markAsShown();
    widget.onClose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabeçalho
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.school,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tutorial: Talhões',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _finishTutorial,
                        tooltip: 'Fechar',
                      ),
                    ],
                  ),
                ),
                
                // Conteúdo
                SizedBox(
                  height: 350,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _steps.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Ícone
                            Icon(
                              step.icon,
                              size: 80,
                              color: step.color,
                            ),
                            const SizedBox(height: 24),
                            
                            // Título
                            Text(
                              step.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            
                            // Descrição
                            Text(
                              step.description,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Indicadores de página
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? const Color(0xFF4CAF50)
                              : Colors.grey.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Botões de navegação
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botão de voltar
                      TextButton(
                        onPressed: _currentPage > 0 ? _previousPage : null,
                        child: Text(
                          'Voltar',
                          style: TextStyle(
                            color: _currentPage > 0
                                ? const Color(0xFF4CAF50)
                                : Colors.grey,
                          ),
                        ),
                      ),
                      
                      // Botão de avançar/concluir
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          // backgroundColor: const Color(0xFF4CAF50), // backgroundColor não é suportado em flutter_map 5.0.0
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _currentPage < _steps.length - 1
                              ? 'Próximo'
                              : 'Concluir',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Classe para representar um passo do tutorial
class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  
  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
