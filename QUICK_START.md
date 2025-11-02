# 🚀 Quick Start - FortSmart Splash Premium

## ⚡ Uso Imediato (5 minutos)

### 1. Copiar Arquivos
```bash
# Copie estes arquivos para seu projeto:
assets/animations/fortsmart_splash.json
lib/screens/splash_screen_premium.dart
lib/widgets/fortsmart_splash_animation.dart
```

### 2. Configurar pubspec.yaml
```yaml
dependencies:
  lottie: ^3.0.0

flutter:
  assets:
    - assets/animations/
```

### 3. Usar no main.dart
```dart
import 'package:flutter/material.dart';
import 'screens/splash_screen_premium.dart';
import 'screens/home_screen.dart'; // Sua tela principal

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreenPremium(
        nextScreen: HomeScreen(), // Sua tela principal
        minimumDuration: Duration(seconds: 3),
        onInit: () async {
          // Carregar dados do seu app aqui
          await loadAppData();
        },
      ),
    );
  }
}
```

## 🎯 Pronto! 

Sua splash screen premium está funcionando! 🎉

---

## 📋 O que você tem agora:

✅ **Animação Lottie premium** com logo, brilho e textos animados  
✅ **Widget Flutter otimizado** com controle total  
✅ **Loading de dados integrado**  
✅ **Fallback nativo** caso Lottie falhe  
✅ **Documentação completa** para personalização  

## 🔧 Personalizações Rápidas:

### Mudar duração mínima:
```dart
minimumDuration: Duration(seconds: 2), // Mais rápido
minimumDuration: Duration(seconds: 5), // Mais lento
```

### Adicionar carregamento personalizado:
```dart
onInit: () async {
  await loadUserSettings();
  await checkConnectivity();
  await initializeServices();
}
```

### Usar animação customizada:
```dart
lottiePath: 'assets/animations/minha_animacao.json',
```

## 📚 Próximos Passos:

1. **Personalizar animação:** Veja `docs/after_effects_premium_guide.md`
2. **Exemplos avançados:** Veja `lib/examples/splash_screen_usage.dart`
3. **Documentação completa:** Veja `README_SPLASH_PREMIUM.md`

---

**🎬 Sua splash screen premium está pronta para impressionar!**
