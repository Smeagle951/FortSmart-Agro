import 'package:flutter/material.dart';

/// Dialog para configurações do GPS
class GpsSettingsDialog extends StatefulWidget {
  final Function(GpsSettings) onSave;

  const GpsSettingsDialog({
    Key? key,
    required this.onSave,
  }) : super(key: key);

  @override
  State<GpsSettingsDialog> createState() => _GpsSettingsDialogState();
}

class _GpsSettingsDialogState extends State<GpsSettingsDialog> {
  double _minAccuracy = 5.0;
  double _maxSpeed = 50.0;
  double _minDistance = 1.0;
  bool _smoothPoints = true;
  int _smoothingWindow = 3;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurações GPS'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Precisão mínima
            _buildSliderSetting(
              'Precisão Mínima (m)',
              _minAccuracy,
              1.0,
              20.0,
              (value) => setState(() => _minAccuracy = value),
            ),
            
            const SizedBox(height: 16),
            
            // Velocidade máxima
            _buildSliderSetting(
              'Velocidade Máxima (km/h)',
              _maxSpeed,
              10.0,
              100.0,
              (value) => setState(() => _maxSpeed = value),
            ),
            
            const SizedBox(height: 16),
            
            // Distância mínima
            _buildSliderSetting(
              'Distância Mínima (m)',
              _minDistance,
              0.5,
              10.0,
              (value) => setState(() => _minDistance = value),
            ),
            
            const SizedBox(height: 16),
            
            // Suavização
            SwitchListTile(
              title: const Text('Suavizar Pontos'),
              subtitle: const Text('Aplica filtro de média móvel'),
              value: _smoothPoints,
              onChanged: (value) => setState(() => _smoothPoints = value),
            ),
            
            if (_smoothPoints) ...[
              const SizedBox(height: 8),
              _buildSliderSetting(
                'Janela de Suavização',
                _smoothingWindow.toDouble(),
                3.0,
                10.0,
                (value) => setState(() => _smoothingWindow = value.round()),
                isInt: true,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final settings = GpsSettings(
              minAccuracy: _minAccuracy,
              maxSpeed: _maxSpeed,
              minDistance: _minDistance,
              smoothPoints: _smoothPoints,
              smoothingWindow: _smoothingWindow,
            );
            widget.onSave(settings);
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  Widget _buildSliderSetting(
    String title,
    double value,
    double min,
    double max,
    Function(double) onChanged, {
    bool isInt = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: isInt ? (max - min).round() : null,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              isInt ? value.round().toString() : value.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Configurações do GPS
class GpsSettings {
  final double minAccuracy;
  final double maxSpeed;
  final double minDistance;
  final bool smoothPoints;
  final int smoothingWindow;

  GpsSettings({
    required this.minAccuracy,
    required this.maxSpeed,
    required this.minDistance,
    required this.smoothPoints,
    required this.smoothingWindow,
  });
}
