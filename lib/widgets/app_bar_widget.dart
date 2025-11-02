import 'package:flutter/material.dart';

/// Widget de AppBar personalizado para manter a consistência visual no aplicativo
class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? leading;
  final double elevation;
  final VoidCallback? onBackPressed;

  const AppBarWidget({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor,
    this.textColor,
    this.leading,
    this.elevation = 4.0,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      // backgroundColor: backgroundColor ?? Theme.of(context).primaryColor, // backgroundColor não é suportado em flutter_map 5.0.0
      elevation: elevation,
      leading: showBackButton
          ? leading ??
              IconButton(
                icon: const Icon(Icons.arrow_back),
                color: textColor ?? Colors.white,
                onPressed: onBackPressed ??
                    () {
                      Navigator.of(context).pop();
                    },
              )
          : null,
      automaticallyImplyLeading: showBackButton,
      actions: actions,
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
