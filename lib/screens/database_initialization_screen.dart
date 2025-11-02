import 'package:flutter/material.dart';
import '../database/database_initializer.dart';
import '../database/database_helper.dart';
import '../widgets/safe_text.dart';
import '../widgets/safe_title.dart';
import '../utils/text_encoding_helper.dart';
import '../database/database_migration.dart';
import 'dart:async';
import '../utils/database_text_encoding_fixer.dart';
import '../screens/text_encoding_fix_screen.dart';
import '../widgets/text_encoding_error_widget.dart';
import '../database/database_manager.dart';

/// Tela de inicialização do banco de dados
/// Esta tela é exibida durante a inicialização do aplicativo
/// para garantir que todas as tabelas necessárias estejam criadas
class DatabaseInitializationScreen extends StatefulWidget {
  final VoidCallback onInitializationComplete;

  const DatabaseInitializationScreen({
    Key? key,
    required this.onInitializationComplete,
  }) : super(key: key);

  @override
  _DatabaseInitializationScreenState createState() => _DatabaseInitializationScreenState();
}

class _DatabaseInitializationScreenState extends State<DatabaseInitializationScreen> {
  final DatabaseInitializer _initializer = DatabaseInitializer();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final DatabaseMigration _migration = DatabaseMigration();
  final DatabaseManager _databaseManager = DatabaseManager();
  
  bool _isInitializing = true;
  bool _initializationSuccess = false;
  bool _hasEncodingIssues = false;
  String _statusMessage = 'Inicializando banco de dados...';
  double _progress = 0.0;
  int _retryCount = 0;
  final int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    setState(() {
      _isInitializing = true;
      _statusMessage = 'Inicializando banco de dados...';
      _progress = 0.0;
    });

    try {
      // Primeiro, tenta inicializar com o DatabaseManager (mais robusto)
      setState(() {
        _statusMessage = 'Verificando integridade do banco de dados...';
        _progress = 0.2;
      });
      
      final managerSuccess = await _databaseManager.initialize();
      
      if (!managerSuccess && _retryCount < _maxRetries) {
        _retryCount++;
        setState(() {
          _statusMessage = 'Tentando recuperar banco de dados (tentativa $_retryCount de $_maxRetries)...';
          _progress = 0.3;
        });
        
        // Aguarda um momento antes de tentar novamente
        await Future.delayed(const Duration(milliseconds: 500));
        return _initializeDatabase();
      }
      
      // Continua com a inicialização normal
      setState(() {
        _statusMessage = 'Configurando tabelas e índices...';
        _progress = 0.4;
      });
      
      final initializer = DatabaseInitializer();
      
      final success = await initializer.initializeDatabase(
        onProgress: (message, progress) {
          setState(() {
            _statusMessage = message;
            _progress = 0.4 + (progress * 0.5); // Escala de 0.4 a 0.9
          });
        },
      );

      // Verifica se há problemas de codificação após a inicialização
      if (success) {
        setState(() {
          _statusMessage = 'Verificando codificação de texto...';
          _progress = 0.9;
        });
        
        final db = await DatabaseHelper().database;
        final hasIssues = await DatabaseTextEncodingFixer.databaseHasEncodingIssues(db);
        
        setState(() {
          _isInitializing = false;
          _initializationSuccess = success;
          _hasEncodingIssues = hasIssues;
          _progress = 1.0;
          _statusMessage = success 
              ? (hasIssues 
                  ? 'Inicialização concluída com sucesso, mas foram detectados problemas de codificação de texto.' 
                  : 'Inicialização concluída com sucesso!')
              : 'Falha na inicialização do banco de dados.';
        });
        
        // Notifica que a inicialização foi concluída
        if (success) {
          // Aguarda um momento para mostrar a mensagem
          if (!hasIssues) {
            Future.delayed(const Duration(seconds: 1), () {
              widget.onInitializationComplete();
            });
          }
        }
      } else {
        setState(() {
          _isInitializing = false;
          _initializationSuccess = false;
          _statusMessage = 'Falha na inicialização do banco de dados.';
        });
      }
    } catch (e) {
      debugPrint('Erro durante inicialização do banco de dados: $e');
      
      if (_retryCount < _maxRetries) {
        _retryCount++;
        setState(() {
          _statusMessage = 'Erro detectado. Tentando recuperar (tentativa $_retryCount de $_maxRetries)...';
          _progress = 0.3;
        });
        
        // Aguarda um momento antes de tentar novamente
        await Future.delayed(const Duration(seconds: 1));
        return _initializeDatabase();
      } else {
        setState(() {
          _isInitializing = false;
          _initializationSuccess = false;
          _statusMessage = 'Erro: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SafeTitle(
                  'Inicialização do Banco de Dados',
                ),
                const SizedBox(height: 40),
                if (_isInitializing) ...[
                  CircularProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    color: const Color(0xFF2A4F3D),
                  ),
                  const SizedBox(height: 24),
                  SafeText(
                    _statusMessage,
                  ),
                  if (_progress > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ] else if (_hasEncodingIssues) ...[
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 60,
                  ),
                  const SizedBox(height: 24),
                  const SafeText(
                    'Problemas de codificação de texto detectados',
                  ),
                  const SizedBox(height: 16),
                  const TextEncodingErrorWidget(
                    originalText: 'Texto com problemas de codificação',
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TextEncodingFixScreen(
                            onComplete: () {
                              setState(() {
                                _hasEncodingIssues = false;
                              });
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Corrigir Agora'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      widget.onInitializationComplete();
                    },
                    child: const Text('Continuar sem corrigir'),
                  ),
                ] else if (_initializationSuccess) ...[
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 60,
                  ),
                  const SizedBox(height: 24),
                  SafeText(
                    'Inicialização concluída com sucesso!',
                  ),
                ] else ...[
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 24),
                  SafeText(
                    'Falha na inicialização do banco de dados.',
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _initializeDatabase,
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
