import 'package:flutter/material.dart';
import '../utils/text_corruption_fix.dart';

/// Exemplo de como usar as correções de corrupção de texto
class TextCorruptionFixExample extends StatefulWidget {
  const TextCorruptionFixExample({Key? key}) : super(key: key);

  @override
  State<TextCorruptionFixExample> createState() => _TextCorruptionFixExampleState();
}

class _TextCorruptionFixExampleState extends State<TextCorruptionFixExample> 
    with TextCorruptionFixMixin {
  
  @override
  void onAndroid12AppResumed() {
    super.onAndroid12AppResumed();
    // Implementação específica se necessário
  }
  
  @override
  void refreshTextIfNeeded() {
    super.refreshTextIfNeeded();
    // Implementação específica se necessário
  }
  
  String _dynamicText = 'Texto inicial';
  int _counter = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextCorruptionFix.safeText('Exemplo de Correção de Texto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção de diagnóstico
            _buildDiagnosticSection(),
            
            const SizedBox(height: 24),
            
            // Exemplos de texto seguro
            _buildTextExamples(),
            
            const SizedBox(height: 24),
            
            // Exemplo de ListTile seguro
            _buildListTileExamples(),
            
            const SizedBox(height: 24),
            
            // Botões de teste
            _buildTestButtons(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDiagnosticSection() {
    final diagnosticInfo = TextCorruptionFix.getDiagnosticInfo();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextCorruptionFix.safeText(
              'Diagnóstico do Sistema',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...diagnosticInfo.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    TextCorruptionFix.safeText(
                      '${entry.key}: ',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    TextCorruptionFix.safeText(
                      '${entry.value}',
                      style: TextStyle(
                        color: entry.value.toString().contains('true') 
                            ? Colors.orange 
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextExamples() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextCorruptionFix.safeText(
              'Exemplos de Texto Seguro',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Texto normal
            TextCorruptionFix.safeText(
              'Este é um texto normal com fonte padrão.',
            ),
            const SizedBox(height: 8),
            
            // Texto com estilo
            TextCorruptionFix.safeText(
              'Este é um texto com estilo customizado.',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            
            // Texto dinâmico
            TextCorruptionFix.safeText(
              'Texto dinâmico: $_dynamicText (contador: $_counter)',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            
            // Usando extensão
            'Texto usando extensão toSafeText()'.toSafeText(
              style: const TextStyle(color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildListTileExamples() {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextCorruptionFix.safeText(
              'Exemplos de ListTile Seguro',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          TextCorruptionFix.safeListTile(
            leading: const Icon(Icons.info),
            title: TextCorruptionFix.safeText('Título do ListTile'),
            subtitle: TextCorruptionFix.safeText('Subtítulo com informações adicionais'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ListTile clicado!')),
              );
            },
          ),
          
          TextCorruptionFix.safeListTile(
            leading: const Icon(Icons.settings),
            title: TextCorruptionFix.safeText('Configurações'),
            subtitle: TextCorruptionFix.safeText('Gerenciar configurações do app'),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTestButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextCorruptionFix.safeText(
              'Botões de Teste',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _updateDynamicText,
                  child: TextCorruptionFix.safeText('Atualizar Texto'),
                ),
                
                ElevatedButton(
                  onPressed: _forceTextRefresh,
                  child: TextCorruptionFix.safeText('Forçar Refresh'),
                ),
                
                ElevatedButton(
                  onPressed: _simulateBackgroundReturn,
                  child: TextCorruptionFix.safeText('Simular Background'),
                ),
                
                ElevatedButton(
                  onPressed: _showDiagnosticDialog,
                  child: TextCorruptionFix.safeText('Ver Diagnóstico'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _updateDynamicText() {
    setState(() {
      _counter++;
      _dynamicText = 'Texto atualizado ${DateTime.now().millisecond}';
    });
  }
  
  void _forceTextRefresh() {
    TextCorruptionFix.forceTextRefresh();
    forceTextRefresh();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refresh de texto forçado!')),
    );
  }
  
  void _simulateBackgroundReturn() {
    // Simular o que acontece quando app volta do background
    TextCorruptionFix.onAppResumed();
    onAppResumed();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulação de retorno do background aplicada!')),
    );
  }
  
  void _showDiagnosticDialog() {
    final diagnosticInfo = TextCorruptionFix.getDiagnosticInfo();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: TextCorruptionFix.safeText('Diagnóstico Completo'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: diagnosticInfo.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextCorruptionFix.safeText(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: TextCorruptionFix.safeText('Fechar'),
          ),
        ],
      ),
    );
  }
}

/// Exemplo de uso no main.dart
class TextCorruptionFixExampleApp extends StatelessWidget {
  const TextCorruptionFixExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextCorruptionFixWrapper(
      child: MaterialApp(
        title: 'Exemplo de Correção de Texto',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          // Configurar fonte padrão se necessário
          textTheme: const TextTheme(),
        ),
        home: const TextCorruptionFixExample(),
      ),
    );
  }
}
