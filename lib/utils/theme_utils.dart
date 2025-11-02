import 'package:flutter/material.dart';

/// Utilitário para padronização de cores e estilos do tema do aplicativo
class ThemeUtils {
  // Cores principais
  static final Color primaryColor = Color(0xFF1B5E20); // Verde escuro
  static final Color accentColor = Color(0xFF4CAF50);  // Verde médio
  static final Color secondaryColor = Color(0xFF8BC34A); // Verde claro
  static final Color backgroundColor = Color(0xFFF5F5F5); // Cinza claro
  
  // Cores de texto
  static final Color textPrimaryColor = Color(0xFF212121); // Quase preto
  static final Color textSecondaryColor = Color(0xFF757575); // Cinza médio
  static final Color textLightColor = Color(0xFFFFFFFF); // Branco
  
  // Cores de status
  static final Color successColor = Color(0xFF4CAF50); // Verde
  static final Color errorColor = Color(0xFFF44336); // Vermelho
  static final Color warningColor = Color(0xFFFF9800); // Laranja
  static final Color infoColor = Color(0xFF2196F3); // Azul
  
  // Estilos de texto
  static final TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );
  
  static final TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
  );
  
  static final TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: textPrimaryColor,
  );
  
  static final TextStyle captionStyle = TextStyle(
    fontSize: 14,
    color: textSecondaryColor,
  );
  
  // Estilos de botões
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: textLightColor,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
  
  static final ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: primaryColor,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: primaryColor),
    ),
  );
  
  // Estilos de cards
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  );
  
  // Estilos de inputs
  static final InputDecoration inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}
