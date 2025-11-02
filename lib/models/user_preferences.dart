/// Preferências do usuário para temas e acessibilidade
class UserPreferences {
  // Configurações de tema
  final ThemeMode themeMode;
  final ColorSchemeType colorScheme;
  final bool highContrast;
  final bool darkModeOptimized;
  
  // Configurações de acessibilidade
  final FontSizeLevel fontSizeLevel;
  final bool boldText;
  final bool reduceMotion;
  final bool screenReaderOptimized;
  
  // Configurações de contexto
  final UserContext userContext;
  final DeviceType deviceType;
  final bool fieldOptimized;
  
  // Configurações de layout
  final LayoutDensity layoutDensity;
  final bool compactMode;
  final bool touchOptimized;

  const UserPreferences({
    this.themeMode = ThemeMode.system,
    this.colorScheme = ColorSchemeType.adaptive,
    this.highContrast = false,
    this.darkModeOptimized = false,
    this.fontSizeLevel = FontSizeLevel.medium,
    this.boldText = false,
    this.reduceMotion = false,
    this.screenReaderOptimized = false,
    this.userContext = UserContext.general,
    this.deviceType = DeviceType.auto,
    this.fieldOptimized = false,
    this.layoutDensity = LayoutDensity.medium,
    this.compactMode = false,
    this.touchOptimized = false,
  });

  /// Cria uma cópia com campos atualizados
  UserPreferences copyWith({
    ThemeMode? themeMode,
    ColorSchemeType? colorScheme,
    bool? highContrast,
    bool? darkModeOptimized,
    FontSizeLevel? fontSizeLevel,
    bool? boldText,
    bool? reduceMotion,
    bool? screenReaderOptimized,
    UserContext? userContext,
    DeviceType? deviceType,
    bool? fieldOptimized,
    LayoutDensity? layoutDensity,
    bool? compactMode,
    bool? touchOptimized,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      colorScheme: colorScheme ?? this.colorScheme,
      highContrast: highContrast ?? this.highContrast,
      darkModeOptimized: darkModeOptimized ?? this.darkModeOptimized,
      fontSizeLevel: fontSizeLevel ?? this.fontSizeLevel,
      boldText: boldText ?? this.boldText,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      screenReaderOptimized: screenReaderOptimized ?? this.screenReaderOptimized,
      userContext: userContext ?? this.userContext,
      deviceType: deviceType ?? this.deviceType,
      layoutDensity: layoutDensity ?? this.layoutDensity,
      compactMode: compactMode ?? this.compactMode,
      touchOptimized: touchOptimized ?? this.touchOptimized,
    );
  }

  /// Converte para Map (para salvar no SharedPreferences)
  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.name,
      'colorScheme': colorScheme.name,
      'highContrast': highContrast,
      'darkModeOptimized': darkModeOptimized,
      'fontSizeLevel': fontSizeLevel.name,
      'boldText': boldText,
      'reduceMotion': reduceMotion,
      'screenReaderOptimized': screenReaderOptimized,
      'userContext': userContext.name,
      'deviceType': deviceType.name,
      'fieldOptimized': fieldOptimized,
      'layoutDensity': layoutDensity.name,
      'compactMode': compactMode,
      'touchOptimized': touchOptimized,
    };
  }

  /// Cria a partir de Map (do SharedPreferences)
  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == map['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      colorScheme: ColorSchemeType.values.firstWhere(
        (e) => e.name == map['colorScheme'],
        orElse: () => ColorSchemeType.adaptive,
      ),
      highContrast: map['highContrast'] ?? false,
      darkModeOptimized: map['darkModeOptimized'] ?? false,
      fontSizeLevel: FontSizeLevel.values.firstWhere(
        (e) => e.name == map['fontSizeLevel'],
        orElse: () => FontSizeLevel.medium,
      ),
      boldText: map['boldText'] ?? false,
      reduceMotion: map['reduceMotion'] ?? false,
      screenReaderOptimized: map['screenReaderOptimized'] ?? false,
      userContext: UserContext.values.firstWhere(
        (e) => e.name == map['userContext'],
        orElse: () => UserContext.general,
      ),
      deviceType: DeviceType.values.firstWhere(
        (e) => e.name == map['deviceType'],
        orElse: () => DeviceType.auto,
      ),
      fieldOptimized: map['fieldOptimized'] ?? false,
      layoutDensity: LayoutDensity.values.firstWhere(
        (e) => e.name == map['layoutDensity'],
        orElse: () => LayoutDensity.medium,
      ),
      compactMode: map['compactMode'] ?? false,
      touchOptimized: map['touchOptimized'] ?? false,
    );
  }

  /// Preferências padrão para campo
  factory UserPreferences.fieldOptimized() {
    return const UserPreferences(
      themeMode: ThemeMode.light,
      colorScheme: ColorSchemeType.highContrast,
      highContrast: true,
      fontSizeLevel: FontSizeLevel.large,
      boldText: true,
      userContext: UserContext.field,
      fieldOptimized: true,
      layoutDensity: LayoutDensity.loose,
      touchOptimized: true,
    );
  }

  /// Preferências padrão para escritório
  factory UserPreferences.officeOptimized() {
    return const UserPreferences(
      themeMode: ThemeMode.system,
      colorScheme: ColorSchemeType.adaptive,
      fontSizeLevel: FontSizeLevel.medium,
      userContext: UserContext.office,
      layoutDensity: LayoutDensity.medium,
      compactMode: false,
    );
  }

  /// Preferências para acessibilidade
  factory UserPreferences.accessibilityOptimized() {
    return const UserPreferences(
      themeMode: ThemeMode.light,
      colorScheme: ColorSchemeType.highContrast,
      highContrast: true,
      fontSizeLevel: FontSizeLevel.extraLarge,
      boldText: true,
      screenReaderOptimized: true,
      layoutDensity: LayoutDensity.loose,
      touchOptimized: true,
    );
  }
}

/// Modo do tema
enum ThemeMode {
  light,
  dark,
  system,
}

/// Tipo de esquema de cores
enum ColorSchemeType {
  adaptive,      // Adapta ao contexto
  highContrast,  // Alto contraste
  nature,        // Cores naturais (verde/terra)
  professional,  // Cores profissionais
  custom,        // Personalizado
}

/// Nível de tamanho da fonte
enum FontSizeLevel {
  extraSmall,  // 0.8x
  small,        // 0.9x
  medium,       // 1.0x (padrão)
  large,        // 1.2x
  extraLarge,   // 1.4x
  huge,         // 1.6x
}

/// Contexto do usuário
enum UserContext {
  general,      // Uso geral
  field,        // Campo
  office,       // Escritório
  laboratory,   // Laboratório
  warehouse,    // Armazém
}

/// Tipo de dispositivo
enum DeviceType {
  auto,         // Detecção automática
  smartphone,   // Smartphone
  tablet,       // Tablet
  desktop,      // Desktop
}

/// Densidade do layout
enum LayoutDensity {
  compact,      // Layout compacto
  medium,       // Layout médio
  loose,        // Layout espaçoso
}
