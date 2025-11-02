# Rotas do Módulo de Subáreas

Este documento explica como usar as rotas do módulo de subáreas no FortSmart Agro.

## Rotas Disponíveis

### 1. Detalhes do Talhão
- **Rota**: `/talhao/detalhes`
- **Classe**: `TalhaoDetalhesScreen`
- **Argumentos**: `{'experimento': Experimento}`

```dart
// Navegação usando SubareaRoutes
SubareaRoutes.navigateToTalhaoDetalhes(context, experimento);

// Navegação direta
Navigator.pushNamed(
  context,
  '/talhao/detalhes',
  arguments: {'experimento': experimento},
);
```

### 2. Detalhes da Subárea
- **Rota**: `/subarea/detalhes`
- **Classe**: `SubareaDetalhesScreen`
- **Argumentos**: `{'subarea': Subarea}`

```dart
// Navegação usando SubareaRoutes
SubareaRoutes.navigateToSubareaDetalhes(context, subarea);

// Navegação direta
Navigator.pushNamed(
  context,
  '/subarea/detalhes',
  arguments: {'subarea': subarea},
);
```

### 3. Criar Subárea
- **Rota**: `/subarea/criar`
- **Classe**: `CriarSubareaScreen`
- **Argumentos**: `{'experimentoId': String, 'talhaoId': String}`

```dart
// Navegação usando SubareaRoutes
SubareaRoutes.navigateToCriarSubarea(context, experimentoId, talhaoId);

// Navegação direta
Navigator.pushNamed(
  context,
  '/subarea/criar',
  arguments: {
    'experimentoId': experimentoId,
    'talhaoId': talhaoId,
  },
);
```

### 4. Exemplo de Uso
- **Rota**: `/subarea/exemplo`
- **Classe**: `ExemploUsoSubareas`
- **Argumentos**: Nenhum

```dart
// Navegação usando SubareaRoutes
SubareaRoutes.navigateToExemploSubareas(context);

// Navegação direta
Navigator.pushNamed(context, '/subarea/exemplo');
```

## Classe SubareaRoutes

A classe `SubareaRoutes` fornece métodos auxiliares para navegação:

```dart
class SubareaRoutes {
  // Constantes das rotas
  static const String talhaoDetalhes = '/talhao/detalhes';
  static const String subareaDetalhes = '/subarea/detalhes';
  static const String criarSubarea = '/subarea/criar';
  static const String exemploSubareas = '/subarea/exemplo';

  // Métodos de navegação
  static Future<T?> navigateToTalhaoDetalhes<T extends Object?>(
    BuildContext context,
    Experimento experimento,
  );

  static Future<T?> navigateToSubareaDetalhes<T extends Object?>(
    BuildContext context,
    Subarea subarea,
  );

  static Future<T?> navigateToCriarSubarea<T extends Object?>(
    BuildContext context,
    String experimentoId,
    String talhaoId,
  );

  static Future<T?> navigateToExemploSubareas<T extends Object?>(
    BuildContext context,
  );
}
```

## Integração com o Sistema de Rotas Principal

As rotas do módulo de subáreas estão integradas ao sistema principal de rotas em `lib/routes.dart`:

```dart
// Imports
import 'screens/plantio/talhao_detalhes_screen.dart';
import 'screens/plantio/subarea_detalhes_screen.dart';
import 'screens/plantio/criar_subarea_screen.dart';
import 'screens/plantio/exemplo_uso_subareas.dart';

// Constantes das rotas
static const String talhaoDetalhes = '/talhao/detalhes';
static const String subareaDetalhes = '/subarea/detalhes';
static const String criarSubarea = '/subarea/criar';
static const String exemploSubareas = '/subarea/exemplo';

// Mapa de rotas
static final Map<String, WidgetBuilder> routes = {
  talhaoDetalhes: (context) { /* ... */ },
  subareaDetalhes: (context) { /* ... */ },
  criarSubarea: (context) { /* ... */ },
  exemploSubareas: (context) => const ExemploUsoSubareas(),
};
```

## Exemplo de Uso Completo

```dart
import 'package:flutter/material.dart';
import 'screens/plantio/subarea_routes.dart';
import 'models/experimento_talhao_model.dart';
import 'models/subarea_experimento_model.dart';

class MinhaTela extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Minha Tela')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // Criar um experimento de exemplo
              final experimento = Experimento(
                id: 'exp_001',
                nome: 'Experimento Teste',
                talhaoId: 'talhao_001',
                talhaoNome: 'Talhão Teste',
                dataInicio: DateTime.now(),
                status: 'ativo',
                criadoEm: DateTime.now(),
              );
              
              // Navegar para detalhes do talhão
              SubareaRoutes.navigateToTalhaoDetalhes(context, experimento);
            },
            child: Text('Abrir Detalhes do Talhão'),
          ),
          
          ElevatedButton(
            onPressed: () {
              // Navegar para exemplo de uso
              SubareaRoutes.navigateToExemploSubareas(context);
            },
            child: Text('Ver Exemplo'),
          ),
        ],
      ),
    );
  }
}
```

## Validação de Argumentos

Todas as rotas incluem validação de argumentos. Se os argumentos necessários não forem fornecidos, a rota redireciona para a tela de exemplo (`ExemploUsoSubareas`).

## Tratamento de Erros

As rotas incluem tratamento de erros para casos onde:
- Argumentos são nulos
- Tipos de argumentos são incorretos
- Dados obrigatórios estão ausentes

Em caso de erro, o usuário é redirecionado para a tela de exemplo com uma mensagem apropriada.
