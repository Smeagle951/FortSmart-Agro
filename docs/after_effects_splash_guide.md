# 🎬 Guia: Criando Splash Screen FortSmart no After Effects

## 📋 Pré-requisitos

1. **Adobe After Effects** (versão 2020 ou superior)
2. **Plugin Bodymovin** (para exportar Lottie)
3. **Fontes:** Montserrat Bold e Regular
4. **Logo FortSmart** (SVG ou PNG transparente)

## 🚀 Passo 1: Configuração da Composição

### Criar Nova Composição
1. Abra o After Effects
2. `Composition` → `New Composition`
3. Configurações:
   - **Name:** `FortSmart_Splash`
   - **Width:** `1080px`
   - **Height:** `1920px`
   - **Frame Rate:** `30fps`
   - **Duration:** `2.5 seconds`
   - **Background Color:** `#FAFAFA`

## 🎨 Passo 2: Criar os Elementos

### 2.1 Logo FortSmart
1. **Criar Shape Layer:**
   - `Layer` → `New` → `Shape Layer`
   - Adicionar Rectangle com `120x120px`
   - Corner Radius: `20px`
   - Fill Color: `#2D9CDB`
   - Position: `540, 700`

2. **Adicionar Ícone:**
   - Importar ícone de agricultura (SVG)
   - Position: `540, 700`
   - Scale: `60%`
   - Color: `White`

3. **Animação do Logo:**
   - Selecionar o Shape Layer
   - **Frame 0:** Scale `0%`, Opacity `0%`
   - **Frame 12:** Scale `120%`, Opacity `100%`
   - **Frame 24:** Scale `100%`, Opacity `100%`
   - **Easing:** `Ease In-Out`

### 2.2 Brilho do Logo
1. **Criar Shape Circular:**
   - `Layer` → `New` → `Shape Layer`
   - Adicionar Ellipse `200x200px`
   - Fill: `White`
   - Position: `540, 700`
   - Blend Mode: `Add`

2. **Animação do Brilho:**
   - **Frame 18:** Opacity `0%`
   - **Frame 30:** Opacity `60%`
   - **Frame 36:** Opacity `0%`
   - **Easing:** `Ease In-Out`

### 2.3 Texto "FORTSMART"
1. **Criar Text Layer:**
   - `Layer` → `New` → `Text`
   - Texto: `FORTSMART`
   - Font: `Montserrat Bold`
   - Size: `48px`
   - Color: `#2C2C2C`
   - Position: `540, 800`
   - Letter Spacing: `48px`

2. **Animação do Texto:**
   - **Frame 30:** Opacity `0%`, Scale `90%`, Y Position `+30px`
   - **Frame 48:** Opacity `100%`, Scale `100%`, Y Position `0px`
   - **Easing:** `Ease Out Cubic`

### 2.4 Subtexto
1. **Criar Text Layer:**
   - `Layer` → `New` → `Text`
   - Texto: `Tudo na palma da mão`
   - Font: `Montserrat Regular`
   - Size: `24px`
   - Color: `#2D9CDB`
   - Position: `540, 880`
   - Letter Spacing: `8px`

2. **Animação do Subtexto:**
   - **Frame 42:** Opacity `0%`, Y Position `+30px`
   - **Frame 60:** Opacity `100%`, Y Position `0px`
   - **Easing:** `Ease Out Cubic`

### 2.5 Fade Out Geral
1. **Criar Null Object:**
   - `Layer` → `New` → `Null Object`
   - Renomear para `Master_Fade`

2. **Animação de Fade:**
   - **Frame 60:** Opacity `100%`
   - **Frame 75:** Opacity `0%`
   - **Easing:** `Ease In`

3. **Parenting:**
   - Parentar todos os layers ao `Master_Fade`

## 📤 Passo 3: Exportação para Lottie

### 3.1 Instalar Bodymovin
1. Baixar plugin Bodymovin
2. Instalar em: `Applications/Adobe After Effects/Support Files/Scripts/ScriptUI Panels/`
3. Reiniciar After Effects

### 3.2 Exportar JSON
1. `Window` → `Extensions` → `Bodymovin`
2. Selecionar composição `FortSmart_Splash`
3. **Settings:**
   - ✅ Include unused compositions
   - ✅ Compress
   - ✅ Glyphs
   - ✅ Expressions
4. **Output:** Escolher pasta de destino
5. Clique em `Render`
6. Arquivo gerado: `fortsmart_splash.json`

## 🔧 Passo 4: Otimizações

### 4.1 Reduzir Tamanho do Arquivo
- Usar shapes simples em vez de imagens complexas
- Evitar muitos keyframes desnecessários
- Usar easing suaves

### 4.2 Performance
- Máximo 30fps
- Duração não superior a 3 segundos
- Resolução mobile (1080x1920)

## 📱 Passo 5: Implementação no Flutter

### 5.1 Adicionar Dependência
```yaml
dependencies:
  lottie: ^2.7.0
```

### 5.2 Usar o Widget
```dart
import 'package:lottie/lottie.dart';

Lottie.asset(
  'assets/animations/fortsmart_splash.json',
  fit: BoxFit.contain,
  repeat: false,
)
```

## 🎯 Timeline da Animação

| Tempo | Ação | Elemento |
|-------|------|----------|
| 0.0s | Logo aparece | Scale 0→120%→100% |
| 0.6s | Brilho inicia | Opacity 0→60% |
| 0.8s | Logo estabiliza | Scale 100% |
| 1.0s | Texto aparece | Fade In + Scale 90%→100% |
| 1.2s | Brilho desaparece | Opacity 60%→0% |
| 1.4s | Subtexto aparece | Slide Up + Fade In |
| 2.0s | Fade Out inicia | Opacity 100%→0% |
| 2.5s | Animação termina | Opacity 0% |

## 🎨 Paleta de Cores

- **Fundo:** `#FAFAFA` (Branco perolado)
- **Logo:** `#2D9CDB` (Azul FortSmart)
- **Texto principal:** `#2C2C2C` (Cinza escuro)
- **Subtexto:** `#2D9CDB` (Azul FortSmart)
- **Brilho:** `#FFFFFF` (Branco)

## 📏 Especificações Técnicas

- **Resolução:** 1080x1920 (9:16)
- **Frame Rate:** 30fps
- **Duração:** 2.5 segundos
- **Formato:** Lottie JSON
- **Tamanho máximo:** < 500KB

## 🔍 Dicas Profissionais

1. **Easing:** Use `Ease In-Out` para movimentos naturais
2. **Timing:** Deixe espaços entre animações para respiração
3. **Performance:** Evite muitas camadas simultâneas
4. **Consistência:** Mantenha o mesmo estilo visual em todas as animações
5. **Teste:** Sempre teste em dispositivos reais

## 🚀 Resultado Final

A animação deve transmitir:
- ✅ **Profissionalismo** - Movimentos suaves e precisos
- ✅ **Modernidade** - Design limpo e minimalista  
- ✅ **Confiança** - Branding forte e consistente
- ✅ **Performance** - Carregamento rápido e fluido

---

**🎬 Sua animação FortSmart está pronta para impressionar!**
