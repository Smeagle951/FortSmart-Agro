# 🎬 Guia Premium: Splash Screen FortSmart no After Effects

## 📋 Visão Geral

Este guia completo te ensina a criar a animação premium da splash screen do FortSmart no After Effects, com exportação para Lottie JSON. A animação inclui efeitos dinâmicos, brilho deslizante e transições suaves.

## 🚀 Configuração Inicial

### 1. Pré-requisitos
- **Adobe After Effects** (2020 ou superior)
- **Plugin Bodymovin** (LottieFiles)
- **Fontes:** Montserrat Bold e Regular
- **Logo FortSmart:** PNG/SVG transparente (120x120px)

### 2. Instalação do Bodymovin
1. Baixar: [LottieFiles Bodymovin](https://lottiefiles.com/plugins/after-effects)
2. Instalar em: `Applications/Adobe After Effects/Support Files/Scripts/ScriptUI Panels/`
3. Reiniciar After Effects

## 🎨 Passo 1: Configuração da Composição

### Criar Nova Composição
```
Nome: FortSmart_Splash
Largura: 1080px
Altura: 1920px
Taxa de Quadros: 30fps
Duração: 2.5 segundos
Cor de Fundo: #FAFAFA
```

## 🔧 Passo 2: Estrutura dos Layers

### Ordem dos Layers (de cima para baixo):
1. **Fade Out Overlay** (Layer 5)
2. **Subtext** (Layer 4)
3. **FORTSMART Text** (Layer 3)
4. **Brilho Dinâmico** (Layer 2)
5. **FortSmart Logo** (Layer 1)

## 🎯 Passo 3: Layer 1 - FortSmart Logo

### 3.1 Importar Logo
1. `File` → `Import` → `File`
2. Selecionar `fortsmart_logo.png`
3. Arrastar para a composição
4. Posicionar em: `540, 700`

### 3.2 Configurar Animações
**Scale Animation:**
- **Frame 0:** Scale `0%`
- **Frame 12:** Scale `120%`
- **Frame 24:** Scale `100%`
- **Easing:** Ease In-Out

**Opacity Animation:**
- **Frame 0:** Opacity `0%`
- **Frame 24:** Opacity `100%`
- **Easing:** Ease In-Out

### 3.3 Keyframes Detalhados
```
Scale:
- 0s: [0, 0, 100]
- 0.4s: [120, 120, 100] (Ease Out)
- 0.8s: [100, 100, 100] (Ease In)

Opacity:
- 0s: 0%
- 0.8s: 100%
```

## ✨ Passo 4: Layer 2 - Brilho Dinâmico

### 4.1 Criar Shape Layer
1. `Layer` → `New` → `Shape Layer`
2. Adicionar `Ellipse`
3. Tamanho: `200x200px`
4. Fill: `White`
5. Position: `540, 700`

### 4.2 Configurar Blend Mode
- **Blend Mode:** `Add`
- **Opacity:** 60%

### 4.3 Adicionar Gaussian Blur
1. `Effect` → `Blur & Sharpen` → `Gaussian Blur`
2. Blur Amount: `20px`

### 4.4 Animação do Brilho
**Position Animation (desliza da esquerda para direita):**
- **Frame 18:** Position `300, 700`
- **Frame 36:** Position `780, 700`
- **Easing:** Ease In-Out

**Opacity Animation:**
- **Frame 18:** Opacity `0%`
- **Frame 30:** Opacity `60%`
- **Frame 36:** Opacity `0%`
- **Easing:** Ease In-Out

### 4.5 Keyframes Detalhados
```
Position:
- 0.6s: [300, 700, 0] (Ease Out)
- 1.2s: [780, 700, 0] (Ease In)

Opacity:
- 0.6s: 0%
- 1.0s: 60% (Ease In-Out)
- 1.2s: 0%
```

## 📝 Passo 5: Layer 3 - Texto "FORTSMART"

### 5.1 Criar Text Layer
1. `Layer` → `New` → `Text`
2. Texto: `FORTSMART`
3. Font: `Montserrat Bold`
4. Size: `48px`
5. Color: `#2C2C2C`
6. Position: `540, 800`
7. Letter Spacing: `48px`
8. Alignment: `Center`

### 5.2 Animação do Texto
**Opacity Animation:**
- **Frame 30:** Opacity `0%`
- **Frame 48:** Opacity `100%`
- **Easing:** Ease In-Out

**Scale Animation:**
- **Frame 30:** Scale `90%`
- **Frame 48:** Scale `100%`
- **Easing:** Ease Out Cubic

### 5.3 Keyframes Detalhados
```
Opacity:
- 1.0s: 0%
- 1.6s: 100% (Ease In-Out)

Scale:
- 1.0s: [90, 90, 100] (Ease Out)
- 1.6s: [100, 100, 100]
```

## 📄 Passo 6: Layer 4 - Subtexto

### 6.1 Criar Text Layer
1. `Layer` → `New` → `Text`
2. Texto: `Tudo na palma da mão`
3. Font: `Montserrat Regular`
4. Size: `24px`
5. Color: `#2D9CDB`
6. Position: `540, 880`
7. Letter Spacing: `8px`
8. Alignment: `Center`

### 6.2 Animação do Subtexto
**Opacity Animation:**
- **Frame 42:** Opacity `0%`
- **Frame 60:** Opacity `100%`
- **Easing:** Ease In-Out

**Position Animation (slide up):**
- **Frame 42:** Position `540, 920`
- **Frame 60:** Position `540, 880`
- **Easing:** Ease Out Cubic

### 6.3 Keyframes Detalhados
```
Opacity:
- 1.4s: 0%
- 2.0s: 100% (Ease In-Out)

Position:
- 1.4s: [540, 920, 0] (Ease Out)
- 2.0s: [540, 880, 0]
```

## 🌅 Passo 7: Layer 5 - Fade Out Overlay

### 7.1 Criar Shape Layer
1. `Layer` → `New` → `Shape Layer`
2. Adicionar `Rectangle`
3. Tamanho: `1080x1920px`
4. Fill: `#FAFAFA`
5. Position: `540, 960`

### 7.2 Animação de Fade Out
**Opacity Animation:**
- **Frame 60:** Opacity `0%`
- **Frame 75:** Opacity `100%`
- **Easing:** Ease In

### 7.3 Keyframes Detalhados
```
Opacity:
- 2.0s: 0%
- 2.5s: 100% (Ease In)
```

## 🎬 Passo 8: Timeline Completa

| Tempo | Ação | Elemento | Easing |
|-------|------|----------|---------|
| 0.0s | Logo aparece | Scale 0→120%→100% | Ease In-Out |
| 0.6s | Brilho inicia | Opacity 0% | Ease In |
| 0.8s | Logo estabiliza | Scale 100% | Ease In |
| 1.0s | Texto aparece | Fade In + Scale 90%→100% | Ease Out |
| 1.2s | Brilho termina | Opacity 0% | Ease Out |
| 1.4s | Subtexto aparece | Slide Up + Fade In | Ease Out |
| 2.0s | Fade Out inicia | Opacity 0%→100% | Ease In |
| 2.5s | Animação termina | Opacity 100% | - |

## 📤 Passo 9: Exportação Bodymovin

### 9.1 Configurar Bodymovin
1. `Window` → `Extensions` → `Bodymovin`
2. Selecionar composição `FortSmart_Splash`
3. **Settings:**
   - ✅ Include unused compositions
   - ✅ Compress
   - ✅ Glyphs
   - ✅ Expressions
   - ✅ Assets
   - ❌ Loop (desativado)

### 9.2 Renderizar
1. Escolher pasta de destino
2. Nome do arquivo: `fortsmart_splash`
3. Clique em `Render`
4. Aguardar processamento

### 9.3 Verificar Arquivos Gerados
- `fortsmart_splash.json` (arquivo principal)
- `images/fortsmart_logo.png` (logo exportado)

## 🔧 Passo 10: Otimizações

### 10.1 Reduzir Tamanho do Arquivo
- Usar shapes simples
- Evitar muitos keyframes
- Comprimir assets
- Remover layers não utilizados

### 10.2 Melhorar Performance
- Máximo 30fps
- Duração ≤ 3 segundos
- Resolução mobile otimizada
- Easing suaves

## 📱 Passo 11: Implementação no Flutter

### 11.1 Estrutura de Arquivos
```
assets/
├── animations/
│   └── fortsmart_splash.json
└── images/
    └── fortsmart_logo.png
```

### 11.2 pubspec.yaml
```yaml
flutter:
  assets:
    - assets/animations/
    - assets/images/
```

### 11.3 Widget Flutter
```dart
import 'package:lottie/lottie.dart';

Lottie.asset(
  'assets/animations/fortsmart_splash.json',
  repeat: false,
  fit: BoxFit.contain,
)
```

## 🎨 Paleta de Cores

### Cores Principais
- **Fundo:** `#FAFAFA` (Branco perolado)
- **Logo:** `#2D9CDB` (Azul FortSmart)
- **Texto principal:** `#2C2C2C` (Cinza escuro)
- **Subtexto:** `#2D9CDB` (Azul FortSmart)
- **Brilho:** `#FFFFFF` (Branco)

### Cores de Suporte
- **Sombra suave:** `#F5F5F5`
- **Borda:** `#E0E0E0`
- **Texto secundário:** `#757575`

## 🔍 Troubleshooting

### Problema: Animação não exporta corretamente
**Soluções:**
1. Verificar se todos os layers estão visíveis
2. Confirmar que as fontes estão instaladas
3. Testar com shapes simples primeiro
4. Verificar configurações do Bodymovin

### Problema: Arquivo JSON muito pesado
**Soluções:**
1. Reduzir número de keyframes
2. Usar easing mais simples
3. Comprimir assets de imagem
4. Remover efeitos complexos

### Problema: Performance ruim no Flutter
**Soluções:**
1. Reduzir frame rate para 24fps
2. Simplificar animações
3. Usar `repeat: false`
4. Testar em dispositivos reais

## 📚 Recursos Adicionais

### Links Úteis
- [LottieFiles](https://lottiefiles.com/)
- [After Effects + Bodymovin](https://github.com/airbnb/lottie-web)
- [Documentação Lottie Flutter](https://pub.dev/packages/lottie)
- [FortSmart Brand Guidelines](./brand_guidelines.md)

### Templates Prontos
- `fortsmart_splash.json` (base completa)
- `fortsmart_logo.png` (logo otimizado)
- Widgets Flutter prontos

## 🎯 Resultado Final

### Características da Animação Premium
- ✅ **Logo dinâmico** com escala suave
- ✅ **Brilho deslizante** da esquerda para direita
- ✅ **Textos animados** com fade e slide
- ✅ **Fade out elegante** no final
- ✅ **Performance otimizada** para mobile
- ✅ **Compatibilidade total** com Flutter

### Métricas de Qualidade
- **Duração:** 2.5 segundos
- **Tamanho:** < 500KB
- **Frame Rate:** 30fps
- **Resolução:** 1080x1920
- **Compatibilidade:** iOS/Android

---

**🎬 Sua animação premium FortSmart está pronta para impressionar!**

## 📞 Suporte

Para dúvidas ou problemas:
1. Verificar este guia passo-a-passo
2. Consultar documentação do Bodymovin
3. Testar em ambiente de desenvolvimento
4. Validar em dispositivos reais

**Boa sorte criando sua animação premium! 🚀**
