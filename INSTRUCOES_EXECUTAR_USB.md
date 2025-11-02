# 📱 Instruções para Executar via Cabo USB

## ⚠️ Dispositivo Android Não Detectado

Atualmente não há dispositivos Android conectados. Siga os passos abaixo:

## 🔧 Passo a Passo

### 1️⃣ **Habilitar Modo Desenvolvedor no Android**

1. Vá em **Configurações** → **Sobre o telefone**
2. Toque 7 vezes em **Número da versão** ou **Versão do MIUI**
3. Uma mensagem aparecerá: "Você agora é um desenvolvedor!"

### 2️⃣ **Ativar Depuração USB**

1. Vá em **Configurações** → **Sistema** → **Opções do desenvolvedor**
   - Ou **Configurações** → **Opções adicionais** → **Opções do desenvolvedor** (Xiaomi)
2. Ative **Depuração USB**
3. Ative **Instalação via USB** (se disponível)
4. Ative **Depuração de USB (configurações de segurança)** (se disponível)

### 3️⃣ **Conectar o Dispositivo**

1. Conecte o celular ao PC via cabo USB
2. No celular, uma mensagem aparecerá: "Permitir depuração USB?"
3. Marque **"Sempre permitir neste computador"**
4. Toque em **"Permitir"** ou **"OK"**

### 4️⃣ **Verificar Conexão**

Execute no terminal:
```bash
flutter devices
```

Você deve ver algo como:
```
Found 3 connected devices:
  SM G960F (mobile) • 988f1d474d4e42 • android-arm64 • Android 10 (API 29)
  Chrome (web)      • chrome          • web-javascript • Google Chrome
  Edge (web)        • edge            • web-javascript • Microsoft Edge
```

### 5️⃣ **Executar o App**

```bash
flutter run --debug
```

Ou para forçar um dispositivo específico:
```bash
flutter run -d <device-id>
```

## 🚨 Troubleshooting

### Problema 1: "No devices found"

**Solução:**
1. Reinstale drivers USB do dispositivo
2. Tente outro cabo USB (alguns cabos são apenas para carga)
3. Mude a porta USB do computador
4. Verifique se o celular está no modo "Transferência de arquivos" e não apenas "Carregando"

### Problema 2: "Unauthorized"

**Solução:**
1. No celular, revogue autorizações antigas:
   - **Opções do desenvolvedor** → **Revogar autorizações de depuração USB**
2. Desconecte e reconecte o cabo
3. Aceite novamente a mensagem de depuração

### Problema 3: Driver ADB não instalado

**No Windows:**
1. Baixe e instale: [Android SDK Platform Tools](https://developer.android.com/studio/releases/platform-tools)
2. Ou instale o Android Studio completo
3. Execute: `flutter doctor` para verificar

### Problema 4: Dispositivo conectado mas não aparece

```bash
# Reiniciar servidor ADB
adb kill-server
adb start-server
adb devices
```

## 📦 Comandos Úteis

### Verificar dispositivos conectados
```bash
flutter devices
flutter devices --device-timeout 30
```

### Listar emuladores disponíveis
```bash
flutter emulators
```

### Executar em dispositivo específico
```bash
flutter run -d android
flutter run -d chrome
flutter run -d <device-id>
```

### Ver logs em tempo real
```bash
flutter run --debug --verbose
```

### Limpar build e executar
```bash
flutter clean
flutter pub get
flutter run --debug
```

## 🎯 Verificação Final

Antes de executar, certifique-se:
- ✅ Modo desenvolvedor ativado
- ✅ Depuração USB ativada
- ✅ Celular conectado via USB
- ✅ Permissão de depuração concedida
- ✅ Dispositivo aparece em `flutter devices`

## 🚀 Executar o App

Quando tudo estiver configurado:

```bash
cd C:\Users\fortu\fortsmart_agro_new
flutter run --debug
```

O app será instalado e executado no dispositivo automaticamente! 📱

---

## 📊 Status das Correções Aplicadas

Antes de executar, lembre-se que as seguintes correções foram aplicadas:

✅ Erros de compilação corrigidos
✅ Schemas de banco de dados unificados
✅ Tabela `estande_plantas` corrigida
✅ Tabela `plantios` corrigida
✅ Imports faltantes adicionados
✅ Métodos duplicados removidos

**Versão do Banco**: v40 (com migração automática)

O app deve funcionar corretamente após as correções! 🎉

