# 🎬 Animações FortSmart

Este diretório contém os arquivos de animação Lottie do FortSmart.

## 📁 Estrutura

```
assets/animations/
├── fortsmart_splash.json      # Splash screen principal
├── loading_spinner.json       # Spinner de carregamento
├── success_check.json         # Animação de sucesso
├── error_alert.json          # Animação de erro
└── README.md                 # Este arquivo
```

## 🚀 Splash Screen

### Arquivo: `fortsmart_splash.json`
- **Duração:** 2.5 segundos
- **Resolução:** 1080x1920 (mobile vertical)
- **Elementos:**
  - Logo FortSmart com animação de escala
  - Brilho suave no logo
  - Texto "FORTSMART" com fade in
  - Subtexto "Tudo na palma da mão" com slide up
  - Fade out geral

### Como usar:
```dart
import 'package:lottie/lottie.dart';

Lottie.asset(
  'assets/animations/fortsmart_splash.json',
  fit: BoxFit.contain,
  repeat: false,
  onLoaded: (composition) {
    // Animação carregada
  },
)
```

## 🎨 Especificações Técnicas

### Cores
- **Fundo:** #FAFAFA (Branco perolado)
- **Logo:** #2D9CDB (Azul FortSmart)
- **Texto:** #2C2C2C (Cinza escuro)
- **Subtexto:** #2D9CDB (Azul FortSmart)

### Fontes
- **Título:** Montserrat Bold
- **Subtítulo:** Montserrat Regular

### Performance
- **Frame Rate:** 30fps
- **Tamanho máximo:** < 500KB
- **Duração máxima:** 3 segundos

## 🔧 Como Criar Novas Animações

### 1. After Effects
1. Criar composição 1080x1920
2. Usar cores da paleta FortSmart
3. Manter animações suaves (Ease In-Out)
4. Duração máxima de 3 segundos

### 2. Exportação
1. Instalar plugin Bodymovin
2. Selecionar composição
3. Configurar:
   - ✅ Include unused compositions
   - ✅ Compress
   - ✅ Glyphs
4. Renderizar JSON

### 3. Otimização
- Usar shapes em vez de imagens
- Evitar muitos keyframes
- Testar em dispositivos reais

## 📱 Implementação no Flutter

### Dependência
```yaml
dependencies:
  lottie: ^3.0.0
```

### Widget Básico
```dart
class FortSmartAnimation extends StatelessWidget {
  final String assetPath;
  final bool repeat;
  final double? width;
  final double? height;

  const FortSmartAnimation({
    Key? key,
    required this.assetPath,
    this.repeat = false,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      repeat: repeat,
    );
  }
}
```

### Controle de Animação
```dart
class ControlledAnimation extends StatefulWidget {
  @override
  _ControlledAnimationState createState() => _ControlledAnimationState();
}

class _ControlledAnimationState extends State<ControlledAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/fortsmart_splash.json',
      controller: _controller,
      onLoaded: (composition) {
        _controller.duration = composition.duration;
        _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## 🎯 Boas Práticas

### Design
- ✅ Manter consistência visual
- ✅ Usar paleta de cores FortSmart
- ✅ Animações suaves e naturais
- ✅ Duração apropriada (não muito longa)

### Performance
- ✅ Arquivos < 500KB
- ✅ Máximo 30fps
- ✅ Testar em dispositivos antigos
- ✅ Otimizar para mobile

### UX
- ✅ Feedback visual claro
- ✅ Estados de loading/sucesso/erro
- ✅ Animações que não distraem
- ✅ Tempo de resposta rápido

## 🔍 Troubleshooting

### Problema: Animação não carrega
**Solução:**
1. Verificar se o arquivo está em `assets/animations/`
2. Adicionar no `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/animations/
```

### Problema: Animação muito pesada
**Solução:**
1. Reduzir duração
2. Usar menos keyframes
3. Otimizar shapes no After Effects
4. Comprimir o arquivo JSON

### Problema: Performance ruim
**Solução:**
1. Reduzir frame rate para 24fps
2. Simplificar animações
3. Usar `repeat: false`
4. Testar em dispositivos reais

## 📚 Recursos Adicionais

- [Documentação Lottie Flutter](https://pub.dev/packages/lottie)
- [LottieFiles](https://lottiefiles.com/)
- [After Effects + Bodymovin](https://github.com/airbnb/lottie-web)
- [Paleta de Cores FortSmart](./colors.md)

---

**🎬 Suas animações FortSmart estão prontas para impressionar!**
