import 'package:flutter/material.dart';
import '../routes.dart';

/// Widget de navegação para os módulos de mapas offline e download
class MapsNavigationWidget extends StatelessWidget {
  const MapsNavigationWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Módulos de Mapas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          
          // Card para Mapas Offline
          Card(
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.offline_bolt, color: Colors.blue),
              title: const Text(
                'Mapas Offline - DEV',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Gerencie mapas baixados para uso offline',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.offlineMapsManagement,
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Card para Download de Mapas
          Card(
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.download, color: Colors.orange),
              title: const Text(
                'Download de Mapas - DEV',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Baixe mapas de talhões e áreas livres',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.mapDownload,
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Card para Download Livre
          Card(
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.map, color: Colors.green),
              title: const Text(
                'Download Livre',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Selecione e baixe qualquer área do mapa',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.freeMapDownload,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
