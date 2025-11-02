import 'package:flutter/material.dart';

/// Widget de dropdown personalizado para o FortSmart Agro
class FortsSmartDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final bool isExpanded;
  final bool isEnabled;
  final EdgeInsetsGeometry? contentPadding;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double? borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? hintColor;
  final String? hintText;

  const FortsSmartDropdown({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.isExpanded = true,
    this.isEnabled = true,
    this.contentPadding,
    this.prefixIcon,
    this.suffixIcon,
    this.borderRadius,
    this.fillColor,
    this.borderColor,
    this.textColor,
    this.hintColor,
    this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final defaultFillColor = isDarkMode 
        ? Colors.grey[800] 
        : Colors.grey[100];
    
    final defaultBorderColor = isDarkMode
        ? Colors.grey[700]
        : Colors.grey[300];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor ?? theme.primaryColor,
              ),
            ),
          ),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: isEnabled ? onChanged : null,
          validator: validator,
          isExpanded: isExpanded,
          icon: suffixIcon ?? const Icon(Icons.arrow_drop_down),
          decoration: InputDecoration(
            filled: true,
            fillColor: isEnabled 
                ? (fillColor ?? defaultFillColor) 
                : Colors.grey[200],
            contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon: prefixIcon,
            hintText: hintText,
            hintStyle: TextStyle(
              color: hintColor ?? Colors.grey[500],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
              borderSide: BorderSide(
                color: borderColor ?? defaultBorderColor!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
              borderSide: BorderSide(
                color: borderColor ?? defaultBorderColor!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
              borderSide: BorderSide(
                color: theme.primaryColor,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
              borderSide: BorderSide(
                color: Colors.grey[400]!,
              ),
            ),
          ),
          style: TextStyle(
            color: isEnabled 
                ? (textColor ?? theme.textTheme.bodyLarge?.color) 
                : Colors.grey[600],
          ),
          dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
        ),
      ],
    );
  }
}

/// Widget de dropdown para seleção de itens com pesquisa
class FortsSmartSearchableDropdown<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemLabel;
  final Widget Function(T)? itemBuilder;
  final bool isEnabled;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? emptyResultWidget;
  final String? Function(String?)? validator;

  const FortsSmartSearchableDropdown({
    Key? key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.itemLabel,
    this.itemBuilder,
    this.isEnabled = true,
    this.hintText,
    this.prefixIcon,
    this.emptyResultWidget,
    this.validator,
  }) : super(key: key);

  @override
  State<FortsSmartSearchableDropdown<T>> createState() => _FortsSmartSearchableDropdownState<T>();
}

class _FortsSmartSearchableDropdownState<T> extends State<FortsSmartSearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _openDropdown();
      } else {
        _closeDropdown();
      }
    });
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _closeDropdown();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FortsSmartSearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filteredItems = List.from(widget.items);
      _filterItems();
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        return widget.itemLabel(item).toLowerCase().contains(query);
      }).toList();
    });
    
    // Atualizar o overlay
    _updateOverlay();
  }

  void _openDropdown() {
    _isOpen = true;
    _createOverlay();
  }

  void _closeDropdown() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _isOpen = false;
  }

  void _updateOverlay() {
    if (_isOpen) {
      _closeDropdown();
      _openDropdown();
    }
  }

  void _createOverlay() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height),
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 200,
                  minWidth: size.width,
                ),
                child: _filteredItems.isEmpty
                    ? widget.emptyResultWidget ?? 
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Nenhum resultado encontrado'),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return InkWell(
                            onTap: () {
                              widget.onChanged(item);
                              _searchController.text = widget.itemLabel(item);
                              _closeDropdown();
                            },
                            child: widget.itemBuilder != null
                                ? widget.itemBuilder!(item)
                                : ListTile(
                                    title: Text(widget.itemLabel(item)),
                                    selected: widget.value == item,
                                  ),
                          );
                        },
                      ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final defaultFillColor = isDarkMode 
        ? Colors.grey[800] 
        : Colors.grey[100];
    
    final defaultBorderColor = isDarkMode
        ? Colors.grey[700]
        : Colors.grey[300];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ),
        CompositedTransformTarget(
          link: _layerLink,
          child: TextFormField(
            controller: _searchController,
            focusNode: _focusNode,
            enabled: widget.isEnabled,
            decoration: InputDecoration(
              filled: true,
              fillColor: widget.isEnabled 
                  ? defaultFillColor
                  : Colors.grey[200],
              hintText: widget.hintText ?? 'Selecione ou pesquise',
              prefixIcon: widget.prefixIcon,
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_drop_down),
                onPressed: widget.isEnabled
                    ? () {
                        if (_isOpen) {
                          _focusNode.unfocus();
                        } else {
                          _focusNode.requestFocus();
                        }
                      }
                    : null,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: defaultBorderColor!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: defaultBorderColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: theme.primaryColor,
                  width: 2.0,
                ),
              ),
            ),
            validator: widget.validator,
          ),
        ),
      ],
    );
  }
}
