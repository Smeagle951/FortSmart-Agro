import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../models/monitoring_alert.dart';
import '../../repositories/monitoring_repository.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_dialog.dart';

class AlertDetailsScreen extends StatefulWidget {
  final String alertId;
  
  const AlertDetailsScreen({
    Key? key,
    required this.alertId,
  }) : super(key: key);

  @override
  _AlertDetailsScreenState createState() => _AlertDetailsScreenState();
}

class _AlertDetailsScreenState extends State<AlertDetailsScreen> {
  final MonitoringRepository _monitoringRepository = MonitoringRepository();
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  bool _isResolving = false;
  String _errorMessage = '';
  MonitoringAlert? _alert;
  
  @override
  void initState() {
    super.initState();
    _loadAlertDetails();
  }
  
  Future<void> _loadAlertDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final alert = await _monitoringRepository.getAlertById(widget.alertId);
      setState(() {
        _alert = alert;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar detalhes do alerta: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _resolveAlert() async {
    setState(() {
      _isResolving = true;
    });
    
    try {
      await _apiService.resolveAlert(widget.alertId);
      await _loadAlertDetails();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alerta resolvido com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao resolver alerta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isResolving = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Alerta'),
        backgroundColor: const Color(0xFF2A4F3D),
        elevation: 0,
        actions: [
          if (_alert != null && !_alert!.isResolved)
            IconButton(
              icon: Icon(Icons.check_circle_outline),
              onPressed: _isResolving ? null : _resolveAlert,
              tooltip: 'Marcar como resolvido',
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? LoadingIndicator(message: 'Carregando detalhes do alerta...')
          : _errorMessage.isNotEmpty
              ? ErrorDialog(
                  message: _errorMessage,
                  onRetry: _loadAlertDetails,
                )
              : _buildAlertDetails(),
    );
  }
  
  Widget _buildAlertDetails() {
    if (_alert == null) {
      return Center(
        child: Text(
          'Alerta não encontrado',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2A4F3D).withOpacity(0.8),
            const Color(0xFF1A2A20).withOpacity(0.9),
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com status
            _buildAlertHeader(),
            
            // Detalhes do alerta
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  SizedBox(height: 16),
                  _buildMediaSection(),
                  SizedBox(height: 16),
                  _buildNotesSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAlertHeader() {
    Color statusColor;
    String statusText;
    
    if (_alert!.isResolved) {
      statusColor = Colors.green;
      statusText = 'Resolvido';
    } else if (_alert!.severity == 'critical') {
      statusColor = Colors.red;
      statusText = 'Crítico';
    } else if (_alert!.severity == 'warning') {
      statusColor = Colors.orange;
      statusText = 'Atenção';
    } else {
      statusColor = Colors.blue;
      statusText = 'Informação';
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: MediaQuery.of(context).padding.top + 76,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(_alert!.date),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _alert!.pestName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Talhão: ${_alert!.plotName}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return _buildGlassmorphicCard(
      title: 'Informações',
      child: Column(
        children: [
          _buildInfoRow('Tipo de Praga', _alert!.pestName),
          Divider(color: Colors.white24),
          _buildInfoRow('Severidade', _alert!.severity),
          Divider(color: Colors.white24),
          _buildInfoRow('Data de Detecção', DateFormat('dd/MM/yyyy HH:mm').format(_alert!.date)),
          Divider(color: Colors.white24),
          _buildInfoRow('Localização', 'Talhão: ${_alert!.plotName}'),
          if (_alert!.gpsLocation != null) ...[
            Divider(color: Colors.white24),
            _buildInfoRow('Coordenadas GPS', _alert!.gpsLocation!),
          ],
          if (_alert!.isResolved) ...[
            Divider(color: Colors.white24),
            _buildInfoRow('Data de Resolução', 
                _alert!.resolutionDate != null 
                    ? DateFormat('dd/MM/yyyy HH:mm').format(_alert!.resolutionDate!) 
                    : 'Não informada'),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMediaSection() {
    return _buildGlassmorphicCard(
      title: 'Mídia',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_alert!.images != null && _alert!.images!.isNotEmpty)
            _buildImageGrid(_alert!.images!)
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.white54,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Nenhuma imagem disponível',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          if (_alert!.audioUrl != null) ...[
            SizedBox(height: 16),
            Text(
              'Gravação de Áudio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.audio_file,
                    color: Colors.white70,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Gravação de ${_alert!.pestName}',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.play_circle_fill,
                      color: Color(0xFF00FF66),
                    ),
                    onPressed: () {
                      // Implementar reprodução de áudio
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reprodução de áudio não implementada'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildImageGrid(List<String> imageUrls) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // Abrir visualizador de imagem em tela cheia
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  body: Center(
                    child: Image.network(
                      imageUrls[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                  backgroundColor: Colors.black,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(imageUrls[index]),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildNotesSection() {
    return _buildGlassmorphicCard(
      title: 'Observações',
      child: _alert!.description != null && _alert!.description!.isNotEmpty
          ? Text(
              _alert!.description!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Nenhuma observação registrada',
                  style: TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
    );
  }
  
  Widget _buildGlassmorphicCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
