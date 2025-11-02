import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/talhoes/talhao_safra_model.dart';
import '../models/cultura_model.dart';
import '../utils/area_formatter.dart';

/// Card elegante com fundo de vidro transparente para exibir informações do talhão
class ElegantTalhaoCard extends StatefulWidget {
  final TalhaoSafraModel? selectedTalhao;
  final List<CulturaModel>? culturas;
  final VoidCallback? onClose;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ElegantTalhaoCard({
    Key? key,
    this.selectedTalhao,
    this.culturas,
    this.onClose,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  State<ElegantTalhaoCard> createState() => _ElegantTalhaoCardState();
}

class _ElegantTalhaoCardState extends State<ElegantTalhaoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedTalhao == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildCard(),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Fundo de vidro transparente elegante
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 0),
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildContent(),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final cultura = _getCulturaAtual();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.3),
            Colors.green.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Ícone elegante da cultura
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              _getCulturaIcon(cultura?.name),
              color: Colors.white,
              size: 28,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Informações principais
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedTalhao!.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  cultura?.name ?? 'Cultura não definida',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Botão fechar
          if (widget.onClose != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: IconButton(
                onPressed: widget.onClose,
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final cultura = _getCulturaAtual();
    final area = _calculateAreaTotal();
    final safra = _getSafraAtual();
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Área
          _buildInfoRow(
            icon: Icons.area_chart,
            iconColor: Colors.greenAccent,
            title: 'Área Total',
            value: AreaFormatter.formatArea(area),
            subtitle: 'hectares',
          ),
          
          const SizedBox(height: 16),
          
          // Safra
          if (safra.isNotEmpty)
            _buildInfoRow(
              icon: Icons.calendar_today,
              iconColor: Colors.blueAccent,
              title: 'Safra Atual',
              value: safra,
              subtitle: 'temporada',
            ),
          
          if (safra.isNotEmpty) const SizedBox(height: 16),
          
          // Perímetro
          _buildInfoRow(
            icon: Icons.straighten,
            iconColor: Colors.orangeAccent,
            title: 'Perímetro',
            value: '${_calculatePerimetroTotal().toStringAsFixed(1)} m',
            subtitle: 'total',
          ),
          
          const SizedBox(height: 16),
          
          // Data de criação
          _buildInfoRow(
            icon: Icons.access_time,
            iconColor: Colors.purpleAccent,
            title: 'Criado em',
            value: _formatDate(widget.selectedTalhao!.dataCriacao),
            subtitle: 'data de criação',
          ),
          
          const SizedBox(height: 16),
          
          // Status de sincronização
          _buildInfoRow(
            icon: Icons.sync,
            iconColor: widget.selectedTalhao!.sincronizado ? Colors.greenAccent : Colors.redAccent,
            title: 'Status',
            value: widget.selectedTalhao!.sincronizado ? 'Sincronizado' : 'Pendente',
            subtitle: 'sincronização',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Botão Editar
          Expanded(
            child: _buildActionButton(
              onPressed: widget.onEdit,
              icon: Icons.edit,
              label: 'Editar',
              color: Colors.blueAccent,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Botão Deletar
          Expanded(
            child: _buildActionButton(
              onPressed: widget.onDelete,
              icon: Icons.delete,
              label: 'Deletar',
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Métodos auxiliares
  CulturaModel? _getCulturaAtual() {
    if (widget.culturas == null || widget.selectedTalhao == null) return null;
    
    try {
      if (widget.selectedTalhao!.safras.isNotEmpty) {
        final safra = widget.selectedTalhao!.safras.first;
        final culturaNome = safra.culturaNome;
        
        return widget.culturas!.firstWhere(
          (c) => c.name.toLowerCase().trim() == culturaNome.toLowerCase().trim(),
          orElse: () => CulturaModel(id: '0', name: 'Padrão', color: Colors.green),
        );
      }
    } catch (e) {
      print('❌ Erro ao obter cultura atual: $e');
    }
    
    return null;
  }

  String _getSafraAtual() {
    try {
      if (widget.selectedTalhao!.safras.isNotEmpty) {
        return widget.selectedTalhao!.safras.first.idSafra ?? 'Safra não definida';
      }
    } catch (e) {
      print('❌ Erro ao obter safra atual: $e');
    }
    
    return '';
  }

  double _calculateAreaTotal() {
    try {
      if (widget.selectedTalhao!.area != null) {
        return widget.selectedTalhao!.area!;
      }
      
      double areaTotal = 0.0;
      for (final poligono in widget.selectedTalhao!.poligonos) {
        areaTotal += poligono.area;
      }
      return areaTotal;
    } catch (e) {
      print('❌ Erro ao calcular área total: $e');
      return 0.0;
    }
  }

  double _calculatePerimetroTotal() {
    try {
      double perimetroTotal = 0.0;
      for (final poligono in widget.selectedTalhao!.poligonos) {
        perimetroTotal += poligono.perimetro;
      }
      return perimetroTotal;
    } catch (e) {
      print('❌ Erro ao calcular perímetro total: $e');
      return 0.0;
    }
  }

  String _formatDate(DateTime date) {
    try {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'Data inválida';
    }
  }

  /// Obtém ícone elegante da biblioteca Flutter baseado no nome da cultura
  IconData _getCulturaIcon(String? culturaNome) {
    if (culturaNome == null) return Icons.agriculture;
    
    final name = culturaNome.toLowerCase();
    
    // Ícones elegantes da biblioteca Flutter
    if (name.contains('soja')) return Icons.grass;
    if (name.contains('milho')) return Icons.eco;
    if (name.contains('algodão') || name.contains('algodao')) return Icons.local_florist;
    if (name.contains('feijão') || name.contains('feijao')) return Icons.egg;
    if (name.contains('trigo')) return Icons.grain;
    if (name.contains('arroz')) return Icons.water_drop;
    if (name.contains('aveia')) return Icons.grass;
    if (name.contains('gergelim')) return Icons.circle;
    if (name.contains('girassol')) return Icons.wb_sunny;
    if (name.contains('sorgo')) return Icons.grass;
    if (name.contains('café') || name.contains('cafe')) return Icons.local_cafe;
    if (name.contains('cana')) return Icons.forest;
    if (name.contains('tomate')) return Icons.circle;
    if (name.contains('batata')) return Icons.circle;
    if (name.contains('cenoura')) return Icons.circle;
    if (name.contains('alface')) return Icons.grass;
    if (name.contains('repolho')) return Icons.circle;
    if (name.contains('couve')) return Icons.grass;
    if (name.contains('brócolis') || name.contains('brocolis')) return Icons.grass;
    if (name.contains('espinafre')) return Icons.grass;
    if (name.contains('cebola')) return Icons.circle;
    if (name.contains('alho')) return Icons.circle;
    if (name.contains('pimentão') || name.contains('pimentao')) return Icons.circle;
    if (name.contains('pimenta')) return Icons.local_fire_department;
    if (name.contains('berinjela') || name.contains('beringela')) return Icons.circle;
    if (name.contains('abobrinha')) return Icons.circle;
    if (name.contains('abóbora') || name.contains('abobora')) return Icons.circle;
    if (name.contains('melancia')) return Icons.circle;
    if (name.contains('melão') || name.contains('melao')) return Icons.circle;
    if (name.contains('uva')) return Icons.circle;
    if (name.contains('maçã') || name.contains('maca')) return Icons.circle;
    if (name.contains('banana')) return Icons.circle;
    if (name.contains('laranja')) return Icons.circle;
    if (name.contains('limão') || name.contains('limao')) return Icons.circle;
    if (name.contains('manga')) return Icons.circle;
    if (name.contains('abacaxi')) return Icons.circle;
    if (name.contains('morango')) return Icons.circle;
    if (name.contains('pêssego') || name.contains('pessego')) return Icons.circle;
    if (name.contains('pera')) return Icons.circle;
    if (name.contains('kiwi')) return Icons.circle;
    if (name.contains('coco')) return Icons.circle;
    if (name.contains('castanha')) return Icons.circle;
    if (name.contains('amendoim')) return Icons.circle;
    if (name.contains('amêndoa') || name.contains('amendoa')) return Icons.circle;
    if (name.contains('noz')) return Icons.circle;
    if (name.contains('avelã') || name.contains('avela')) return Icons.circle;
    if (name.contains('pistache')) return Icons.circle;
    if (name.contains('caju')) return Icons.circle;
    if (name.contains('açaí') || name.contains('acai')) return Icons.circle;
    if (name.contains('guaraná') || name.contains('guarana')) return Icons.circle;
    if (name.contains('cupuaçu') || name.contains('cupuacu')) return Icons.circle;
    if (name.contains('graviola')) return Icons.circle;
    if (name.contains('maracujá') || name.contains('maracuja')) return Icons.circle;
    if (name.contains('cacau')) return Icons.circle;
    if (name.contains('café') || name.contains('cafe')) return Icons.local_cafe;
    if (name.contains('chá') || name.contains('cha')) return Icons.local_cafe;
    if (name.contains('mate')) return Icons.local_cafe;
    if (name.contains('tabaco')) return Icons.smoking_rooms;
    if (name.contains('eucalipto')) return Icons.forest;
    if (name.contains('pinus')) return Icons.forest;
    if (name.contains('mogno')) return Icons.forest;
    if (name.contains('cedro')) return Icons.forest;
    if (name.contains('ipê') || name.contains('ipe')) return Icons.forest;
    if (name.contains('pau-brasil')) return Icons.forest;
    if (name.contains('jacarandá') || name.contains('jacaranda')) return Icons.forest;
    if (name.contains('seringueira')) return Icons.forest;
    if (name.contains('borracha')) return Icons.forest;
    if (name.contains('palmeira')) return Icons.forest;
    if (name.contains('coqueiro')) return Icons.forest;
    if (name.contains('dendê') || name.contains('dende')) return Icons.forest;
    if (name.contains('babaçu') || name.contains('babacu')) return Icons.forest;
    if (name.contains('buriti')) return Icons.forest;
    if (name.contains('açaí') || name.contains('acai')) return Icons.forest;
    if (name.contains('açaí') || name.contains('acai')) return Icons.forest;
    
    return Icons.agriculture;
  }
}
