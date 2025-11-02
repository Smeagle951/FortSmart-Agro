import 'package:flutter/material.dart';
import 'package:fortsmart_agro/screens/farm/farm_profile_screen.dart';
import 'package:fortsmart_agro/utils/app_colors.dart';

/// EXEMPLO DE INTEGRAÇÃO DO PERFIL DE FAZENDA NO MENU PRINCIPAL
/// Este arquivo mostra diferentes formas de adicionar o Perfil de Fazenda
/// ao menu do aplicativo.

// ============================================================================
// EXEMPLO 1: DRAWER/MENU LATERAL
// ============================================================================

class ExampleDrawer extends StatelessWidget {
  const ExampleDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header do Drawer
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.agriculture, size: 35, color: Colors.green),
                ),
                SizedBox(height: 10),
                Text(
                  'FortSmart Agro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Perfil da Fazenda - ITEM PRINCIPAL
          ListTile(
            leading: Icon(Icons.agriculture, color: AppColors.primary),
            title: const Text(
              'Perfil da Fazenda',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text('Gerenciar dados da fazenda'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pop(context); // Fecha o drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FarmProfileScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // Outros itens do menu...
          ListTile(
            leading: const Icon(Icons.grid_view),
            title: const Text('Talhões'),
            onTap: () {
              Navigator.pop(context);
              // Navegar para tela de talhões
            },
          ),

          ListTile(
            leading: const Icon(Icons.monitor_heart),
            title: const Text('Monitoramento'),
            onTap: () {
              Navigator.pop(context);
              // Navegar para tela de monitoramento
            },
          ),

          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('Relatórios'),
            onTap: () {
              Navigator.pop(context);
              // Navegar para tela de relatórios
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {
              Navigator.pop(context);
              // Navegar para configurações
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXEMPLO 2: CARD NA HOME/DASHBOARD
// ============================================================================

class FarmProfileCard extends StatelessWidget {
  const FarmProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FarmProfileScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.agriculture,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perfil da Fazenda',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Gerenciar dados e sincronizar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              const SizedBox(height: 16),
              // Estatísticas rápidas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickStat('123,4 ha', 'Área Total'),
                  _buildQuickStat('12', 'Talhões'),
                  _buildQuickStat('3', 'Culturas'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// EXEMPLO 3: FLOATING ACTION BUTTON NA HOME
// ============================================================================

class HomeScreenWithFAB extends StatelessWidget {
  const HomeScreenWithFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FortSmart Agro'),
        backgroundColor: AppColors.primary,
      ),
      body: const Center(
        child: Text('Conteúdo da Home'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FarmProfileScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.agriculture),
        label: const Text('Minha Fazenda'),
      ),
    );
  }
}

// ============================================================================
// EXEMPLO 4: GRID DE OPÇÕES NA HOME
// ============================================================================

class HomeGridOptions extends StatelessWidget {
  const HomeGridOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        // Perfil da Fazenda
        _buildGridOption(
          context,
          'Perfil da\nFazenda',
          Icons.agriculture,
          Colors.green,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FarmProfileScreen(),
              ),
            );
          },
        ),

        // Talhões
        _buildGridOption(
          context,
          'Talhões',
          Icons.grid_view,
          Colors.blue,
          () {
            // Navegar para talhões
          },
        ),

        // Monitoramento
        _buildGridOption(
          context,
          'Monitoramento',
          Icons.monitor_heart,
          Colors.orange,
          () {
            // Navegar para monitoramento
          },
        ),

        // Relatórios
        _buildGridOption(
          context,
          'Relatórios',
          Icons.assessment,
          Colors.purple,
          () {
            // Navegar para relatórios
          },
        ),
      ],
    );
  }

  Widget _buildGridOption(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EXEMPLO 5: BOTTOM NAVIGATION BAR
// ============================================================================

class MainScreenWithBottomNav extends StatefulWidget {
  const MainScreenWithBottomNav({super.key});

  @override
  State<MainScreenWithBottomNav> createState() => _MainScreenWithBottomNavState();
}

class _MainScreenWithBottomNavState extends State<MainScreenWithBottomNav> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const Center(child: Text('Home')),
    const Center(child: Text('Talhões')),
    const FarmProfileScreen(), // Perfil da Fazenda
    const Center(child: Text('Monitoramento')),
    const Center(child: Text('Mais')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Talhões',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture),
            label: 'Fazenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart),
            label: 'Monitor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'Mais',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXEMPLO 6: APPBAR COM BOTÃO DE ACESSO RÁPIDO
// ============================================================================

class HomeScreenWithAppBarButton extends StatelessWidget {
  const HomeScreenWithAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FortSmart Agro'),
        backgroundColor: AppColors.primary,
        actions: [
          // Botão de acesso rápido ao perfil da fazenda
          IconButton(
            icon: const Icon(Icons.agriculture),
            tooltip: 'Perfil da Fazenda',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FarmProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Notificações
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Conteúdo da Home'),
      ),
    );
  }
}

// ============================================================================
// EXEMPLO 7: LISTA DE AÇÕES RÁPIDAS
// ============================================================================

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ações Rápidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickAction(
              context,
              'Ver Perfil da Fazenda',
              Icons.agriculture,
              Colors.green,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FarmProfileScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 24),
            _buildQuickAction(
              context,
              'Adicionar Talhão',
              Icons.add_location,
              Colors.blue,
              () {
                // Adicionar talhão
              },
            ),
            const Divider(height: 24),
            _buildQuickAction(
              context,
              'Novo Monitoramento',
              Icons.add_chart,
              Colors.orange,
              () {
                // Novo monitoramento
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXEMPLO DE USO COMPLETO
// ============================================================================

class ExampleMainScreen extends StatelessWidget {
  const ExampleMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FortSmart Agro'),
        backgroundColor: AppColors.primary,
      ),
      drawer: const ExampleDrawer(), // Menu lateral com Perfil da Fazenda
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Card do Perfil da Fazenda
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FarmProfileCard(),
            ),
            const SizedBox(height: 16),
            // Ações rápidas
            const QuickActionsCard(),
            const SizedBox(height: 16),
            // Grid de opções
            const SizedBox(
              height: 400,
              child: HomeGridOptions(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FarmProfileScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.agriculture),
      ),
    );
  }
}

// ============================================================================
// INSTRUÇÕES DE USO
// ============================================================================

/*

COMO USAR ESTE ARQUIVO:

1. COPIAR O EXEMPLO DESEJADO
   Escolha um dos 7 exemplos acima e copie para seu arquivo de tela principal.

2. AJUSTAR IMPORTS
   Certifique-se de que os imports estão corretos:
   - import 'package:fortsmart_agro/screens/farm/farm_profile_screen.dart';
   - import 'package:fortsmart_agro/utils/app_colors.dart';

3. INTEGRAR NA SUA TELA
   Cole o código escolhido na sua tela principal (home, dashboard, etc.)

4. TESTAR
   Execute o app e teste a navegação para o Perfil da Fazenda.

EXEMPLOS RECOMENDADOS POR CASO:

- Menu Lateral: Exemplo 1 (ExampleDrawer)
- Dashboard: Exemplo 2 (FarmProfileCard)
- App com múltiplas seções: Exemplo 5 (BottomNavigationBar)
- Home simples: Exemplo 3 (FAB) ou Exemplo 7 (QuickActionsCard)
- Grid de funcionalidades: Exemplo 4 (HomeGridOptions)

PERSONALIZAÇÃO:

Você pode combinar múltiplos exemplos. Por exemplo:
- Drawer (Exemplo 1) + Card na Home (Exemplo 2)
- BottomNavigationBar (Exemplo 5) + FAB (Exemplo 3)

DÚVIDAS:

Consulte a documentação em INTEGRACAO_PERFIL_FAZENDA.md

*/

