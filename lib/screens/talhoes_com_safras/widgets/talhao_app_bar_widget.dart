import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../talhao_diagnostic_screen.dart';

/// Widget personalizado para o AppBar da tela de talhões
class TalhaoAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final LatLng? userLocation;
  final VoidCallback onCenterGPS;
  final VoidCallback onReloadTalhoes;
  final VoidCallback onDebugTalhoes;

  const TalhaoAppBarWidget({
    Key? key,
    required this.userLocation,
    required this.onCenterGPS,
    required this.onReloadTalhoes,
    required this.onDebugTalhoes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Módulo de Polígonos'),
      backgroundColor: const Color(0xFF3BAA57),
      foregroundColor: Colors.white,
      actions: [
        // Botão de centralizar no GPS (sempre visível)
        IconButton(
          icon: Icon(
            userLocation != null ? Icons.my_location : Icons.location_searching,
            color: userLocation != null ? Colors.blue : Colors.white,
          ),
          onPressed: onCenterGPS,
          tooltip: userLocation != null ? 'Centralizar no GPS' : 'Obtendo localização...',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onReloadTalhoes,
          tooltip: 'Recarregar talhões',
        ),
        IconButton(
          icon: const Icon(Icons.analytics),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TalhaoDiagnosticScreen(),
              ),
            );
          },
          tooltip: 'Diagnóstico dos talhões',
        ),
        IconButton(
          icon: const Icon(Icons.bug_report),
          onPressed: onDebugTalhoes,
          tooltip: 'Debug dos talhões',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
