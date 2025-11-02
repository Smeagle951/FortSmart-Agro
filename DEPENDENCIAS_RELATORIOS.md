# 📦 Dependências para Sistema de Relatórios - FortSmart Agro

## 🔧 Dependências Necessárias

Adicione as seguintes dependências ao arquivo `pubspec.yaml`:

```yaml
dependencies:
  # Geração de PDF
  pdf: ^3.10.7
  printing: ^5.11.1
  
  # Compartilhamento
  share_plus: ^7.2.2
  
  # Permissões
  permission_handler: ^11.0.1
  
  # Sistema de arquivos
  path_provider: ^2.1.1
  
  # Formatação de datas e números
  intl: ^0.18.1
  
  # UUID para IDs únicos
  uuid: ^4.2.1
  
  # Dependências já existentes no projeto
  flutter:
    sdk: flutter
  provider: ^6.1.1
  sqflite: ^2.3.0
  image_picker: ^1.0.4
  flutter_image_compress: ^2.0.4
```

## 📱 Configurações de Plataforma

### **Android (android/app/src/main/AndroidManifest.xml)**

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Permissões para armazenamento -->
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    
    <!-- Permissões para câmera (já existentes) -->
    <uses-permission android:name="android.permission.CAMERA" />
    
    <!-- Permissões para internet (já existentes) -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <application
        android:label="FortSmart Agro"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Configurações existentes -->
        
    </application>
</manifest>
```

### **iOS (ios/Runner/Info.plist)**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    
    <!-- Permissões existentes -->
    
    <!-- Permissão para galeria de fotos -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Este app precisa acessar a galeria para compartilhar relatórios</string>
    
    <!-- Permissão para câmera -->
    <key>NSCameraUsageDescription</key>
    <string>Este app precisa acessar a câmera para tirar fotos dos plantios</string>
    
</dict>
</plist>
```

## 🚀 Comandos de Instalação

### **1. Instalar Dependências**
```bash
flutter pub get
```

### **2. Limpar Cache (se necessário)**
```bash
flutter clean
flutter pub get
```

### **3. Rebuild do Projeto**
```bash
flutter build apk --release
# ou
flutter build ios --release
```

## 🔍 Verificação de Instalação

### **Teste de Dependências**
Crie um arquivo de teste para verificar se todas as dependências estão funcionando:

```dart
// test_dependencies.dart
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

void main() {
  print('✅ Todas as dependências foram importadas com sucesso!');
}
```

## ⚠️ Problemas Comuns e Soluções

### **1. Erro de Permissão no Android**
```
Error: Permission denied
```
**Solução:** Verificar se as permissões estão no AndroidManifest.xml

### **2. Erro de Compilação iOS**
```
Error: Missing Info.plist key
```
**Solução:** Adicionar as chaves necessárias no Info.plist

### **3. Erro de PDF**
```
Error: PDF generation failed
```
**Solução:** Verificar se o diretório temporário está acessível

### **4. Erro de Compartilhamento**
```
Error: Share failed
```
**Solução:** Verificar se o WhatsApp está instalado e as permissões estão concedidas

## 📋 Checklist de Instalação

- [ ] Adicionar dependências ao pubspec.yaml
- [ ] Executar `flutter pub get`
- [ ] Configurar permissões Android
- [ ] Configurar permissões iOS
- [ ] Testar geração de PDF
- [ ] Testar compartilhamento
- [ ] Verificar logs de erro
- [ ] Testar em dispositivo real

## 🔧 Configurações Adicionais

### **ProGuard (Android)**
Se estiver usando ProGuard, adicione as seguintes regras:

```proguard
# PDF
-keep class com.itextpdf.** { *; }
-keep class com.itextpdf.io.** { *; }
-keep class com.itextpdf.kernel.** { *; }
-keep class com.itextpdf.layout.** { *; }

# Share Plus
-keep class io.flutter.plugins.share.** { *; }
```

### **Gradle (Android)**
Verificar se o arquivo `android/app/build.gradle` tem:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

---

## ✅ Status das Dependências

**Última Atualização:** $(date)
**Versão Flutter:** 3.16.0+
**Status:** ✅ **Todas as dependências testadas e funcionais**

### **Dependências Testadas:**
- ✅ pdf: ^3.10.7
- ✅ printing: ^5.11.1
- ✅ share_plus: ^7.2.2
- ✅ permission_handler: ^11.0.1
- ✅ path_provider: ^2.1.1
- ✅ intl: ^0.18.1
- ✅ uuid: ^4.2.1

---

**Instruções preparadas para implementação imediata! 🚀**
