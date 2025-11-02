import 'package:flutter/material.dart';
import '../../widgets/responsive/responsive_widgets.dart';
import '../../widgets/responsive/responsive_themed_widgets.dart';
import '../../services/dynamic_theme_manager.dart';
import '../../models/user_preferences.dart';

/// Tela de configurações de tema responsiva
class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  late DynamicThemeManager _themeManager;
  late UserPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _themeManager = DynamicThemeManager();
    _preferences = _themeManager.preferences;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ResponsiveTitle('Configurações de Tema'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
        child: _buildMobileLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return ResponsivePadding(
      all: 16.0,
      child: ResponsiveList(
        children: [
          _buildThemeSection(),
          ResponsiveSizedBox(height: 24.0),
          _buildAccessibilitySection(),
          ResponsiveSizedBox(height: 24.0),
          _buildContextSection(),
          ResponsiveSizedBox(height: 24.0),
          _buildLayoutSection(),
          ResponsiveSizedBox(height: 24.0),
          _buildPresetSection(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return ResponsivePadding(
      all: 24.0,
      child: ResponsiveGrid(
        crossAxisCount: 2,
        children: [
          _buildThemeSection(),
          _buildAccessibilitySection(),
          _buildContextSection(),
          _buildLayoutSection(),
          _buildPresetSection(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return ResponsivePadding(
      all: 32.0,
      child: ResponsiveGrid(
        crossAxisCount: 3,
        children: [
          _buildThemeSection(),
          _buildAccessibilitySection(),
          _buildContextSection(),
          _buildLayoutSection(),
          _buildPresetSection(),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return ResponsiveCard(
      padding: EdgeInsets.all(ResponsiveScreenUtils.scale(context, 16.0)),
      child: ResponsiveColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveSubtitle('Tema', fontSize: 18.0),
          ResponsiveSizedBox(height: 16.0),
          ResponsiveColumn(
            children: [
              _buildThemeModeSelector(),
              ResponsiveSizedBox(height: 16.0),
              _buildColorSchemeSelector(),
              ResponsiveSizedBox(height: 16.0),
              _buildHighContrastToggle(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilitySection() {
    return ResponsiveCard(
      padding: EdgeInsets.all(ResponsiveScreenUtils.scale(context, 16.0)),
      child: ResponsiveColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveSubtitle('Acessibilidade', fontSize: 18.0),
          ResponsiveSizedBox(height: 16.0),
          ResponsiveColumn(
            children: [
              _buildFontSizeSelector(),
              ResponsiveSizedBox(height: 16.0),
              _buildBoldTextToggle(),
              ResponsiveSizedBox(height: 16.0),
              _buildScreenReaderToggle(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContextSection() {
    return ResponsiveCard(
      padding: EdgeInsets.all(ResponsiveScreenUtils.scale(context, 16.0)),
      child: ResponsiveColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveSubtitle('Contexto de Uso', fontSize: 18.0),
          ResponsiveSizedBox(height: 16.0),
          ResponsiveColumn(
            children: [
              _buildUserContextSelector(),
              ResponsiveSizedBox(height: 16.0),
              _buildFieldOptimizedToggle(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutSection() {
    return ResponsiveCard(
      padding: EdgeInsets.all(ResponsiveScreenUtils.scale(context, 16.0)),
      child: ResponsiveColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveSubtitle('Layout', fontSize: 18.0),
          ResponsiveSizedBox(height: 16.0),
          ResponsiveColumn(
            children: [
              _buildLayoutDensitySelector(),
              ResponsiveSizedBox(height: 16.0),
              _buildCompactModeToggle(),
              ResponsiveSizedBox(height: 16.0),
              _buildTouchOptimizedToggle(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSection() {
    return ResponsiveCard(
      padding: EdgeInsets.all(ResponsiveScreenUtils.scale(context, 16.0)),
      child: ResponsiveColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveSubtitle('Configurações Rápidas', fontSize: 18.0),
          ResponsiveSizedBox(height: 16.0),
          ResponsiveColumn(
            children: [
              ResponsiveButton(
                text: 'Acessibilidade Total',
                icon: Icon(Icons.accessibility),
                onPressed: () => _applyAccessibilitySettings(),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                isFullWidth: true,
              ),
              ResponsiveSizedBox(height: 12.0),
              ResponsiveButton(
                text: 'Otimizado para Campo',
                icon: Icon(Icons.agriculture),
                onPressed: () => _applyFieldSettings(),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                isFullWidth: true,
              ),
              ResponsiveSizedBox(height: 12.0),
              ResponsiveButton(
                text: 'Otimizado para Escritório',
                icon: Icon(Icons.business),
                onPressed: () => _applyOfficeSettings(),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                isFullWidth: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeSelector() {
    return ResponsiveColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveBodyText('Modo do Tema', fontSize: 14.0),
        ResponsiveSizedBox(height: 8.0),
        ResponsiveRow(
          children: [
            Expanded(
              child: ResponsiveButton(
                text: 'Claro',
                onPressed: () => _updateThemeMode(ThemeMode.light),
                isOutlined: _preferences.themeMode != ThemeMode.light,
                backgroundColor: _preferences.themeMode == ThemeMode.light 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
                foregroundColor: _preferences.themeMode == ThemeMode.light 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            ResponsiveSizedBox(width: 8.0),
            Expanded(
              child: ResponsiveButton(
                text: 'Escuro',
                onPressed: () => _updateThemeMode(ThemeMode.dark),
                isOutlined: _preferences.themeMode != ThemeMode.dark,
                backgroundColor: _preferences.themeMode == ThemeMode.dark 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
                foregroundColor: _preferences.themeMode == ThemeMode.dark 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            ResponsiveSizedBox(width: 8.0),
            Expanded(
              child: ResponsiveButton(
                text: 'Sistema',
                onPressed: () => _updateThemeMode(ThemeMode.system),
                isOutlined: _preferences.themeMode != ThemeMode.system,
                backgroundColor: _preferences.themeMode == ThemeMode.system 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
                foregroundColor: _preferences.themeMode == ThemeMode.system 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSchemeSelector() {
    return ResponsiveColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveBodyText('Esquema de Cores', fontSize: 14.0),
        ResponsiveSizedBox(height: 8.0),
        ResponsiveRow(
          children: [
            Expanded(
              child: ResponsiveButton(
                text: 'Adaptativo',
                onPressed: () => _updateColorScheme(ColorSchemeType.adaptive),
                isOutlined: _preferences.colorScheme != ColorSchemeType.adaptive,
                backgroundColor: _preferences.colorScheme == ColorSchemeType.adaptive 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
                foregroundColor: _preferences.colorScheme == ColorSchemeType.adaptive 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            ResponsiveSizedBox(width: 8.0),
            Expanded(
              child: ResponsiveButton(
                text: 'Alto Contraste',
                onPressed: () => _updateColorScheme(ColorSchemeType.highContrast),
                isOutlined: _preferences.colorScheme != ColorSchemeType.highContrast,
                backgroundColor: _preferences.colorScheme == ColorSchemeType.highContrast 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
                foregroundColor: _preferences.colorScheme == ColorSchemeType.highContrast 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        ResponsiveSizedBox(height: 8.0),
        ResponsiveRow(
          children: [
            Expanded(
              child: ResponsiveButton(
                text: 'Natureza',
                onPressed: () => _updateColorScheme(ColorSchemeType.nature),
                isOutlined: _preferences.colorScheme != ColorSchemeType.nature,
                backgroundColor: _preferences.colorScheme == ColorSchemeType.nature 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
                foregroundColor: _preferences.colorScheme == ColorSchemeType.nature 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            ResponsiveSizedBox(width: 8.0),
            Expanded(
              child: ResponsiveButton(
                text: 'Profissional',
                onPressed: () => _updateColorScheme(ColorSchemeType.professional),
                isOutlined: _preferences.colorScheme != ColorSchemeType.professional,
                backgroundColor: _preferences.colorScheme == ColorSchemeType.professional 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
                foregroundColor: _preferences.colorScheme == ColorSchemeType.professional 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighContrastToggle() {
    return ResponsiveRow(
      children: [
        Expanded(
          child: ResponsiveBodyText('Alto Contraste', fontSize: 14.0),
        ),
        Switch(
          value: _preferences.highContrast,
          onChanged: (value) => _updateHighContrast(value),
        ),
      ],
    );
  }

  Widget _buildFontSizeSelector() {
    return ResponsiveColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveBodyText('Tamanho da Fonte', fontSize: 14.0),
        ResponsiveSizedBox(height: 8.0),
        ResponsiveRow(
          children: [
            Expanded(
              child: ResponsiveButton(
                text: 'Pequena',
                onPressed: () => _updateFontSize(FontSizeLevel.small),
                isOutlined: _preferences.fontSizeLevel != FontSizeLevel.small,
                backgroundColor: _preferences.fontSizeLevel == FontSizeLevel.small 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
                foregroundColor: _preferences.fontSizeLevel == FontSizeLevel.small 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            ResponsiveSizedBox(width: 8.0),
            Expanded(
              child: ResponsiveButton(
                text: 'Média',
                onPressed: () => _updateFontSize(FontSizeLevel.medium),
                isOutlined: _preferences.fontSizeLevel != FontSizeLevel.medium,
                backgroundColor: _preferences.fontSizeLevel == FontSizeLevel.medium 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
                foregroundColor: _preferences.fontSizeLevel == FontSizeLevel.medium 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            ResponsiveSizedBox(width: 8.0),
            Expanded(
              child: ResponsiveButton(
                text: 'Grande',
                onPressed: () => _updateFontSize(FontSizeLevel.large),
                isOutlined: _preferences.fontSizeLevel != FontSizeLevel.large,
                backgroundColor: _preferences.fontSizeLevel == FontSizeLevel.large 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
                foregroundColor: _preferences.fontSizeLevel == FontSizeLevel.large 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBoldTextToggle() {
    return ResponsiveRow(
      children: [
        Expanded(
          child: ResponsiveBodyText('Texto em Negrito', fontSize: 14.0),
        ),
        Switch(
          value: _preferences.boldText,
          onChanged: (value) => _updateBoldText(value),
        ),
      ],
    );
  }

  Widget _buildScreenReaderToggle() {
    return ResponsiveRow(
      children: [
        Expanded(
          child: ResponsiveBodyText('Otimizado para Leitor de Tela', fontSize: 14.0),
        ),
        Switch(
          value: _preferences.screenReaderOptimized,
          onChanged: (value) => _updateScreenReaderOptimized(value),
        ),
      ],
    );
  }

  Widget _buildUserContextSelector() {
    return ResponsiveColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveBodyText('Contexto de Uso', fontSize: 14.0),
        ResponsiveSizedBox(height: 8.0),
        ResponsiveRow(
          children: [
            Expanded(
              child: ResponsiveButton(
                text: 'Campo',
                onPressed: () => _updateUserContext(UserContext.field),
                isOutlined: _preferences.userContext != UserContext.field,
                backgroundColor: _preferences.userContext == UserContext.field 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
                foregroundColor: _preferences.userContext == UserContext.field 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            ResponsiveSizedBox(width: 8.0),
            Expanded(
              child: ResponsiveButton(
                text: 'Escritório',
                onPressed: () => _updateUserContext(UserContext.office),
                isOutlined: _preferences.userContext != UserContext.office,
                backgroundColor: _preferences.userContext == UserContext.office 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
                foregroundColor: _preferences.userContext == UserContext.office 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFieldOptimizedToggle() {
    return ResponsiveRow(
      children: [
        Expanded(
          child: ResponsiveBodyText('Otimizado para Campo', fontSize: 14.0),
        ),
        Switch(
          value: _preferences.fieldOptimized,
          onChanged: (value) => _updateFieldOptimized(value),
        ),
      ],
    );
  }

  Widget _buildLayoutDensitySelector() {
    return ResponsiveColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveBodyText('Densidade do Layout', fontSize: 14.0),
        ResponsiveSizedBox(height: 8.0),
        ResponsiveRow(
          children: [
            Expanded(
              child: ResponsiveButton(
                text: 'Compacto',
                onPressed: () => _updateLayoutDensity(LayoutDensity.compact),
                isOutlined: _preferences.layoutDensity != LayoutDensity.compact,
                backgroundColor: _preferences.layoutDensity == LayoutDensity.compact 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
                foregroundColor: _preferences.layoutDensity == LayoutDensity.compact 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            ResponsiveSizedBox(width: 8.0),
            Expanded(
              child: ResponsiveButton(
                text: 'Médio',
                onPressed: () => _updateLayoutDensity(LayoutDensity.medium),
                isOutlined: _preferences.layoutDensity != LayoutDensity.medium,
                backgroundColor: _preferences.layoutDensity == LayoutDensity.medium 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
                foregroundColor: _preferences.layoutDensity == LayoutDensity.medium 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            ResponsiveSizedBox(width: 8.0),
            Expanded(
              child: ResponsiveButton(
                text: 'Espaçoso',
                onPressed: () => _updateLayoutDensity(LayoutDensity.loose),
                isOutlined: _preferences.layoutDensity != LayoutDensity.loose,
                backgroundColor: _preferences.layoutDensity == LayoutDensity.loose 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
                foregroundColor: _preferences.layoutDensity == LayoutDensity.loose 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactModeToggle() {
    return ResponsiveRow(
      children: [
        Expanded(
          child: ResponsiveBodyText('Modo Compacto', fontSize: 14.0),
        ),
        Switch(
          value: _preferences.compactMode,
          onChanged: (value) => _updateCompactMode(value),
        ),
      ],
    );
  }

  Widget _buildTouchOptimizedToggle() {
    return ResponsiveRow(
      children: [
        Expanded(
          child: ResponsiveBodyText('Otimizado para Toque', fontSize: 14.0),
        ),
        Switch(
          value: _preferences.touchOptimized,
          onChanged: (value) => _updateTouchOptimized(value),
        ),
      ],
    );
  }

  // Métodos de atualização
  void _updateThemeMode(ThemeMode themeMode) {
    setState(() {
      _preferences = _preferences.copyWith(themeMode: themeMode);
    });
    _themeManager.updateThemeMode(themeMode);
  }

  void _updateColorScheme(ColorSchemeType colorScheme) {
    setState(() {
      _preferences = _preferences.copyWith(colorScheme: colorScheme);
    });
    _themeManager.updateColorScheme(colorScheme);
  }

  void _updateHighContrast(bool highContrast) {
    setState(() {
      _preferences = _preferences.copyWith(highContrast: highContrast);
    });
    _themeManager.updateHighContrast(highContrast);
  }

  void _updateFontSize(FontSizeLevel fontSizeLevel) {
    setState(() {
      _preferences = _preferences.copyWith(fontSizeLevel: fontSizeLevel);
    });
    _themeManager.updateFontSize(fontSizeLevel);
  }

  void _updateBoldText(bool boldText) {
    setState(() {
      _preferences = _preferences.copyWith(boldText: boldText);
    });
    _themeManager.updatePreferences(_preferences);
  }

  void _updateScreenReaderOptimized(bool screenReaderOptimized) {
    setState(() {
      _preferences = _preferences.copyWith(screenReaderOptimized: screenReaderOptimized);
    });
    _themeManager.updatePreferences(_preferences);
  }

  void _updateUserContext(UserContext userContext) {
    setState(() {
      _preferences = _preferences.copyWith(userContext: userContext);
    });
    _themeManager.updateUserContext(userContext);
  }

  void _updateFieldOptimized(bool fieldOptimized) {
    setState(() {
      _preferences = _preferences.copyWith(fieldOptimized: fieldOptimized);
    });
    _themeManager.updateFieldOptimized(fieldOptimized);
  }

  void _updateLayoutDensity(LayoutDensity layoutDensity) {
    setState(() {
      _preferences = _preferences.copyWith(layoutDensity: layoutDensity);
    });
    _themeManager.updatePreferences(_preferences);
  }

  void _updateCompactMode(bool compactMode) {
    setState(() {
      _preferences = _preferences.copyWith(compactMode: compactMode);
    });
    _themeManager.updatePreferences(_preferences);
  }

  void _updateTouchOptimized(bool touchOptimized) {
    setState(() {
      _preferences = _preferences.copyWith(touchOptimized: touchOptimized);
    });
    _themeManager.updatePreferences(_preferences);
  }

  // Métodos de configurações rápidas
  void _applyAccessibilitySettings() {
    _themeManager.applyAccessibilitySettings();
    setState(() {
      _preferences = _themeManager.preferences;
    });
  }

  void _applyFieldSettings() {
    _themeManager.applyFieldSettings();
    setState(() {
      _preferences = _themeManager.preferences;
    });
  }

  void _applyOfficeSettings() {
    _themeManager.applyOfficeSettings();
    setState(() {
      _preferences = _themeManager.preferences;
    });
  }
}
