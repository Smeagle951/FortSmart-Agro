import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/novo_talhao_controller.dart';
import 'novo_talhao_screen_elegant.dart';

/// Wrapper para a tela NovoTalhaoScreen que fornece todos os providers necessários
class NovoTalhaoScreenWrapper extends StatefulWidget {
  const NovoTalhaoScreenWrapper({Key? key}) : super(key: key);

  @override
  State<NovoTalhaoScreenWrapper> createState() => _NovoTalhaoScreenWrapperState();
}

class _NovoTalhaoScreenWrapperState extends State<NovoTalhaoScreenWrapper> {
  late NovoTalhaoController _controller;

  @override
  void initState() {
    super.initState();
    print('Wrapper: Criando controller...');
    _controller = NovoTalhaoController();
    print('Wrapper: Controller criado: $_controller');
    print('Wrapper: MapController: ${_controller.mapController}');
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: const NovoTalhaoScreenElegant(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
