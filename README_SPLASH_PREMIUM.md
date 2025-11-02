# 🎬 FortSmart Splash Screen Premium

## 📋 Visão Geral

Sistema completo de splash screen premium para o FortSmart, incluindo animação Lottie profissional, widgets Flutter otimizados e documentação completa para After Effects.

## 🚀 Características

### ✨ Animação Premium
- **Logo FortSmart** com animação de escala suave (0% → 120% → 100%)
- **Brilho dinâmico** que desliza da esquerda para direita
- **Textos animados** com fade in e slide up
- **Fade out elegante** no final da animação
- **Duração otimizada** de 2.5 segundos

### 🎨 Design System
- **Paleta de cores FortSmart** consistente
- **Tipografia Montserrat** (Bold e Regular)
- **Resolução mobile** 1080x1920 (vertical)
- **Performance otimizada** para dispositivos móveis

### 🔧 Implementação Flutter
- **Widgets prontos** para uso imediato
- **Controle total** da animação
- **Loading de dados** integrado
- **Fallback nativo** caso Lottie falhe

## 📁 Estrutura de Arquivos

```
📦 FortSmart Splash Premium
├── 📄 assets/animations/
│   ├── 🎬 fortsmart_splash.json      # Animação Lottie principal
│   └── 📋 README.md                  # Documentação das animações
├── 📄 lib/
│   ├── 🎯 screens/
│   │   ├── splash_screen.dart        # Splash screens básicas
│   │   └── splash_screen_premium.dart # Splash screen premium
│   ├── 🧩 widgets/
│   │   └── fortsmart_splash_animation.dart # Widget nativo
│   └── 📚 examples/
│       └── splash_screen_usage.dart  # Exemplos de uso
├── 📄 docs/
│   ├── after_effects_splash_guide.md # Guia básico After Effects
│   └── after_effects_premium_guide.md # Guia premium completo
└── 📄 README_SPLASH_PREMIUM.md      # Este arquivo
```

## 🎯 Uso Rápido

### 1. Splash Screen Simples
```dart
import 'package:lottie/lottie.dart';

Lottie.asset(
  'assets/animations/fortsmart_splash.json',
  repeat: false,
  fit: BoxFit.contain,
)
```

### 2. Splash Screen Premium
```dart
import '../screens/splash_screen_premium.dart';

SplashScreenPremium(
  nextScreen: const HomeScreen(),
  minimumDuration: const Duration(seconds: 3),
  onInit: () async {
    // Carregar dados do app
    await loadAppData();
  },
)
```

### 3. Widget Nativo (Fallback)
```dart
import '../widgets/fortsmart_splash_animation.dart';

FortSmartSplashAnimation(
  onAnimationComplete: () {
    // Navegar para próxima tela
  },
)
```

## 🎨 Personalização

### Cores da Marca
```dart
// Azul FortSmart
Color(0xFF2D9CDB)

// Fundo perolado
Color(0xFFFAFAFA)

// Texto principal
Color(0xFF2C2C2C)

// Subtexto
Color(0xFF2D9CDB)
```

### Configurações de Animação
```dart
SplashScreenPremium(
  // Tela de destino
  nextScreen: const HomeScreen(),
  
  // Tempo mínimo de exibição
  minimumDuration: const Duration(seconds: 3),
  
  // Função de inicialização
  onInit: () async {
    // Sua lógica aqui
  },
  
  // Caminho personalizado do Lottie
  lottiePath: 'assets/animations/custom_splash.json',
)
```

## 📱 Exemplos de Uso

### Exemplo 1: App Simples
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SplashScreenLottie(
        nextScreen: HomeScreen(),
      ),
    );
  }
}
```

### Exemplo 2: App com Carregamento
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreenPremium(
        nextScreen: const HomeScreen(),
        minimumDuration: const Duration(seconds: 3),
        onInit: () async {
          // Carregar configurações
          await loadUserSettings();
          
          // Verificar conectividade
          await checkConnectivity();
          
          // Inicializar serviços
          await initializeServices();
        },
      ),
    );
  }
}
```

### Exemplo 3: App com Fallback
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreenPremium(
        nextScreen: const HomeScreen(),
        lottiePath: 'assets/animations/fortsmart_splash.json',
        // Se o Lottie falhar, usa o widget nativo automaticamente
      ),
    );
  }
}
```

## 🔧 Configuração do Projeto

### 1. Adicionar Dependências
```yaml
dependencies:
  lottie: ^3.0.0
```

### 2. Configurar Assets
```yaml
flutter:
  assets:
    - assets/animations/
    - assets/images/
```

### 3. Importar Widgets
```dart
import 'screens/splash_screen_premium.dart';
import 'widgets/fortsmart_splash_animation.dart';
```

## 🎬 Criando Sua Própria Animação

### Passo 1: After Effects
1. Abrir After Effects
2. Criar composição 1080x1920
3. Seguir guia em `docs/after_effects_premium_guide.md`
4. Exportar com Bodymovin

### Passo 2: Otimização
- Máximo 30fps
- Duração ≤ 3 segundos
- Tamanho < 500KB
- Usar shapes simples

### Passo 3: Teste
```dart
// Testar em diferentes dispositivos
Lottie.asset(
  'assets/animations/my_custom_splash.json',
  errorBuilder: (context, error, stackTrace) {
    return const FortSmartSplashAnimation(); // Fallback
  },
)
```

## 📊 Performance

### Métricas Otimizadas
- **Tamanho:** < 500KB
- **Duração:** 2.5 segundos
- **Frame Rate:** 30fps
- **Memória:** < 50MB
- **Tempo de carregamento:** < 1 segundo

### Compatibilidade
- ✅ **iOS:** 12.0+
- ✅ **Android:** API 21+
- ✅ **Flutter:** 3.0+
- ✅ **Lottie:** 3.0+

## 🐛 Troubleshooting

### Problema: Animação não carrega
```dart
// Verificar se o arquivo existe
Lottie.asset(
  'assets/animations/fortsmart_splash.json',
  errorBuilder: (context, error, stackTrace) {
    print('Erro ao carregar Lottie: $error');
    return const FortSmartSplashAnimation();
  },
)
```

### Problema: Performance ruim
```dart
// Usar configurações otimizadas
Lottie.asset(
  'assets/animations/fortsmart_splash.json',
  repeat: false, // Não repetir
  fit: BoxFit.contain, // Ajustar ao container
)
```

### Problema: Arquivo muito pesado
1. Reduzir duração da animação
2. Usar menos keyframes
3. Comprimir assets
4. Simplificar efeitos

## 📚 Documentação Adicional

### Guias Completos
- 📖 [Guia After Effects Básico](docs/after_effects_splash_guide.md)
- 📖 [Guia After Effects Premium](docs/after_effects_premium_guide.md)
- 📖 [Documentação das Animações](assets/animations/README.md)

### Exemplos Práticos
- 🎯 [Exemplos de Uso](lib/examples/splash_screen_usage.dart)
- 🎯 [Widgets Prontos](lib/widgets/fortsmart_splash_animation.dart)
- 🎯 [Splash Screens](lib/screens/splash_screen_premium.dart)

## 🎨 Brand Guidelines

### Logo FortSmart
- **Formato:** PNG/SVG transparente
- **Tamanho:** 120x120px
- **Cor:** #2D9CDB (azul FortSmart)
- **Fundo:** Transparente

### Tipografia
- **Título:** Montserrat Bold, 48px
- **Subtítulo:** Montserrat Regular, 24px
- **Cor do título:** #2C2C2C
- **Cor do subtítulo:** #2D9CDB

### Espaçamento
- **Letter spacing título:** 48px
- **Letter spacing subtítulo:** 8px
- **Line height:** 1.2x do tamanho da fonte

## 🚀 Próximos Passos

### Melhorias Futuras
- [ ] Suporte a temas claro/escuro
- [ ] Múltiplas variações da animação
- [ ] Animações sazonais
- [ ] Integração com analytics
- [ ] A/B testing de animações

### Contribuições
1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📞 Suporte

### Recursos
- 📖 Documentação completa nos arquivos `docs/`
- 🎯 Exemplos práticos em `lib/examples/`
- 🎬 Guias passo-a-passo para After Effects
- 🔧 Widgets prontos para uso

### Contato
Para dúvidas ou sugestões:
1. Verificar documentação existente
2. Testar exemplos fornecidos
3. Consultar guias de troubleshooting
4. Abrir issue no repositório

---

**🎬 FortSmart Splash Screen Premium - Impressione seus usuários desde o primeiro segundo!**

## 📄 Licença

Este projeto está sob a licença do FortSmart. Todos os direitos reservados.

---

**Desenvolvido com ❤️ para o FortSmart**
