import 'package:flutter/material.dart';

/// Classe que define a paleta de cores e estilos para o FortSmart Agro
/// seguindo o estilo Google Material Design 3
class FortSmartTheme {
  // Cores principais
  static const Color backgroundPrimary = Color(0xFFF9FAFB); // Cinza claro suave
  static const Color appBarColor = Color(0xFF1565C0);       // Azul neutro elegante
  static const Color primaryButton = Color(0xFF1E88E5);     // Azul Google moderno
  static const Color secondaryButton = Color(0xFF90A4AE);   // Cinza médio
  
  // Cores de texto
  static const Color textPrimary = Color(0xFF212121);       // Cinza escuro
  static const Color textSecondary = Color(0xFF616161);     // Cinza médio
  
  // Cores de containers
  static const Color cardBackground = Color(0xFFFFFFFF);    // Branco puro
  static const Color inputBackground = Color(0xFFF5F5F5);   // Branco gelo
  static const Color inputBorderFocus = Color(0xFF42A5F5);  // Azul Google leve
  
  // Cores de ícones e detalhes
  static const Color iconColor = Color(0xFF64B5F6);         // Azul claro suave
  
  // Cores de alertas
  static const Color errorColor = Color(0xFFE53935);        // Vermelho suave
  static const Color warningColor = Color(0xFFFDD835);      // Amarelo alerta
  static const Color successColor = Color(0xFF43A047);      // Verde profissional
  
  // Cores específicas para o módulo de plantio
  static const Color plantioAppBar = Color(0xFF1565C0);     // Azul neutro elegante
  static const Color plantioBackground = Color(0xFFF9FAFB);  // Cinza claro suave
  static const Color plantioCard = Color(0xFFFFFFFF);       // Branco puro
  static const Color plantioInput = Color(0xFFF5F5F5);      // Fundo de input
  static const Color plantioInputFocus = Color(0xFF42A5F5); // Borda de foco
  static const Color plantioPrimary = Color(0xFF1E88E5);    // Botão principal
  static const Color plantioSecondary = Color(0xFF90A4AE);  // Botão secundário
  static const Color plantioIcon = Color(0xFF64B5F6);       // Ícones

  // Cores adicionais para experimentos
  static const Color accentColor = Color(0xFF42A5F5);

  // Estilos de texto
  static const TextStyle titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle headingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    color: textPrimary,
  );
  
  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    color: textSecondary,
  );

  // Estilos de botões
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryButton,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
  
  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: secondaryButton,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  // Decoração para inputs
  static InputDecoration Function(String) inputDecoration = (String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: inputBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: inputBorderFocus, width: 2),
    ),
  );

  // Método para criar InputDecoration com customizações
  static InputDecoration createInputDecoration(String label, {
    String? hintText,
    IconData? prefixIcon,
    Color? prefixIconColor,
    Widget? suffixIcon,
    Color? borderColor,
    double? borderWidth,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: inputBackground,
      prefixIcon: prefixIcon != null 
        ? Icon(prefixIcon, color: prefixIconColor ?? inputBorderFocus)
        : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: borderColor ?? inputBorderFocus, 
          width: borderWidth ?? 2,
        ),
      ),
    );
  }

  // Decoração para cards
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Cores legadas (mantidas para compatibilidade)
  static const Color primaryColor = Color(0xFF1E88E5);  // Azul Google moderno
  static const Color backgroundColor = backgroundPrimary;
}
