import 'package:flutter/material.dart';
import 'constants/app_colors.dart';

/// Teste simples do módulo de Tratamento de Sementes
/// Sem dependências de banco de dados - apenas para verificar compilação
void main() {
  runApp(const TratamentoSementesSimpleTestApp());
}

class TratamentoSementesSimpleTestApp extends StatelessWidget {
  const TratamentoSementesSimpleTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teste Simples - Tratamento de Sementes',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const TratamentoSementesSimpleTestScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TratamentoSementesSimpleTestScreen extends StatefulWidget {
  const TratamentoSementesSimpleTestScreen({Key? key}) : super(key: key);

  @override
  State<TratamentoSementesSimpleTestScreen> createState() => _TratamentoSementesSimpleTestScreenState();
}

class _TratamentoSementesSimpleTestScreenState extends State<TratamentoSementesSimpleTestScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _DosesScreen(),
    const _CalculatorScreen(),
    const _HistoryScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.list_alt),
      label: 'Doses',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.calculate),
      label: 'Calculadora',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.history),
      label: 'Histórico',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tratamento de Sementes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: _navItems,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _navigateToDoseEditor,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _navigateToDoseEditor() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Editor de dose será implementado em breve'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tratamento de Sementes'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Funcionalidades:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Cadastro de doses de tratamento'),
              Text('• Calculadora rápida e profissional'),
              Text('• Controle de compatibilidade'),
              Text('• Integração com estoque'),
              Text('• Histórico de cálculos'),
              Text('• Relatórios e exportação'),
              SizedBox(height: 16),
              Text(
                'Modos de Cálculo:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Rápido: Por kg informado'),
              Text('• Profissional: PMS + Germinação + População'),
              SizedBox(height: 16),
              Text(
                'Versão: 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

// Telas simuladas para teste
class _DosesScreen extends StatelessWidget {
  const _DosesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.list_alt,
            size: 64,
            color: Colors.green,
          ),
          SizedBox(height: 16),
          Text(
            'Lista de Doses',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tela de doses será implementada aqui',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculatorScreen extends StatelessWidget {
  const _CalculatorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calculate,
            size: 64,
            color: Colors.blue,
          ),
          SizedBox(height: 16),
          Text(
            'Calculadora',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Calculadora será implementada aqui',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryScreen extends StatelessWidget {
  const _HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.orange,
          ),
          SizedBox(height: 16),
          Text(
            'Histórico',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Histórico será implementado aqui',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
