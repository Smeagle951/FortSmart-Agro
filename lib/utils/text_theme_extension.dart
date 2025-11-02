import 'package:flutter/material.dart';

/// Extension to provide backward compatibility for deprecated text theme properties
extension TextThemeExtension on TextTheme {
  /// Provides backward compatibility for headline5 (now headlineSmall)
  TextStyle get headline5 => headlineSmall ?? const TextStyle();
  
  /// Provides backward compatibility for headline6 (now titleLarge)
  TextStyle get headline6 => titleLarge ?? const TextStyle();
  
  /// Provides backward compatibility for subtitle1 (now titleMedium)
  TextStyle get subtitle1 => titleMedium ?? const TextStyle();
  
  /// Provides backward compatibility for subtitle2 (now titleSmall)
  TextStyle get subtitle2 => titleSmall ?? const TextStyle();
  
  /// Provides backward compatibility for bodyText1 (now bodyLarge)
  TextStyle get bodyText1 => bodyLarge ?? const TextStyle();
  
  /// Provides backward compatibility for bodyText2 (now bodyMedium)
  TextStyle get bodyText2 => bodyMedium ?? const TextStyle();
  
  /// Provides backward compatibility for button (now labelLarge)
  TextStyle get button => labelLarge ?? const TextStyle();
  
  /// Provides backward compatibility for caption (now bodySmall)
  TextStyle get caption => bodySmall ?? const TextStyle();
  
  /// Provides backward compatibility for overline (now labelSmall)
  TextStyle get overline => labelSmall ?? const TextStyle();
}
