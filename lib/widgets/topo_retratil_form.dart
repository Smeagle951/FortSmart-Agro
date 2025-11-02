import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/cultura_model.dart';

class TopoRetratilFormPremium extends StatefulWidget {
  final TextEditingController nomeController;
  final String safraSelecionada;
  final List<String> safraOpcoes;
  final String? culturaSelecionada;
  final List<CulturaModel> culturaOpcoes;
  final ValueChanged<String?> onCulturaChanged;
  final ValueChanged<String?> onSafraChanged;
  final bool aberto;
  final VoidCallback onExpandir;
  final String? culturaIdInicial;
  final String nomeInicial;
  final Function(String nome) onNomeChanged;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final String? errorMessage;

  const TopoRetratilFormPremium({
    Key? key,
    required this.nomeController,
    required this.safraSelecionada,
    required this.safraOpcoes,
    required this.culturaSelecionada,
    required this.culturaOpcoes,
    required this.onSafraChanged,
    required this.onCulturaChanged,
    required this.aberto,
    required this.onExpandir,
    required this.nomeInicial,
    required this.onNomeChanged,
    this.culturaIdInicial,
    this.isLoading = false,
    this.onRefresh,
    this.errorMessage,
  }) : super(key: key);

  @override
  State<TopoRetratilFormPremium> createState() => _TopoRetratilFormPremiumState();
}

class _TopoRetratilFormPremiumState extends State<TopoRetratilFormPremium> 
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _expandAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  
  bool _nomeHasError = false;
  bool _safraHasError = false;
  bool _culturaHasError = false;
  String? _nomeErrorText;
  
  // Converte uma string hexadecimal em um objeto Color
  Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  void initState() {
    super.initState();
    
    // Animação de expansão/recolhimento
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
      value: widget.aberto ? 1 : 0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController, 
      curve: Curves.easeInOutCubic,
    );
    
    // Animação de pulse para estados de loading
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Animação shimmer para loading
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    
    if (widget.isLoading) {
      _startLoadingAnimations();
    }
    
    // Listener para validação em tempo real
    widget.nomeController.addListener(_validateNome);
  }

  void _startLoadingAnimations() {
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();
  }

  void _stopLoadingAnimations() {
    _pulseController.stop();
    _shimmerController.stop();
  }

  void _validateNome() {
    final nome = widget.nomeController.text.trim();
    setState(() {
      if (nome.isEmpty) {
        _nomeHasError = true;
        _nomeErrorText = 'Nome é obrigatório';
      } else if (nome.length < 3) {
        _nomeHasError = true;
        _nomeErrorText = 'Nome deve ter pelo menos 3 caracteres';
      } else if (nome.length > 50) {
        _nomeHasError = true;
        _nomeErrorText = 'Nome deve ter no máximo 50 caracteres';
      } else {
        _nomeHasError = false;
        _nomeErrorText = null;
      }
    });
    widget.onNomeChanged(nome);
  }

  @override
  void didUpdateWidget(covariant TopoRetratilFormPremium oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.aberto != oldWidget.aberto) {
      if (widget.aberto) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
    
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _startLoadingAnimations();
      } else {
        _stopLoadingAnimations();
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    widget.nomeController.removeListener(_validateNome);
    super.dispose();
  }
  
  String? _getValidCulturaValue() {
    if (widget.culturaOpcoes.isEmpty) return null;
    if (widget.culturaSelecionada == null) return widget.culturaOpcoes.first.id.toString();
    
    bool valorExiste = widget.culturaOpcoes.any((cultura) => cultura.id.toString() == widget.culturaSelecionada);
    return valorExiste ? widget.culturaSelecionada : widget.culturaOpcoes.first.id.toString();
  }
  
  String? _getValidSafraValue() {
    if (widget.safraOpcoes.isEmpty) return null;
    if (widget.safraSelecionada.isEmpty) return widget.safraOpcoes.first;
    
    bool valorExiste = widget.safraOpcoes.contains(widget.safraSelecionada);
    return valorExiste ? widget.safraSelecionada : widget.safraOpcoes.first;
  }

  Widget _buildShimmerEffect({required Widget child}) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.transparent,
                Colors.white54,
                Colors.transparent,
              ],
              stops: [
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }

  Widget _buildPremiumTextField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _nomeHasError 
          ? [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: TextField(
        controller: widget.nomeController,
        maxLength: 50,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-_]')),
        ],
        decoration: InputDecoration(
          labelText: 'Nome do Talhão',
          hintText: 'Ex: Talhão Norte, Quadra A1...',
          errorText: _nomeErrorText,
          prefixIcon: Icon(
            Icons.location_on_outlined,
            color: _nomeHasError ? Colors.red : Theme.of(context).primaryColor,
          ),
          suffixIcon: widget.nomeController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  widget.nomeController.clear();
                  widget.onNomeChanged('');
                },
              )
            : null,
          counterText: '${widget.nomeController.text.length}/50',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _nomeHasError 
            ? Colors.red.withOpacity(0.05) 
            : Colors.grey.withOpacity(0.08),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: _nomeHasError ? Colors.red : Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: _nomeHasError ? Colors.red : Colors.transparent,
              width: _nomeHasError ? 1 : 0,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    required IconData prefixIcon,
    required bool hasError,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: hasError 
          ? [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          prefixIcon: Icon(
            prefixIcon,
            color: hasError ? Colors.red : Theme.of(context).primaryColor,
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: hasError 
            ? Colors.red.withOpacity(0.05) 
            : Colors.grey.withOpacity(0.08),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: hasError ? Colors.red : Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.transparent,
              width: hasError ? 1 : 0,
            ),
          ),
        ),
        validator: (value) {
          if (value == null) {
            return 'Selecione uma opção';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: _buildShimmerEffect(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Carregando...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
          if (widget.onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.red, size: 20),
              onPressed: widget.onRefresh,
              tooltip: 'Tentar novamente',
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      axisAlignment: -1.0,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.withOpacity(0.02),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com nome e botão de expandir
            Row(
              children: [
                Expanded(child: _buildPremiumTextField()),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: AnimatedRotation(
                      turns: widget.aberto ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.expand_more,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onExpandir();
                    },
                    tooltip: widget.aberto ? 'Recolher' : 'Expandir',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Dropdowns em linha
            Row(
              children: [
                // Dropdown de Safra
                Expanded(
                  child: widget.errorMessage != null
                    ? _buildErrorState('Erro ao carregar safras')
                    : widget.isLoading || widget.safraOpcoes.isEmpty
                      ? _buildLoadingState()
                      : _buildPremiumDropdown<String>(
                          label: 'Safra',
                          value: _getValidSafraValue(),
                          items: widget.safraOpcoes
                              .map((safra) => DropdownMenuItem<String>(
                                    value: safra,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(safra),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: widget.onSafraChanged,
                          prefixIcon: Icons.calendar_today_outlined,
                          hasError: _safraHasError,
                        ),
                ),
                
                const SizedBox(width: 16),
                
                // Dropdown de Cultura
                Expanded(
                  child: widget.errorMessage != null
                    ? _buildErrorState('Erro ao carregar culturas')
                    : widget.isLoading || widget.culturaOpcoes.isEmpty
                      ? _buildLoadingState()
                      : _buildPremiumDropdown<String>(
                          label: 'Cultura',
                          value: _getValidCulturaValue(),
                          items: widget.culturaOpcoes
                              .map((cultura) => DropdownMenuItem<String>(
                                    value: cultura.id.toString(),
                                    child: Row(
                                      children: [
                                        Hero(
                                          tag: 'cultura_${cultura.id}',
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  cultura.color,
                                                  cultura.color.withOpacity(0.8),
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: cultura.color.withOpacity(0.4),
                                                  blurRadius: 4,
                                                  spreadRadius: 0,
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                (cultura.name.isNotEmpty) 
                                                  ? cultura.name[0].toUpperCase() 
                                                  : '-',
                                                style: const TextStyle(
                                                  fontSize: 12, 
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Text(
                                            cultura.name,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: widget.onCulturaChanged,
                          prefixIcon: Icons.eco_outlined,
                          hasError: _culturaHasError,
                        ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Footer com informações e status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Culturas importadas do módulo Culturas e Pragas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  if (widget.culturaOpcoes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.culturaOpcoes.length} culturas',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Object? {
  get nome => null;
  
  get cor => null;
  
  get id => null;
  
  withOpacity(double d) {}
}