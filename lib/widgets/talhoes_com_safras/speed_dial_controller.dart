import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../enums/modo_talhao.dart';

class SpeedDialController extends StatelessWidget {
  final Function() onDesenhoManual;
  final Function() onCaminhadaGps;
  final Function() onImportarArquivo;
  final Function() onCentralizarGps;
  final Function() onApagarDesenho;
  final Function() onSalvarTalhao;
  final bool mostrarBotaoSalvar;
  final ModoTalhao modoAtual;

  const SpeedDialController({
    Key? key,
    required this.onDesenhoManual,
    required this.onCaminhadaGps,
    required this.onImportarArquivo,
    required this.onCentralizarGps,
    required this.onApagarDesenho,
    required this.onSalvarTalhao,
    required this.mostrarBotaoSalvar,
    required this.modoAtual,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: const IconThemeData(size: 22.0),
      backgroundColor: Theme.of(context).primaryColor,
      visible: true,
      curve: Curves.bounceIn,
      children: [
        // Botão de Desenho Manual
        SpeedDialChild(
          child: const Icon(Icons.edit),
          backgroundColor: modoAtual == ModoTalhao.desenhoManual 
              ? Colors.green 
              : Colors.blue,
          label: 'Desenho Manual',
          labelStyle: const TextStyle(fontSize: 16.0),
          onTap: onDesenhoManual,
        ),
        
        // Botão de Caminhada GPS
        SpeedDialChild(
          child: const Icon(Icons.directions_walk),
          backgroundColor: modoAtual == ModoTalhao.caminhadaGPS 
              ? Colors.green 
              : Colors.blue,
          label: 'Caminhada GPS',
          labelStyle: const TextStyle(fontSize: 16.0),
          onTap: onCaminhadaGps,
        ),
        
        // Botão de Importar Arquivo
        SpeedDialChild(
          child: const Icon(Icons.file_upload),
          backgroundColor: modoAtual == ModoTalhao.importacao 
              ? Colors.green 
              : Colors.blue,
          label: 'Importar Arquivo',
          labelStyle: const TextStyle(fontSize: 16.0),
          onTap: onImportarArquivo,
        ),
        
        // Botão de Centralizar GPS
        SpeedDialChild(
          child: const Icon(Icons.my_location),
          backgroundColor: Colors.blue,
          label: 'Centralizar GPS',
          labelStyle: const TextStyle(fontSize: 16.0),
          onTap: onCentralizarGps,
        ),
        
        // Botão de Apagar Desenho (visível apenas em modo de desenho manual)
        if (modoAtual == ModoTalhao.desenhoManual)
          SpeedDialChild(
            child: const Icon(Icons.delete),
            backgroundColor: Colors.red,
            label: 'Apagar Desenho',
            labelStyle: const TextStyle(fontSize: 16.0),
            onTap: onApagarDesenho,
          ),
        
        // Botão de Salvar (visível apenas quando há pontos suficientes)
        if (mostrarBotaoSalvar)
          SpeedDialChild(
            child: const Icon(Icons.save),
            backgroundColor: Colors.green,
            label: 'Salvar Talhão',
            labelStyle: const TextStyle(fontSize: 16.0),
            onTap: onSalvarTalhao,
          ),
      ],
    );
  }
}
